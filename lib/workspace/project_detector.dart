// 디렉터리 → 프로젝트 후보 (PLAN.md §1.4, §4.2). 종류(Flutter·Rust·Electron …)마다 detector 하나가 있고,
// "고른 폴더(depth 0)에서 못 찾으면 바로 아래 폴더(depth 1)까지" 규칙은 [findWithDepth]가 공통으로 처리한다.

import 'dart:io';

/// 감지된 프로젝트 한 개 (종류 공통 최소 정보).
class DetectedProject {
  const DetectedProject({required this.kind, required this.path, required this.name, this.version});

  final String kind;
  final String path;
  final String name;
  final String? version;

  @override
  bool operator ==(Object other) => other is DetectedProject && other.kind == kind && other.path == path;

  @override
  int get hashCode => Object.hash(kind, path);
}

abstract class ProjectDetector {
  const ProjectDetector();

  /// 'flutter', 'cargo', 'electron' …
  String get kind;

  /// [dir] 자체가 이 종류의 프로젝트면 돌려준다. 아니면 null. 한 폴더만 본다.
  Future<DetectedProject?> detectAt(String dir);

  /// depth 0 → 1 규칙 (요청 사항). depth 2 이상은 찾지 않는다.
  Future<List<DetectedProject>> detect(String dir) => findWithDepth(dir, detectAt);
}

const _skippedDirs = {'build', 'node_modules', 'target', 'dist'};

Future<List<DetectedProject>> findWithDepth(String dir, Future<DetectedProject?> Function(String) detectAt) async {
  final here = await detectAt(dir);
  if (here != null) return [here];
  final found = <DetectedProject>[];
  try {
    await for (final e in Directory(dir).list(followLinks: false)) {
      if (e is! Directory) continue;
      final name = e.path.split(RegExp(r'[\\/]')).last;
      if (name.startsWith('.') || _skippedDirs.contains(name)) continue;
      final p = await detectAt(e.path);
      if (p != null) found.add(p);
    }
  } on FileSystemException {
    return const [];
  }
  return found..sort((a, b) => a.path.compareTo(b.path));
}

/// `dependencies:` 아래에 `flutter:` SDK 의존성이 있으면 Flutter 프로젝트다.
bool isFlutterPubspec(String pubspec) =>
    RegExp(r'^\s{2}flutter:\s*$\n\s{4}sdk:\s*flutter', multiLine: true).hasMatch(pubspec);

String? parsePubspecField(String pubspec, String key) {
  final m = RegExp('^$key:\\s*["\']?([^"\'\\n#]+?)["\']?\\s*(#.*)?\$', multiLine: true).firstMatch(pubspec);
  return m?.group(1)?.trim();
}

class FlutterDetector extends ProjectDetector {
  const FlutterDetector();

  @override
  String get kind => 'flutter';

  @override
  Future<DetectedProject?> detectAt(String dir) async {
    final pubspec = File('$dir/pubspec.yaml');
    if (!await pubspec.exists()) return null;
    final text = await pubspec.readAsString();
    if (!isFlutterPubspec(text)) return null;
    return DetectedProject(
      kind: kind,
      path: dir,
      name: parsePubspecField(text, 'name') ?? dir.split(Platform.pathSeparator).last,
      version: parsePubspecField(text, 'version'),
    );
  }
}
