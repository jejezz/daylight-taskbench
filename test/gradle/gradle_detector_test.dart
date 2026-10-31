// Gradle 감지와 모양 판정 (docs/GRADLE_RUNNER.md §3): Flutter·React Native 의 android/ 는 제외한다.

import 'dart:io';

import 'package:daylight_taskbench/docks/gradle/detect/gradle_detector.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_project.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

void write(Directory root, String rel, String text) {
  final f = File('${root.path}/$rel')..createSync(recursive: true);
  f.writeAsStringSync(text);
}

const detector = GradleDetector();

void main() {
  late Directory tmp;

  setUp(() async => tmp = await tempDir('gradle'));
  tearDown(() => tmp.deleteSync(recursive: true));

  group('감지', () {
    test('settings.gradle.kts 가 있으면 프로젝트이고 이름은 rootProject.name', () async {
      write(tmp, 'settings.gradle.kts', 'rootProject.name = "notes"\ninclude(":app")\n');
      final p = (await detector.detect(tmp.path)).single;
      expect(p.kind, 'gradle');
      expect(p.name, 'notes');
      expect(p.path, tmp.path);
    });

    test('이름이 없으면 폴더 이름, 루트 version 이 있으면 버전', () async {
      write(tmp, 'settings.gradle', "include ':app'\n");
      write(tmp, 'build.gradle', "version = '2.1.0'\n");
      final p = (await detector.detect(tmp.path)).single;
      expect(p.name, tmp.path.split('/').last);
      expect(p.version, '2.1.0');
    });

    test('아무 파일도 없으면 못 찾는다', () async {
      expect(await detector.detect(tmp.path), isEmpty);
    });

    test('build 파일만 있으면 아니고, 래퍼까지 있으면 단일 프로젝트로 본다', () async {
      write(tmp, 'build.gradle.kts', 'plugins { application }');
      expect(await detector.detect(tmp.path), isEmpty);
      write(tmp, 'gradlew', '#!/bin/sh\n');
      expect(await detector.detect(tmp.path), hasLength(1));
    });

    test('한 단계 아래 폴더에서도 찾는다 (depth 0 → 1)', () async {
      write(tmp, 'work/myapp/settings.gradle.kts', 'rootProject.name = "myapp"');
      write(tmp, 'work/other/readme.md', 'x');
      final found = await detector.detect('${tmp.path}/work');
      expect(found.map((p) => p.name), ['myapp']);
    });

    test('build·.gradle 같은 폴더는 건너뛴다', () async {
      write(tmp, 'build/settings.gradle', '');
      write(tmp, '.gradle/settings.gradle', '');
      expect(await detector.detect(tmp.path), isEmpty);
    });
  });

  group('다른 칸의 몫인 android/ 제외', () {
    test('Flutter 프로젝트의 android/ 는 감지하지 않는다 (직접 열었을 때도)', () async {
      write(tmp, 'app/pubspec.yaml', 'name: app\ndependencies:\n  flutter:\n    sdk: flutter\n');
      write(tmp, 'app/android/settings.gradle', "include ':app'");
      expect(await detector.detect('${tmp.path}/app/android'), isEmpty);
      expect(await detector.detect('${tmp.path}/app'), isEmpty, reason: 'depth 1 의 android/ 도 제외');
    });

    test('React Native 프로젝트의 android/ 도 제외한다', () async {
      write(tmp, 'rn/package.json', '{"dependencies": {"react-native": "0.74.0"}}');
      write(tmp, 'rn/android/settings.gradle', "include ':app'");
      expect(await detector.detect('${tmp.path}/rn'), isEmpty);
    });

    test('react-native 가 없는 package.json 옆의 Gradle 폴더는 그대로 감지한다', () async {
      write(tmp, 'web/package.json', '{"dependencies": {"express": "4"}}');
      write(tmp, 'web/backend/settings.gradle.kts', 'rootProject.name = "backend"');
      expect((await detector.detect('${tmp.path}/web')).map((p) => p.name), ['backend']);
    });
  });

  group('프로젝트 읽기와 모양', () {
    test('앱 모듈이 있으면 Android 앱, 라이브러리는 실행 대상이 아니다', () async {
      write(tmp, 'settings.gradle.kts', 'rootProject.name = "x"\ninclude(":app", ":core")');
      write(tmp, 'app/build.gradle.kts', 'plugins { id("com.android.application") }\nandroid { defaultConfig { applicationId = "com.x" } }');
      write(tmp, 'core/build.gradle.kts', 'plugins { id("com.android.library") }');
      write(tmp, 'gradlew', '');
      final p = await GradleProject.read(tmp.path, name: 'x');
      expect(p.shape, GradleShape.androidApp);
      expect(p.modules.map((m) => (m.path, m.kind)), [(':app', ModuleKind.androidApp), (':core', ModuleKind.androidLibrary)]);
      expect(p.modules.first.isRunnable, isTrue);
      expect(p.modules.last.isRunnable, isFalse);
      expect(p.modules.first.android!.applicationId, 'com.x');
      expect(p.hasWrapper, isTrue);
      expect(p.readError, isNull);
    });

    test('중첩 모듈 경로를 폴더로 바꿔 읽는다', () async {
      write(tmp, 'settings.gradle', "include ':feature:login'");
      write(tmp, 'feature/login/build.gradle', "plugins {\n  id 'com.android.library'\n}");
      final p = await GradleProject.read(tmp.path);
      expect(p.modules.single.path, ':feature:login');
      expect(p.modules.single.dir, 'feature/login');
    });

    test('include 줄이 없어도 app/ 폴더를 시험한다', () async {
      write(tmp, 'settings.gradle', '// nothing\n');
      write(tmp, 'app/build.gradle', "apply plugin: 'com.android.application'");
      expect((await GradleProject.read(tmp.path)).shape, GradleShape.androidApp);
    });

    test('JVM 단일 프로젝트: 루트의 application 플러그인', () async {
      write(tmp, 'settings.gradle.kts', 'rootProject.name = "tool"');
      write(tmp, 'build.gradle.kts', 'plugins {\n  kotlin("jvm") version "1.9.0"\n  application\n}');
      final p = await GradleProject.read(tmp.path);
      expect(p.shape, GradleShape.jvm);
      expect(p.modules.single.kind, ModuleKind.jvmApp);
      expect(p.modules.single.path, ':');
      expect(p.hasWrapper, isFalse);
    });

    test('Spring Boot 모듈', () async {
      write(tmp, 'settings.gradle', "include 'server'");
      write(tmp, 'server/build.gradle', "plugins {\n  id 'org.springframework.boot' version '3.2.0'\n}");
      expect((await GradleProject.read(tmp.path)).modules.single.kind, ModuleKind.springBoot);
    });

    test('읽을 수 없는 구성도 던지지 않고 빈 모듈 목록을 준다', () async {
      write(tmp, 'settings.gradle.kts', 'val x = something()');
      final p = await GradleProject.read(tmp.path);
      expect(p.modules, isEmpty);
      expect(p.shape, GradleShape.jvm);
    });
  });
}
