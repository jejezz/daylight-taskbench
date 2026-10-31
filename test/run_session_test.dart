// 공통 실행 엔진(RunSession)·명령 기록 상한·프로세스 트리 종료·adb 기기 목록 (docs/GRADLE_RUNNER.md §7, 단계 9a).
// 실제 프로세스를 띄우므로 POSIX 셸이 필요하다 — Windows 에서는 건너뛴다.

import 'dart:io';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/core/devices/adb_devices.dart';
import 'package:daylight_taskbench/core/devices/mobile_device.dart';
import 'package:daylight_taskbench/core/run_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _Step implements RunStep {
  _Step(this.args, {this.interactive = false});

  @override
  final List<String> args;
  @override
  final bool interactive;
  @override
  String? get workingDirectory => null;
  @override
  Map<String, String> get environment => const {};
}

RunStep sh(String script, {bool interactive = false}) => _Step(['sh', '-c', script], interactive: interactive);

CommandRunner _runner() => CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');

void main() {
  final skip = Platform.isWindows ? 'POSIX 셸 필요' : null;

  group('RunSession', () {
    test('단계를 순서대로 실행하고 상태를 알린다', () async {
      final events = <String>[];
      final out = await RunSession(_runner()).run([sh('exit 0'), sh('exit 0')], [0, 1], onStatus: (i, s) => events.add('$i:${s.name}'));
      expect(out.ok, isTrue);
      expect(events, ['0:running', '0:done', '1:running', '1:done']);
    }, skip: skip);

    test('하나가 실패하면 거기서 멈추고 실패한 단계와 출력을 돌려준다', () async {
      final events = <String>[];
      final out = await RunSession(_runner()).run([sh('echo boom >&2; exit 3'), sh('exit 0')], [0, 1], onStatus: (i, s) => events.add('$i:${s.name}'));
      expect(out.ok, isFalse);
      expect(out.failedIndex, 0);
      expect(out.failedResult!.exitCode, 3);
      expect(out.failedResult!.combined, contains('boom'));
      expect(events, ['0:running', '0:failed']);
    }, skip: skip);

    test('고른 번호의 단계만 실행한다', () async {
      final events = <String>[];
      await RunSession(_runner()).run([sh('exit 1'), sh('exit 0')], [1], onStatus: (i, s) => events.add('$i:${s.name}'));
      expect(events, ['1:running', '1:done']);
    }, skip: skip);

    test('없는 실행 파일은 127 로 실패한다', () async {
      final out = await RunSession(_runner()).run([_Step(['no-such-tool-xyz'])], [0]);
      expect(out.failedResult!.exitCode, 127);
    });

    test('cancel: 실행 중인 단계가 취소로 끝난다', () async {
      final session = RunSession(_runner());
      final events = <String>[];
      final future = session.run([sh('sleep 30')], [0], onStatus: (i, s) => events.add('$i:${s.name}'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(session.running, isTrue);
      session.cancel();
      final out = await future;
      expect(out.cancelled, isTrue);
      expect(out.ok, isFalse);
      expect(events.last, '0:cancelled');
      expect(session.running, isFalse);
    }, skip: skip);

    test('계속 실행되는 단계는 키를 받고 정상 종료하면 성공이다', () async {
      final session = RunSession(_runner());
      final future = session.run([sh('read k; echo got \$k', interactive: true)], [0]);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      session.send('q\n');
      final out = await future;
      expect(out.ok, isTrue);
    }, skip: skip);

    test('cancel 은 자식 프로세스까지 끝낸다 (고아로 남지 않는다)', () async {
      final session = RunSession(_runner());
      // 다른 프로세스와 겹치지 않는 sleep 길이로 자식을 찾는다.
      final n = 100000 + DateTime.now().microsecondsSinceEpoch % 90000;
      final future = session.run([sh('sleep $n & wait')], [0]);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect((await Process.run('pgrep', ['-f', 'sleep $n'])).exitCode, 0, reason: '자식이 떠 있어야 한다');
      session.cancel();
      await future;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final left = await Process.run('pgrep', ['-fl', 'sleep $n']);
      expect(left.exitCode, 1, reason: 'sleep $n 이 남아 있다: ${left.stdout}');
    }, skip: skip);
  });

  group('CommandLog', () {
    test('긴 출력은 꼬리만 남기고 앞부분이 생략됐다고 알린다', () {
      final e = CommandLogEntry(args: const ['x'], started: DateTime.now());
      final chunk = 'a' * 100000;
      for (var i = 0; i < 30; i++) {
        e.append(chunk);
      }
      expect(e.droppedChars, greaterThan(0));
      expect(e.output.length, lessThan(CommandLogEntry.maxOutputChars * 1.3));
      expect(e.output, startsWith('[…'));
    });

    test('짧은 출력은 그대로다', () {
      final e = CommandLogEntry(args: const ['x'], started: DateTime.now())..append('hello\n');
      expect(e.output, 'hello\n');
      expect(e.droppedChars, 0);
    });

    test('updateThrottled: 쏟아지는 갱신은 묶고, 마지막 변화는 반드시 알린다', () async {
      final log = CommandLog();
      var notified = 0;
      log.addListener(() => notified++);
      for (var i = 0; i < 50; i++) {
        log.updateThrottled(interval: const Duration(milliseconds: 80));
      }
      expect(notified, 1, reason: '첫 갱신만 바로');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(notified, 2, reason: '묶인 나머지가 한 번에');
      log.dispose();
    });

    test('update 는 대기 중인 묶음 갱신을 정리한다', () async {
      final log = CommandLog();
      var notified = 0;
      log.addListener(() => notified++);
      log.updateThrottled(interval: const Duration(milliseconds: 80));
      log.updateThrottled(interval: const Duration(milliseconds: 80));
      log.update();
      expect(notified, 2);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(notified, 2, reason: '이미 알렸으니 타이머가 또 알리지 않는다');
      log.dispose();
    });
  });

  group('AdbDevices', () {
    test('adb devices -l 출력에서 Android 기기를 읽는다', () async {
      final dir = Directory.systemTemp.createTempSync('fake_adb');
      addTearDown(() => dir.deleteSync(recursive: true));
      final script = File('${dir.path}/adb')
        ..writeAsStringSync('#!/bin/sh\nprintf "List of devices attached\\nR58M123 device usb:1 product:p model:Pixel_7\\nemulator-5554 offline\\n"\n');
      await Process.run('chmod', ['+x', script.path]);
      final runner = _runner()..toolPaths = {'adb': script.path};
      final devices = await AdbDevices(runner).list();
      expect(devices.map((d) => d.id), ['R58M123', 'emulator-5554']);
      expect(devices.first.name, 'Pixel 7');
      expect(devices.first.platform, DevicePlatform.android);
      expect(devices.last.authorized, isFalse);
    }, skip: skip);

    test('adb 가 없으면 빈 목록이다', () async {
      final runner = _runner()..toolPaths = {'adb': '/no/such/adb'};
      expect(await AdbDevices(runner).list(), isEmpty);
    });
  });
}
