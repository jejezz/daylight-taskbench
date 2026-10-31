// Gradle 프로젝트 감지 (docs/GRADLE_RUNNER.md §3). 한 폴더만 본다 — depth 0 → 1 규칙은 `findWithDepth` 가 한다.

import 'dart:io';

import '../../../workspace/project_detector.dart';
import 'gradle_parse.dart';

const _settingsNames = ['settings.gradle.kts', 'settings.gradle'];
const _buildNames = ['build.gradle.kts', 'build.gradle'];

File? _firstExisting(String dir, List<String> names) {
  for (final n in names) {
    final f = File('$dir${Platform.pathSeparator}$n');
    if (f.existsSync()) return f;
  }
  return null;
}

String _parentOf(String dir) {
  final trimmed = dir.replaceAll(RegExp(r'[\\/]+$'), '');
  final i = trimmed.lastIndexOf(RegExp(r'[\\/]'));
  return i <= 0 ? '' : trimmed.substring(0, i);
}

/// Flutter·React Native 프로젝트의 `android/` 처럼 **다른 칸의 몫인** Gradle 폴더인가. 그런 폴더는 감지하지 않는다.
bool isHostedByOtherRunner(String dir) {
  final parent = _parentOf(dir);
  if (parent.isEmpty) return false;
  if (File('$parent${Platform.pathSeparator}pubspec.yaml').existsSync()) return true;
  final pkg = File('$parent${Platform.pathSeparator}package.json');
  if (pkg.existsSync()) {
    try {
      return pkg.readAsStringSync().contains('"react-native"');
    } on FileSystemException {
      return false;
    }
  }
  return false;
}

class GradleDetector extends ProjectDetector {
  const GradleDetector();

  @override
  String get kind => 'gradle';

  @override
  Future<DetectedProject?> detectAt(String dir) async {
    final settings = _firstExisting(dir, _settingsNames);
    final build = _firstExisting(dir, _buildNames);
    final hasWrapper = File('$dir${Platform.pathSeparator}gradlew').existsSync() ||
        File('$dir${Platform.pathSeparator}gradlew.bat').existsSync();
    // 설정 파일이 있으면 Gradle 루트다. 설정 파일 없이 build 파일과 래퍼만 있는 단일 프로젝트도 후보로 본다.
    if (settings == null && !(build != null && hasWrapper)) return null;
    if (isHostedByOtherRunner(dir)) return null;
    final folderName = dir.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).lastOrNull ?? dir;
    String? name;
    String? version;
    try {
      if (settings != null) name = parseRootProjectName(await settings.readAsString());
      if (build != null) version = parseProjectVersion(await build.readAsString());
    } on FileSystemException {
      // 읽지 못해도 프로젝트로는 잡는다 — 칸 안에서 "읽지 못했습니다"로 보인다.
    }
    return DetectedProject(kind: kind, path: dir, name: name ?? folderName, version: version);
  }
}
