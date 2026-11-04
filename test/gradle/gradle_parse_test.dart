// Gradle 빌드 파일 가벼운 읽기 (docs/GRADLE_RUNNER.md §3, §11): Groovy·Kotlin DSL·버전 카탈로그 별칭.

import 'package:daylight_taskbench/docks/gradle/detect/gradle_parse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suffixTests();
  group('settings', () {
    test('rootProject.name (Kotlin·Groovy)', () {
      expect(parseRootProjectName('rootProject.name = "my-app"\n'), 'my-app');
      expect(parseRootProjectName("rootProject.name = 'my_app'"), 'my_app');
      expect(parseRootProjectName('include(":app")'), isNull);
    });

    test('include: Kotlin 괄호형·여러 줄·Groovy 명령형', () {
      expect(parseIncludedModules('include(":app", ":feature:login")'), [':app', ':feature:login']);
      expect(parseIncludedModules('include(\n  ":app",\n  ":core",\n)\n'), [':app', ':core']);
      expect(parseIncludedModules("include ':app', ':lib'\n"), [':app', ':lib']);
      expect(parseIncludedModules("include ':app',\n        ':lib'\n"), [':app', ':lib']);
      expect(parseIncludedModules('include(":a")\ninclude(":b")\n'), [':a', ':b']);
    });

    test('주석 처리된 include 와 includeBuild 는 모듈이 아니다', () {
      expect(parseIncludedModules('// include(":old")\n/* include(":x") */\ninclude(":app")\nincludeBuild("../lib")\n'), [':app']);
    });

    test('모듈 경로 → 폴더', () {
      expect(moduleDir(':app'), 'app');
      expect(moduleDir(':feature:login'), 'feature/login');
    });
  });

  group('플러그인', () {
    test('Kotlin DSL id(...)', () {
      final p = parsePlugins('plugins {\n  id("com.android.application")\n  id("org.jetbrains.kotlin.android")\n}');
      expect(isAndroidApplication(p), isTrue);
      expect(isAndroidLibrary(p), isFalse);
    });

    test('Groovy id · apply plugin', () {
      expect(isAndroidLibrary(parsePlugins("plugins {\n  id 'com.android.library'\n}")), isTrue);
      expect(isAndroidApplication(parsePlugins("apply plugin: 'com.android.application'")), isTrue);
    });

    test('버전 카탈로그 별칭', () {
      expect(isAndroidApplication(parsePlugins('plugins { alias(libs.plugins.android.application) }')), isTrue);
      expect(isAndroidLibrary(parsePlugins('plugins { alias(libs.plugins.android.library) }')), isTrue);
      expect(isAndroidApplication(parsePlugins('plugins { alias(libs.plugins.android.library) }')), isFalse);
    });

    test('JVM: application · kotlin("jvm") · Spring Boot', () {
      expect(isJvmApplication(parsePlugins('plugins {\n  application\n  kotlin("jvm") version "1.9.0"\n}')), isTrue);
      expect(isJvmApplication(parsePlugins('plugins {\n  `application`\n}')), isTrue);
      expect(isSpringBoot(parsePlugins("plugins {\n  id 'org.springframework.boot' version '3.2.0'\n}")), isTrue);
      expect(parsePlugins('plugins {\n  kotlin("jvm")\n}'), contains('org.jetbrains.kotlin.jvm'));
    });

    test('루트의 `apply false` 선언은 적용한 플러그인이 아니다', () {
      const root = '''
plugins {
    id("com.android.application") version "8.2.0" apply false
    alias(libs.plugins.android.library) apply false
    id 'org.jetbrains.kotlin.android' version '1.9.0' apply false
}
''';
      final p = parsePlugins(root);
      expect(isAndroidApplication(p), isFalse);
      expect(isAndroidLibrary(p), isFalse);
      expect(p, isEmpty);
      expect(isAndroidApplication(parsePlugins('plugins {\n  id("com.android.application")\n}')), isTrue);
    });

    test('주석 안의 플러그인은 무시한다', () {
      expect(isAndroidApplication(parsePlugins('// id("com.android.application")\nplugins { }')), isFalse);
    });

    test('Compose 데스크톱 앱: 플러그인 + compose.desktop { application { … } } (application 플러그인은 없다)', () {
      const build = '''
plugins {
    kotlin("jvm") version "2.2.20"
    kotlin("plugin.compose") version "2.2.20"
    id("org.jetbrains.compose") version "1.9.0"
}
dependencies {
    implementation(compose.desktop.currentOs)
}
compose.desktop {
    application {
        mainClass = "art.example.MainKt"
    }
}
''';
      final p = parsePlugins(build);
      expect(isJvmApplication(p), isFalse);
      expect(isComposeDesktopApplication(p, build), isTrue);
    });

    test('Compose 데스크톱: 점으로 이은 형태와 버전 카탈로그 별칭', () {
      const dotted = 'plugins { id("org.jetbrains.compose") }\ncompose.desktop.application {\n  mainClass = "MainKt"\n}';
      expect(isComposeDesktopApplication(parsePlugins(dotted), dotted), isTrue);
      const catalog = 'plugins { alias(libs.plugins.jetbrains.compose) }\ncompose.desktop {\n    application { mainClass = "MainKt" }\n}';
      expect(isComposeDesktopApplication(parsePlugins(catalog), catalog), isTrue);
    });

    test('Compose 데스크톱 앱이 아닌 것: 의존성만, application 블록 없음, 플러그인 없음, 주석', () {
      const depOnly = 'plugins { id("org.jetbrains.compose") }\ndependencies { implementation(compose.desktop.currentOs) }';
      expect(isComposeDesktopApplication(parsePlugins(depOnly), depOnly), isFalse);
      const noBlock = 'plugins { id("org.jetbrains.compose") }\ncompose.desktop { }';
      expect(isComposeDesktopApplication(parsePlugins(noBlock), noBlock), isFalse);
      const noPlugin = 'plugins { kotlin("jvm") }\ncompose.desktop { application { } }';
      expect(isComposeDesktopApplication(parsePlugins(noPlugin), noPlugin), isFalse);
      const commented = 'plugins { id("org.jetbrains.compose") }\n// compose.desktop { application { } }\n/* compose.desktop.application { } */';
      expect(isComposeDesktopApplication(parsePlugins(commented), commented), isFalse);
    });
  });

  group('Android 빌드 정보', () {
    test('Kotlin DSL', () {
      final info = parseAndroidBuild('''
android {
    namespace = "com.example.app"
    compileSdk = 34
    defaultConfig {
        applicationId = "com.example.app"
        versionName = "1.2.3"
    }
    buildTypes {
        release { isMinifyEnabled = true }
        create("staging") { initWith(getByName("debug")) }
    }
    flavorDimensions += "tier"
    productFlavors {
        create("free") { dimension = "tier" }
        create("paid") { dimension = "tier" }
    }
}
''');
      expect(info.applicationId, 'com.example.app');
      expect(info.namespace, 'com.example.app');
      expect(info.versionName, '1.2.3');
      expect(info.compileSdk, 34);
      expect(info.buildTypes, ['debug', 'release', 'staging']);
      expect(info.flavors, ['free', 'paid']);
    });

    test('Groovy DSL', () {
      final info = parseAndroidBuild('''
android {
    compileSdkVersion 33
    defaultConfig {
        applicationId "com.example.old"
        versionName "0.9"
    }
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
        qa { }
    }
    productFlavors {
        demo { }
    }
}
''');
      expect(info.applicationId, 'com.example.old');
      expect(info.compileSdk, 33);
      expect(info.buildTypes, ['debug', 'release', 'qa']);
      expect(info.flavors, ['demo']);
    });

    test('읽을 수 없으면 비어 있고 던지지 않는다', () {
      final info = parseAndroidBuild('this is not gradle {{{');
      expect(info.applicationId, isNull);
      expect(info.compileSdk, isNull);
      expect(info.buildTypes, ['debug', 'release']);
      expect(info.flavors, isEmpty);
    });
  });

  test('루트 version', () {
    expect(parseProjectVersion("group = 'x'\nversion = '1.4.0'\n"), '1.4.0');
    expect(parseProjectVersion('// version = "9"\n'), isNull);
  });
}

void suffixTests() {
  test('applicationIdSuffix 를 빌드 타입·flavor 별로 읽는다', () {
    final info = parseAndroidBuild('''
android {
    buildTypes {
        debug { applicationIdSuffix = ".debug" }
        getByName("release") { isMinifyEnabled = true }
        create("staging") { applicationIdSuffix ".stg" }
    }
    productFlavors {
        create("free") { applicationIdSuffix = ".free" }
        create("paid") { }
    }
}
''');
    expect(info.typeSuffix, {'debug': '.debug', 'staging': '.stg'});
    expect(info.flavorSuffix, {'free': '.free'});
  });
}
