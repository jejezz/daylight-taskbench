// 탐색기의 "새 파일": 이름 검사와 만들기. 화면(대화상자)과 나눠 두어 따로 시험한다.

import 'dart:io';

import 'package:path/path.dart' as p;

enum NewFileResult { created, exists, invalid, failed }

class NewFileOutcome {
  const NewFileOutcome(this.result, {this.path, this.error});

  final NewFileResult result;

  /// 만든(또는 이미 있던) 파일의 전체 경로.
  final String? path;
  final String? error;
}

/// [baseDir] 아래에 [input](상대 경로, 하위 폴더 허용)으로 빈 파일을 만든다. 없는 폴더는 함께 만든다.
/// 이미 있으면 덮어쓰지 않고 [NewFileResult.exists]. [rootDir] 밖으로 나가는 경로(`..`·절대 경로)는 거부한다.
Future<NewFileOutcome> createNewFile({
  required String rootDir,
  required String baseDir,
  required String input,
}) async {
  final name = input.trim().replaceAll(r'\', '/');
  const bad = ['<', '>', ':', '"', '|', '?', '*'];
  if (name.isEmpty || name.endsWith('/') || bad.any(name.contains) || p.isAbsolute(name) || name.startsWith('/')) {
    return const NewFileOutcome(NewFileResult.invalid);
  }
  final target = p.normalize(p.join(baseDir, name));
  if (!p.isWithin(rootDir, target)) return const NewFileOutcome(NewFileResult.invalid);
  try {
    if (await FileSystemEntity.type(target) != FileSystemEntityType.notFound) {
      return NewFileOutcome(NewFileResult.exists, path: target);
    }
    await Directory(p.dirname(target)).create(recursive: true);
    await File(target).create(exclusive: true);
    return NewFileOutcome(NewFileResult.created, path: target);
  } on FileSystemException catch (e) {
    return NewFileOutcome(NewFileResult.failed, error: e.message);
  }
}
