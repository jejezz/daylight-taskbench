// Gradle 칸이 셸과 만나는 곳 (단계 9e): 실행 중 브랜치 전환, 접힌 제목의 요약, 색(mood)·busy, 진행 중인 git 작업.
// 가짜 gradlew 셸 스크립트를 쓰므로 POSIX 가 필요하다 — Windows 에서는 건너뛴다.

import 'dart:io';

import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/core/devices/adb_devices.dart';
import 'package:daylight_taskbench/core/devices/mobile_device.dart';
import 'package:daylight_taskbench/core/run_session.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_project.dart';
import 'package:daylight_taskbench/docks/gradle/doctor/gradle_diagnostics.dart';
import 'package:daylight_taskbench/docks/gradle/gradle_dock.dart';
import 'package:daylight_taskbench/docks/gradle/run/gradle_controller.dart';
import 'package:daylight_taskbench/docks/gradle/run/gradle_plan.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/theme/taskbench_style.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

class _Adb implements AdbDevices {
  @override
  CommandRunner get runner => throw UnimplementedError();

  @override
  Future<List<MobileDevice>> list() async => const [MobileDevice(id: 'R58M123', name: 'Pixel 7', platform: DevicePlatform.android, link: DeviceLink.usb)];
}

class _Diag implements GradleDiagnosticsService {
  _Diag({this.healthy = true});

  final bool healthy;

  @override
  Future<GradleDiagnostics> collect(GradleProject? project, GradleModule? module, {String? variant}) async => GradleDiagnostics(
        collectedAt: DateTime(2026),
        jdk: healthy ? const JdkInfo(version: '17', major: 17, source: 'PATH') : const JdkInfo(),
        sdk: healthy ? const SdkInfo(dir: '/sdk', source: 'ANDROID_HOME') : null,
        platformPresent: true,
        buildToolsPresent: true,
        licensesAccepted: true,
        adbVersion: '1.0.41',
        wrapperPresent: true,
      );
}

void main() {
  final skip = Platform.isWindows ? 'POSIX 셸 필요' : null;
  late Directory dir;

  setUp(() async => dir = await tempDir('gradleflow'));
  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    dir.deleteSync(recursive: true);
  });

  Future<void> script(String body) async {
    final f = File('${dir.path}/gradlew')..writeAsStringSync('#!/bin/sh\n$body\n');
    await Process.run('chmod', ['+x', f.path]);
  }

  void androidApp() {
    File('${dir.path}/settings.gradle.kts').writeAsStringSync('rootProject.name = "notes"\ninclude(":app")');
    Directory('${dir.path}/app').createSync();
    File('${dir.path}/app/build.gradle.kts').writeAsStringSync('plugins { id("com.android.application") }\nandroid { defaultConfig { applicationId = "com.example.notes" } }');
    // 래퍼는 프로젝트를 읽을 때 있어야 한다 — 내용은 테스트마다 script() 로 바꾼다.
    File('${dir.path}/gradlew').writeAsStringSync('#!/bin/sh\necho ok\n');
    Process.runSync('chmod', ['+x', '${dir.path}/gradlew']);
  }

  Future<(GradleDock, GradleController, Workspace, FakeGitStateSource)> setup({bool healthy = true}) async {
    androidApp();
    final ws = await makeWorkspace();
    final source = FakeGitStateSource(GitState(root: dir.path, branch: 'main', sha: '1'));
    ws.attachForTest(source, selectedDir: dir.path);
    final c = GradleController(runner: ws.runner, prefs: ws.prefs, adb: _Adb(), diagnosticsService: _Diag(healthy: healthy), processEnvironment: const {}, hostIsWindows: false);
    final dock = GradleDock(controller: c)..attach(ws);
    ws.headChanges.listen((change) => dock.onHeadChange(ws, change));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return (dock, c, ws, source);
  }

  void dispose(GradleDock dock, Workspace ws) {
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  }

  testWidgets('접힌 제목의 요약: 평소엔 이름·모양, 실행 중·실패·완료는 동작과 함께', (tester) async {
    late GradleDock dock;
    late GradleController c;
    late Workspace ws;
    await tester.runAsync(() async {
      (dock, c, ws, _) = await setup();
      await c.init();
      await script('sleep 1; echo ok');
      c.selectAction(GradleAction.assemble);
    });
    Future<String> summary() async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: Builder(builder: (context) => dock.summary(context, ws))),
      ));
      return tester.widget<Text>(find.byType(Text)).data!;
    }

    expect(await summary(), 'notes · Android app');
    late Future<void> run;
    await tester.runAsync(() async {
      run = c.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    expect(await summary(), 'Build APK…');
    await tester.runAsync(() => run);
    expect(await summary(), 'Build APK done');
    await tester.runAsync(() async {
      await script('exit 1');
      await c.start();
    });
    expect(await summary(), 'Build APK failed');
    // 드롭다운을 바꿔도 지난 실행의 이름이 그대로다.
    c.selectAction(GradleAction.lint);
    expect(await summary(), 'Build APK failed');
    addTearDown(() => dispose(dock, ws));
  }, skip: Platform.isWindows);

  test('mood·busy: 일하는 중 → 성공 → 실패, 그리고 경고(점검 실패·오래된 점검·진행 중인 git 작업)', () async {
    final (dock, c, ws, source) = await setup();
    await c.init();
    expect(dock.mood(ws), TaskbenchMood.idle);
    expect(dock.busy(ws), isFalse);
    await script('sleep 1');
    c.selectAction(GradleAction.assemble);
    final run = c.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(dock.busy(ws), isTrue);
    expect(dock.mood(ws), TaskbenchMood.working);
    await run;
    expect(dock.busy(ws), isFalse);
    expect(dock.mood(ws), TaskbenchMood.success);
    await script('exit 1');
    await c.start();
    expect(dock.mood(ws), TaskbenchMood.failed);
    // 실패 표시를 지우려면 성공한 실행이 필요하다 — 아래 경고들은 새 칸에서 본다.
    source.set(GitState(root: dir.path, branch: 'main', sha: '1', operation: RepoOperation.merging, conflictCount: 1));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(dock.operationInProgress(ws), isTrue);
    dispose(dock, ws);
  }, skip: skip);

  test('mood: 환경 점검에서 실패한 항목이 있으면 경고, 브랜치가 바뀌면 오래된 점검도 경고', () async {
    final (dock, c, ws, source) = await setup(healthy: false);
    await c.init();
    expect(c.checks.any((x) => x.status.name == 'fail'), isTrue);
    expect(dock.mood(ws), TaskbenchMood.warning);
    dispose(dock, ws);

    final (dock2, c2, ws2, source2) = await setup();
    await c2.init();
    expect(dock2.mood(ws2), TaskbenchMood.idle);
    source2.set(GitState(root: dir.path, branch: 'other', sha: '2'));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(c2.diagnosticsStale, isTrue);
    expect(dock2.mood(ws2), TaskbenchMood.warning);
    expect(source, isNotNull);
    dispose(dock2, ws2);
  });

  test('실행 중 브랜치가 바뀌면 중지하지 않고 배너만 띄우고, 끝나면 사라진다 (§1.10)', () async {
    final (dock, c, ws, source) = await setup();
    await c.init();
    await script('sleep 1; echo done');
    c.selectAction(GradleAction.assemble);
    final run = c.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    source.set(GitState(root: dir.path, branch: 'feature/login', sha: '2'));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(c.running, isTrue, reason: '중지하지 않는다');
    expect(dock.branchChangedWhileRunning, 'feature/login');
    expect(dock.mood(ws), TaskbenchMood.working);
    await run;
    expect(c.statuses, [StepStatus.done], reason: '실행은 끝까지 간다');
    expect(dock.branchChangedWhileRunning, isNull, reason: '실행이 끝나면 배너가 사라진다');
    dispose(dock, ws);
  }, skip: skip);

  test('실행 중이 아닐 때 브랜치가 바뀌면 배너 없이 목록 캐시만 버린다', () async {
    final (dock, c, ws, source) = await setup();
    await c.init();
    c.exactVariants = const ['freeDebug'];
    c.tasks = const [GradleTaskInfo('build', '')];
    source.set(GitState(root: dir.path, branch: 'other', sha: '2'));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(dock.branchChangedWhileRunning, isNull);
    expect(c.exactVariants, isNull);
    expect(c.tasks, isNull);
    dispose(dock, ws);
  });

  test('배너를 닫을 수 있다', () async {
    final (dock, c, ws, source) = await setup();
    await c.init();
    await script('sleep 1');
    c.selectAction(GradleAction.assemble);
    final run = c.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    source.set(GitState(root: dir.path, branch: 'other', sha: '2'));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(dock.branchChangedWhileRunning, isNotNull);
    dock.dismissBranchBanner();
    expect(dock.branchChangedWhileRunning, isNull);
    await run;
    dispose(dock, ws);
  }, skip: skip);

  test('Stop daemons: ./gradlew --stop 을 같은 환경으로 실행한다', () async {
    final (dock, c, ws, _) = await setup();
    await c.init();
    await script('echo "args: \$@"');
    await c.stopDaemons();
    expect(ws.runner.log.last!.commandLine, './gradlew --console=plain --stop');
    expect(ws.runner.log.last!.output, contains('args: --console=plain --stop'));
    dispose(dock, ws);
  }, skip: skip);
}
