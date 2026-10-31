import 'dart:io';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 임시 폴더를 만들고 테스트가 끝나면 지운다.
Future<Directory> tempDir(String name) async {
  final d = await Directory.systemTemp.createTemp('taskbench_$name');
  return Directory(d.resolveSymbolicLinksSync());
}

Future<void> git(String cwd, List<String> args) async {
  final r = await Process.run('git', args, workingDirectory: cwd, environment: {
    'GIT_AUTHOR_NAME': 't',
    'GIT_AUTHOR_EMAIL': 't@t',
    'GIT_COMMITTER_NAME': 't',
    'GIT_COMMITTER_EMAIL': 't@t',
  });
  if (r.exitCode != 0) throw StateError('git ${args.join(' ')}: ${r.stderr}');
}

/// 커밋 하나가 있는 저장소.
Future<Directory> makeRepo(String name) async {
  final d = await tempDir(name);
  await git(d.path, ['init', '-b', 'main']);
  File('${d.path}/a.txt').writeAsStringSync('a');
  await git(d.path, ['add', '-A']);
  await git(d.path, ['commit', '-m', 'init']);
  return d;
}

Future<Workspace> makeWorkspace() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return Workspace(runner: CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? ''), prefs: prefs);
}
