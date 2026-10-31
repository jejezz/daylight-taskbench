// 환경 점검 (docs/GRADLE_RUNNER.md §4.4): JDK, Android SDK, adb, Gradle 래퍼, 릴리스 서명.
// 찾은 JDK·SDK 위치는 실행할 때 `JAVA_HOME`·`ANDROID_HOME` 으로 넣어 준다 — GUI 로 연 앱은 셸 환경을 받지 못한다.

import 'dart:io';

import '../../../core/check_status.dart';
import '../../../core/command_runner.dart';
import '../detect/gradle_project.dart';

/// 찾은 JDK. [home] 이 없으면 PATH 의 `java` 로만 확인한 것이다.
class JdkInfo {
  const JdkInfo({this.home, this.version, this.major, this.source = ''});

  final String? home;
  final String? version;
  final int? major;

  /// 어디서 찾았는지: `gradle.properties`, `JAVA_HOME`, `java_home`, `Android Studio`, `PATH` …
  final String source;

  bool get found => version != null;
}

class SdkInfo {
  const SdkInfo({required this.dir, required this.source});

  final String dir;
  final String source;
}

class GradleDiagnostics {
  const GradleDiagnostics({
    required this.collectedAt,
    required this.jdk,
    this.sdk,
    this.requiredJdk,
    this.agpVersion,
    this.platformPresent,
    this.buildToolsPresent,
    this.licensesAccepted,
    this.adbVersion,
    this.adbPath,
    this.wrapperPresent = false,
    this.systemGradle,
    this.releaseSigning,
  });

  final DateTime collectedAt;
  final JdkInfo jdk;
  final SdkInfo? sdk;

  /// 이 프로젝트의 Android Gradle 플러그인이 요구하는 JDK 주 버전 (작은 표에서 얻은 **힌트**, 틀릴 수 있다).
  final int? requiredJdk;
  final String? agpVersion;

  /// `compileSdk` 용 플랫폼 폴더·빌드 도구·라이선스. 알 수 없으면 null.
  final bool? platformPresent;
  final bool? buildToolsPresent;
  final bool? licensesAccepted;

  /// `adb` 를 PATH 에서 실행해 얻은 버전. 없으면 null.
  final String? adbVersion;

  /// PATH 에는 없지만 SDK 의 platform-tools 에서 찾은 `adb`.
  final String? adbPath;
  final bool wrapperPresent;

  /// 래퍼가 없을 때 PATH 의 `gradle`.
  final String? systemGradle;

  /// 릴리스 변형일 때의 서명 점검: null = 해당 없음, 아니면 (서명 설정이 있는가, 키스토어 파일이 있는가?).
  final ReleaseSigning? releaseSigning;

  /// 실행할 때 **환경에 없는 것만** 채워 주는 변수. 사용자가 이미 설정한 값은 건드리지 않는다.
  Map<String, String> runEnvironment(Map<String, String> processEnv) {
    final out = <String, String>{};
    final java = jdk.home;
    if (java != null && (processEnv['JAVA_HOME'] ?? '').isEmpty) out['JAVA_HOME'] = java;
    final s = sdk;
    // local.properties 의 sdk.dir 는 Gradle 이 직접 읽으므로 넣지 않는다.
    if (s != null && s.source != 'local.properties' && (processEnv['ANDROID_HOME'] ?? '').isEmpty && (processEnv['ANDROID_SDK_ROOT'] ?? '').isEmpty) {
      out['ANDROID_HOME'] = s.dir;
    }
    return out;
  }
}

class ReleaseSigning {
  const ReleaseSigning({required this.configured, this.keystoreFound});

  final bool configured;
  final bool? keystoreFound;
}

enum GradleCheckId { project, wrapper, jdk, sdk, platform, licenses, adb, signing }

/// 점검 결과 한 줄. 문구는 화면이 [id]와 [params]로 만든다.
class GradleCheck {
  const GradleCheck(this.id, this.status, [this.params = const {}]);

  final GradleCheckId id;
  final CheckStatus status;
  final Map<String, String> params;
}

/// AGP 주 버전 → 필요한 JDK 주 버전 (작은 표, 힌트).
int? requiredJdkForAgp(String? agp) {
  if (agp == null) return null;
  final parts = agp.split('.');
  final major = int.tryParse(parts.first);
  final minor = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (major == null) return null;
  if (major >= 9) return 17;
  if (major == 8) return 17;
  if (major == 7) return (minor ?? 0) >= 0 ? 11 : 8;
  return 8;
}

/// `java -version` 출력(`openjdk version "17.0.9" …`, `java version "1.8.0_301"`)에서 (버전, 주 버전).
(String, int)? parseJavaVersion(String output) {
  final m = RegExp(r'version "([^"]+)"').firstMatch(output);
  if (m == null) return null;
  final v = m.group(1)!;
  final parts = v.split(RegExp(r'[._\-+]'));
  var major = int.tryParse(parts.first);
  if (major == 1 && parts.length > 1) major = int.tryParse(parts[1]);
  return major == null ? null : (v, major);
}

/// 빌드 파일들에서 Android Gradle 플러그인 버전(`8.2.0`)을 찾는다. 못 찾으면 null.
String? findAgpVersion(Iterable<String> texts) {
  for (final t in texts) {
    for (final re in [
      RegExp(r'''com\.android\.tools\.build:gradle:(\d+\.\d+(?:\.\d+)?)'''),
      RegExp(r'''com\.android\.(?:application|library)["']\)?\s*version\s*["'](\d+\.\d+(?:\.\d+)?)'''),
      RegExp(r'^agp\s*=\s*"(\d+\.\d+(?:\.\d+)?)"', multiLine: true),
    ]) {
      final m = re.firstMatch(t);
      if (m != null) return m.group(1);
    }
  }
  return null;
}

/// `gradle.properties`/`local.properties` 한 줄: `key=value`.
String? readProperty(String text, String key) {
  for (final line in text.split('\n')) {
    final t = line.trim();
    if (t.startsWith('#') || t.startsWith('!')) continue;
    final m = RegExp('^${RegExp.escape(key)}\\s*[=:]\\s*(.*)\$').firstMatch(t);
    if (m != null) return m.group(1)!.trim().replaceAll(r'\\', r'\').replaceAll(r'\:', ':');
  }
  return null;
}

abstract class GradleDiagnosticsService {
  Future<GradleDiagnostics> collect(GradleProject? project, GradleModule? module, {String? variant});
}

class ProcessGradleDiagnostics implements GradleDiagnosticsService {
  ProcessGradleDiagnostics(this.runner, {Map<String, String>? env, String? home, bool? isMac, bool? isWindows})
      : env = env ?? Platform.environment,
        home = home ?? Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '',
        isMac = isMac ?? Platform.isMacOS,
        isWindows = isWindows ?? Platform.isWindows;

  final CommandRunner runner;
  final Map<String, String> env;
  final String home;
  final bool isMac;
  final bool isWindows;

  String get _sep => isWindows ? '\\' : '/';

  Future<String?> _read(String path) async {
    try {
      final f = File(path);
      return await f.exists() ? await f.readAsString() : null;
    } on FileSystemException {
      return null;
    }
  }

  String get _javaName => isWindows ? 'java.exe' : 'java';

  Future<JdkInfo?> _probe(String javaHome, String source) async {
    final exe = '$javaHome$_sep' 'bin$_sep$_javaName';
    if (!File(exe).existsSync()) return null;
    final r = await runner.run([exe, '-version'], quiet: true);
    final v = parseJavaVersion(r.combined);
    return v == null ? null : JdkInfo(home: javaHome, version: v.$1, major: v.$2, source: source);
  }

  Future<JdkInfo> _findJdk(String projectPath) async {
    final candidates = <(String, String)>[];
    // 사용자가 설정 창에서 지정한 java 가 가장 앞선다.
    final custom = runner.toolPaths['java'];
    if (custom != null && custom.isNotEmpty) {
      final bin = File(custom).parent.path;
      candidates.add((Directory(bin).parent.path, 'tool path'));
    }
    for (final (path, label) in [('$projectPath$_sep' 'gradle.properties', 'gradle.properties'), ('$home$_sep.gradle$_sep' 'gradle.properties', '~/.gradle/gradle.properties')]) {
      final text = await _read(path);
      final h = text == null ? null : readProperty(text, 'org.gradle.java.home');
      if (h != null && h.isNotEmpty) candidates.add((h, label));
    }
    final javaHome = env['JAVA_HOME'];
    if (javaHome != null && javaHome.isNotEmpty) candidates.add((javaHome, 'JAVA_HOME'));
    if (isMac) {
      final r = await runner.run(['/usr/libexec/java_home'], quiet: true);
      final h = r.stdout.trim();
      if (r.ok && h.isNotEmpty) candidates.add((h, 'java_home'));
      for (final studio in const ['Android Studio', 'Android Studio Preview']) {
        candidates.add(('/Applications/$studio.app/Contents/jbr/Contents/Home', 'Android Studio'));
      }
    } else if (isWindows) {
      final pf = env['ProgramFiles'] ?? r'C:\Program Files';
      candidates.add(('$pf\\Android\\Android Studio\\jbr', 'Android Studio'));
    }
    for (final (h, source) in candidates) {
      final info = await _probe(h, source);
      if (info != null) return info;
    }
    // 위치는 몰라도 PATH 의 java 가 돌면 버전은 안다.
    final r = await runner.run(['java', '-version'], quiet: true);
    final v = r.exitCode == 127 ? null : parseJavaVersion(r.combined);
    return v == null ? const JdkInfo() : JdkInfo(version: v.$1, major: v.$2, source: 'PATH');
  }

  Future<SdkInfo?> _findSdk(String projectPath) async {
    final candidates = <(String, String)>[];
    final local = await _read('$projectPath$_sep' 'local.properties');
    final dirProp = local == null ? null : readProperty(local, 'sdk.dir');
    if (dirProp != null && dirProp.isNotEmpty) candidates.add((dirProp, 'local.properties'));
    for (final key in const ['ANDROID_HOME', 'ANDROID_SDK_ROOT']) {
      final v = env[key];
      if (v != null && v.isNotEmpty) candidates.add((v, key));
    }
    if (isMac) candidates.add(('$home/Library/Android/sdk', 'default location'));
    if (isWindows) {
      final local = env['LOCALAPPDATA'];
      if (local != null) candidates.add(('$local\\Android\\Sdk', 'default location'));
    }
    if (!isMac && !isWindows) candidates.add(('$home/Android/Sdk', 'default location'));
    for (final (d, source) in candidates) {
      if (Directory(d).existsSync()) return SdkInfo(dir: d, source: source);
    }
    return null;
  }

  @override
  Future<GradleDiagnostics> collect(GradleProject? project, GradleModule? module, {String? variant}) async {
    final root = project?.path ?? '';
    final android = project?.shape == GradleShape.androidApp;
    final jdk = await _findJdk(root);
    final sdk = android ? await _findSdk(root) : null;

    String? agp;
    final sources = <String>[];
    if (android) {
      for (final rel in ['build.gradle.kts', 'build.gradle', 'gradle${_sep}libs.versions.toml', if (module != null) '${module.dir}${_sep}build.gradle.kts', if (module != null) '${module.dir}${_sep}build.gradle']) {
        final t = await _read('$root$_sep$rel');
        if (t != null) sources.add(t);
      }
      agp = findAgpVersion(sources);
    }

    bool? platform, tools, licenses;
    if (sdk != null) {
      final sdkInt = module?.android?.compileSdk;
      if (sdkInt != null) platform = Directory('${sdk.dir}${_sep}platforms${_sep}android-$sdkInt').existsSync();
      final bt = Directory('${sdk.dir}${_sep}build-tools');
      tools = bt.existsSync() && bt.listSync().isNotEmpty;
      licenses = File('${sdk.dir}${_sep}licenses${_sep}android-sdk-license').existsSync();
    }

    String? adbVersion;
    String? adbPath;
    if (android) {
      final r = await runner.run(['adb', 'version'], quiet: true);
      adbVersion = r.ok ? RegExp(r'[Vv]ersion (\d\S*)').firstMatch(r.stdout)?.group(1) ?? '' : null;
      if (adbVersion == null && sdk != null) {
        final f = File('${sdk.dir}${_sep}platform-tools$_sep${isWindows ? 'adb.exe' : 'adb'}');
        if (f.existsSync()) adbPath = f.path;
      }
    }

    final wrapper = root.isNotEmpty && (File('$root${_sep}gradlew').existsSync() || File('$root${_sep}gradlew.bat').existsSync());
    final systemGradle = wrapper ? null : runner.locate('gradle');

    ReleaseSigning? signing;
    final type = variant == null || module?.android == null ? null : splitVariantType(variant, module!.android!.buildTypes);
    if (android && module != null && type == 'release') {
      final text = await _read('$root$_sep${module.dir}${_sep}build.gradle.kts') ?? await _read('$root$_sep${module.dir}${_sep}build.gradle') ?? '';
      final configured = text.contains('signingConfig');
      bool? keystore;
      final store = RegExp(r'''storeFile\s*=?\s*(?:file\()?\s*["']([^"']+)["']''').firstMatch(text)?.group(1);
      if (store != null) {
        final f = File(store).isAbsolute ? File(store) : File('$root$_sep${module.dir}$_sep$store');
        keystore = f.existsSync();
      }
      signing = ReleaseSigning(configured: configured, keystoreFound: keystore);
    }

    return GradleDiagnostics(
      collectedAt: DateTime.now(),
      jdk: jdk,
      sdk: sdk,
      requiredJdk: requiredJdkForAgp(agp),
      agpVersion: agp,
      platformPresent: platform,
      buildToolsPresent: tools,
      licensesAccepted: licenses,
      adbVersion: adbVersion,
      adbPath: adbPath,
      wrapperPresent: wrapper,
      systemGradle: systemGradle,
      releaseSigning: signing,
    );
  }
}

/// 변형 이름에서 빌드 타입만 (`freeRelease` → `release`).
String splitVariantType(String variant, List<String> buildTypes) {
  final byLength = [...buildTypes]..sort((a, b) => b.length.compareTo(a.length));
  for (final t in byLength) {
    if (variant.toLowerCase().endsWith(t.toLowerCase())) return t;
  }
  return variant;
}

/// 점검 결과 → 화면에 보일 항목. 실행하지 않고 판단만 한다.
List<GradleCheck> buildGradleChecks({
  required GradleDiagnostics? diagnostics,
  required GradleProject? project,
  GradleModule? module,
}) {
  final d = diagnostics;
  if (d == null || project == null) return const [];
  final android = project.shape == GradleShape.androidApp;
  final items = <GradleCheck>[];

  items.add(project.readError != null
      ? GradleCheck(GradleCheckId.project, CheckStatus.fail, {'reason': project.readError!})
      : project.modules.isEmpty
          ? const GradleCheck(GradleCheckId.project, CheckStatus.warn)
          : GradleCheck(GradleCheckId.project, CheckStatus.ok, {'count': '${project.modules.length}'}));

  items.add(d.wrapperPresent
      ? const GradleCheck(GradleCheckId.wrapper, CheckStatus.ok)
      : d.systemGradle != null
          ? GradleCheck(GradleCheckId.wrapper, CheckStatus.warn, {'gradle': d.systemGradle!})
          : const GradleCheck(GradleCheckId.wrapper, CheckStatus.fail));

  final jdk = d.jdk;
  if (!jdk.found) {
    items.add(const GradleCheck(GradleCheckId.jdk, CheckStatus.fail));
  } else {
    final need = d.requiredJdk;
    final tooOld = need != null && (jdk.major ?? 0) < need;
    items.add(GradleCheck(GradleCheckId.jdk, tooOld ? CheckStatus.warn : CheckStatus.ok, {
      'version': jdk.version!,
      'source': jdk.source,
      if (jdk.home != null) 'home': jdk.home!,
      if (need != null) 'required': '$need',
      if (d.agpVersion != null) 'agp': d.agpVersion!,
      if (tooOld) 'tooOld': 'true',
    }));
  }

  if (android) {
    final sdk = d.sdk;
    if (sdk == null) {
      items.add(const GradleCheck(GradleCheckId.sdk, CheckStatus.fail));
    } else {
      items.add(GradleCheck(GradleCheckId.sdk, CheckStatus.ok, {'dir': sdk.dir, 'source': sdk.source}));
      final compile = module?.android?.compileSdk;
      if (compile != null && d.platformPresent == false) {
        items.add(GradleCheck(GradleCheckId.platform, CheckStatus.fail, {'api': '$compile'}));
      } else if (d.buildToolsPresent == false) {
        items.add(const GradleCheck(GradleCheckId.platform, CheckStatus.warn));
      } else {
        items.add(GradleCheck(GradleCheckId.platform, CheckStatus.ok, {if (compile != null) 'api': '$compile'}));
      }
      items.add(GradleCheck(GradleCheckId.licenses, d.licensesAccepted == true ? CheckStatus.ok : CheckStatus.warn));
    }
    items.add(d.adbVersion != null
        ? GradleCheck(GradleCheckId.adb, CheckStatus.ok, {'version': d.adbVersion!})
        : d.adbPath != null
            ? GradleCheck(GradleCheckId.adb, CheckStatus.warn, {'path': d.adbPath!})
            : const GradleCheck(GradleCheckId.adb, CheckStatus.fail));
    final s = d.releaseSigning;
    if (s != null) {
      items.add(!s.configured
          ? const GradleCheck(GradleCheckId.signing, CheckStatus.warn)
          : s.keystoreFound == false
              ? const GradleCheck(GradleCheckId.signing, CheckStatus.fail)
              : const GradleCheck(GradleCheckId.signing, CheckStatus.ok));
    }
  }
  return items;
}

/// 가장 먼저 고칠 문제(실패 → 주의 순). 없으면 null.
GradleCheck? firstGradleProblem(List<GradleCheck> items) =>
    items.where((c) => c.status == CheckStatus.fail).firstOrNull ?? items.where((c) => c.status == CheckStatus.warn).firstOrNull;
