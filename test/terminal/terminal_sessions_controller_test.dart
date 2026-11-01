import 'package:daylight_taskbench/terminal/local_shell.dart';
import 'package:daylight_taskbench/terminal/terminal_sessions_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_pty.dart';

const _bash = LocalShell(id: 'bash', name: 'bash', executable: '/bin/bash', kind: ShellKind.posix);
const _zsh = LocalShell(id: 'zsh', name: 'zsh', executable: '/bin/zsh', kind: ShellKind.posix);

void main() {
  late FakePtyFactory ptys;

  setUp(() {
    ptys = FakePtyFactory();
  });

  TerminalSessionsController make() => TerminalSessionsController(ptyFactory: ptys.call);

  test('add opens a new tab, starts the shell, and selects it', () {
    final c = make();
    final s = c.add('/work', _bash);
    expect(s, isNotNull);
    expect(c.sessions, [s]);
    expect(c.selected, 0);
    expect(c.current, s);
    expect(s!.connected, isTrue);
    c.dispose();
  });

  test('add without a shell needs loadShells to have found one first', () {
    final c = make();
    expect(c.add('/work'), isNull); // 아직 못 찾았다 (loadShells를 부르지 않았다)
    expect(c.sessions, isEmpty);
    c.dispose();
  });

  test('select, move and close keep the selection sane', () {
    final c = make();
    final a = c.add('/work', _bash)!;
    final b = c.add('/work', _zsh)!;
    final d = c.add('/work', _bash)!;
    expect(c.sessions, [a, b, d]);
    expect(c.selected, 2); // 새로 연 탭이 선택된다

    c.select(0);
    expect(c.current, a);

    c.move(0, 2);
    expect(c.sessions, [b, d, a]);
    expect(c.current, a); // 선택된 세션은 자리를 옮겨도 그대로 유지된다

    c.closeAt(1); // d를 닫는다
    expect(c.sessions, [b, a]);
    expect(c.current, a);
    c.dispose();
  });

  test('closing the selected tab selects a neighbor', () {
    final c = make();
    c.add('/work', _bash);
    final b = c.add('/work', _zsh)!;
    c.closeCurrent(); // b가 선택된 상태에서 닫는다
    expect(c.sessions, isNot(contains(b)));
    expect(c.selected, 0);
    c.dispose();
  });

  test('dispose kills every running shell', () {
    final c = make();
    c.add('/work', _bash);
    c.add('/work', _zsh);
    c.dispose();
    expect(ptys.made, hasLength(2));
    expect(ptys.made.every((p) => p.killed), isTrue);
  });
}
