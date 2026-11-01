/// daylight-terminal-flutter의 state/local_shell_session.dart를 간단히 줄인 것 — 이 앱은 왼쪽에 폴더 뷰를
/// 두지 않으므로(프로젝트 트리가 있다) `LocalFolderSession`은 가져오지 않는다.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'local_shell.dart';
import 'pty_backend.dart';
import 'terminal_session.dart';

/// 탭 하나 = 이 PC에서 도는 셸 하나. 작업 폴더는 탭을 열 때 한 번 정해지고(연 프로젝트/worktree),
/// 이후 프로젝트를 바꿔도 이미 열린 셸은 그대로 그 폴더에서 돈다.
class LocalShellSession extends TerminalSession {
  LocalShellSession(this.shell, {required this.workingDirectory, super.scrollback, PtyFactory? ptyFactory})
    : _ptyFactory = ptyFactory ?? startFlutterPty;

  final LocalShell shell;
  final String workingDirectory;
  final PtyFactory _ptyFactory;

  PtyProcess? _pty;
  StreamSubscription<Uint8List>? _outputSub;
  int? _exitCode;
  String? _startError;

  /// 셸이 끝났을 때의 종료 코드. 아직 돌고 있으면 null.
  int? get exitCode => _exitCode;

  /// 셸을 띄우지 못했을 때의 오류 문구.
  String? get startError => _startError;

  @override
  String get tabTitle => shell.name;

  /// 셸을 띄운다. 이미 돌고 있으면 아무것도 하지 않는다.
  void start() {
    if (_pty != null) return;
    _exitCode = null;
    _startError = null;
    try {
      final pty = _ptyFactory(
        shell,
        workingDirectory: workingDirectory,
        environment: {...Platform.environment, 'TERM': 'xterm-256color', 'COLORTERM': 'truecolor'},
        rows: terminal.viewHeight,
        columns: terminal.viewWidth,
      );
      _pty = pty;
      _outputSub = pty.output.listen(handleOutput);
      unawaited(pty.exitCode.then((code) => _onExit(pty, code), onError: (Object _) => _onExit(pty, -1)));
      setStatus(SessionStatus.connected);
    } catch (e) {
      _pty = null;
      _startError = e.toString();
      setStatus(SessionStatus.error);
    }
    notify();
  }

  void _onExit(PtyProcess pty, int code) {
    if (!identical(_pty, pty)) return; // 우리가 끈 것이면 이미 정리됐다
    _release();
    _exitCode = code;
    setStatus(SessionStatus.idle);
    notify();
  }

  void _release() {
    final pty = _pty;
    _pty = null;
    _outputSub?.cancel();
    _outputSub = null;
    if (pty != null) {
      try {
        pty.kill();
      } catch (_) {
        // 이미 끝난 프로세스일 수 있다.
      }
    }
  }

  /// 끝난 셸을 같은 폴더에서 다시 띄운다.
  void restart() {
    _release();
    terminal.write('\r\n');
    start();
  }

  @override
  void writeInput(List<int> bytes) {
    if (!connected) return;
    try {
      _pty?.write(Uint8List.fromList(bytes));
    } catch (_) {
      // 막 끝난 셸에 쓴 입력이다. 종료 처리는 exitCode에서 한다.
    }
  }

  @override
  void onTerminalResize(int width, int height, int pixelWidth, int pixelHeight) => _pty?.resize(height, width);

  @override
  void dispose() {
    _release();
    super.dispose();
  }
}
