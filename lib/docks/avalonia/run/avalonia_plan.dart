// 버튼이 실행할 명령을 만든다 (docs/AVALONIA_RUNNER.md §4). 화면에 보이는 명령과 실제로 실행하는 명령이 같다.
// 순수한 계산이라 프로세스 없이 테스트한다.

import 'dart:convert';

import '../../../core/command_log.dart';
import '../../../core/run_session.dart';
import '../detect/avalonia_project.dart';

enum AvaloniaAction {
  // 화면의 칩 순서이기도 하다 (Gradle 칸처럼): 빌드 → 테스트 → 실행 → AOT → 정리.
  build,

  /// `dotnet test <솔루션>`.
  test,

  /// `dotnet run` — 개발 실행. 앱 창이 닫힐 때까지 계속 돈다.
  run,

  /// NativeAOT 로 게시만 한다.
  publishAot,

  /// NativeAOT 로 게시한 뒤 만들어진 실행 파일을 띄운다 (시작 속도를 재는 용도).
  aotRun,
  clean,
}

enum AvaloniaStepKind { dotnet, launch }

/// 명령 미리보기에 적지 않는 환경 변수 (길거나, 사용자가 신경 쓸 필요 없는 것).
const hiddenEnvKeys = {'PATH', 'OS'};

class AvaloniaStep implements RunStep {
  const AvaloniaStep(this.kind, this.args, {this.workingDirectory, this.environment = const {}, this.interactive = false});

  final AvaloniaStepKind kind;

  @override
  final List<String> args;
  @override
  final String? workingDirectory;
  @override
  final Map<String, String> environment;

  /// 앱 창이 떠 있는 동안 계속 실행되는 단계 (`dotnet run`, AOT 실행 파일).
  @override
  final bool interactive;

  /// 터미널에 붙여 넣어 그대로 실행할 수 있는 한 줄. PATH·OS 는 보이지 않는다 (PATH 를 더했다는 사실은 계획의 `pathExtended` 로 따로 알린다).
  String get commandLine => [
        for (final e in environment.entries)
          if (!hiddenEnvKeys.contains(e.key)) '${e.key}=${e.value}',
        formatCommandLine(args),
      ].join(' ');
}

/// 계획을 세울 수 없을 때의 이유 — 실행 전에 알려 준다.
enum AvaloniaBlocker { noProject, noApp, noSolution }

class AvaloniaPlan {
  const AvaloniaPlan({this.steps = const [], this.blocker, this.pathExtended = false});

  final List<AvaloniaStep> steps;
  final AvaloniaBlocker? blocker;

  /// AOT 링크를 위해 PATH 에 vswhere 폴더를 더했다 (명령 미리보기 아래에 알린다).
  final bool pathExtended;

  bool get runnable => blocker == null && steps.isNotEmpty;
}

/// 고급 옵션. 폴더마다 따로 저장한다 (`avalonia.options:<dir>`), 모르는 필드는 버리고 읽는다.
class AvaloniaOptions {
  const AvaloniaOptions({this.debug = false, this.rid = '', this.aotDir = defaultAotDir, this.extraArgs = ''});

  static const defaultAotDir = 'publish/aot';

  /// 꺼 두면 Release (요청한 기본값).
  final bool debug;

  /// 게시할 런타임 식별자. 비워 두면 이 컴퓨터에 맞는 값을 쓴다 ([defaultRid]).
  final String rid;

  /// AOT 게시 폴더 (프로젝트 루트 기준).
  final String aotDir;

  /// 명령 끝에 붙일 인자 한 줄 (공백으로 나누고 따옴표를 존중한다).
  final String extraArgs;

  bool get isDefault => !debug && rid.trim().isEmpty && aotDir == defaultAotDir && extraArgs.trim().isEmpty;

  String get configuration => debug ? 'Debug' : 'Release';

  AvaloniaOptions copyWith({bool? debug, String? rid, String? aotDir, String? extraArgs}) =>
      AvaloniaOptions(debug: debug ?? this.debug, rid: rid ?? this.rid, aotDir: aotDir ?? this.aotDir, extraArgs: extraArgs ?? this.extraArgs);

  String toJson() => jsonEncode({'debug': debug, 'rid': rid, 'aotDir': aotDir, 'extraArgs': extraArgs});

  static AvaloniaOptions fromJson(String? text) {
    if (text == null) return const AvaloniaOptions();
    try {
      final m = jsonDecode(text);
      if (m is! Map) return const AvaloniaOptions();
      return AvaloniaOptions(
        debug: m['debug'] == true,
        rid: m['rid'] is String ? m['rid'] as String : '',
        aotDir: m['aotDir'] is String && (m['aotDir'] as String).trim().isNotEmpty ? m['aotDir'] as String : defaultAotDir,
        extraArgs: m['extraArgs'] is String ? m['extraArgs'] as String : '',
      );
    } on FormatException {
      return const AvaloniaOptions();
    }
  }
}

/// 이 컴퓨터에 맞는 런타임 식별자. macOS 는 Apple 칩을 기본으로 보고, 다르면 옵션에서 고친다.
String defaultRid({required bool isWindows, required bool isMacOS}) => isWindows ? 'win-x64' : (isMacOS ? 'osx-arm64' : 'linux-x64');

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

/// Visual Studio Installer 폴더 — `vswhere.exe` 가 있다. NativeAOT 링크가 PATH 에서 이것을 찾는다.
const vswhereDir = r'C:\Program Files (x86)\Microsoft Visual Studio\Installer';

/// 명령에 쓰는 경로는 상대 경로(작업 폴더 = 프로젝트 루트)로, 이 컴퓨터의 구분자로 적는다.
String _native(String rel, bool isWindows) => isWindows ? rel.replaceAll('/', r'\') : rel.replaceAll(r'\', '/');

String _trimDir(String dir) => dir.trim().replaceAll(RegExp(r'[\\/]+$'), '');

/// AOT 게시 결과 실행 파일의 프로젝트 루트 기준 경로. 예: `publish\aot\DaylightCommander.exe`.
String aotExecutable(AvaloniaApp app, AvaloniaOptions o, {required bool isWindows}) {
  final file = isWindows ? '${app.assemblyName}.exe' : app.assemblyName;
  return _native('${_trimDir(o.aotDir)}/$file', isWindows);
}

AvaloniaPlan buildAvaloniaPlan({
  required AvaloniaProject? project,
  required AvaloniaApp? app,
  required AvaloniaAction action,
  required AvaloniaOptions options,
  bool isWindows = false,
  bool isMacOS = false,
  String basePath = '',

  /// 이 컴퓨터에 vswhere 폴더가 실제로 있는지 (테스트에서 주입).
  bool vswhereDirExists = false,
}) {
  if (project == null) return const AvaloniaPlan(blocker: AvaloniaBlocker.noProject);
  if (action == AvaloniaAction.test && project.solution == null) return const AvaloniaPlan(blocker: AvaloniaBlocker.noSolution);
  final needsApp = action != AvaloniaAction.test && action != AvaloniaAction.clean;
  if (needsApp && app == null) return const AvaloniaPlan(blocker: AvaloniaBlocker.noApp);

  final csproj = app == null ? '' : _native(app.relativePath, isWindows);
  final config = options.configuration;
  final extra = splitArgs(options.extraArgs);
  final rid = options.rid.trim().isEmpty ? defaultRid(isWindows: isWindows, isMacOS: isMacOS) : options.rid.trim();
  final aotDir = _native(_trimDir(options.aotDir), isWindows);
  final target = project.solution ?? csproj;

  const baseEnv = {'DOTNET_CLI_TELEMETRY_OPTOUT': '1', 'DOTNET_NOLOGO': '1'};

  // NativeAOT 링크는 PATH 의 vswhere.exe 로 Visual Studio C++ 도구를 찾는다. 없으면 링크가 실패한다.
  final extendPath = isWindows && vswhereDirExists;
  // OS: Git Bash 에서 띄운 앱은 OS 가 `MINGW64_NT-…` 로 바뀌어 있고, MSBuild 가 이를 보고 "Cross-OS native compilation" 으로 실패한다.
  final aotEnv = {
    ...baseEnv,
    if (isWindows) 'OS': 'Windows_NT',
    if (extendPath) 'PATH': '$basePath;$vswhereDir',
  };

  AvaloniaStep dotnet(List<String> args, {Map<String, String> env = baseEnv, bool interactive = false}) =>
      AvaloniaStep(AvaloniaStepKind.dotnet, ['dotnet', ...args, ...extra], workingDirectory: project.path, environment: env, interactive: interactive);

  AvaloniaStep publish() => dotnet(['publish', csproj, '-c', config, '-r', rid, '-p:PublishAot=true', '-o', aotDir], env: aotEnv);

  final steps = switch (action) {
    AvaloniaAction.run => [dotnet(['run', '-c', config, '--project', csproj], interactive: true)],
    AvaloniaAction.build => [dotnet(['build', csproj, '-c', config])],
    AvaloniaAction.test => [dotnet(['test', target])],
    AvaloniaAction.publishAot => [publish()],
    AvaloniaAction.aotRun => [
        publish(),
        AvaloniaStep(
          AvaloniaStepKind.launch,
          [isWindows ? aotExecutable(app!, options, isWindows: true) : './${aotExecutable(app!, options, isWindows: false)}'],
          workingDirectory: project.path,
          interactive: true,
        ),
      ],
    AvaloniaAction.clean => [dotnet(['clean', target, '-c', config])],
  };
  final aot = action == AvaloniaAction.publishAot || action == AvaloniaAction.aotRun;
  return AvaloniaPlan(steps: steps, pathExtended: aot && extendPath);
}

/// 실패 원문에서 알아낼 수 있는 원인. 처방 문구는 화면이 고른다.
enum AvaloniaFailure { aotLinker, sdk, fileLocked, restore, rid }

AvaloniaFailure? explainAvaloniaFailure(String output) {
  bool has(Pattern p) => output.contains(p);
  if (has('vswhere') || has('Platform linker not found') || has('link.exe') && has('not found')) return AvaloniaFailure.aotLinker;
  if (has('NETSDK1045') || has('NETSDK1141') || has('A compatible .NET SDK was not found') || has('requested SDK version')) {
    return AvaloniaFailure.sdk;
  }
  if (has('NETSDK1083') || has('NETSDK1112')) return AvaloniaFailure.rid;
  if (has('MSB3027') || has('MSB3021') || has('being used by another process')) return AvaloniaFailure.fileLocked;
  if (has('NU1301') || has('NU1101') || has('Unable to load the service index')) return AvaloniaFailure.restore;
  return null;
}
