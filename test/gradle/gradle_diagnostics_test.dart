// Gradle 환경 점검 (docs/GRADLE_RUNNER.md §4.4): JDK·SDK 찾기 순서, 라이선스·플랫폼, adb, 래퍼, 서명, 실행 환경 주입.
// 가짜 java·adb 셸 스크립트를 쓰므로 POSIX 가 필요하다 — Windows 에서는 건너뛴다.

import 'dart:io';

import 'package:daylight_taskbench/core/check_status.dart';
import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_parse.dart';
import 'package:daylight_taskbench/docks/gradle/detect/gradle_project.dart';
import 'package:daylight_taskbench/docks/gradle/doctor/gradle_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

void main() {
  final skip = Platform.isWindows ? 'POSIX 셸 필요' : null;

  group('읽기 도우미', () {
    test('java -version 출력', () {
      expect(parseJavaVersion('openjdk version "17.0.9" 2023-10-17\nOpenJDK Runtime'), ('17.0.9', 17));
      expect(parseJavaVersion('java version "1.8.0_301"'), ('1.8.0_301', 8));
      expect(parseJavaVersion('openjdk version "21" 2023-09-19'), ('21', 21));
      expect(parseJavaVersion('The operation couldn\'t be completed. Unable to locate a Java Runtime.'), isNull);
    });

    test('AGP → 필요한 JDK (작은 표)', () {
      expect(requiredJdkForAgp('8.2.0'), 17);
      expect(requiredJdkForAgp('7.4.2'), 11);
      expect(requiredJdkForAgp('4.2.2'), 8);
      expect(requiredJdkForAgp(null), isNull);
    });

    test('AGP 버전 찾기: classpath · plugins · 버전 카탈로그', () {
      expect(findAgpVersion(["classpath 'com.android.tools.build:gradle:7.4.2'"]), '7.4.2');
      expect(findAgpVersion(['plugins { id("com.android.application") version "8.2.0" apply false }']), '8.2.0');
      expect(findAgpVersion(['[versions]\nagp = "8.5.1"\nkotlin = "1.9.0"']), '8.5.1');
      expect(findAgpVersion(['nothing']), isNull);
    });

    test('properties 한 줄', () {
      expect(readProperty('# c\nsdk.dir=/Users/me/Library/Android/sdk\n', 'sdk.dir'), '/Users/me/Library/Android/sdk');
      expect(readProperty(r'sdk.dir=C\:\\Users\\me\\Android\\Sdk', 'sdk.dir'), r'C:\Users\me\Android\Sdk');
      expect(readProperty('org.gradle.jvmargs=-Xmx2g', 'sdk.dir'), isNull);
    });
  });

  group('수집', () {
    late Directory tmp;
    late Directory project;
    late Directory home;

    setUp(() async {
      tmp = await tempDir('gradlediag');
      project = Directory('${tmp.path}/proj')..createSync();
      home = Directory('${tmp.path}/home')..createSync();
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    Future<String> fakeJdk(String name, String version) async {
      final dir = Directory('${tmp.path}/$name/bin')..createSync(recursive: true);
      final f = File('${dir.path}/java')..writeAsStringSync('#!/bin/sh\necho \'openjdk version "$version" 2023-10-17\' >&2\n');
      await Process.run('chmod', ['+x', f.path]);
      return '${tmp.path}/$name';
    }

    CommandRunner runner({String? path}) => CommandRunner(log: CommandLog(), path: path ?? '/usr/bin:/bin');

    ProcessGradleDiagnostics service({Map<String, String> env = const {}, CommandRunner? r}) =>
        ProcessGradleDiagnostics(r ?? runner(), env: env, home: home.path, isMac: false, isWindows: false);

    GradleProject androidProject({int? compileSdk = 34}) => GradleProject(
          path: project.path,
          name: 'p',
          hasWrapper: true,
          modules: [
            GradleModule(
              path: ':app',
              dir: 'app',
              kind: ModuleKind.androidApp,
              android: AndroidBuildInfo(applicationId: 'x', compileSdk: compileSdk, buildTypes: const ['debug', 'release']),
            ),
          ],
        );

    test('JDK: gradle.properties 가 JAVA_HOME 보다 앞선다', () async {
      final a = await fakeJdk('jdkA', '11.0.2');
      final b = await fakeJdk('jdkB', '17.0.9');
      File('${project.path}/gradle.properties').writeAsStringSync('org.gradle.java.home=$a\n');
      final d = await service(env: {'JAVA_HOME': b}).collect(androidProject(), null);
      expect(d.jdk.home, a);
      expect(d.jdk.major, 11);
      expect(d.jdk.source, 'gradle.properties');
    }, skip: skip);

    test('JDK: JAVA_HOME, 그다음 PATH 의 java', () async {
      final b = await fakeJdk('jdkB', '17.0.9');
      final viaEnv = await service(env: {'JAVA_HOME': b}).collect(androidProject(), null);
      expect((viaEnv.jdk.home, viaEnv.jdk.source, viaEnv.jdk.major), (b, 'JAVA_HOME', 17));
      final viaPath = await service(r: runner(path: '$b/bin:/usr/bin:/bin')).collect(androidProject(), null);
      expect(viaPath.jdk.source, 'PATH');
      expect(viaPath.jdk.home, isNull);
      expect(viaPath.jdk.major, 17);
    }, skip: skip);

    test('JDK: 사용자가 지정한 java 경로가 가장 앞선다', () async {
      final a = await fakeJdk('jdkA', '11.0.2');
      final b = await fakeJdk('jdkB', '17.0.9');
      final r = runner()..toolPaths = {'java': '$a/bin/java'};
      final d = await service(env: {'JAVA_HOME': b}, r: r).collect(androidProject(), null);
      expect((d.jdk.home, d.jdk.source), (a, 'tool path'));
    }, skip: skip);

    test('JDK: 어디에도 없으면 못 찾은 것', () async {
      final d = await service(r: runner(path: tmp.path)).collect(androidProject(), null);
      expect(d.jdk.found, isFalse);
    }, skip: skip);

    test('SDK: local.properties > ANDROID_HOME > 기본 위치, 없는 폴더는 건너뛴다', () async {
      final a = Directory('${tmp.path}/sdkA')..createSync();
      final b = Directory('${tmp.path}/sdkB')..createSync();
      File('${project.path}/local.properties').writeAsStringSync('sdk.dir=${a.path}\n');
      var d = await service(env: {'ANDROID_HOME': b.path}).collect(androidProject(), null);
      expect((d.sdk!.dir, d.sdk!.source), (a.path, 'local.properties'));
      File('${project.path}/local.properties').writeAsStringSync('sdk.dir=${tmp.path}/ghost\n');
      d = await service(env: {'ANDROID_HOME': b.path}).collect(androidProject(), null);
      expect((d.sdk!.dir, d.sdk!.source), (b.path, 'ANDROID_HOME'));
      Directory('${home.path}/Android/Sdk').createSync(recursive: true);
      d = await service().collect(androidProject(), null);
      expect(d.sdk!.source, 'default location');
      Directory('${home.path}/Android').deleteSync(recursive: true);
      expect((await service().collect(androidProject(), null)).sdk, isNull);
    }, skip: skip);

    test('SDK 안: 플랫폼·빌드 도구·라이선스', () async {
      final sdk = Directory('${tmp.path}/sdk')..createSync();
      final env = {'ANDROID_HOME': sdk.path};
      var d = await service(env: env).collect(androidProject(), androidProject().modules.first);
      expect((d.platformPresent, d.buildToolsPresent, d.licensesAccepted), (false, false, false));
      Directory('${sdk.path}/platforms/android-34').createSync(recursive: true);
      Directory('${sdk.path}/build-tools/34.0.0').createSync(recursive: true);
      Directory('${sdk.path}/licenses').createSync();
      File('${sdk.path}/licenses/android-sdk-license').writeAsStringSync('abc');
      d = await service(env: env).collect(androidProject(), androidProject().modules.first);
      expect((d.platformPresent, d.buildToolsPresent, d.licensesAccepted), (true, true, true));
    }, skip: skip);

    test('adb: PATH 에서 실행되면 버전, 아니면 SDK 의 platform-tools', () async {
      final bin = Directory('${tmp.path}/bin')..createSync();
      final adb = File('${bin.path}/adb')..writeAsStringSync('#!/bin/sh\necho "Android Debug Bridge version 1.0.41"\n');
      await Process.run('chmod', ['+x', adb.path]);
      var d = await service(r: runner(path: '${bin.path}:/usr/bin:/bin')).collect(androidProject(), null);
      expect(d.adbVersion, '1.0.41');
      final sdk = Directory('${tmp.path}/sdk/platform-tools')..createSync(recursive: true);
      File('${sdk.path}/adb').writeAsStringSync('x');
      d = await service(env: {'ANDROID_HOME': '${tmp.path}/sdk'}, r: runner(path: '/usr/bin:/bin')).collect(androidProject(), null);
      expect(d.adbVersion, isNull);
      expect(d.adbPath, '${sdk.path}/adb');
    }, skip: skip);

    test('릴리스 변형: 서명 설정과 키스토어 파일', () async {
      Directory('${project.path}/app').createSync();
      final p = androidProject();
      var d = await service().collect(p, p.modules.first, variant: 'release');
      expect(d.releaseSigning!.configured, isFalse);
      File('${project.path}/app/build.gradle.kts').writeAsStringSync('signingConfigs { create("release") { storeFile = file("../my.jks") } }\nbuildTypes { release { signingConfig = signingConfigs.getByName("release") } }');
      d = await service().collect(p, p.modules.first, variant: 'release');
      expect((d.releaseSigning!.configured, d.releaseSigning!.keystoreFound), (true, false));
      File('${project.path}/my.jks').writeAsStringSync('k');
      d = await service().collect(p, p.modules.first, variant: 'release');
      expect(d.releaseSigning!.keystoreFound, isTrue);
      d = await service().collect(p, p.modules.first, variant: 'debug');
      expect(d.releaseSigning, isNull, reason: '디버그 변형에는 해당 없음');
    }, skip: skip);

    test('AGP 가 요구하는 JDK 보다 낮으면 주의로 표시한다', () async {
      final a = await fakeJdk('jdk11', '11.0.2');
      File('${project.path}/build.gradle').writeAsStringSync("classpath 'com.android.tools.build:gradle:8.2.0'");
      File('${project.path}/gradle.properties').writeAsStringSync('org.gradle.java.home=$a\n');
      final p = androidProject();
      final d = await service().collect(p, p.modules.first);
      expect(d.requiredJdk, 17);
      final jdk = buildGradleChecks(diagnostics: d, project: p, module: p.modules.first).firstWhere((c) => c.id == GradleCheckId.jdk);
      expect(jdk.status, CheckStatus.warn);
      expect(jdk.params['required'], '17');
    }, skip: skip);
  });

  group('실행 환경 주입', () {
    final d = GradleDiagnostics(
      collectedAt: DateTime(2026),
      jdk: const JdkInfo(home: '/jdk', version: '17', major: 17, source: 'java_home'),
      sdk: const SdkInfo(dir: '/sdk', source: 'default location'),
    );

    test('환경에 없는 것만 채운다', () {
      expect(d.runEnvironment({}), {'JAVA_HOME': '/jdk', 'ANDROID_HOME': '/sdk'});
      expect(d.runEnvironment({'JAVA_HOME': '/mine'}), {'ANDROID_HOME': '/sdk'});
      expect(d.runEnvironment({'ANDROID_SDK_ROOT': '/mine'}), {'JAVA_HOME': '/jdk'});
      expect(d.runEnvironment({'JAVA_HOME': '/a', 'ANDROID_HOME': '/b'}), isEmpty);
    });

    test('local.properties 의 SDK 는 Gradle 이 직접 읽으므로 넣지 않는다', () {
      final x = GradleDiagnostics(collectedAt: DateTime(2026), jdk: const JdkInfo(), sdk: const SdkInfo(dir: '/sdk', source: 'local.properties'));
      expect(x.runEnvironment({}), isEmpty);
    });

    test('PATH 로만 확인한 JDK(위치 모름)는 JAVA_HOME 을 만들지 않는다', () {
      final x = GradleDiagnostics(collectedAt: DateTime(2026), jdk: const JdkInfo(version: '17', major: 17, source: 'PATH'));
      expect(x.runEnvironment({}), isEmpty);
    });
  });

  group('점검 목록', () {
    GradleProject project({bool wrapper = true, String? error, bool android = true}) => GradleProject(
          path: '/p',
          name: 'p',
          hasWrapper: wrapper,
          readError: error,
          modules: [GradleModule(path: ':app', dir: 'app', kind: android ? ModuleKind.androidApp : ModuleKind.jvmApp, android: const AndroidBuildInfo(compileSdk: 34))],
        );
    GradleDiagnostics diag({JdkInfo jdk = const JdkInfo(version: '17', major: 17, home: '/j', source: 'JAVA_HOME'), SdkInfo? sdk, bool? platform, bool? tools, bool? lic, String? adb, String? adbPath, bool wrapper = true}) =>
        GradleDiagnostics(collectedAt: DateTime(2026), jdk: jdk, sdk: sdk, platformPresent: platform, buildToolsPresent: tools, licensesAccepted: lic, adbVersion: adb, adbPath: adbPath, wrapperPresent: wrapper);
    CheckStatus status(List<GradleCheck> l, GradleCheckId id) => l.firstWhere((c) => c.id == id).status;

    test('모두 정상이면 firstProblem 이 null', () {
      final l = buildGradleChecks(diagnostics: diag(sdk: const SdkInfo(dir: '/s', source: 'ANDROID_HOME'), platform: true, tools: true, lic: true, adb: '1.0.41'), project: project(), module: project().modules.first);
      expect(firstGradleProblem(l), isNull);
      expect(l.map((c) => c.id), [GradleCheckId.project, GradleCheckId.wrapper, GradleCheckId.jdk, GradleCheckId.sdk, GradleCheckId.platform, GradleCheckId.licenses, GradleCheckId.adb]);
    });

    test('문제는 실패 → 주의 순으로 먼저 고칠 것을 알린다', () {
      final l = buildGradleChecks(diagnostics: diag(jdk: const JdkInfo(), lic: false), project: project(), module: project().modules.first);
      expect(status(l, GradleCheckId.jdk), CheckStatus.fail);
      expect(status(l, GradleCheckId.sdk), CheckStatus.fail);
      expect(status(l, GradleCheckId.adb), CheckStatus.fail);
      expect(firstGradleProblem(l)!.status, CheckStatus.fail);
    });

    test('플랫폼 폴더가 없으면 실패, 라이선스 미동의는 주의, adb 가 PATH 에 없으면 주의', () {
      final l = buildGradleChecks(diagnostics: diag(sdk: const SdkInfo(dir: '/s', source: 'x'), platform: false, tools: true, lic: false, adbPath: '/s/platform-tools/adb'), project: project(), module: project().modules.first);
      expect(status(l, GradleCheckId.platform), CheckStatus.fail);
      expect(l.firstWhere((c) => c.id == GradleCheckId.platform).params['api'], '34');
      expect(status(l, GradleCheckId.licenses), CheckStatus.warn);
      expect(status(l, GradleCheckId.adb), CheckStatus.warn);
    });

    test('JVM 프로젝트에는 Android 항목이 없다', () {
      final l = buildGradleChecks(diagnostics: diag(), project: project(android: false));
      expect(l.map((c) => c.id), [GradleCheckId.project, GradleCheckId.wrapper, GradleCheckId.jdk]);
    });

    test('래퍼 없음: 시스템 gradle 이 있으면 주의, 없으면 실패. 읽기 오류는 실패', () {
      expect(status(buildGradleChecks(diagnostics: diag(wrapper: false), project: project(wrapper: false)), GradleCheckId.wrapper), CheckStatus.fail);
      expect(status(buildGradleChecks(diagnostics: diag(), project: project(error: 'denied')), GradleCheckId.project), CheckStatus.fail);
    });
  });
}
