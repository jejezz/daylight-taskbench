// 버튼이 만드는 명령 (docs/GRADLE_RUNNER.md §4.1): 변형 이름, 작업 이름, 기기 지정, 실행 단계, 실패 원인.

import 'package:daylight_taskbench/core/devices/mobile_device.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_parse.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_project.dart';
import 'package:daylight_taskbench/docks/gradle/run/gradle_plan.dart';
import 'package:flutter_test/flutter_test.dart';

const _info = AndroidBuildInfo(
  applicationId: 'com.example.notes',
  buildTypes: ['debug', 'release', 'staging'],
  flavors: ['free', 'paid'],
  typeSuffix: {'debug': '.debug'},
  flavorSuffix: {'free': '.free'},
);

const _app = GradleModule(path: ':app', dir: 'app', kind: ModuleKind.androidApp, android: _info);
const _plain = GradleModule(
  path: ':app',
  dir: 'app',
  kind: ModuleKind.androidApp,
  android: AndroidBuildInfo(applicationId: 'com.example.plain', buildTypes: ['debug', 'release']),
);
const _jvm = GradleModule(path: ':', dir: '', kind: ModuleKind.jvmApp);
const _device = MobileDevice(id: 'R58M123', name: 'Pixel 7', platform: DevicePlatform.android, link: DeviceLink.usb);

GradleProject _project(List<GradleModule> modules, {bool wrapper = true}) =>
    GradleProject(path: '/work/notes', name: 'notes', modules: modules, hasWrapper: wrapper);

GradlePlan _plan(GradleAction a, {GradleModule? module = _app, String? variant = 'freeDebug', MobileDevice? device = _device, GradleOptions options = const GradleOptions(), String? custom, bool wrapper = true, bool windows = false}) =>
    buildGradlePlan(project: _project([?module], wrapper: wrapper), module: module, variant: variant, action: a, options: options, device: device, customTask: custom, isWindows: windows);

void main() {
  group('변형 이름', () {
    test('flavor 가 없으면 빌드 타입, 있으면 flavor + 빌드 타입', () {
      expect(androidVariants(_plain.android), ['debug', 'release']);
      expect(androidVariants(_info), ['freeDebug', 'freeRelease', 'freeStaging', 'paidDebug', 'paidRelease', 'paidStaging']);
      expect(androidVariants(null), ['debug', 'release']);
    });

    test('Gradle 의 install 작업 목록에서 정확한 변형을 읽는다', () {
      const out = 'Install tasks\n-------------\ninstallFreeDebug - Installs the DebugFree build.\ninstallFreeDebugAndroidTest - Installs the android (on-device) tests for the FreeDebug build.\ninstallPaidRelease - Installs the Release build.\n';
      expect(parseInstallVariants(out), ['freeDebug', 'paidRelease']);
    });

    test('일반 Gradle 작업 목록', () {
      const out = 'Build tasks\n-----------\nassemble - Assembles the outputs of this project.\nbuild - Assembles and tests this project.\n\nOther tasks\n-----------\n:app:dependencies - Displays all dependencies.\n';
      expect(parseTasks(out).map((t) => t.name), ['assemble', 'build', ':app:dependencies']);
      expect(parseTasks(out).first.description, 'Assembles the outputs of this project.');
    });

    test('변형을 (flavor, 빌드 타입)으로 나눈다 — 긴 빌드 타입부터', () {
      expect(splitVariant('freeDebug', ['debug', 'release']), ('free', 'debug'));
      expect(splitVariant('debug', ['debug', 'release']), ('', 'debug'));
      expect(splitVariant('paidDebugStaging', ['debug', 'staging']), ('paidDebug', 'staging'));
    });

    test('설치된 패키지 이름 = applicationId + flavor 접미어 + 빌드 타입 접미어', () {
      expect(installedPackage(_app, 'freeDebug'), 'com.example.notes.free.debug');
      expect(installedPackage(_app, 'paidRelease'), 'com.example.notes');
      expect(installedPackage(const GradleModule(path: ':app', dir: 'app', kind: ModuleKind.androidApp), 'debug'), isNull);
    });
  });

  group('명령', () {
    test('설치+실행은 두 단계: Gradle 설치 → adb 로 앱 열기', () {
      final plan = _plan(GradleAction.installRun);
      expect(plan.runnable, isTrue);
      expect(plan.steps.map((s) => s.kind), [GradleStepKind.gradle, GradleStepKind.launch]);
      expect(plan.steps[0].commandLine, 'ANDROID_SERIAL=R58M123 ./gradlew --console=plain :app:installFreeDebug');
      expect(plan.steps[1].commandLine, 'adb -s R58M123 shell monkey -p com.example.notes.free.debug -c android.intent.category.LAUNCHER 1');
      expect(plan.steps[0].workingDirectory, '/work/notes');
    });

    test('패키지 이름을 모르면 설치만 하고 알린다', () {
      final plan = _plan(GradleAction.installRun, module: const GradleModule(path: ':app', dir: 'app', kind: ModuleKind.androidApp), variant: 'debug');
      expect(plan.steps, hasLength(1));
      expect(plan.launchSkipped, isTrue);
    });

    test('작업 이름: 어셈블·번들·테스트·린트·정리', () {
      String task(GradleAction a) => _plan(a, variant: 'paidRelease').steps.single.args.last;
      expect(task(GradleAction.assemble), ':app:assemblePaidRelease');
      expect(task(GradleAction.bundle), ':app:bundlePaidRelease');
      expect(task(GradleAction.test), ':app:testPaidReleaseUnitTest');
      expect(task(GradleAction.lint), ':app:lintPaidRelease');
      expect(task(GradleAction.clean), ':app:clean');
    });

    test('기기가 필요 없는 작업에는 ANDROID_SERIAL 을 붙이지 않는다', () {
      expect(_plan(GradleAction.assemble, device: null).steps.single.environment, isEmpty);
    });

    test('앱이 찾은 JAVA_HOME·ANDROID_HOME 은 명령 앞에 그대로 보이고, 기기 지정과 함께 간다', () {
      final plan = buildGradlePlan(
        project: _project([_app]),
        module: _app,
        variant: 'freeDebug',
        action: GradleAction.install,
        options: const GradleOptions(),
        device: _device,
        extraEnvironment: const {'JAVA_HOME': '/jdk', 'ANDROID_HOME': '/sdk'},
      );
      expect(plan.steps.single.commandLine, 'JAVA_HOME=/jdk ANDROID_HOME=/sdk ANDROID_SERIAL=R58M123 ./gradlew --console=plain :app:installFreeDebug');
      expect(plan.steps.single.environment, {'JAVA_HOME': '/jdk', 'ANDROID_HOME': '/sdk', 'ANDROID_SERIAL': 'R58M123'});
    });

    test('래퍼가 없으면 시스템 gradle, Windows 는 gradlew.bat', () {
      expect(_plan(GradleAction.assemble, wrapper: false).steps.single.args.first, 'gradle');
      expect(_plan(GradleAction.assemble, windows: true).steps.single.args.first, 'gradlew.bat');
    });

    test('옵션과 추가 인자는 작업 앞뒤에 붙는다', () {
      final args = _plan(GradleAction.assemble, options: const GradleOptions(offline: true, stacktrace: true, noDaemon: true, keepGoing: true, extraArgs: '-Pfoo="a b" --info')).steps.single.args;
      expect(args, ['./gradlew', '--console=plain', '--offline', '--stacktrace', '--no-daemon', '--continue', ':app:assembleFreeDebug', '-Pfoo=a b', '--info']);
    });

    test('루트 프로젝트 모듈(`:`)은 작업 이름에 접두어가 없다', () {
      final plan = buildGradlePlan(project: _project([_jvm]), module: _jvm, variant: null, action: GradleAction.build, options: const GradleOptions());
      expect(plan.steps.single.args.last, 'build');
    });

    test('run·bootRun 은 끝나지 않는 단계다', () {
      final plan = buildGradlePlan(project: _project([_jvm]), module: _jvm, variant: null, action: GradleAction.run, options: const GradleOptions());
      expect(plan.steps.single.interactive, isTrue);
      expect(plan.steps.single.args.last, 'run');
      expect(buildGradlePlan(project: _project([_jvm]), module: _jvm, variant: null, action: GradleAction.test, options: const GradleOptions()).steps.single.interactive, isFalse);
    });

    test('직접 고른 작업: 공백으로 여러 개', () {
      final plan = buildGradlePlan(project: _project([_jvm]), module: null, variant: null, action: GradleAction.task, options: const GradleOptions(), customTask: ':core:test  :core:jar');
      expect(plan.steps.single.args.sublist(2), [':core:test', ':core:jar']);
    });
  });

  group('막힘', () {
    test('프로젝트·모듈·변형·작업·기기', () {
      expect(buildGradlePlan(project: null, module: null, variant: null, action: GradleAction.clean, options: const GradleOptions()).blocker, GradleBlocker.noProject);
      expect(_plan(GradleAction.assemble, module: null).blocker, GradleBlocker.noModule);
      expect(_plan(GradleAction.clean, module: null).runnable, isTrue, reason: 'clean 은 모듈 없이도 된다');
      expect(_plan(GradleAction.assemble, variant: null).blocker, GradleBlocker.noVariant);
      expect(_plan(GradleAction.task, custom: ' ').blocker, GradleBlocker.noTask);
      expect(_plan(GradleAction.install, device: null).blocker, GradleBlocker.noDevice);
      expect(_plan(GradleAction.install, device: const MobileDevice(id: 'x', name: 'x', platform: DevicePlatform.android, link: DeviceLink.usb, authorized: false)).blocker, GradleBlocker.deviceUnauthorized);
      expect(_plan(GradleAction.install, device: const MobileDevice(id: 'macos', name: 'macOS', platform: DevicePlatform.macos, link: DeviceLink.local)).blocker, GradleBlocker.noDevice);
    });
  });

  group('옵션 저장', () {
    test('JSON 으로 저장하고 읽고, 모르는 필드와 깨진 값은 기본으로', () {
      const o = GradleOptions(offline: true, extraArgs: '--info');
      expect(GradleOptions.fromJson(o.toJson()).offline, isTrue);
      expect(GradleOptions.fromJson(o.toJson()).extraArgs, '--info');
      expect(GradleOptions.fromJson('{"offline": true, "future": 1}').offline, isTrue);
      expect(GradleOptions.fromJson('not json').isDefault, isTrue);
      expect(GradleOptions.fromJson(null).isDefault, isTrue);
    });
  });

  group('인자 나누기', () {
    test('따옴표와 빈 인자', () {
      expect(splitArgs('a  b'), ['a', 'b']);
      expect(splitArgs('-Pa="x y" \'z w\''), ['-Pa=x y', 'z w']);
      expect(splitArgs('  '), isEmpty);
      expect(splitArgs('""'), ['']);
    });
  });

  group('실패 원인', () {
    test('Gradle 오류 문구 → 원인', () {
      expect(explainGradleFailure('SDK location not found. Define a valid SDK location'), GradleFailure.sdkLocation);
      expect(explainGradleFailure('Failed to install the following Android SDK packages as some licences have not been accepted.'), GradleFailure.licenses);
      expect(explainGradleFailure('Unsupported class file major version 65'), GradleFailure.jdk);
      expect(explainGradleFailure('Android Gradle plugin requires Java 17 to run'), GradleFailure.jdk);
      expect(explainGradleFailure('adb: failed to install: INSTALL_FAILED_UPDATE_INCOMPATIBLE'), GradleFailure.installFailed);
      expect(installFailedCode('x INSTALL_FAILED_UPDATE_INCOMPATIBLE y'), 'INSTALL_FAILED_UPDATE_INCOMPATIBLE');
      expect(explainGradleFailure('Keystore file \'/x/my.jks\' not found for signing config'), GradleFailure.keystore);
      expect(explainGradleFailure('Could not resolve com.foo:bar:1.0'), GradleFailure.resolve);
      expect(explainGradleFailure('No connected devices!'), GradleFailure.noDevice);
      expect(explainGradleFailure('everything is fine'), isNull);
    });
  });
}
