// Gradle 빌드 파일을 **한 줄 단위로 가볍게** 읽는다 (docs/GRADLE_RUNNER.md §3, §11).
//
// Groovy·Kotlin DSL·버전 카탈로그를 해석하지 않는다. 칸을 켜고 처음 목록을 보이는 용도일 뿐이고,
// 정답은 Gradle 자신(`./gradlew tasks`)이다. 그래서 못 읽으면 null·빈 목록을 돌려줄 뿐 던지지 않는다.

/// settings.gradle(.kts) 의 `rootProject.name`.
String? parseRootProjectName(String settings) =>
    RegExp(r'''rootProject\.name\s*=\s*["']([^"']+)["']''').firstMatch(settings)?.group(1);

/// settings.gradle(.kts) 의 `include` 로 가져온 모듈 경로 (`:app`, `:feature:login` …), 나온 순서대로.
List<String> parseIncludedModules(String settings) {
  final text = _stripComments(settings);
  final out = <String>[];
  void collect(String args) {
    for (final m in RegExp(r'''["']([^"']+)["']''').allMatches(args)) {
      final name = m.group(1)!.trim();
      if (name.isNotEmpty && !out.contains(name)) out.add(name);
    }
  }

  // include(":a", ":b") — 여러 줄에 걸칠 수 있다.
  for (final m in RegExp(r'\binclude\s*\(([^)]*)\)').allMatches(text)) {
    collect(m.group(1)!);
  }
  // include ':a', ':b' — Groovy 명령 호출. 다음 줄이 따옴표로 시작하면 이어진 인자로 본다.
  for (final m in RegExp(r'''^[ \t]*include[ \t]+(["'][^\n]*(?:\n[ \t]*["'][^\n]*)*)''', multiLine: true).allMatches(text)) {
    collect(m.group(1)!);
  }
  return out;
}

/// `:feature:login` → `feature/login` (settings 기준 상대 폴더).
String moduleDir(String modulePath) => modulePath.replaceFirst(RegExp(r'^:+'), '').replaceAll(':', '/');

/// 빌드 파일이 적용하는 플러그인 id (소문자). 버전 카탈로그 별칭은 `alias:android.application` 꼴로 담는다.
Set<String> parsePlugins(String build) {
  final text = _stripComments(build);
  final out = <String>{};
  for (final m in RegExp(r'''\bid\s*\(?\s*["']([\w.\-]+)["']''').allMatches(text)) {
    out.add(m.group(1)!.toLowerCase());
  }
  for (final m in RegExp(r'''apply\s+plugin\s*:\s*["']([\w.\-]+)["']''').allMatches(text)) {
    out.add(m.group(1)!.toLowerCase());
  }
  for (final m in RegExp(r'''apply\s*\(\s*plugin\s*=\s*["']([\w.\-]+)["']''').allMatches(text)) {
    out.add(m.group(1)!.toLowerCase());
  }
  for (final m in RegExp(r'alias\s*\(\s*libs\.plugins\.([\w.]+)\s*\)').allMatches(text)) {
    out.add('alias:${m.group(1)!.toLowerCase()}');
  }
  for (final m in RegExp(r'''\bkotlin\s*\(\s*["'](\w+)["']\s*\)''').allMatches(text)) {
    out.add('org.jetbrains.kotlin.${m.group(1)}');
  }
  // plugins { application / `java` / java-library } 의 맨몸·백틱 형태.
  for (final m in RegExp(r'^[ \t]*`?(application|java|java-library)`?[ \t]*$', multiLine: true).allMatches(text)) {
    out.add(m.group(1)!);
  }
  return out;
}

bool _hasPlugin(Set<String> plugins, String id) {
  if (plugins.contains(id)) return true;
  // 별칭 이름은 카탈로그 쪽 표기를 따르므로 `android.application` 조각이 들어 있으면 같은 것으로 본다.
  final tail = id.replaceFirst('com.', '');
  return plugins.any((p) => p.startsWith('alias:') && p.substring(6).replaceAll('-', '.').contains(tail));
}

bool isAndroidApplication(Set<String> plugins) => _hasPlugin(plugins, 'com.android.application');
bool isAndroidLibrary(Set<String> plugins) => _hasPlugin(plugins, 'com.android.library');
bool isJvmApplication(Set<String> plugins) => plugins.contains('application');
bool isSpringBoot(Set<String> plugins) => plugins.any((p) => p.contains('org.springframework.boot'));

/// Android 모듈 build.gradle(.kts) 에서 읽을 수 있는 값. 못 읽은 것은 null·빈 목록.
class AndroidBuildInfo {
  const AndroidBuildInfo({
    this.applicationId,
    this.namespace,
    this.versionName,
    this.compileSdk,
    this.buildTypes = const [],
    this.flavors = const [],
  });

  final String? applicationId;
  final String? namespace;
  final String? versionName;
  final int? compileSdk;

  /// `debug`, `release` 와 파일에 선언한 것들.
  final List<String> buildTypes;
  final List<String> flavors;
}

AndroidBuildInfo parseAndroidBuild(String build) {
  final text = _stripComments(build);
  String? str(String key) => RegExp('\\b$key\\s*=?\\s*["\']([^"\']+)["\']').firstMatch(text)?.group(1);
  final sdk = RegExp(r'\bcompileSdk(?:Version)?\s*=?\s*(\d+)').firstMatch(text)?.group(1);
  final types = <String>['debug', 'release'];
  for (final n in _namesInBlock(text, 'buildTypes')) {
    if (!types.contains(n)) types.add(n);
  }
  return AndroidBuildInfo(
    applicationId: str('applicationId'),
    namespace: str('namespace'),
    versionName: str('versionName'),
    compileSdk: sdk == null ? null : int.parse(sdk),
    buildTypes: types,
    flavors: _namesInBlock(text, 'productFlavors').toList(),
  );
}

/// 루트 build.gradle 의 `version = '1.2.3'`.
String? parseProjectVersion(String build) =>
    RegExp(r'''^[ \t]*version\s*=\s*["']([^"']+)["']''', multiLine: true).firstMatch(_stripComments(build))?.group(1);

/// `buildTypes { … }` 같은 블록 안의 이름들: `release {`, `create("staging")`, `register("x")`, `getByName("debug")`.
Iterable<String> _namesInBlock(String text, String block) sync* {
  final body = _blockBody(text, block);
  if (body == null) return;
  final seen = <String>{};
  void add(String n, List<String> into) {
    if (seen.add(n)) into.add(n);
  }

  final names = <String>[];
  for (final m in RegExp(r'''(?:create|register|getByName|maybeCreate)\s*\(\s*["'](\w+)["']''').allMatches(body)) {
    add(m.group(1)!, names);
  }
  // 최상위(깊이 0) 의 `name {` 만 — 안쪽 블록(`signingConfig`, `proguardFiles` …)은 건너뛴다.
  var depth = 0;
  final top = StringBuffer();
  for (final ch in body.split('')) {
    if (ch == '{') {
      depth++;
      if (depth == 1) top.write('{');
    } else if (ch == '}') {
      depth--;
    } else if (depth == 0) {
      top.write(ch);
    }
  }
  for (final m in RegExp(r'(?:^|\n)\s*(\w+)\s*\{').allMatches(top.toString())) {
    final n = m.group(1)!;
    if (!const {'create', 'register', 'getByName', 'maybeCreate'}.contains(n)) add(n, names);
  }
  yield* names;
}

/// `keyword { … }` 의 안쪽 문자열. 중괄호 짝을 센다. 없으면 null.
String? _blockBody(String text, String keyword) {
  final m = RegExp('\\b$keyword\\s*\\{').firstMatch(text);
  if (m == null) return null;
  var depth = 1;
  var i = m.end;
  while (i < text.length && depth > 0) {
    final c = text[i];
    if (c == '{') depth++;
    if (c == '}') depth--;
    i++;
  }
  return depth == 0 ? text.substring(m.end, i - 1) : null;
}

String _stripComments(String s) => s.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '').replaceAll(RegExp(r'//[^\n]*'), '');
