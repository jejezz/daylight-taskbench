// 버튼이 실행할 명령을 만든다 (docs/GRADLE_RUNNER.md §4). 화면에 보이는 명령과 실제로 실행하는 명령이 같다.
// 순수한 계산이라 프로세스 없이 테스트한다.

import 'dart:convert';

import '../../../core/command_log.dart';
import '../../../core/devices/mobile_device.dart';
import '../../../core/run_session.dart';
import '../detect/gradle_parse.dart';
import '../detect/gradle_project.dart';

enum GradleAction {
  // Android 앱
  installRun,
  install,
  assemble,
  bundle,
  test,
  lint,
  clean,
  // 일반 Gradle
  build,
  check,
  run,
  bootRun,
  task,
}

/// 단계의 역할. 화면의 이름과 진행 표시가 쓴다.
enum GradleStepKind { gradle, launch }

class GradleStep implements RunStep {
  const GradleStep(this.kind, this.args, {this.workingDirectory, this.environment = const {}, this.interactive = false});

  final GradleStepKind kind;

  @override
  final List<String> args;
  @override
  final String? workingDirectory;
  @override
  final Map<String, String> environment;

  /// `run`·`bootRun` 처럼 끝나지 않고 사용자가 멈추는 단계.
  @override
  final bool interactive;

  /// 터미널에 붙여 넣어 그대로 실행할 수 있는 한 줄.
  String get commandLine => [for (final e in environment.entries) '${e.key}=${e.value}', formatCommandLine(args)].join(' ');
}

/// 계획을 세울 수 없을 때의 이유 — 실행 전에 알려 준다.
enum GradleBlocker { noProject, noModule, noVariant, noTask, noDevice, deviceUnauthorized }

class GradlePlan {
  const GradlePlan({this.steps = const [], this.blocker, this.launchSkipped = false});

  final List<GradleStep> steps;
  final GradleBlocker? blocker;

  /// 설치는 하지만 패키지 이름을 몰라 앱은 열지 못한다.
  final bool launchSkipped;

  bool get runnable => blocker == null && steps.isNotEmpty;
}

/// 고급 옵션. 폴더마다 따로 저장한다 (`gradle.options:<dir>`), 모르는 필드는 버리고 읽는다.
class GradleOptions {
  const GradleOptions({this.offline = false, this.stacktrace = false, this.noDaemon = false, this.keepGoing = false, this.extraArgs = ''});

  final bool offline;
  final bool stacktrace;
  final bool noDaemon;
  final bool keepGoing;

  /// 명령 끝에 붙일 인자 한 줄 (공백으로 나누고 따옴표를 존중한다).
  final String extraArgs;

  bool get isDefault => !offline && !stacktrace && !noDaemon && !keepGoing && extraArgs.trim().isEmpty;

  GradleOptions copyWith({bool? offline, bool? stacktrace, bool? noDaemon, bool? keepGoing, String? extraArgs}) => GradleOptions(
        offline: offline ?? this.offline,
        stacktrace: stacktrace ?? this.stacktrace,
        noDaemon: noDaemon ?? this.noDaemon,
        keepGoing: keepGoing ?? this.keepGoing,
        extraArgs: extraArgs ?? this.extraArgs,
      );

  String toJson() => jsonEncode({'offline': offline, 'stacktrace': stacktrace, 'noDaemon': noDaemon, 'keepGoing': keepGoing, 'extraArgs': extraArgs});

  static GradleOptions fromJson(String? text) {
    if (text == null) return const GradleOptions();
    try {
      final m = jsonDecode(text);
      if (m is! Map) return const GradleOptions();
      return GradleOptions(
        offline: m['offline'] == true,
        stacktrace: m['stacktrace'] == true,
        noDaemon: m['noDaemon'] == true,
        keepGoing: m['keepGoing'] == true,
        extraArgs: m['extraArgs'] is String ? m['extraArgs'] as String : '',
      );
    } on FormatException {
      return const GradleOptions();
    }
  }
}

/// 공백으로 나누되 `"..."`·`'...'` 안은 하나로 본다 (셸을 거치지 않고 인자 목록으로 실행하므로 우리가 나눈다).
List<String> splitArgs(String line) {
  final out = <String>[];
  final cur = StringBuffer();
  String? quote;
  var started = false;
  for (final ch in line.split('')) {
    if (quote != null) {
      if (ch == quote) {
        quote = null;
      } else {
        cur.write(ch);
      }
    } else if (ch == '"' || ch == "'") {
      quote = ch;
      started = true;
    } else if (ch.trim().isEmpty) {
      if (started || cur.isNotEmpty) out.add(cur.toString());
      cur.clear();
      started = false;
    } else {
      cur.write(ch);
      started = true;
    }
  }
  if (started || cur.isNotEmpty) out.add(cur.toString());
  return out;
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
String lowerFirst(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

/// 빌드 타입 × flavor → 변형 이름 (`debug`, `freeDebug`). flavor 가 여럿이어도 차원 조합은 모르므로
/// 한 차원으로 본다 — 정확한 목록은 [parseInstallVariants] 로 Gradle 에게 묻는다.
List<String> androidVariants(AndroidBuildInfo? info) {
  final types = info?.buildTypes.isNotEmpty == true ? info!.buildTypes : const ['debug', 'release'];
  final flavors = info?.flavors ?? const <String>[];
  if (flavors.isEmpty) return types;
  return [for (final f in flavors) for (final t in types) '$f${capitalize(t)}'];
}

/// `./gradlew :app:tasks --group=install` 출력에서 `installFreeDebug` → `freeDebug`.
List<String> parseInstallVariants(String output) {
  final out = <String>[];
  for (final m in RegExp(r'^install([A-Z]\w*)\s+-', multiLine: true).allMatches(output)) {
    final name = m.group(1)!;
    if (name.endsWith('AndroidTest')) continue;
    final v = lowerFirst(name);
    if (!out.contains(v)) out.add(v);
  }
  return out;
}

class GradleTaskInfo {
  const GradleTaskInfo(this.name, this.description);
  final String name;
  final String description;
}

/// `./gradlew tasks --all -q` 출력: `build - Assembles and tests this project.` 줄들.
List<GradleTaskInfo> parseTasks(String output) {
  final out = <GradleTaskInfo>[];
  final seen = <String>{};
  for (final m in RegExp(r'^(:?[A-Za-z][\w:.\-]*) - (.*)$', multiLine: true).allMatches(output)) {
    if (seen.add(m.group(1)!)) out.add(GradleTaskInfo(m.group(1)!, m.group(2)!.trim()));
  }
  return out;
}

/// 변형 이름을 (flavor, 빌드 타입)으로 나눈다: `freeDebug` → (`free`, `debug`). 빌드 타입은 가장 긴 것부터 맞춘다.
(String flavor, String type) splitVariant(String variant, List<String> buildTypes) {
  final byLength = [...buildTypes]..sort((a, b) => b.length.compareTo(a.length));
  for (final t in byLength) {
    if (variant.toLowerCase().endsWith(t.toLowerCase())) {
      return (lowerFirst(variant.substring(0, variant.length - t.length)), t);
    }
  }
  return ('', variant);
}

/// 설치된 앱의 패키지 이름: `applicationId` + flavor 접미어 + 빌드 타입 접미어. 모르면 null.
String? installedPackage(GradleModule module, String variant) {
  final info = module.android;
  final base = info?.applicationId;
  if (info == null || base == null) return null;
  final (flavor, type) = splitVariant(variant, info.buildTypes);
  return '$base${info.flavorSuffix[flavor] ?? ''}${info.typeSuffix[type] ?? ''}';
}

/// 실행할 Gradle: 프로젝트의 래퍼, 없으면 시스템 `gradle`. 화면에 보이는 이름과 같다.
String gradleExecutable(GradleProject project, bool isWindows) {
  if (!project.hasWrapper) return 'gradle';
  return isWindows ? 'gradlew.bat' : './gradlew';
}

String _taskFor(GradleAction action, GradleModule module, String? variant, String? custom) {
  final prefix = module.path == ':' ? '' : '${module.path}:';
  final v = capitalize(variant ?? '');
  return switch (action) {
    GradleAction.installRun || GradleAction.install => '${prefix}install$v',
    GradleAction.assemble => '${prefix}assemble$v',
    GradleAction.bundle => '${prefix}bundle$v',
    GradleAction.test => module.kind == ModuleKind.androidApp ? '${prefix}test${v}UnitTest' : '${prefix}test',
    GradleAction.lint => '${prefix}lint$v',
    GradleAction.clean => '${prefix}clean',
    GradleAction.build => '${prefix}build',
    GradleAction.check => '${prefix}check',
    GradleAction.run => '${prefix}run',
    GradleAction.bootRun => '${prefix}bootRun',
    GradleAction.task => custom ?? '',
  };
}

bool _needsVariant(GradleAction a) => const {
      GradleAction.installRun,
      GradleAction.install,
      GradleAction.assemble,
      GradleAction.bundle,
      GradleAction.lint,
    }.contains(a);

bool _needsDevice(GradleAction a) => a == GradleAction.installRun || a == GradleAction.install;

GradlePlan buildGradlePlan({
  required GradleProject? project,
  required GradleModule? module,
  required String? variant,
  required GradleAction action,
  required GradleOptions options,
  MobileDevice? device,
  String? customTask,
  bool isWindows = false,
}) {
  if (project == null) return const GradlePlan(blocker: GradleBlocker.noProject);
  // 모듈이 없어도 clean 과 사용자가 고른 작업은 프로젝트 루트에서 돌릴 수 있다.
  final root = GradleModule(path: ':', dir: '', kind: ModuleKind.other);
  final target = module ?? root;
  if (module == null && action != GradleAction.clean && action != GradleAction.task) {
    return const GradlePlan(blocker: GradleBlocker.noModule);
  }
  if (_needsVariant(action) && (variant == null || variant.isEmpty)) return const GradlePlan(blocker: GradleBlocker.noVariant);
  if (action == GradleAction.task && (customTask == null || customTask.trim().isEmpty)) {
    return const GradlePlan(blocker: GradleBlocker.noTask);
  }
  if (_needsDevice(action)) {
    if (device == null || device.platform != DevicePlatform.android) return const GradlePlan(blocker: GradleBlocker.noDevice);
    if (!device.authorized) return const GradlePlan(blocker: GradleBlocker.deviceUnauthorized);
  }

  final task = _taskFor(action, target, variant, customTask?.trim());
  final args = [
    gradleExecutable(project, isWindows),
    '--console=plain',
    if (options.offline) '--offline',
    if (options.stacktrace) '--stacktrace',
    if (options.noDaemon) '--no-daemon',
    if (options.keepGoing) '--continue',
    // `task` 는 사용자가 입력한 작업 이름(공백으로 여러 개일 수 있다).
    ...(action == GradleAction.task ? splitArgs(task) : [task]),
    ...splitArgs(options.extraArgs),
  ];
  final interactive = action == GradleAction.run || action == GradleAction.bootRun;
  final steps = <GradleStep>[
    GradleStep(
      GradleStepKind.gradle,
      args,
      workingDirectory: project.path,
      // Gradle 은 연결된 모든 기기에 설치하므로 고른 기기 하나로 좁힌다 (AGP 가 ANDROID_SERIAL 을 읽는다).
      environment: _needsDevice(action) ? {'ANDROID_SERIAL': device!.id} : const {},
      interactive: interactive,
    ),
  ];
  var launchSkipped = false;
  if (action == GradleAction.installRun) {
    final pkg = installedPackage(target, variant!);
    if (pkg == null) {
      launchSkipped = true;
    } else {
      steps.add(GradleStep(GradleStepKind.launch, ['adb', '-s', device!.id, 'shell', 'monkey', '-p', pkg, '-c', 'android.intent.category.LAUNCHER', '1']));
    }
  }
  return GradlePlan(steps: steps, launchSkipped: launchSkipped);
}

/// Gradle 실패 원문에서 알아낼 수 있는 원인. 처방 문구는 화면이 고른다.
enum GradleFailure { sdkLocation, licenses, jdk, resolve, keystore, installFailed, noDevice }

GradleFailure? explainGradleFailure(String output) {
  bool has(Pattern p) => output.contains(p);
  if (has('SDK location not found') || has('ANDROID_HOME') && has('not set')) return GradleFailure.sdkLocation;
  if (has('licenses have not been accepted') || has('Failed to install the following Android SDK packages')) return GradleFailure.licenses;
  if (has('Unsupported class file major version') || has('requires Java') || has('Unsupported Java') || has('Could not target platform')) {
    return GradleFailure.jdk;
  }
  if (has('INSTALL_FAILED') || has('INSTALL_PARSE_FAILED')) return GradleFailure.installFailed;
  if (has('No connected devices')) return GradleFailure.noDevice;
  if (has('Keystore file') && has('not found')) return GradleFailure.keystore;
  if (has('Could not resolve') || has('Could not GET') || has('UnknownHostException')) return GradleFailure.resolve;
  return null;
}

/// `INSTALL_FAILED_UPDATE_INCOMPATIBLE` 같은 코드. 없으면 null.
String? installFailedCode(String output) => RegExp(r'INSTALL_(?:PARSE_)?FAILED\w*').firstMatch(output)?.group(0);
