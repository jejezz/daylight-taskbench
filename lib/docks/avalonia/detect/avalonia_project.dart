// Avalonia(.NET) 프로젝트 읽기 — 솔루션과 실행 가능한 앱 csproj 를 찾는다 (docs/AVALONIA_RUNNER.md §3).
// MSBuild 를 실행하지 않고 파일만 읽는다: 어셈블리 이름이 `$(AppFileName)` 처럼 Directory.Build.props 의 속성일 수 있어
// 같은 폴더(루트)의 props 와 csproj 의 `<PropertyGroup>` 값으로 `$(이름)` 을 풀어 본다.

import 'dart:io';

/// 한 줄짜리 `<이름>값</이름>` 속성을 모은다 (자식 태그가 없는 것만). 같은 이름이 또 나오면 뒤엣것이 이긴다 — MSBuild 와 같다.
Map<String, String> parseMsbuildProperties(String xml) {
  final out = <String, String>{};
  for (final m in RegExp(r'<([A-Za-z_][\w.]*)>\s*([^<>]*?)\s*</\1>').allMatches(xml)) {
    out[m.group(1)!] = m.group(2)!;
  }
  return out;
}

/// `$(이름)` 을 [props] 로 푼다. 모르는 이름이 남으면 null.
String? resolveMsbuild(String value, Map<String, String> props, {int depth = 0}) {
  if (!value.contains(r'$(')) return value;
  if (depth > 5) return null;
  var unknown = false;
  final replaced = value.replaceAllMapped(RegExp(r'\$\(([^)]+)\)'), (m) {
    final v = props[m.group(1)!];
    if (v == null) {
      unknown = true;
      return m.group(0)!;
    }
    return v;
  });
  if (unknown) return null;
  return resolveMsbuild(replaced, props, depth: depth + 1);
}

/// Avalonia 를 쓰는 실행 파일 프로젝트인가 (`Avalonia` 패키지 + `Exe`/`WinExe`). 테스트·라이브러리 프로젝트는 아니다.
bool isAvaloniaApp(String csproj) {
  final avalonia = RegExp(r'<PackageReference\s+Include="Avalonia(\.[\w.]+)?"').hasMatch(csproj);
  final exe = RegExp(r'<OutputType>\s*(Win)?Exe\s*</OutputType>').hasMatch(csproj);
  return avalonia && exe;
}

class AvaloniaApp {
  const AvaloniaApp({required this.relativePath, required this.assemblyName});

  /// 프로젝트 루트 기준 csproj 경로 (`/` 로 통일). 예: `src/DaylightCommander.App/DaylightCommander.App.csproj`.
  final String relativePath;

  /// 실행 파일 이름(확장자 없음). 속성으로 풀지 못하면 csproj 파일 이름.
  final String assemblyName;

  String get fileName => relativePath.split('/').last;

  @override
  bool operator ==(Object other) => other is AvaloniaApp && other.relativePath == relativePath;

  @override
  int get hashCode => relativePath.hashCode;
}

const _skipDirs = {'bin', 'obj', 'node_modules', 'publish', 'artifacts', 'packages'};

/// [root] 아래 두 단계(`src/App/…`)까지에서 `.csproj` 상대 경로를 모은다.
Future<List<String>> findCsprojFiles(String root, {int maxDepth = 2}) async {
  final out = <String>[];
  Future<void> walk(Directory dir, String rel, int depth) async {
    try {
      await for (final e in dir.list(followLinks: false)) {
        final name = e.path.split(RegExp(r'[\\/]')).last;
        if (e is File && name.toLowerCase().endsWith('.csproj')) {
          out.add(rel.isEmpty ? name : '$rel/$name');
        } else if (e is Directory && depth < maxDepth && !name.startsWith('.') && !_skipDirs.contains(name.toLowerCase())) {
          await walk(e, rel.isEmpty ? name : '$rel/$name', depth + 1);
        }
      }
    } on FileSystemException {
      // 읽을 수 없는 폴더는 건너뛴다.
    }
  }

  await walk(Directory(root), '', 0);
  out.sort();
  return out;
}

/// 루트 폴더의 `.slnx`/`.sln` (여럿이면 `.slnx` 우선, 이름순). 없으면 null.
Future<String?> findSolution(String root) async {
  final found = <String>[];
  try {
    await for (final e in Directory(root).list(followLinks: false)) {
      if (e is! File) continue;
      final name = e.path.split(RegExp(r'[\\/]')).last;
      final l = name.toLowerCase();
      if (l.endsWith('.slnx') || l.endsWith('.sln')) found.add(name);
    }
  } on FileSystemException {
    return null;
  }
  if (found.isEmpty) return null;
  found.sort((a, b) {
    final ax = a.toLowerCase().endsWith('.slnx') ? 0 : 1;
    final bx = b.toLowerCase().endsWith('.slnx') ? 0 : 1;
    return ax != bx ? ax.compareTo(bx) : a.compareTo(b);
  });
  return found.first;
}

class AvaloniaProject {
  const AvaloniaProject({required this.path, required this.name, required this.apps, this.solution, this.version, this.readError});

  final String path;
  final String name;

  /// 루트의 솔루션 파일 이름. 없으면 null (테스트는 솔루션이 있어야 돌릴 수 있다).
  final String? solution;

  /// 실행할 수 있는 Avalonia 앱 후보.
  final List<AvaloniaApp> apps;
  final String? version;
  final String? readError;

  /// 폴더를 읽어 프로젝트 상세를 만든다. 읽기 오류는 [readError] 로 담고 던지지 않는다.
  static Future<AvaloniaProject> read(String root, {String? name, String? version}) async {
    final sep = Platform.pathSeparator;
    String? error;
    final apps = <AvaloniaApp>[];
    String? solution;
    var rootProps = <String, String>{};
    try {
      solution = await findSolution(root);
      final propsFile = File('$root${sep}Directory.Build.props');
      if (await propsFile.exists()) rootProps = parseMsbuildProperties(await propsFile.readAsString());
      for (final rel in await findCsprojFiles(root)) {
        final text = await File('$root$sep${rel.replaceAll('/', sep)}').readAsString();
        if (!isAvaloniaApp(text)) continue;
        final own = parseMsbuildProperties(text);
        final props = {...rootProps, ...own};
        final fileBase = rel.split('/').last.replaceAll(RegExp(r'\.csproj$', caseSensitive: false), '');
        final assembly = resolveMsbuild(own['AssemblyName'] ?? fileBase, props) ?? fileBase;
        apps.add(AvaloniaApp(relativePath: rel, assemblyName: assembly));
      }
    } on FileSystemException catch (e) {
      error = e.message;
    }
    return AvaloniaProject(
      path: root,
      name: name ?? root.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).lastOrNull ?? root,
      solution: solution,
      apps: apps,
      version: version ?? rootProps['AppVersion'] ?? rootProps['Version'],
      readError: error,
    );
  }
}
