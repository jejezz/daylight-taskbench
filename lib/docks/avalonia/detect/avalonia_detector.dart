// Avalonia 프로젝트 감지 (docs/AVALONIA_RUNNER.md §3). 한 폴더만 본다 — depth 0 → 1 규칙은 `findWithDepth` 가 한다.
// 폴더(또는 그 아래 두 단계)에 Avalonia 앱 csproj 가 있고, 솔루션이나 csproj 가 폴더 바로 아래에 있으면 프로젝트로 본다.

import 'dart:io';

import '../../../workspace/project_detector.dart';
import 'avalonia_project.dart';

class AvaloniaDetector extends ProjectDetector {
  const AvaloniaDetector();

  @override
  String get kind => 'avalonia';

  @override
  Future<DetectedProject?> detectAt(String dir) async {
    if (!Directory(dir).existsSync()) return null;
    final solution = await findSolution(dir);
    final csprojs = await findCsprojFiles(dir);
    // 솔루션이 없으면 폴더 바로 아래의 csproj 여야 한다 — 그래야 상위 폴더를 프로젝트로 잘못 잡지 않는다.
    if (solution == null && !csprojs.any((r) => !r.contains('/'))) return null;
    for (final rel in csprojs) {
      try {
        if (isAvaloniaApp(await File('$dir${Platform.pathSeparator}${rel.replaceAll('/', Platform.pathSeparator)}').readAsString())) {
          final p = await AvaloniaProject.read(dir);
          return DetectedProject(kind: kind, path: dir, name: p.name, version: p.version);
        }
      } on FileSystemException {
        // 읽지 못한 csproj 는 건너뛴다.
      }
    }
    return null;
  }
}
