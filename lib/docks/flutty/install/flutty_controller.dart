import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/command_runner.dart';
import '../../../core/run_session.dart';
import '../devices/device_service.dart';
import '../doctor/checks.dart';
import '../doctor/diagnostics.dart';
import '../devices/mobile_device.dart';
import '../flutter/flutter_project.dart';
import 'build_options.dart';
import 'install_plan.dart';

// [Taskbench에서 달라진 곳] StepStatus 는 core/run_session.dart 로 옮겼다. 기존 import 가 그대로 동작하도록 다시 내보낸다.
export '../../../core/run_session.dart' show StepStatus;

/// 같은 폴더인지: `\`와 `/`, 끝의 구분자, (Windows·macOS의) 대소문자 차이는 무시한다.
bool samePath(String a, String b) => _pathKey(a) == _pathKey(b);

String _pathKey(String p) {
  final k = p.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  return Platform.isWindows || Platform.isMacOS ? k.toLowerCase() : k;
}


/// 프로젝트·기기·모드를 고르고 계획을 실행하는 화면의 상태.
class FluttyController extends ChangeNotifier {
  FluttyController({
    required this.runner,
    required this.deviceService,
    this.diagnosticsService,
    bool? hostIsMac,
    bool? hostIsWindows,
  }) : hostIsMac = hostIsMac ?? Platform.isMacOS,
       hostIsWindows = hostIsWindows ?? Platform.isWindows;

  /// 이 앱이 도는 OS. 이 컴퓨터를 빌드 대상으로 보여 줄지(데스크톱)와 iOS 설치 가능 여부가 여기에 달렸다.
  final bool hostIsMac;
  final bool hostIsWindows;

  // [Taskbench에서 달라진 곳] 저장 키는 모두 `flutty.` 접두어. 마지막 프로젝트·최근 프로젝트·도구 경로는
  // 공유 영역(Workspace)과 ToolPaths 가 맡으므로 여기서 뺐다.
  static const _teamKey = 'flutty.ios_team_id';
  static const _modeKey = 'flutty.build_mode';
  static const _tabIdKey = 'flutty.last_tab_id';
  static const _optionsKeyPrefix = 'flutty.build_options:';
  static const _projectModeKeyPrefix = 'flutty.project_mode:';
  static const _projectDeviceKeyPrefix = 'flutty.project_device:';

  /// 사용자가 위치를 지정할 수 있는 도구. 설정 창의 "도구" 구역(ToolPaths)에 등록된다.
  static const configurableTools = ['flutter', 'adb'];

  final CommandRunner runner;
  final DeviceService deviceService;
  final DiagnosticsService? diagnosticsService;

  SharedPreferences? _prefs;
  FlutterProject? project;
  String? projectError;

  List<MobileDevice> devices = const [];
  bool loadingDevices = false;
  String? selectedId;
  BuildMode mode = BuildMode.release;
  String? teamId;

  /// 이 프로젝트에서 마지막으로 직접 고른 대상. 그 기기가 보이면 기본 선택보다 이것을 쓴다.
  String? _preferredId;

  /// 이 프로젝트를 연 뒤 대상을 직접 골랐는지 — 골랐다면 기기 목록이 갱신돼도 바꾸지 않는다.
  bool _userPicked = false;

  /// 이 프로젝트의 빌드 옵션 (flavor, 진입 파일, dart-define 파일 …). 프로젝트마다 따로 저장한다.
  BuildOptions options = const BuildOptions();

  Diagnostics? diagnostics;

  /// 브랜치가 바뀐 뒤 아직 다시 읽지 않은 점검 결과 (§1.10 — 오래된 값으로 보이게 하고 다시 확인을 권한다).
  bool diagnosticsStale = false;
  bool diagnosing = false;

  /// 화면의 탭 순서. 저장은 번호가 아니라 이름으로 한다 — 탭이 늘어도 저장된 값이 엉뚱한 탭을 가리키지 않는다.
  static const tabIds = ['run', 'devices', 'signing', 'doctor', 'log'];

  /// 마지막으로 보던 탭의 번호 ([tabIds] 기준).
  int tabIndex = 0;

  /// 저장된 탭을 읽었는지 — 화면이 한 번만 그 탭으로 옮긴다.
  bool tabLoaded = false;

  bool running = false;

  /// `flutter clean` + `flutter pub get`을 실행 중인지, 마지막 결과(null이면 아직 안 함).
  bool cleaning = false;
  bool? cleanResult;
  List<StepStatus> statuses = const [];
  FailureHint? hint;

  /// 실행 파일을 찾지 못해 실패했을 때 그 이름 (`flutter`, `adb` …).
  String? missingCommand;
  late final RunSession _session = RunSession(runner);

  /// 화면에 보이는 대상: 연결된 실기기 + (프로젝트가 이 OS의 데스크톱을 이미 지원하면) 이 컴퓨터.
  List<MobileDevice> get visibleDevices {
    final host = hostDesktopDevice(
      project,
      isMac: hostIsMac,
      isWindows: hostIsWindows,
    );
    return [...devices, ?host];
  }

  MobileDevice? get device {
    for (final d in visibleDevices) {
      if (d.id == selectedId) return d;
    }
    return null;
  }

  /// 이 프로젝트가 그 대상의 플랫폼을 지원하는지 (프로젝트를 아직 안 열었으면 지원한다고 본다).
  bool _supports(MobileDevice d) {
    final p = project;
    if (p == null) return true;
    return switch (d.platform) {
      DevicePlatform.ios => p.hasIos,
      DevicePlatform.android => p.hasAndroid,
      DevicePlatform.macos => p.hasMacos,
      DevicePlatform.windows => p.hasWindows,
    };
  }

  /// 프로젝트가 지원하는 대상을 먼저, 그중 USB로 연결된 실기기를 먼저 고른다. 없으면 보이는 첫 대상.
  void _pickDefaultDevice() {
    final all = visibleDevices;
    final supported = all.where(_supports).toList();
    selectedId = [
      ...supported.where((d) => d.isUsb),
      ...supported,
      ...all.where((d) => d.isUsb),
      ...all,
    ].firstOrNull?.id;
  }

  /// 입력한 Team ID → 프로젝트의 Team ID → 키체인에 쓸 수 있는 인증서가 하나뿐이면 그 Team 순서.
  String? get effectiveTeamId {
    if (teamId != null) return teamId;
    if (project?.iosTeamId != null) return project!.iosTeamId;
    final teams = diagnostics?.usableTeams ?? const <String>{};
    return teams.length == 1 ? teams.single : null;
  }

  InstallPlan get plan => buildInstallPlan(
    project: project,
    device: device,
    mode: mode,
    teamId: effectiveTeamId,
    hostIsMac: hostIsMac,
    // Windows ARM에서는 산출물이 build\windows\arm64 아래에 생긴다.
    windowsArch:
        Platform.environment['PROCESSOR_ARCHITECTURE']?.toUpperCase() == 'ARM64'
        ? 'arm64'
        : 'x64',
    options: options,
  );

  List<CheckItem> get checks => buildChecks(
    diagnostics: diagnostics,
    project: project,
    device: device,
    teamId: effectiveTeamId,
    hostIsMac: hostIsMac,
    hostIsWindows: hostIsWindows,
    now: DateTime.now(),
  );

  /// 도구·인증서·프로파일·키스토어를 다시 읽는다.
  Future<void> runDiagnostics() async {
    final service = diagnosticsService;
    if (service == null) return;
    // 읽는 도중에 다시 요청되면(도구 경로를 방금 바꾼 경우 등) 끝난 뒤 한 번 더 읽는다.
    if (diagnosing) {
      _diagnoseAgain = true;
      return;
    }
    diagnosing = true;
    notifyListeners();
    do {
      _diagnoseAgain = false;
      final result = await service.collect(project);
      // 읽는 사이에 다시 요청됐다면 이 결과는 이미 낡았다 — 보여 주지 않는다.
      if (!_diagnoseAgain) {
        diagnostics = result;
        diagnosticsStale = false;
      }
    } while (_diagnoseAgain);
    diagnosing = false;
    notifyListeners();
  }

  bool _diagnoseAgain = false;

  /// [init]을 했는지. 하기 전에는 기기·점검을 읽지 않는다 (칸을 처음 펼칠 때 시작한다 — 앱 시작을 늦추지 않는다).
  bool started = false;

  /// 저장값을 읽는다. 프로젝트는 [setProject]로 따로 받는다.
  Future<void> init() async {
    if (started) return;
    started = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      teamId = _prefs!.getString(_teamKey);
      mode =
          BuildMode.values.asNameMap()[_prefs!.getString(_modeKey)] ??
          BuildMode.release;
      tabIndex = _savedTabIndex();
      tabLoaded = true;
    } on Object {
      // 기억해 둔 값은 편의일 뿐이다.
    }
    notifyListeners();
    await Future.wait([refreshDevices(), runDiagnostics()]);
  }

  /// 칸이 고른 프로젝트를 받는다 ([FluttyDock]이 부른다). 같은 폴더면 정보(버전·이름)만 새로 읽는다.
  /// [Taskbench에서 달라진 곳] 원본의 openProject·최근 목록·git 상태는 공유 영역으로 옮겨 갔다.
  Future<void> setProject(FlutterProject? next) async {
    final same = next != null && project?.path == next.path;
    project = next;
    if (!same) {
      _loadOptions();
      _loadSelection();
      _applyPreferredDevice();
      statuses = const [];
      hint = null;
      if (next != null && device == null) _pickDefaultDevice();
    }
    notifyListeners();
    if (started) await runDiagnostics();
  }

  Future<void> refreshDevices() async {
    loadingDevices = true;
    notifyListeners();
    final found = await deviceService.list();
    devices = found;
    if (device == null) _pickDefaultDevice();
    // 기기가 늦게 잡혀도(케이블을 나중에 꽂은 경우) 이 프로젝트에서 쓰던 대상으로 돌아간다.
    _applyPreferredDevice();
    loadingDevices = false;
    notifyListeners();
  }

  /// 도구 경로가 바뀐 뒤(ToolPaths.onChanged) 기기·점검을 다시 읽는다.
  Future<void> toolsChanged() async {
    diagnostics = null;
    notifyListeners();
    await Future.wait([refreshDevices(), runDiagnostics()]);
  }

  /// 저장된 탭의 번호. 모르면 첫 탭.
  int _savedTabIndex() {
    final i = tabIds.indexOf(_prefs!.getString(_tabIdKey) ?? '');
    return i < 0 ? 0 : i;
  }

  void setTab(int i) {
    if (i == tabIndex || i < 0 || i >= tabIds.length) return;
    tabIndex = i;
    _prefs?.setString(_tabIdKey, tabIds[i]);
  }

  void select(MobileDevice d) {
    selectedId = d.id;
    _userPicked = true;
    _preferredId = d.id;
    final p = project;
    if (p != null) _prefs?.setString(_projectDeviceKeyPrefix + p.path, d.id);
    notifyListeners();
  }

  /// 이 프로젝트에서 마지막으로 고른 모드·대상을 읽는다. 저장된 것이 없으면 지금 값을 그대로 둔다.
  void _loadSelection() {
    final p = project;
    final prefs = _prefs;
    _userPicked = false;
    if (p == null || prefs == null) {
      _preferredId = null;
      return;
    }
    mode =
        BuildMode.values.asNameMap()[prefs.getString(
          _projectModeKeyPrefix + p.path,
        )] ??
        mode;
    _preferredId = prefs.getString(_projectDeviceKeyPrefix + p.path);
  }

  /// 기억해 둔 대상이 지금 보이고 이 프로젝트가 지원하면 그것을 고른다. 사용자가 이미 골랐으면 건드리지 않는다.
  void _applyPreferredDevice() {
    final id = _preferredId;
    if (id == null || _userPicked || selectedId == id) return;
    for (final d in visibleDevices) {
      if (d.id == id && _supports(d)) {
        selectedId = id;
        return;
      }
    }
  }

  void _loadOptions() {
    final p = project;
    options = p == null
        ? const BuildOptions()
        : BuildOptions.decode(_prefs?.getString(_optionsKeyPrefix + p.path));
  }

  /// 빌드 옵션을 바꾸고 이 프로젝트용으로 저장한다 (비우면 저장된 것도 지운다).
  void setOptions(BuildOptions value) {
    final p = project;
    if (running || value == options) return;
    options = value;
    if (p != null) {
      final key = _optionsKeyPrefix + p.path;
      if (value.isEmpty) {
        _prefs?.remove(key);
      } else {
        _prefs?.setString(key, value.encode());
      }
    }
    notifyListeners();
  }

  void setMode(BuildMode m) {
    mode = m;
    _prefs?.setString(_modeKey, m.name);
    final p = project;
    if (p != null) _prefs?.setString(_projectModeKeyPrefix + p.path, m.name);
    notifyListeners();
  }

  void setTeamId(String value) {
    final v = value.trim().toUpperCase();
    teamId = v.isEmpty ? null : v;
    if (teamId == null) {
      _prefs?.remove(_teamKey);
    } else if (RegExp(r'^[A-Z0-9]{10}$').hasMatch(teamId!)) {
      _prefs?.setString(_teamKey, teamId!);
    }
    notifyListeners();
  }

  /// 계획의 단계를 차례로 실행한다. 하나라도 실패하면 거기서 멈춘다.
  ///
  /// [phase]가 build나 run이면 그 단계들만 실행한다 (release에서 빌드와 실행을 따로 할 때).
  /// 다른 단계의 이전 결과(체크 표시)는 그대로 둔다.
  Future<void> start({RunPhase phase = RunPhase.all}) async {
    final p = plan;
    if (running || !p.runnable) return;
    final indices = p.indicesOf(phase);
    if (indices.isEmpty) return;
    running = true;
    hint = null;
    missingCommand = null;
    if (phase == RunPhase.all || statuses.length != p.steps.length) {
      statuses = List.filled(p.steps.length, StepStatus.pending);
    } else {
      statuses = [...statuses];
      for (final i in indices) {
        statuses[i] = StepStatus.pending;
      }
    }
    notifyListeners();
    final out = await _session.run(p.steps, indices, onStatus: (i, status) {
      statuses[i] = status;
      notifyListeners();
    });
    final failed = out.failedIndex;
    if (failed != null) {
      final r = out.failedResult!;
      if (r.exitCode == 127) missingCommand = p.steps[failed].args.first;
      hint = explainFailure(r.combined);
    }
    running = false;
    notifyListeners();
  }

  /// 빌드 없이 실행할 수 있는지: release 결과물이 이미 있다.
  bool get artifactReady {
    final a = plan.artifact;
    return a != null &&
        FileSystemEntity.typeSync(a) != FileSystemEntityType.notFound;
  }

  /// 빌드가 알 수 없는 이유로 깨질 때의 처방: `flutter clean` 다음 `flutter pub get`.
  /// 둘 다 성공하면 true. 명령은 기록 탭에도 남는다.
  Future<bool> cleanProject() async {
    final p = project;
    if (p == null || running || cleaning) return false;
    cleaning = true;
    cleanResult = null;
    missingCommand = null;
    hint = null;
    statuses = const [];
    notifyListeners();
    var ok = true;
    for (final args in const [
      ['flutter', 'clean'],
      ['flutter', 'pub', 'get'],
    ]) {
      final r = await runner.run(args, workingDirectory: p.path);
      if (!r.ok) {
        ok = false;
        if (r.exitCode == 127) missingCommand = args.first;
        break;
      }
    }
    cleaning = false;
    cleanResult = ok;
    notifyListeners();
    return ok;
  }

  void cancel() => _session.cancel();

  /// 실행 중인 `flutter run`에 키를 보낸다: `r` 핫 리로드, `R` 핫 리스타트, `q` 종료.
  void sendKey(String key) => _session.send(key);

  /// 브랜치가 바뀐 뒤 점검 결과를 오래된 것으로 표시한다. 칸이 시작되고 결과가 있을 때만 의미가 있다.
  void markDiagnosticsStale() {
    if (!started || diagnostics == null || diagnosticsStale) return;
    diagnosticsStale = true;
    notifyListeners();
  }
}
