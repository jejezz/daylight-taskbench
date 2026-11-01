// 탐색기에서 고른 파일을 여는 곳. 내장 에디터(단계 15)가 켜지기 전과, 내장 에디터를 껐을 때는 외부 편집기
// (설정의 편집기 명령, 없으면 VS Code)로 연다 (PLAN.md §1.13). 셸이 이것 하나만 부른다.

import 'dart:io';

import '../workspace/workspace.dart';

enum OpenFileResult {
  /// 편집기를 띄웠다.
  opened,

  /// 편집기를 찾지 못했다 (VS Code 가 없고 편집기 명령도 비어 있다).
  noEditor,

  /// 찾았지만 실행하지 못했다.
  failed,
}

class FileOpener {
  FileOpener(
    this.workspace, {
    Future<void> Function(List<String> command)? start,
  }) : _start = start ?? _spawn;

  final Workspace workspace;
  final Future<void> Function(List<String> command) _start;

  /// [path] 파일을 외부 편집기로 연다.
  Future<OpenFileResult> open(String path) async {
    // 폴더용 명령에 파일 경로를 넘기면 같은 방식으로 그 파일이 열린다 (VS Code 는 폴더·파일 모두 같은 인자).
    final command = await workspace.folderEditorCommand(path);
    if (command == null) return OpenFileResult.noEditor;
    try {
      await _start(command);
      return OpenFileResult.opened;
    } on Object {
      return OpenFileResult.failed;
    }
  }

  static Future<void> _spawn(List<String> command) async {
    await Process.start(
      command.first,
      command.sublist(1),
      mode: ProcessStartMode.detached,
      runInShell: Platform.isWindows,
    );
  }
}
