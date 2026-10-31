// Flutty Dock 칸 — 실기기·데스크톱 빌드/설치/실행 (flutty-dock-flutter 이식, PLAN.md 단계 4).
//
// 공유 영역의 폴더(Workspace.selectedDir)에서 Flutter 프로젝트를 depth 0 → 1 로 찾고(여럿이면 드롭다운),
// 고른 프로젝트를 [FluttyController]에 넘긴다. 칸이 접혀 있어도 이 객체는 살아 있어 빌드가 이어지고,
// 브랜치가 바뀌면(onHeadChange) 프로젝트를 다시 찾고 실행 중이었다면 배너로 알린다 (§1.10, 중단하지 않음).

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/tool_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/taskbench_style.dart';
import '../../workspace/git_state.dart';
import '../../workspace/project_detector.dart';
import '../../workspace/workspace.dart';
import '../dock_module.dart';
import 'devices/device_service.dart';
import 'doctor/diagnostics.dart';
import 'flutter/flutter_project.dart';
import 'install/flutty_controller.dart';
import 'ui/flutty_dock_body.dart';

class FluttyDock extends DockModule {
  // ignore: prefer_initializing_formals
  FluttyDock({this.detector = const FlutterDetector(), this.tools, FluttyController? controller}) : _controller = controller;

  final ProjectDetector detector;

  /// 설정 창 "도구" 구역에 flutter·adb 줄을 더하려고 받는다 (없으면 더하지 않음 — 테스트).
  final ToolPaths? tools;

  FluttyController? _controller;
  bool _ownsController = false;

  /// 화면과 테스트가 읽는다. [attach] 전에는 null.
  FluttyController? get controller => _controller;

  List<DetectedProject> _projects = const [];
  String? _forDir;
  int _generation = 0;
  Workspace? _workspace;
  bool _disposed = false;

  /// 빌드가 도는 동안 브랜치가 바뀌었다는 알림 (배너). 사용자가 닫거나 실행이 끝나면 사라진다.
  String? branchChangedWhileRunning;

  List<DetectedProject> get projects => _projects;

  /// 여럿일 때 고른 프로젝트. 선택은 고른 폴더별로 기억한다 (`flutty.project_choice:<dir>`).
  DetectedProject? selected(Workspace w) {
    if (_projects.isEmpty) return null;
    final saved = w.prefs.getString('flutty.project_choice:${w.selectedDir}');
    return _projects.firstWhere((p) => p.path == saved, orElse: () => _projects.first);
  }

  Future<void> choose(Workspace w, DetectedProject p) async {
    await w.prefs.setString('flutty.project_choice:${w.selectedDir}', p.path);
    await _syncProject(w);
    notifyListeners();
  }

  /// 칸이 처음 펼쳐질 때 기기·환경 점검을 시작한다.
  void ensureStarted() => _controller?.init();

  void dismissBranchBanner() {
    branchChangedWhileRunning = null;
    notifyListeners();
  }

  @override
  String get id => 'flutty';

  @override
  IconData get icon => Icons.play_circle_outline_rounded;

  @override
  bool get isRunner => true;

  @override
  String title(AppLocalizations l10n) => l10n.dockFluttyTitle;

  @override
  bool appliesTo(Workspace w) => _projects.isNotEmpty;

  @override
  void attach(Workspace w) {
    _workspace = w;
    if (_controller == null) {
      _ownsController = true;
      _controller = FluttyController(
        runner: w.runner,
        deviceService: ProcessDeviceService(w.runner),
        diagnosticsService: ProcessDiagnosticsService(w.runner),
      );
    }
    _controller!.addListener(_onController);
    _registerTools();
    w.addListener(_onWorkspace);
    _onWorkspace();
  }

  void _registerTools() {
    final t = tools;
    if (t == null) return;
    t
      ..register(const ToolSpec('flutter', 'flutter'))
      ..register(const ToolSpec('adb', 'adb (Android)'));
    final previous = t.onChanged;
    t.onChanged = () {
      previous?.call();
      _controller?.toolsChanged();
    };
  }

  @override
  void detach(Workspace w) {
    w.removeListener(_onWorkspace);
    _controller?.removeListener(_onController);
    _workspace = null;
    _generation++; // 진행 중이던 검색 결과는 버린다
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  void _onController() {
    final c = _controller;
    if (c != null && !c.running) branchChangedWhileRunning = null;
    if (!_disposed) notifyListeners();
  }

  void _onWorkspace() {
    final w = _workspace;
    if (w == null) return;
    if (w.selectedDir != _forDir) _detect(w);
  }

  Future<void> _detect(Workspace w) async {
    final dir = w.selectedDir;
    _forDir = dir;
    final gen = ++_generation;
    var found = const <DetectedProject>[];
    if (dir != null) {
      try {
        found = await detector.detect(dir);
      } on FileSystemException {
        // 브랜치를 바꾸는 사이 파일이 사라졌다 — 없는 것으로 보고, 다음 변화에서 다시 찾는다.
      }
    }
    if (gen != _generation || _disposed) return; // 그 사이 폴더가 또 바뀌었거나 칸이 사라졌다
    _projects = found;
    await _syncProject(w, generation: gen);
    if (gen != _generation || _disposed) return;
    notifyListeners();
  }

  /// 고른 프로젝트의 상세(플랫폼 폴더, 번들 ID …)를 읽어 컨트롤러에 넘긴다.
  Future<void> _syncProject(Workspace w, {int? generation}) async {
    final c = _controller;
    if (c == null) return;
    final picked = selected(w);
    FlutterProject? detail;
    if (picked != null) {
      try {
        detail = await FlutterProject.detect(picked.path);
      } on FileSystemException {
        // 위와 같다.
      }
    }
    if (_disposed || (generation != null && generation != _generation)) return;
    await c.setProject(detail);
  }

  @override
  void onHeadChange(Workspace w, HeadChange change) {
    // 브랜치에 따라 pubspec·하위 프로젝트가 생기거나 사라질 수 있다 — 다시 찾는다 (§1.10).
    if (change.kind != HeadChangeKind.branch && change.kind != HeadChangeKind.commit) return;
    if (change.kind == HeadChangeKind.branch && (_controller?.running ?? false)) {
      branchChangedWhileRunning = change.to.branch ?? change.to.sha ?? '';
      notifyListeners();
    }
    _detect(w);
  }

  @override
  TaskbenchMood mood(Workspace w) {
    final c = _controller;
    if (c == null) return TaskbenchMood.idle;
    if (c.running || c.cleaning) return TaskbenchMood.working;
    if (c.statuses.contains(StepStatus.failed)) return TaskbenchMood.failed;
    if (c.statuses.isNotEmpty && c.statuses.every((s) => s == StepStatus.done)) return TaskbenchMood.success;
    return TaskbenchMood.idle;
  }

  @override
  bool busy(Workspace w) => (_controller?.running ?? false) || (_controller?.cleaning ?? false);

  @override
  Widget summary(BuildContext context, Workspace w) {
    final p = selected(w);
    if (p == null) return const SizedBox.shrink();
    return Text(
      p.version == null ? p.name : '${p.name} ${p.version}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  @override
  Widget body(BuildContext context, Workspace w) => FluttyDockBody(dock: this, workspace: w);
}
