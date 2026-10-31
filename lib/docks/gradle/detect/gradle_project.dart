// 감지된 Gradle 프로젝트의 상세: 모듈과 각 모듈의 종류 (docs/GRADLE_RUNNER.md §3 "모양 판정").

import 'dart:io';

import 'gradle_parse.dart';

enum GradleShape { androidApp, jvm }

enum ModuleKind { androidApp, androidLibrary, jvmApp, springBoot, other }

class GradleModule {
  const GradleModule({required this.path, required this.dir, required this.kind, this.android});

  /// Gradle 경로: `:app`, `:feature:login`. 루트 프로젝트는 `:`.
  final String path;

  /// 프로젝트 루트 기준 폴더 (루트면 빈 문자열).
  final String dir;
  final ModuleKind kind;

  /// Android 모듈(앱·라이브러리)에서만. 못 읽은 값은 null.
  final AndroidBuildInfo? android;

  bool get isRunnable => kind == ModuleKind.androidApp || kind == ModuleKind.jvmApp || kind == ModuleKind.springBoot;
}

class GradleProject {
  const GradleProject({
    required this.path,
    required this.name,
    required this.modules,
    required this.hasWrapper,
    this.version,
    this.readError,
  });

  final String path;
  final String name;
  final String? version;
  final List<GradleModule> modules;
  final bool hasWrapper;

  /// 빌드 파일을 읽다가 난 오류 (있으면 칸 안에 이유를 보인다).
  final String? readError;

  List<GradleModule> get androidApps => [for (final m in modules) if (m.kind == ModuleKind.androidApp) m];

  GradleShape get shape => androidApps.isNotEmpty ? GradleShape.androidApp : GradleShape.jvm;

  /// 폴더를 읽어 프로젝트 상세를 만든다. 읽기 오류는 [readError] 로 담고 던지지 않는다.
  static Future<GradleProject> read(String root, {String? name, String? version}) async {
    final sep = Platform.pathSeparator;
    Future<String?> readFirst(String dir, List<String> names) async {
      for (final n in names) {
        final f = File('$dir$sep$n');
        if (await f.exists()) return f.readAsString();
      }
      return null;
    }

    String? error;
    final modules = <GradleModule>[];
    try {
      final settings = await readFirst(root, const ['settings.gradle.kts', 'settings.gradle']);
      final rootBuild = await readFirst(root, const ['build.gradle.kts', 'build.gradle']);
      var paths = settings == null ? <String>[] : parseIncludedModules(settings);
      // include 줄을 못 읽었으면 Android Studio 기본 구조(`app/`)를 시험한다.
      if (paths.isEmpty && Directory('$root${sep}app').existsSync()) paths = [':app'];

      Future<GradleModule?> moduleAt(String gradlePath, String dir, String? build) async {
        if (build == null) return null;
        final plugins = parsePlugins(build);
        final kind = isAndroidApplication(plugins)
            ? ModuleKind.androidApp
            : isAndroidLibrary(plugins)
                ? ModuleKind.androidLibrary
                : isSpringBoot(plugins)
                    ? ModuleKind.springBoot
                    : isJvmApplication(plugins)
                        ? ModuleKind.jvmApp
                        : ModuleKind.other;
        final android = kind == ModuleKind.androidApp || kind == ModuleKind.androidLibrary ? parseAndroidBuild(build) : null;
        return GradleModule(path: gradlePath, dir: dir, kind: kind, android: android);
      }

      // 루트 프로젝트 자신이 플러그인을 적용했으면(단일 프로젝트) 모듈 하나로 본다.
      final rootModule = await moduleAt(':', '', rootBuild);
      if (rootModule != null && rootModule.kind != ModuleKind.other) modules.add(rootModule);
      for (final p in paths) {
        final dir = moduleDir(p);
        final build = await readFirst('$root$sep${dir.replaceAll('/', sep)}', const ['build.gradle.kts', 'build.gradle']);
        final m = await moduleAt(p.startsWith(':') ? p : ':$p', dir, build);
        if (m != null) modules.add(m);
      }
    } on FileSystemException catch (e) {
      error = e.message;
    }

    return GradleProject(
      path: root,
      name: name ?? root.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).lastOrNull ?? root,
      version: version,
      modules: modules,
      hasWrapper: File('$root${sep}gradlew').existsSync() || File('$root${sep}gradlew.bat').existsSync(),
      readError: error,
    );
  }
}
