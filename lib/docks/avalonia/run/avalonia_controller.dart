// Avalonia 칸의 상태: 앱·동작·옵션을 고르고 계획을 실행한다 (docs/AVALONIA_RUNNER.md §4).
// 칸이 접혀 있어도 이 객체는 살아 있어 실행이 이어진다. 프로세스를 띄우는 일(환경 점검)은 칸이 처음 펼쳐질 때 시작한다.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/check_status.dart';
import '../../../core/command_runner.dart';
import '../../../core/run_session.dart';
import '../detect/avalonia_project.dart';
import 'avalonia_plan.dart';

enum AvaloniaCheckId { dotnet, project, solution, aot }

/// 점검 항목 한 줄. 문구는 화면이 [id]·[status]·[value] 로 만든다.
class AvaloniaCheck {
  const AvaloniaCheck(this.id, this.status, [this.value]);

  final AvaloniaCheckId id;
  final CheckStatus status;
  final String? value;
}

/// 환경 점검을 프로세스 없이 테스트하려고 뗀 경계.
abstract interface class AvaloniaDiagnosticsService {
  /// `dotnet --version` 의 결과. dotnet 을 못 찾으면 null.
  Future<String?> dotnetVersion();

  /// NativeAOT 링크에 필요한 vswhere 를 쓸 수 있는가 (PATH 또는 표준 위치). Windows 가 아니면 필요 없어 true.
  bool vswhereAvailable();
}

class ProcessAvaloniaDiagnostics implements AvaloniaDiagnosticsService {
  ProcessAvaloniaDiagnostics(this.runner);

  final CommandRunner runner;

  @override
  Future<String?> dotnetVersion() async {
    final r = await runner.run(['dotnet', '--version'], quiet: true, environment: const {'DOTNET_CLI_TELEMETRY_OPTOUT': '1', 'DOTNET_NOLOGO': '1'});
    final v = r.stdout.trim().split('\n').first.trim();
    return r.ok && v.isNotEmpty ? v : null;
  }

  @override
  bool vswhereAvailable() {
    if (!Platform.isWindows) return true;
    return runner.locate('vswhere') != null || File('$vswhereDir\\vswhere.exe').existsSync();
  }
}

class AvaloniaController extends ChangeNotifier {
  AvaloniaController({
    required this.runner,
    required this.prefs,
    AvaloniaDiagnosticsService? diagnosticsService,
    bool? hostIsWindows,
    bool? hostIsMacOS,
    bool? vswhereDirExists,
  })  : diagnosticsService = diagnosticsService ?? ProcessAvaloniaDiagnostics(runner),
        hostIsWindows = hostIsWindows ?? Platform.isWindows,
        hostIsMacOS = hostIsMacOS ?? Platform.isMacOS,
        // ignore: prefer_initializing_formals
        _vswhereDirExists = vswhereDirExists;

  final CommandRunner runner;
  final SharedPreferences prefs;
  final AvaloniaDiagnosticsService diagnosticsService;
  final bool hostIsWindows;
  final bool hostIsMacOS;
  final bool? _vswhereDirExists;

  // 저장 키는 모두 `avalonia.` 접두어. 폴더마다 따로 저장하는 값은 `<접두어>:<프로젝트 경로>`.
  static const _tabIdKey = 'avalonia.last_tab_id';
  static const _appKeyPrefix = 'avalonia.app:';
  static const _actionKeyPrefix = 'avalonia.action:';
  static const _optionsKeyPrefix = 'avalonia.options:';

  /// 화면의 탭 순서. 저장은 번호가 아니라 이름으로 한다.
  static const tabIds = ['run', 'log'];

  AvaloniaProject? project;
  AvaloniaApp? app;
  AvaloniaAction action = AvaloniaAction.run;
  AvaloniaOptions options = const AvaloniaOptions();

  bool running = false;
  List<StepStatus> statuses = const [];
  AvaloniaFailure? hint;
  String? missingCommand;

  /// 마지막으로 시작한 동작 (접힌 제목의 "…중/실패/완료" 문구에 쓴다).
  AvaloniaAction? lastAction;

  int tabIndex = 0;
  bool started = false;

  /// 환경 점검 결과. 브랜치가 바뀐 뒤에는 오래된 값으로 표시한다 (§1.10).
  List<AvaloniaCheck> checks = const [];
  bool diagnosing = false;
  bool diagnosticsStale = false;

  late final RunSession _session = RunSession(runner);

  bool get busy => running || diagnosing;

  List<AvaloniaAction> get actions => AvaloniaAction.values;

  bool get _vswhereDir => _vswhereDirExists ?? (hostIsWindows && Directory(vswhereDir).existsSync());

  AvaloniaPlan get plan => buildAvaloniaPlan(
        project: project,
        app: app,
        action: action,
        options: options,
        isWindows: hostIsWindows,
        isMacOS: hostIsMacOS,
        basePath: runner.effectivePath,
        vswhereDirExists: _vswhereDir,
      );

  /// 칸이 처음 펼쳐질 때 불린다 — 환경 점검을 시작한다.
  Future<void> init() async {
    if (started) return;
    started = true;
    final i = tabIds.indexOf(prefs.getString(_tabIdKey) ?? '');
    if (i >= 0) tabIndex = i;
    await runDiagnostics();
  }

  void ensureStarted() {
    if (!started) init();
  }

  String _k(String prefix) => '$prefix${project?.path}';

  void selectTab(int i) {
    tabIndex = i;
    prefs.setString(_tabIdKey, tabIds[i]);
    notifyListeners();
  }

  /// 고른 프로젝트의 상세가 바뀌었다. 폴더별로 저장한 선택을 복원한다.
  void setProject(AvaloniaProject? p) {
    final sameProject = p != null && project?.path == p.path;
    project = p;
    if (!sameProject) {
      statuses = const [];
      hint = null;
      missingCommand = null;
    }
    if (p == null) {
      app = null;
      notifyListeners();
      return;
    }
    final saved = prefs.getString(_k(_appKeyPrefix));
    app = p.apps.where((a) => a.relativePath == saved).firstOrNull ?? p.apps.firstOrNull;
    final savedAction = prefs.getString(_k(_actionKeyPrefix));
    action = AvaloniaAction.values.where((a) => a.name == savedAction).firstOrNull ?? AvaloniaAction.run;
    options = AvaloniaOptions.fromJson(prefs.getString(_k(_optionsKeyPrefix)));
    notifyListeners();
    if (started && !sameProject) runDiagnostics();
  }

  void selectApp(AvaloniaApp a) {
    app = a;
    prefs.setString(_k(_appKeyPrefix), a.relativePath);
    notifyListeners();
  }

  void selectAction(AvaloniaAction a) {
    action = a;
    prefs.setString(_k(_actionKeyPrefix), a.name);
    notifyListeners();
  }

  void setOptions(AvaloniaOptions o) {
    options = o;
    prefs.setString(_k(_optionsKeyPrefix), o.toJson());
    notifyListeners();
  }

  /// 환경(dotnet SDK·프로젝트·솔루션·AOT 링크 도구)을 점검한다. 칸이 처음 펼쳐질 때와 사용자가 요청할 때만 한다.
  Future<void> runDiagnostics() async {
    if (diagnosing) return;
    diagnosing = true;
    notifyListeners();
    final version = await diagnosticsService.dotnetVersion();
    final p = project;
    checks = [
      AvaloniaCheck(AvaloniaCheckId.dotnet, version == null ? CheckStatus.fail : CheckStatus.ok, version),
      AvaloniaCheck(AvaloniaCheckId.project, p == null || p.apps.isEmpty ? CheckStatus.fail : CheckStatus.ok, p?.apps.length.toString()),
      AvaloniaCheck(AvaloniaCheckId.solution, p?.solution == null ? CheckStatus.warn : CheckStatus.ok, p?.solution),
      AvaloniaCheck(AvaloniaCheckId.aot, diagnosticsService.vswhereAvailable() ? CheckStatus.ok : CheckStatus.warn),
    ];
    diagnosticsStale = false;
    diagnosing = false;
    notifyListeners();
  }

  /// 도구 경로를 바꾼 뒤 — 점검을 다시 한다.
  void toolsChanged() {
    if (started) runDiagnostics();
  }

  /// 브랜치가 바뀐 뒤 점검 결과를 오래된 것으로 표시한다 (§1.10).
  void markDiagnosticsStale() {
    if (!started || checks.isEmpty || diagnosticsStale) return;
    diagnosticsStale = true;
    notifyListeners();
  }

  /// 계획의 단계를 차례로 실행한다. 하나라도 실패하면 거기서 멈춘다.
  Future<void> start() async {
    final p = plan;
    if (running || !p.runnable) return;
    running = true;
    hint = null;
    missingCommand = null;
    lastAction = action;
    statuses = List.filled(p.steps.length, StepStatus.pending);
    notifyListeners();
    final out = await _session.run(p.steps, List.generate(p.steps.length, (i) => i), onStatus: (i, s) {
      statuses[i] = s;
      notifyListeners();
    });
    final failed = out.failedIndex;
    if (failed != null) {
      final r = out.failedResult!;
      if (r.exitCode == 127) missingCommand = p.steps[failed].args.first;
      hint = explainAvaloniaFailure(r.combined);
    }
    running = false;
    notifyListeners();
  }

  void cancel() => _session.cancel();
}
