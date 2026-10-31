// Gradle 칸 컨트롤러: 폴더별 선택 복원, 기기 고르기, 실제 프로세스로 실행·실패 처방·취소, 변형·작업 목록 읽기.
// 가짜 gradlew·adb 셸 스크립트를 쓰므로 POSIX 가 필요하다 — Windows 에서는 건너뛴다.

import 'dart:io';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/core/devices/adb_devices.dart';
import 'package:daylight_taskbench/core/devices/mobile_device.dart';
import 'package:daylight_taskbench/core/run_session.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_parse.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_project.dart';
import 'package:daylight_taskbench/docks/gradle/run/gradle_controller.dart';
import 'package:daylight_taskbench/docks/gradle/run/gradle_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_support.dart';

class _FakeAdb implements AdbDevices {
  _FakeAdb(this.devices);

  List<MobileDevice> devices;
  int calls = 0;

  @override
  CommandRunner get runner => throw UnimplementedError();

  @override
  Future<List<MobileDevice>> list() async {
    calls++;
    return devices;
  }
}

const _pixel = MobileDevice(id: 'R58M123', name: 'Pixel 7', platform: DevicePlatform.android, link: DeviceLink.usb);
const _locked = MobileDevice(id: 'LOCKED', name: 'Locked', platform: DevicePlatform.android, link: DeviceLink.usb, authorized: false);

void main() {
  final skip = Platform.isWindows ? 'POSIX 셸 필요' : null;
  late Directory dir;
  late SharedPreferences prefs;
  late CommandRunner runner;

  Future<void> exe(String name, String body) async {
    final f = File('${dir.path}/$name')..writeAsStringSync('#!/bin/sh\n$body\n');
    await Process.run('chmod', ['+x', f.path]);
  }

  GradleProject androidProject({bool wrapper = true}) => GradleProject(
        path: dir.path,
        name: 'notes',
        hasWrapper: wrapper,
        modules: const [
          GradleModule(
            path: ':app',
            dir: 'app',
            kind: ModuleKind.androidApp,
            android: AndroidInfoForTest.info,
          ),
          GradleModule(path: ':core', dir: 'core', kind: ModuleKind.androidLibrary),
        ],
      );

  GradleController make({List<MobileDevice> devices = const [_pixel]}) =>
      GradleController(runner: runner, prefs: prefs, adb: _FakeAdb(devices), hostIsWindows: false);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dir = await tempDir('gradlectl');
    runner = CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('프로젝트를 받으면 실행할 수 있는 모듈·기본 변형·동작을 고른다 (라이브러리는 제외)', () {
    final c = make()..setProject(androidProject());
    expect(c.isAndroid, isTrue);
    expect(c.runnableModules.map((m) => m.path), [':app']);
    expect(c.module!.path, ':app');
    expect(c.variant, 'debug');
    expect(c.action, GradleAction.installRun);
    expect(c.variants, ['debug', 'release']);
    expect(c.actions, contains(GradleAction.bundle));
  });

  test('고른 변형·동작·옵션·작업은 프로젝트별로 저장되고 다시 열면 복원된다', () {
    final a = make()..setProject(androidProject());
    a.selectVariant('release');
    a.selectAction(GradleAction.assemble);
    a.setOptions(const GradleOptions(offline: true, extraArgs: '--info'));
    a.setCustomTask(':app:dependencies');
    final b = make()..setProject(androidProject());
    expect(b.variant, 'release');
    expect(b.action, GradleAction.assemble);
    expect(b.options.offline, isTrue);
    expect(b.options.extraArgs, '--info');
    expect(b.customTask, ':app:dependencies');
    expect(prefs.getKeys().every((k) => k.startsWith('gradle.')), isTrue, reason: '저장 키는 모두 gradle. 접두어');
  });

  test('저장된 변형이 더는 없으면 기본(debug)으로 돌아간다', () {
    prefs.setString('gradle.variant:${dir.path}', 'ghost');
    final c = make()..setProject(androidProject());
    expect(c.variant, 'debug');
  });

  test('JVM 프로젝트의 동작: 빌드·테스트·검사·정리·(application 이면 실행)·다른 작업', () {
    final c = make()
      ..setProject(GradleProject(
        path: dir.path,
        name: 'tool',
        hasWrapper: true,
        modules: const [GradleModule(path: ':', dir: '', kind: ModuleKind.jvmApp)],
      ));
    expect(c.isAndroid, isFalse);
    expect(c.action, GradleAction.build);
    expect(c.actions, [GradleAction.build, GradleAction.test, GradleAction.check, GradleAction.clean, GradleAction.run, GradleAction.task]);
  });

  test('기기: 칸을 처음 펼칠 때 읽고, 승인된 첫 기기를 고른다. 저장된 기기가 있으면 그것', () async {
    final c = make(devices: const [_locked, _pixel])..setProject(androidProject());
    expect((c.adb as _FakeAdb).calls, 0, reason: '펼치기 전에는 adb 를 부르지 않는다');
    await c.init();
    expect(c.devices, hasLength(2));
    expect(c.selectedId, 'R58M123');
    expect(c.plan.blocker, isNull);
    c.selectDevice(_locked);
    expect(c.plan.blocker, GradleBlocker.deviceUnauthorized);
    expect(prefs.getString('gradle.project_device:${dir.path}'), 'LOCKED');
  });

  test('기기가 없으면 설치 계획이 막힌다', () async {
    final c = make(devices: const [])..setProject(androidProject());
    await c.init();
    expect(c.plan.blocker, GradleBlocker.noDevice);
    c.selectAction(GradleAction.assemble);
    expect(c.plan.runnable, isTrue, reason: 'APK 만들기는 기기가 필요 없다');
  });

  test('실행: 가짜 gradlew 가 성공하면 모든 단계가 done 이고 명령이 기록에 남는다', () async {
    await exe('gradlew', 'echo "args: \$@"');
    final c = make()..setProject(androidProject());
    await c.init();
    c.selectAction(GradleAction.assemble);
    await c.start();
    expect(c.running, isFalse);
    expect(c.statuses, [StepStatus.done]);
    expect(c.hint, isNull);
    final entry = runner.log.last!;
    expect(entry.commandLine, './gradlew --console=plain :app:assembleDebug');
    expect(entry.output, contains('args: --console=plain :app:assembleDebug'));
  }, skip: skip);

  test('설치+실행은 두 단계: 가짜 adb 로 앱 열기까지', () async {
    await exe('gradlew', 'echo installed');
    await exe('adb', 'echo "adb \$@"');
    runner.toolPaths = {'adb': '${dir.path}/adb'};
    final c = make()..setProject(androidProject());
    await c.init();
    await c.start();
    expect(c.statuses, [StepStatus.done, StepStatus.done]);
    expect(runner.log.entries.map((e) => e.args.first), ['./gradlew', 'adb']);
    expect(runner.log.last!.output, contains('adb -s R58M123 shell monkey -p com.example.notes.debug'));
  }, skip: skip);

  test('실패하면 거기서 멈추고 원문에서 원인을 찾는다', () async {
    await exe('gradlew', 'echo "SDK location not found. Define a valid SDK location" >&2; exit 1');
    final c = make()..setProject(androidProject());
    await c.init();
    await c.start();
    expect(c.statuses, [StepStatus.failed, StepStatus.pending]);
    expect(c.hint, GradleFailure.sdkLocation);
    expect(c.missingCommand, isNull);
  }, skip: skip);

  test('설치 거부: 오류 코드를 처방에 붙인다', () async {
    await exe('gradlew', 'echo "adb: failed to install: INSTALL_FAILED_UPDATE_INCOMPATIBLE" >&2; exit 1');
    final c = make()..setProject(androidProject());
    await c.init();
    await c.start();
    expect(c.hint, GradleFailure.installFailed);
    expect(c.hintDetail, 'INSTALL_FAILED_UPDATE_INCOMPATIBLE');
  }, skip: skip);

  test('실행 파일이 없으면(127) 이름을 알려 준다', () async {
    final c = make()..setProject(androidProject(wrapper: false));
    await c.init();
    c.selectAction(GradleAction.assemble);
    await c.start();
    expect(c.missingCommand, 'gradle');
  }, skip: skip);

  test('중지하면 취소로 끝난다', () async {
    await exe('gradlew', 'sleep 30');
    final c = make()..setProject(androidProject());
    await c.init();
    c.selectAction(GradleAction.assemble);
    final future = c.start();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(c.running, isTrue);
    expect(c.busy, isTrue);
    c.cancel();
    await future;
    expect(c.statuses, [StepStatus.cancelled]);
    expect(c.running, isFalse);
  }, skip: skip);

  test('계획을 세울 수 없으면 시작하지 않는다', () async {
    final c = make(devices: const [])..setProject(androidProject());
    await c.init();
    await c.start();
    expect(c.statuses, isEmpty);
    expect(runner.log.entries, isEmpty);
  });

  test('정확한 변형 목록: Gradle 에게 물어 채우고, 브랜치가 바뀌면 버린다', () async {
    await exe('gradlew', 'echo "installFreeDebug - Installs the DebugFree build."; echo "installPaidRelease - Installs the Release build."');
    final c = make()..setProject(androidProject());
    await c.init();
    await c.loadVariants();
    expect(c.exactVariants, ['freeDebug', 'paidRelease']);
    expect(c.variants, ['freeDebug', 'paidRelease']);
    expect(c.variant, 'freeDebug', reason: '기존 변형이 목록에 없으면 첫 것으로');
    expect(runner.log.last!.commandLine, './gradlew --console=plain :app:tasks --group=install -q');
    c.invalidateCaches();
    expect(c.exactVariants, isNull);
    expect(c.variants, ['debug', 'release']);
  }, skip: skip);

  test('일반 Gradle 작업 목록 읽기', () async {
    await exe('gradlew', 'echo "build - Assembles and tests this project."; echo "test - Runs the test suite."');
    final c = make()
      ..setProject(GradleProject(path: dir.path, name: 'tool', hasWrapper: true, modules: const [GradleModule(path: ':', dir: '', kind: ModuleKind.jvmApp)]));
    await c.loadTasks();
    expect(c.tasks!.map((t) => t.name), ['build', 'test']);
    expect(runner.log.last!.commandLine, './gradlew --console=plain tasks --all -q');
  }, skip: skip);

  test('탭은 이름으로 저장한다', () {
    final c = make()..setProject(androidProject());
    c.selectTab(2);
    expect(prefs.getString('gradle.last_tab_id'), 'log');
  });
}

/// 테스트 안에서 const 로 쓰는 Android 모듈 정보.
abstract final class AndroidInfoForTest {
  static const info = AndroidBuildInfo(
    applicationId: 'com.example.notes',
    buildTypes: ['debug', 'release'],
    typeSuffix: {'debug': '.debug'},
  );
}
