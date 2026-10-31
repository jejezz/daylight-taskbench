// Gradle 칸의 상태: 프로젝트·모듈·변형·기기·동작을 고르고 계획을 실행한다 (docs/GRADLE_RUNNER.md §4).
// 칸이 접혀 있어도 이 객체는 살아 있어 실행이 이어진다. 프로세스를 띄우는 일(기기 목록)은 칸이 처음 펼쳐질 때 시작한다.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/command_runner.dart';
import '../../../core/devices/adb_devices.dart';
import '../../../core/devices/mobile_device.dart';
import '../../../core/run_session.dart';
import '../detect/gradle_project.dart';
import 'gradle_plan.dart';

class GradleController extends ChangeNotifier {
  GradleController({required this.runner, required this.prefs, AdbDevices? adb, bool? hostIsWindows})
      : adb = adb ?? AdbDevices(runner),
        hostIsWindows = hostIsWindows ?? Platform.isWindows;

  final CommandRunner runner;
  final SharedPreferences prefs;
  final AdbDevices adb;
  final bool hostIsWindows;

  // 저장 키는 모두 `gradle.` 접두어. 폴더마다 따로 저장하는 값은 `<접두어>:<프로젝트 경로>`.
  static const _tabIdKey = 'gradle.last_tab_id';
  static const _moduleKeyPrefix = 'gradle.module:';
  static const _variantKeyPrefix = 'gradle.variant:';
  static const _actionKeyPrefix = 'gradle.action:';
  static const _optionsKeyPrefix = 'gradle.options:';
  static const _deviceKeyPrefix = 'gradle.project_device:';
  static const _taskKeyPrefix = 'gradle.task:';

  /// 화면의 탭 순서. 저장은 번호가 아니라 이름으로 한다. (Doctor 는 이어지는 단계에서 붙는다.)
  static const tabIds = ['run', 'devices', 'log'];

  GradleProject? project;
  GradleModule? module;
  String? variant;
  GradleAction action = GradleAction.installRun;
  GradleOptions options = const GradleOptions();
  String customTask = '';

  List<MobileDevice> devices = const [];
  bool loadingDevices = false;
  String? selectedId;

  /// Gradle 에게 물어 얻은 정확한 변형·작업 목록. 파일에서 읽은 것으로 시작하고, 사용자가 불러오면 채운다.
  List<String>? exactVariants;
  bool loadingVariants = false;
  List<GradleTaskInfo>? tasks;
  bool loadingTasks = false;

  bool running = false;
  List<StepStatus> statuses = const [];
  GradleFailure? hint;
  String? hintDetail;
  String? missingCommand;
  GradlePlan? lastPlan;

  int tabIndex = 0;
  bool started = false;

  late final RunSession _session = RunSession(runner);

  bool get isAndroid => project?.shape == GradleShape.androidApp;
  bool get busy => running || loadingVariants || loadingTasks;

  List<GradleModule> get runnableModules => [for (final m in project?.modules ?? const <GradleModule>[]) if (m.isRunnable) m];

  List<String> get variants => exactVariants ?? androidVariants(module?.android);

  List<GradleAction> get actions => isAndroid
      ? const [GradleAction.installRun, GradleAction.install, GradleAction.assemble, GradleAction.bundle, GradleAction.test, GradleAction.lint, GradleAction.clean]
      : [
          GradleAction.build,
          GradleAction.test,
          GradleAction.check,
          GradleAction.clean,
          if (module?.kind == ModuleKind.jvmApp) GradleAction.run,
          if (module?.kind == ModuleKind.springBoot) GradleAction.bootRun,
          GradleAction.task,
        ];

  MobileDevice? get selectedDevice => devices.where((d) => d.id == selectedId).firstOrNull;

  GradlePlan get plan => buildGradlePlan(
        project: project,
        module: module,
        variant: variant,
        action: action,
        options: options,
        device: selectedDevice,
        customTask: customTask,
        isWindows: hostIsWindows,
      );

  /// 칸이 처음 펼쳐질 때 불린다 — 기기 목록을 읽는다 (프로세스를 띄우는 일은 여기서부터).
  Future<void> init() async {
    if (started) return;
    started = true;
    final i = tabIds.indexOf(prefs.getString(_tabIdKey) ?? '');
    if (i >= 0) tabIndex = i;
    if (isAndroid) await refreshDevices();
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
  void setProject(GradleProject? p) {
    final sameProject = p != null && project?.path == p.path;
    project = p;
    if (!sameProject) {
      exactVariants = null;
      tasks = null;
      statuses = const [];
      hint = null;
      missingCommand = null;
    }
    if (p == null) {
      module = null;
      variant = null;
      notifyListeners();
      return;
    }
    final modules = runnableModules;
    final savedModule = prefs.getString(_k(_moduleKeyPrefix));
    module = modules.where((m) => m.path == savedModule).firstOrNull ?? modules.firstOrNull;
    _restoreVariant();
    final savedAction = prefs.getString(_k(_actionKeyPrefix));
    final allowed = actions;
    action = allowed.where((a) => a.name == savedAction).firstOrNull ?? allowed.first;
    options = GradleOptions.fromJson(prefs.getString(_k(_optionsKeyPrefix)));
    customTask = prefs.getString(_k(_taskKeyPrefix)) ?? '';
    _pickDevice();
    notifyListeners();
    if (started && isAndroid && !sameProject) refreshDevices();
  }

  void _restoreVariant() {
    final list = variants;
    final saved = prefs.getString(_k(_variantKeyPrefix));
    variant = list.contains(saved) ? saved : (list.contains('debug') ? 'debug' : list.firstOrNull);
  }

  void selectModule(GradleModule m) {
    module = m;
    prefs.setString(_k(_moduleKeyPrefix), m.path);
    exactVariants = null;
    _restoreVariant();
    final allowed = actions;
    if (!allowed.contains(action)) action = allowed.first;
    notifyListeners();
  }

  void selectVariant(String v) {
    variant = v;
    prefs.setString(_k(_variantKeyPrefix), v);
    notifyListeners();
  }

  void selectAction(GradleAction a) {
    action = a;
    prefs.setString(_k(_actionKeyPrefix), a.name);
    notifyListeners();
  }

  void setOptions(GradleOptions o) {
    options = o;
    prefs.setString(_k(_optionsKeyPrefix), o.toJson());
    notifyListeners();
  }

  void setCustomTask(String t) {
    customTask = t;
    prefs.setString(_k(_taskKeyPrefix), t);
    notifyListeners();
  }

  void selectDevice(MobileDevice d) {
    selectedId = d.id;
    prefs.setString(_k(_deviceKeyPrefix), d.id);
    notifyListeners();
  }

  void _pickDevice() {
    if (devices.any((d) => d.id == selectedId)) return;
    final saved = prefs.getString(_k(_deviceKeyPrefix));
    final byId = devices.where((d) => d.id == saved).firstOrNull;
    selectedId = (byId ?? devices.where((d) => d.authorized).firstOrNull ?? devices.firstOrNull)?.id;
  }

  Future<void> refreshDevices() async {
    if (loadingDevices) return;
    loadingDevices = true;
    notifyListeners();
    devices = await adb.list();
    _pickDevice();
    loadingDevices = false;
    notifyListeners();
  }

  /// 계획의 단계를 차례로 실행한다. 하나라도 실패하면 거기서 멈춘다.
  Future<void> start() async {
    final p = plan;
    if (running || !p.runnable) return;
    running = true;
    hint = null;
    hintDetail = null;
    missingCommand = null;
    lastPlan = p;
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
      hint = explainGradleFailure(r.combined);
      if (hint == GradleFailure.installFailed) hintDetail = installFailedCode(r.combined);
    }
    running = false;
    notifyListeners();
  }

  void cancel() => _session.cancel();

  /// 실행 중인 `run`·`bootRun` 에 키를 보낸다.
  void sendKey(String key) => _session.send(key);

  Future<List<String>> _gradleArgs(List<String> tail) async => [gradleExecutable(project!, hostIsWindows), '--console=plain', ...tail];

  /// 설정 단계를 돌려 정확한 변형 목록을 얻는다. 느리고 처음엔 Gradle 을 내려받을 수 있어 사용자가 눌렀을 때만 한다.
  Future<void> loadVariants() async {
    final m = module;
    if (project == null || m == null || loadingVariants || !isAndroid) return;
    loadingVariants = true;
    notifyListeners();
    final prefix = m.path == ':' ? '' : '${m.path}:';
    final r = await runner.run(await _gradleArgs(['${prefix}tasks', '--group=install', '-q']), workingDirectory: project!.path);
    final list = r.ok ? parseInstallVariants(r.stdout) : <String>[];
    if (list.isNotEmpty) {
      exactVariants = list;
      _restoreVariant();
    }
    loadingVariants = false;
    notifyListeners();
  }

  /// 일반 Gradle 의 작업 선택기를 채운다 (`tasks --all`).
  Future<void> loadTasks() async {
    if (project == null || loadingTasks) return;
    loadingTasks = true;
    notifyListeners();
    final r = await runner.run(await _gradleArgs(['tasks', '--all', '-q']), workingDirectory: project!.path);
    if (r.ok) tasks = parseTasks(r.stdout);
    loadingTasks = false;
    notifyListeners();
  }

  /// 백그라운드에 남은 Gradle 데몬을 모두 끈다.
  Future<void> stopDaemons() async {
    if (project == null) return;
    await runner.run(await _gradleArgs(['--stop']), workingDirectory: project!.path);
  }

  /// 브랜치가 바뀌었다 — 모듈·변형·작업 목록은 브랜치마다 다를 수 있으므로 버린다.
  void invalidateCaches() {
    exactVariants = null;
    tasks = null;
    notifyListeners();
  }
}
