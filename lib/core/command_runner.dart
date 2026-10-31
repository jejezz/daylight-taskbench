// branch-dock-flutter 와 flutty-dock-flutter 의 command_runner 를 합친 것 (PLAN.md §3.2, 단계 2).
//
// [Taskbench에서 달라진 곳] 두 원본의 합집합이다 — 어느 쪽 호출 코드도 이름만 바꾸면 그대로 돈다:
//   - Branch: 필수 `path`(동기 String), git/gh 실행 파일 지정(`gitPath`·`ghPath`), `cancel:`(CancelToken),
//     git/gh 환경 변수(`LC_ALL=C` 등), 같은 설치의 Git for Windows `bash` 찾기.
//   - Flutty: 이름별 실행 파일 지정(`toolPaths`), 실행 중 입력(`RunHandle.send`·`keepStdinOpen`), 출력 스트림
//     (`onOutput`), 코드 페이지 대체 해석(`decodeProcessOutput`), Windows 의 `flutter` 를 Git Bash 로 실행.
//   - `CancelToken` 은 `RunHandle` 의 다른 이름이다. 새 코드는 `handle:` 하나를 쓴다.
//   - `path` 는 앱 시작에서 한 번 `resolvePath()` 로 만들어 넘긴다 (Flutty 의 지연 `Future` 대신).
// 이 파일을 고치면 test/command_runner_test.dart 가 두 원본의 동작을 함께 지킨다.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'command_log.dart';

/// 명령 실행 결과.
class CommandResult {
  const CommandResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get ok => exitCode == 0;

  String get combined => [stdout, stderr].where((s) => s.trim().isNotEmpty).join('\n');
}

/// 오래 걸리는 실행을 중간에 끊거나 입력을 보내는 핸들.
class RunHandle {
  Process? _process;
  bool _cancelled = false;

  bool get cancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    final p = _process;
    if (p == null) return;
    // [Taskbench에서 달라진 곳] 자식까지 끝낸다. `cargo`·`gradlew`·`flutter` 는 실제 일을 하는 자식 프로세스를 띄우므로
    // 부모만 죽이면 자식이 고아로 남아 계속 돈다 (특히 Windows).
    // 부모를 먼저 죽이면 자식이 고아가 되어 pid 관계가 끊기므로, 자손을 먼저 끝내고 부모를 끝낸다.
    unawaited(killProcessTree(p.pid).whenComplete(p.kill));
  }

  /// 실행 중인 프로세스의 표준 입력으로 글자를 보낸다 (`flutter run`의 `r`, `R`, `q`).
  /// [CommandRunner.run]의 `keepStdinOpen` 으로 실행했을 때만 닿는다.
  void send(String text) => _process?.stdin.add(utf8.encode(text));
}

/// [pid] 와 그 자손 프로세스를 끝낸다. 실패해도 조용히 넘어간다 (이미 끝났을 수 있다).
Future<void> killProcessTree(int pid) async {
  try {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/PID', '$pid', '/T', '/F']);
      return;
    }
    // 자손을 먼저 모아 두고(부모가 죽으면 pid 관계가 끊긴다) 아래쪽부터 끝낸다.
    final all = <int>[];
    var level = [pid];
    for (var depth = 0; depth < 6 && level.isNotEmpty; depth++) {
      final next = <int>[];
      for (final parent in level) {
        final r = await Process.run('pgrep', ['-P', '$parent']);
        if (r.exitCode != 0) continue;
        next.addAll(const LineSplitter().convert(r.stdout as String).map(int.tryParse).whereType<int>());
      }
      all.addAll(next);
      level = next;
    }
    for (final child in all.reversed) {
      Process.killPid(child);
    }
  } on ProcessException {
    // pgrep/taskkill 이 없는 환경 — 부모만 끝난다.
  }
}

/// Branch Dock 쪽 이름 — [RunHandle] 과 같다.
typedef CancelToken = RunHandle;

const _utf8 = Utf8Codec(allowMalformed: true);

/// 자식 프로세스 출력 한 덩어리를 글자로 바꾼다. UTF-8이면 그대로 읽고, Windows에서 UTF-8이
/// 아니면 시스템 코드 페이지(한국어 Windows는 CP949)로 읽는다 — PowerShell·cmd의 오류 메시지가
/// 그 코드 페이지로 나온다.
String decodeProcessOutput(List<int> bytes, {Encoding? fallback}) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    final enc = fallback ?? (Platform.isWindows ? systemEncoding : null);
    return enc == null ? _utf8.decode(bytes) : enc.decode(bytes);
  }
}

/// 명령을 셸 없이 인자 목록으로 실행하고 [CommandLog]에 남긴다.
///
/// - macOS GUI 앱은 로그인 셸의 PATH를 받지 못하므로 [resolvePath]가 만든 PATH를 모든 프로세스에
///   넘긴다. `gh`가 git 인증 도우미로 다시 불릴 때, `flutter`가 `adb`를 찾을 때도 같은 PATH가 필요하다.
/// - 대화형 프롬프트를 막는다. 입력이 필요한 작업은 앱이 먼저 값을 받는다.
class CommandRunner {
  CommandRunner({required this.log, required this.path, String? gitPath, String? ghPath, Map<String, String>? toolPaths}) {
    if (toolPaths != null) this.toolPaths = toolPaths;
    if (gitPath != null) this.gitPath = gitPath;
    if (ghPath != null) this.ghPath = ghPath;
  }

  final CommandLog log;

  /// [resolvePath]가 만든 PATH.
  String path;

  /// 사용자가 직접 지정한 실행 파일 (`git`, `gh`, `flutter`, `adb` …). 있으면 이름 대신 이 파일을 실행한다.
  /// 값이 빈 문자열이면 지정하지 않은 것으로 본다.
  Map<String, String> toolPaths = {};

  String? get gitPath => _custom('git');
  set gitPath(String? v) => _set('git', v);
  String? get ghPath => _custom('gh');
  set ghPath(String? v) => _set('gh', v);

  String? _custom(String name) {
    final v = toolPaths[name];
    return v == null || v.isEmpty ? null : v;
  }

  void _set(String name, String? v) {
    toolPaths = {...toolPaths}..remove(name);
    if (v != null && v.isNotEmpty) toolPaths[name] = v;
  }

  /// 명령 이름을 실제로 실행할 파일로 바꾼다. 지정한 것이 없으면 이름 그대로(PATH에서 찾는다).
  String executableFor(String name) {
    final custom = _custom(name);
    if (custom != null) return custom;
    if (name == 'bash' && Platform.isWindows) {
      return gitBashPath() ??
          (throw const ProcessException('bash', [], 'bash from Git for Windows was not found. Install Git, or set the git path in Settings → Tools.'));
    }
    return name;
  }

  /// [name]을 실제로 실행하게 될 파일의 전체 경로. 찾지 못하면 null.
  String? locate(String name) {
    final custom = _custom(name);
    if (custom != null) return File(custom).existsSync() ? custom : null;
    return findExecutable(name, effectivePath);
  }

  /// Windows에서 PATH의 `bash`는 WSL의 `System32\bash.exe`가 먼저 잡히는 일이 많다.
  /// WSL의 git은 `core.autocrlf` 설정이 달라 CRLF 파일을 모두 수정됨으로 보므로
  /// (bump-version.sh의 깨끗한 트리 검사가 실패한다), git과 같은 설치의 bash만 쓴다.
  /// 찾지 못해도 PATH의 bash로 되돌아가지 않는다.
  String? gitBashPath() {
    if (!Platform.isWindows) return null;
    final sep = Platform.pathSeparator;
    final git = gitPath ?? findExecutable('git', path);
    if (git != null) {
      var dir = File(git).parent;
      for (var i = 0; i < 3; i++) {
        final bash = File('${dir.path}${sep}bin${sep}bash.exe');
        if (bash.existsSync()) return bash.path;
        dir = dir.parent;
      }
    }
    // git이 shim(scoop 등)이거나 PATH에 없을 때의 표준 설치 위치.
    for (final base in [
      Platform.environment['ProgramFiles'],
      Platform.environment['ProgramW6432'],
      Platform.environment['ProgramFiles(x86)'],
      if (Platform.environment['LOCALAPPDATA'] case final l?) '$l${sep}Programs',
    ]) {
      if (base == null) continue;
      final bash = File('$base${sep}Git${sep}bin${sep}bash.exe');
      if (bash.existsSync()) return bash.path;
    }
    return null;
  }

  /// 프로세스에 넘기는 PATH. 지정한 실행 파일의 폴더를 앞에 둔다 — `gh`가 git을 부르거나 git이 인증
  /// 도우미로 `gh`를 부를 때, `flutter`가 `adb`를 찾을 때도 같은 파일을 쓰게 한다.
  String get effectivePath {
    final sep = Platform.isWindows ? ';' : ':';
    final dirs = [
      for (final p in toolPaths.values)
        if (p.isNotEmpty) File(p).parent.path,
    ];
    return [...dirs.toSet(), path].join(sep);
  }

  Map<String, String> _env(String name) => {
        'PATH': effectivePath,
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_EDITOR': 'true',
        'GH_PROMPT_DISABLED': '1',
        'GH_NO_UPDATE_NOTIFIER': '1',
        'NO_COLOR': '1',
        // 오류 문구를 영어로 고정해야 오류 설명(error_hints.dart)이 맞는다.
        // 내용(커밋 메시지, 파일 이름)은 바이트 그대로라 영향이 없다.
        if (name == 'git') 'LC_ALL': 'C',
      };

  /// 명령을 실행하고 로그에 남긴다.
  ///
  /// - [quiet]면 로그에 남기지 않는다 (상태 새로 고침처럼 자주 도는 읽기 명령).
  /// - [stdin]은 한 번 쓰고 닫는다. [keepStdinOpen]이면 [handle]로 나중에 입력을 보낼 수 있게 열어 둔다.
  /// - [workingDirectory]를 안 주면 쓸 수 있는 임시 폴더에서 돈다 — 이 앱의 작업 디렉터리(설치 폴더 등)를
  ///   물려받으면 flutter 가 거기에 hash.txt 를 쓰려다 권한 오류로 실패한다.
  /// - [cancel]은 [handle]의 옛 이름(Branch 쪽)이다. 둘 다 주면 [handle]이 이긴다.
  Future<CommandResult> run(
    List<String> args, {
    String? workingDirectory,
    Map<String, String> environment = const {},
    bool quiet = false,
    String? stdin,
    RunHandle? handle,
    RunHandle? cancel,
    bool keepStdinOpen = false,
    void Function(String chunk)? onOutput,
  }) async {
    final h = handle ?? cancel;
    final entry = quiet ? null : log.start(args);
    final watch = Stopwatch()..start();
    void finish(int code) {
      entry
        ?..exitCode = code
        ..cancelled = h?.cancelled ?? false
        ..duration = watch.elapsed;
      if (entry != null) log.update();
    }

    try {
      var executable = executableFor(args.first);
      var arguments = args.sublist(1);
      var viaShell = Platform.isWindows;
      final bash = args.first == 'flutter' ? gitBashPath() : null;
      if (bash != null) {
        // Windows의 cmd/PowerShell로 `flutter.bat`을 돌리면 오류가 많다 — Git Bash에서
        // `flutter` 셸 스크립트를 직접 실행한다. 인자는 "$@"로 넘겨 따옴표 문제를 피한다.
        final script = flutterShellScript(executable, effectivePath);
        if (script != null) {
          arguments = ['-c', r'exec "$@"', 'bash', script, ...arguments];
          executable = bash;
          viaShell = false;
        }
      }
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory ?? Directory.systemTemp.path,
        environment: {..._env(args.first), ...environment},
        runInShell: viaShell,
      );
      h?._process = process;
      if (stdin != null) {
        process.stdin.add(_utf8.encode(stdin));
        await process.stdin.close();
      } else if (!keepStdinOpen) {
        await process.stdin.close();
      }
      final out = StringBuffer();
      final err = StringBuffer();
      void tee(StringBuffer to, String chunk) {
        to.write(chunk);
        entry?.append(chunk);
        onOutput?.call(chunk);
        if (entry != null) log.updateThrottled();
      }

      final outDone = process.stdout.map(decodeProcessOutput).listen((c) => tee(out, c)).asFuture<void>();
      final errDone = process.stderr.map(decodeProcessOutput).listen((c) => tee(err, c)).asFuture<void>();
      final code = await process.exitCode;
      await Future.wait([outDone, errDone]);
      finish(code);
      return CommandResult(code, out.toString(), err.toString());
    } on ProcessException catch (e) {
      entry?.append(e.message);
      finish(127);
      return CommandResult(127, '', e.message);
    }
  }
}

/// `flutter` 명령에 해당하는 셸 스크립트(`bin/flutter`, 확장자 없음) 경로. 없으면 null.
String? flutterShellScript(String executable, String path) {
  var file = executable;
  if (executable == 'flutter') {
    file = findExecutable('flutter', path) ?? '';
  }
  if (file.isEmpty) return null;
  final lower = file.toLowerCase();
  if (lower.endsWith('.bat') || lower.endsWith('.cmd') || lower.endsWith('.exe')) {
    file = file.substring(0, file.length - 4);
  }
  return File(file).existsSync() ? file.replaceAll('\\', '/') : null;
}

/// [path]의 폴더들에서 [name] 실행 파일을 찾아 전체 경로를 돌려준다. 없으면 null.
/// Windows에서는 `.exe`를 먼저, 그다음 `.cmd`·`.bat`를 찾는다.
String? findExecutable(String name, String path) {
  final windows = Platform.isWindows;
  final names = windows ? ['$name.exe', '$name.cmd', '$name.bat'] : [name];
  for (final file in names) {
    for (final dir in path.split(windows ? ';' : ':')) {
      if (dir.trim().isEmpty) continue;
      final f = File('${dir.trim()}${Platform.pathSeparator}$file');
      if (f.existsSync()) return f.path;
    }
  }
  return null;
}

/// 실행 파일을 찾을 PATH: 이 프로세스의 PATH → 로그인 셸의 PATH → 흔한 설치 위치.
///
/// Finder에서 띄운 macOS 앱의 PATH는 `/usr/bin:/bin:/usr/sbin:/sbin`뿐이라 Homebrew로 설치한 `gh`나
/// 따로 설치한 `flutter`를 찾지 못한다. 두 원본의 흔한 위치를 모두 더했다.
Future<String> resolvePath() async {
  final sep = Platform.isWindows ? ';' : ':';
  final parts = <String>[];
  void addAll(String? value) {
    if (value == null) return;
    for (final p in value.split(sep)) {
      final t = p.trim();
      if (t.isNotEmpty && !parts.contains(t)) parts.add(t);
    }
  }

  addAll(Platform.environment['PATH']);
  if (!Platform.isWindows) {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    try {
      final r = await Process.run(shell, ['-lc', r'printf %s "$PATH"']).timeout(const Duration(seconds: 3));
      if (r.exitCode == 0) addAll(r.stdout as String);
    } on Object {
      // 셸이 느리거나 없으면 흔한 위치로 충분하다.
    }
    addAll('/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/home/linuxbrew/.linuxbrew/bin');
    addAll(_existing(_commonToolDirs()).join(sep));
  } else {
    final env = Platform.environment;
    final pf = env['ProgramFiles'] ?? r'C:\Program Files';
    final local = env['LOCALAPPDATA'];
    addAll(
      [
        '$pf\\Git\\cmd',
        '$pf\\GitHub CLI',
        if (local != null) '$local\\Microsoft\\WinGet\\Links',
        ..._existing([
          if (local != null) '$local\\Android\\Sdk\\platform-tools',
          if (env['ANDROID_HOME'] != null) '${env['ANDROID_HOME']}\\platform-tools',
          if (env['ANDROID_SDK_ROOT'] != null) '${env['ANDROID_SDK_ROOT']}\\platform-tools',
        ]),
      ].join(sep),
    );
  }
  return parts.join(sep);
}

/// 셸 설정(`.zshrc`)에만 PATH를 넣어 둔 도구를 위해 흔한 설치 위치를 더한다 — 실제로 있는 폴더만.
List<String> _commonToolDirs() {
  final env = Platform.environment;
  final home = env['HOME'];
  return [
    if (env['ANDROID_HOME'] != null) '${env['ANDROID_HOME']}/platform-tools',
    if (env['ANDROID_SDK_ROOT'] != null) '${env['ANDROID_SDK_ROOT']}/platform-tools',
    if (home != null) ...[
      '$home/Library/Android/sdk/platform-tools',
      '$home/Android/Sdk/platform-tools',
      '$home/development/flutter/bin',
      '$home/flutter/bin',
      '$home/fvm/default/bin',
    ],
  ];
}

List<String> _existing(List<String> dirs) => [
      for (final d in dirs)
        if (Directory(d).existsSync()) d,
    ];
