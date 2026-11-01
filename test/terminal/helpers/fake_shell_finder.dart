// Taskbench 쪽에서 더한 도우미: 이 컴퓨터의 셸을 찾지 않고 정해 둔 목록을 돌려주는 가짜 찾기.
import 'package:daylight_taskbench/terminal/local_shell.dart';
import 'package:daylight_taskbench/terminal/local_shell_finder.dart';
import 'package:daylight_taskbench/terminal/terminal_sessions_controller.dart';

import 'fake_pty.dart';

const fakeBash = LocalShell(id: 'bash', name: 'bash', executable: '/bin/bash', kind: ShellKind.posix);
const fakeZsh = LocalShell(id: 'zsh', name: 'zsh', executable: '/bin/zsh', kind: ShellKind.posix);

class FakeShellFinder extends LocalShellFinder {
  FakeShellFinder([this.shells = const [fakeBash]]);

  final List<LocalShell> shells;

  @override
  Future<List<LocalShell>> find() async => shells;
}

/// 진짜 셸·pty 를 띄우지 않는 세션 컨트롤러. 셸을 확장 영역에 연결하는 테스트는 모두 이것을 쓴다.
TerminalSessionsController fakeTerminals(FakePtyFactory ptys, {List<LocalShell> shells = const [fakeBash]}) =>
    TerminalSessionsController(shellFinder: FakeShellFinder(shells), ptyFactory: ptys.call);
