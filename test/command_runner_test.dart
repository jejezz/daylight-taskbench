// 두 원본(Branch·Flutty)의 command_runner 동작을 함께 지킨다 (PLAN.md 단계 2 완료 조건).

import 'dart:convert';
import 'dart:io';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';

final _sep = Platform.isWindows ? ';' : ':';

CommandRunner _runner({String? path, String? gitPath, String? ghPath}) =>
    CommandRunner(log: CommandLog(), path: path ?? Platform.environment['PATH'] ?? '', gitPath: gitPath, ghPath: ghPath);

void main() {
  group('실행 파일 지정 (Flutty toolPaths + Branch gitPath/ghPath)', () {
    test('지정한 도구는 이름 대신 쓰이고, 그 폴더가 PATH 맨 앞에 온다', () {
      final r = _runner(path: '/usr/bin')..toolPaths = {'adb': '/opt/sdk/platform-tools/adb'};
      expect(r.executableFor('adb'), '/opt/sdk/platform-tools/adb');
      expect(r.executableFor('flutter'), 'flutter');
      expect(r.effectivePath.startsWith('/opt/sdk/platform-tools$_sep'), isTrue);
    });

    test('gitPath·ghPath 는 toolPaths 의 git·gh 와 같은 값이다', () {
      final r = _runner(gitPath: '/x/git', ghPath: '/y/gh');
      expect(r.toolPaths, {'git': '/x/git', 'gh': '/y/gh'});
      expect(r.executableFor('git'), '/x/git');
      r.gitPath = null;
      expect(r.toolPaths, {'gh': '/y/gh'});
      r.toolPaths = {'git': '/z/git'};
      expect(r.gitPath, '/z/git');
      expect(r.ghPath, isNull);
    });

    test('빈 문자열 경로는 지정하지 않은 것으로 본다', () {
      final r = _runner()..toolPaths = {'git': ''};
      expect(r.gitPath, isNull);
      expect(r.executableFor('git'), 'git');
    });

    test('locate: 지정한 경로는 실제로 있어야 하고, 없으면 PATH 에서 찾는다', () async {
      final dir = await Directory.systemTemp.createTemp('tb_tools');
      addTearDown(() => dir.delete(recursive: true));
      final exe = File('${dir.path}/adb')..writeAsStringSync('#!/bin/sh\n');
      final r = _runner(path: '/usr/bin')..toolPaths = {'adb': exe.path};
      expect(r.locate('adb'), exe.path);
      r.toolPaths = {'adb': '${dir.path}/missing'};
      expect(r.locate('adb'), isNull);
      r.toolPaths = {};
      expect(r.locate('definitely-not-a-real-tool-xyz'), isNull);
    });

    test('findExecutable 은 PATH 형식 목록에서 파일을 찾는다', () async {
      final dir = await Directory.systemTemp.createTemp('tb_find');
      addTearDown(() => dir.delete(recursive: true));
      File('${dir.path}/mytool${Platform.isWindows ? '.exe' : ''}').writeAsStringSync('x');
      expect(findExecutable('mytool', '/nonexistent$_sep${dir.path}'), isNotNull);
      expect(findExecutable('other', dir.path), isNull);
    });
  });

  group('출력 해석 (Flutty)', () {
    test('UTF-8 출력은 그대로 읽는다', () => expect(decodeProcessOutput(utf8.encode('한글 ok')), '한글 ok'));
    test('UTF-8이 아니면 대체 코덱으로 읽는다', () => expect(decodeProcessOutput([0xE9, 0x61], fallback: latin1), 'éa'));
  });

  group('실행', () {
    test('git 은 영어 오류 문구(LC_ALL=C)와 프롬프트 금지 환경을 받는다 (Branch)', () async {
      final r = _runner();
      final res = await r.run(['git', 'rev-parse', '--show-toplevel'], workingDirectory: Directory.systemTemp.path, quiet: true);
      expect(res.exitCode, isNot(0));
      expect(res.stderr, contains('not a git repository')); // 로케일과 무관하게 영어
    }, skip: Platform.isWindows ? 'Windows 에서는 git 설치에 달림' : null);

    test('환경 변수: git 에만 LC_ALL, 모두에게 NO_COLOR·프롬프트 금지, environment 가 덮어쓴다', () async {
      final r = _runner();
      Future<String> env(String cmd, [Map<String, String> extra = const {}]) async =>
          (await r.run(['sh', '-c', 'echo \$$cmd'], environment: extra, quiet: true)).stdout.trim();
      expect(await env('NO_COLOR'), '1');
      expect(await env('GIT_TERMINAL_PROMPT'), '0');
      expect(await env('GH_PROMPT_DISABLED'), '1');
      expect(await env('LC_ALL'), isEmpty); // sh 는 git 이 아니다
      expect(await env('MY_VAR', {'MY_VAR': 'hello'}), 'hello');
    }, skip: Platform.isWindows ? 'sh 없음' : null);

    test('workingDirectory 를 안 주면 쓸 수 있는 임시 폴더에서 돈다 (Flutty)', () async {
      final res = await _runner().run(['pwd'], quiet: true);
      expect(Directory(res.stdout.trim()).resolveSymbolicLinksSync(), Directory(Directory.systemTemp.path).resolveSymbolicLinksSync());
    }, skip: Platform.isWindows ? 'pwd 없음' : null);

    test('없는 명령은 예외 대신 종료 코드 127 과 메시지', () async {
      final res = await _runner().run(['definitely-not-a-real-tool-xyz'], quiet: true);
      expect(res.exitCode, 127);
      expect(res.stderr, isNotEmpty);
    });

    test('onOutput 은 출력을 조각마다 흘려 주고, 로그에도 남는다', () async {
      final r = _runner();
      final chunks = <String>[];
      await r.run(['sh', '-c', 'echo one; echo two'], onOutput: chunks.add);
      expect(chunks.join(), contains('one'));
      expect(chunks.join(), contains('two'));
      expect(r.log.entries.single.output, contains('two'));
      expect(r.log.entries.single.succeeded, isTrue);
    }, skip: Platform.isWindows ? 'sh 없음' : null);

    test('quiet 이면 로그에 남기지 않는다', () async {
      final r = _runner();
      await r.run(['sh', '-c', 'true'], quiet: true);
      expect(r.log.entries, isEmpty);
    }, skip: Platform.isWindows ? 'sh 없음' : null);

    test('stdin 은 한 번 쓰고 닫는다', () async {
      final res = await _runner().run(['cat'], stdin: 'hello', quiet: true);
      expect(res.stdout, 'hello');
    }, skip: Platform.isWindows ? 'cat 없음' : null);

    test('keepStdinOpen + handle.send: 실행 중 입력을 보낼 수 있다 (Flutty flutter run 의 r·q)', () async {
      final r = _runner();
      final handle = RunHandle();
      final seen = <String>[];
      final future = r.run(['cat'], keepStdinOpen: true, handle: handle, quiet: true, onOutput: seen.add);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      handle.send('ping\n');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(seen.join(), contains('ping'));
      handle.cancel();
      await future;
      expect(handle.cancelled, isTrue);
    }, skip: Platform.isWindows ? 'cat 없음' : null);

    test('cancel: (Branch 의 CancelToken)도 같은 핸들이고 로그에 취소로 남는다', () async {
      final r = _runner();
      final token = CancelToken();
      final future = r.run(['sleep', '30'], cancel: token);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      token.cancel();
      await future;
      expect(r.log.entries.single.cancelled, isTrue);
    }, skip: Platform.isWindows ? 'sleep 없음' : null);

    test('handle 과 cancel 을 둘 다 주면 handle 이 이긴다', () async {
      final r = _runner();
      final handle = RunHandle();
      final other = CancelToken();
      final future = r.run(['sleep', '30'], handle: handle, cancel: other, quiet: true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      handle.cancel();
      await future;
      expect(other.cancelled, isFalse);
    }, skip: Platform.isWindows ? 'sleep 없음' : null);
  });

  group('PATH 만들기', () {
    test('resolvePath 는 이 프로세스의 PATH 와 흔한 위치를 합치고 중복이 없다', () async {
      final p = await resolvePath();
      final parts = p.split(_sep);
      expect(parts.toSet().length, parts.length);
      if (!Platform.isWindows) expect(parts, contains('/usr/bin'));
      for (final d in (Platform.environment['PATH'] ?? '').split(_sep).where((s) => s.trim().isNotEmpty)) {
        expect(parts, contains(d.trim()));
      }
    });
  });
}
