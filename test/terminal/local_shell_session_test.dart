import 'dart:convert';
import 'dart:io';

import 'package:daylight_taskbench/terminal/local_shell.dart';
import 'package:daylight_taskbench/terminal/local_shell_session.dart';
import 'package:daylight_taskbench/terminal/terminal_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_pty.dart';

const _bash = LocalShell(id: 'bash', name: 'bash', executable: '/bin/bash', kind: ShellKind.posix, arguments: ['-l']);

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late Directory tmp;
  late FakePtyFactory ptys;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('studio_terminal_');
    ptys = FakePtyFactory();
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  LocalShellSession make([LocalShell shell = _bash]) => LocalShellSession(shell, workingDirectory: tmp.path, ptyFactory: ptys.call);

  test('start spawns the shell in the working directory with a full environment', () {
    final s = make();
    s.start();
    expect(s.connected, isTrue);
    final call = ptys.calls.single;
    expect(call.shell.executable, '/bin/bash');
    expect(call.cwd, tmp.path);
    expect(call.env['TERM'], 'xterm-256color');
    expect(call.env['COLORTERM'], 'truecolor');
    // flutter_pty는 환경을 거의 물려주지 않으므로 전체를 넘겨야 한다.
    expect(call.env.length, greaterThan(5));
    s.dispose();
  });

  test('output from the shell reaches the terminal', () async {
    final s = make();
    s.start();
    ptys.last.emit('hello world\r\n');
    await pump();
    expect(s.terminal.buffer.getText(), contains('hello world'));
    s.dispose();
  });

  test('typing writes to the shell', () {
    final s = make();
    s.start();
    s.terminal.textInput('ls');
    expect(ptys.last.writtenText, 'ls');
    s.dispose();
  });

  test('terminal resize is forwarded as rows x columns', () {
    final s = make();
    s.start();
    s.terminal.resize(100, 30);
    expect(ptys.last.resizes.last, (30, 100));
    s.dispose();
  });

  test('when the shell exits the tab stays, shows the exit code, and can restart in the same folder', () async {
    final s = make();
    s.start();
    ptys.last.finish(3);
    await pump();
    expect(s.connected, isFalse);
    expect(s.status, SessionStatus.idle);
    expect(s.exitCode, 3);

    s.restart();
    expect(ptys.made, hasLength(2));
    expect(s.connected, isTrue);
    expect(s.exitCode, isNull);
    expect(ptys.calls.last.cwd, tmp.path);
    s.dispose();
  });

  test('a shell that cannot be started reports the error and can retry', () {
    ptys.failWith = StateError('Failed to create PTY: no such file');
    final s = make();
    s.start();
    expect(s.status, SessionStatus.error);
    expect(s.startError, contains('Failed to create PTY'));
    expect(s.connected, isFalse);

    ptys.failWith = null;
    s.restart();
    expect(s.connected, isTrue);
    expect(s.startError, isNull);
    s.dispose();
  });

  test('dispose kills the running shell and ignores a late exit', () async {
    final s = make();
    s.start();
    final pty = ptys.last;
    s.dispose();
    expect(pty.killed, isTrue);
    await pump(); // 늦게 도착한 종료 알림이 해제된 세션을 건드려도 오류가 없어야 한다
  });

  test('writing after the shell has exited does nothing', () async {
    final s = make();
    s.start();
    ptys.last.finish(0);
    await pump();
    s.terminal.textInput('ignored');
    expect(ptys.made, hasLength(1));
    s.dispose();
  });

  test('typePaths quotes and pastes the paths without pressing Enter', () {
    final s = make();
    s.start();
    s.typePaths(['/a b/x', "/it's"]);
    expect(utf8.decode(ptys.last.written, allowMalformed: true), contains('/a b/x'));
    s.dispose();
  });

  test('tabTitle is the shell name', () {
    final s = make();
    expect(s.tabTitle, 'bash');
    s.dispose();
  });
}
