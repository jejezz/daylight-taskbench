// Gradle 칸 모듈의 약속: 고른 폴더 → 프로젝트, 접힌 채 브랜치 전환 시 다시 찾기, 요약·모양.

import 'dart:io';

import 'package:daylight_taskbench/docks/gradle/detect/gradle_project.dart';
import 'package:daylight_taskbench/docks/gradle/gradle_dock.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await tempDir('gradledock'));

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 150)); // 진행 중인 감지가 끝난 뒤 지운다
    dir.deleteSync(recursive: true);
  });

  Future<(GradleDock, Workspace, FakeGitStateSource)> setup() async {
    final ws = await makeWorkspace();
    final source = FakeGitStateSource(GitState(root: dir.path, branch: 'main', sha: '1'));
    ws.attachForTest(source, selectedDir: dir.path);
    final dock = GradleDock()..attach(ws);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return (dock, ws, source);
  }

  void androidApp() {
    File('${dir.path}/settings.gradle.kts').writeAsStringSync('rootProject.name = "notes"\ninclude(":app")');
    Directory('${dir.path}/app').createSync();
    File('${dir.path}/app/build.gradle.kts').writeAsStringSync('plugins { id("com.android.application") }');
  }

  test('프로젝트가 없으면 칸이 켜지지 않는다', () async {
    final (dock, ws, _) = await setup();
    expect(dock.appliesTo(ws), isFalse);
    expect(dock.project, isNull);
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });

  test('Gradle 프로젝트를 찾으면 켜지고 모양을 읽는다', () async {
    androidApp();
    final (dock, ws, _) = await setup();
    expect(dock.appliesTo(ws), isTrue);
    expect(dock.isRunner, isTrue);
    expect(dock.id, 'gradle');
    expect(dock.selected(ws)!.name, 'notes');
    expect(dock.project!.shape, GradleShape.androidApp);
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });

  test('브랜치가 바뀌면(접혀 있어도) 다시 찾아 칸이 켜지고 꺼진다 (§1.10)', () async {
    final (dock, ws, source) = await setup();
    ws.headChanges.listen((c) => dock.onHeadChange(ws, c));
    expect(dock.appliesTo(ws), isFalse);
    androidApp(); // 다른 브랜치에는 Gradle 프로젝트가 있다
    source.set(GitState(root: dir.path, branch: 'feature', sha: '2'));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(dock.appliesTo(ws), isTrue);
    File('${dir.path}/settings.gradle.kts').deleteSync();
    source.set(GitState(root: dir.path, branch: 'main', sha: '3'));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(dock.appliesTo(ws), isFalse);
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });

  test('Flutter 프로젝트의 android/ 폴더를 고르면 칸이 켜지지 않는다', () async {
    File('${dir.path}/pubspec.yaml').writeAsStringSync('name: app\ndependencies:\n  flutter:\n    sdk: flutter\n');
    Directory('${dir.path}/android').createSync();
    File('${dir.path}/android/settings.gradle').writeAsStringSync("include ':app'");
    final (dock, ws, _) = await setup();
    expect(dock.appliesTo(ws), isFalse);
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });

  test('프로젝트가 여럿이면 고른 것을 폴더별로 기억한다', () async {
    for (final n in ['a', 'b']) {
      Directory('${dir.path}/$n').createSync();
      File('${dir.path}/$n/settings.gradle.kts').writeAsStringSync('rootProject.name = "$n"');
    }
    final (dock, ws, _) = await setup();
    expect(dock.projects.map((p) => p.name), ['a', 'b']);
    expect(dock.selected(ws)!.name, 'a');
    await dock.choose(ws, dock.projects.last);
    expect(dock.selected(ws)!.name, 'b');
    expect(dock.project!.name, 'b');
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });
}
