// Gradle 칸 화면: 최소 창(380)에서 넘치지 않고, 고른 동작이 명령 미리보기에 그대로 보인다.

import 'dart:io';

import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/core/devices/adb_devices.dart';
import 'package:daylight_taskbench/core/devices/mobile_device.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_project.dart';
import 'package:daylight_taskbench/docks/gradle/doctor/gradle_diagnostics.dart';
import 'package:daylight_taskbench/docks/gradle/gradle_dock.dart';
import 'package:daylight_taskbench/docks/gradle/run/gradle_controller.dart';
import 'package:daylight_taskbench/docks/gradle/run/gradle_plan.dart';
import 'package:daylight_taskbench/docks/gradle/ui/gradle_dock_body.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

class _FakeDiagnostics implements GradleDiagnosticsService {
  @override
  Future<GradleDiagnostics> collect(GradleProject? project, GradleModule? module, {String? variant}) async => GradleDiagnostics(
        collectedAt: DateTime(2026, 1, 1, 9, 30),
        jdk: const JdkInfo(version: '17.0.9', major: 17, source: 'PATH'),
        wrapperPresent: true,
      );
}

class _FakeAdb implements AdbDevices {
  @override
  CommandRunner get runner => throw UnimplementedError();

  @override
  Future<List<MobileDevice>> list() async => const [MobileDevice(id: 'R58M123', name: 'Pixel 7', platform: DevicePlatform.android, link: DeviceLink.usb)];
}

void main() {
  late Directory dir;

  setUp(() async => dir = await tempDir('gradleui'));
  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    dir.deleteSync(recursive: true);
  });

  void write(String rel, String text) => (File('${dir.path}/$rel')..createSync(recursive: true)).writeAsStringSync(text);

  Future<(GradleDock, Workspace)> pump(WidgetTester tester, {Locale locale = const Locale('en'), double width = 380}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late GradleDock dock;
    late Workspace ws;
    await tester.runAsync(() async {
      ws = await makeWorkspace();
      ws.attachForTest(FakeGitStateSource(GitState(root: dir.path, branch: 'main', sha: '1')), selectedDir: dir.path);
      dock = GradleDock(controller: GradleController(runner: ws.runner, prefs: ws.prefs, adb: _FakeAdb(), diagnosticsService: _FakeDiagnostics(), processEnvironment: const {}, hostIsWindows: false))..attach(ws);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: GradleDockBody(dock: dock, workspace: ws)),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    addTearDown(() {
      dock.detach(ws);
      dock.dispose();
      ws.dispose();
    });
    return (dock, ws);
  }

  void androidApp() {
    write('settings.gradle.kts', 'rootProject.name = "notes"\ninclude(":app")');
    write('app/build.gradle.kts', 'plugins { id("com.android.application") }\nandroid { defaultConfig { applicationId = "com.example.notes" }\n buildTypes { release { } } }');
    write('gradlew', '#!/bin/sh\n');
  }

  for (final locale in const [Locale('en'), Locale('ko')]) {
    testWidgets('Android 앱: 380px 에서 넘치지 않고 설치+실행 명령이 그대로 보인다 (${locale.languageCode})', (tester) async {
      androidApp();
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('./gradlew --console=plain :app:installDebug', findRichText: true), findsOneWidget, reason: '명령 미리보기');
      expect(find.textContaining('ANDROID_SERIAL=R58M123', findRichText: true), findsOneWidget);
      expect(find.textContaining('android.intent.category.LAUNCHER', findRichText: true), findsOneWidget);
    });
  }

  testWidgets('동작을 바꾸면 명령 미리보기가 바뀐다', (tester) async {
    androidApp();
    final (dock, _) = await pump(tester);
    dock.controller!.selectAction(GradleAction.bundle);
    dock.controller!.selectVariant('release');
    await tester.pump();
    expect(find.textContaining(':app:bundleRelease', findRichText: true), findsOneWidget);
    expect(find.textContaining('ANDROID_SERIAL', findRichText: true), findsNothing, reason: '번들은 기기가 필요 없다');
  });

  testWidgets('기기가 없으면 시작 단추가 꺼지고 이유가 보인다', (tester) async {
    androidApp();
    final (dock, _) = await pump(tester);
    dock.controller!.devices = const [];
    dock.controller!.selectedId = null;
    dock.controller!.notifyListeners();
    await tester.pump();
    expect(find.textContaining('Connect a device'), findsOneWidget);
    final start = find.widgetWithText(FilledButton, 'Install & run');
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
  });

  testWidgets('JVM 프로젝트: 기기 탭이 없고 바로가기와 작업 입력이 있다', (tester) async {
    write('settings.gradle.kts', 'rootProject.name = "tool"');
    write('build.gradle.kts', 'plugins {\n  kotlin("jvm")\n  application\n}');
    write('gradlew', '#!/bin/sh\n');
    final (dock, _) = await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Devices'), findsNothing);
    expect(find.textContaining('./gradlew --console=plain build', findRichText: true), findsOneWidget);
    dock.controller!.selectAction(GradleAction.task);
    await tester.pump();
    expect(find.text('Task name(s)'), findsOneWidget);
    expect(find.text('Load task list'), findsOneWidget);
  });

  testWidgets('Doctor 탭: 점검 결과가 한 줄씩 보이고, 해결 단계는 펼쳐 본다', (tester) async {
    androidApp();
    final (_, _) = await pump(tester);
    await tester.tap(find.text('Doctor'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Gradle wrapper found'), findsOneWidget);
    expect(find.textContaining('JDK 17.0.9 (from PATH)'), findsOneWidget);
    expect(find.text('Android SDK not found'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    await tester.tap(find.text('Android SDK not found'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ANDROID_HOME'), findsWidgets);
  });

  testWidgets('JVM 프로젝트는 Run · Doctor · Log 세 탭이다', (tester) async {
    write('settings.gradle.kts', 'rootProject.name = "tool"');
    write('build.gradle.kts', 'plugins {\n  kotlin("jvm")\n  application\n}');
    write('gradlew', '#!/bin/sh\n');
    await pump(tester);
    expect(find.text('Run'), findsWidgets);
    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('Devices'), findsNothing);
  });
}
