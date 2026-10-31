import 'dart:io';

import 'package:daylight_taskbench/workspace/project_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

const _flutterPubspec = 'name: app_x\nversion: 1.2.3+4\ndependencies:\n  flutter:\n    sdk: flutter\n';

void _project(String dir, {String name = 'app_x'}) {
  Directory(dir).createSync(recursive: true);
  File('$dir/pubspec.yaml').writeAsStringSync(_flutterPubspec.replaceFirst('app_x', name));
}

void main() {
  const detector = FlutterDetector();
  late Directory root;

  setUp(() async => root = await tempDir('detect'));
  tearDown(() => root.deleteSync(recursive: true));

  test('depth 0 에서 찾으면 아래 폴더는 보지 않는다', () async {
    _project(root.path, name: 'top');
    _project('${root.path}/gui', name: 'inner');
    final found = await detector.detect(root.path);
    expect(found.map((p) => p.name), ['top']);
    expect(found.single.version, '1.2.3+4');
  });

  test('depth 0 에 없으면 depth 1 에서 찾고, 여럿이면 모두 돌려준다', () async {
    _project('${root.path}/b_app', name: 'b');
    _project('${root.path}/a_app', name: 'a');
    final found = await detector.detect(root.path);
    expect(found.map((p) => p.name), ['a', 'b']);
  });

  test('depth 2 이상은 찾지 않는다', () async {
    _project('${root.path}/x/y', name: 'deep');
    expect(await detector.detect(root.path), isEmpty);
  });

  test('. 폴더와 build·node_modules·target·dist 는 건너뛴다', () async {
    for (final d in ['.hidden', 'build', 'node_modules', 'target', 'dist']) {
      _project('${root.path}/$d', name: d);
    }
    _project('${root.path}/ok', name: 'ok');
    expect((await detector.detect(root.path)).map((p) => p.name), ['ok']);
  });

  test('Flutter 가 아닌 pubspec(순수 Dart)은 프로젝트가 아니다', () async {
    Directory('${root.path}/dart_only').createSync();
    File('${root.path}/dart_only/pubspec.yaml').writeAsStringSync('name: d\ndependencies:\n  http: ^1.0.0\n');
    expect(await detector.detect(root.path), isEmpty);
  });
}
