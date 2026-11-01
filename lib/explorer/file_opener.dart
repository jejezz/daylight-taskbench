// 탐색기에서 고른 파일을 여는 곳. 내장 에디터(단계 15)가 켜지기 전과, 내장 에디터를 껐을 때는 외부 편집기
// (설정의 편집기 명령, 없으면 VS Code)로 연다 (PLAN.md §1.13). 셸이 이것 하나만 부른다.

import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

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
    Future<bool> Function(Uri uri)? launch,
  }) : _start = start ?? _spawn,
       _launch = launch ?? _launchUrl;

  final Workspace workspace;
  final Future<void> Function(List<String> command) _start;
  final Future<bool> Function(Uri uri) _launch;

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

  /// [path] 의 [line]:[column] 을 외부 편집기로 연다. 편집기 명령을 따로 정하지 않았으면 VS Code 의
  /// `vscode://file/…` 주소로 줄까지 가고, 그것이 안 되거나 편집기 명령이 있으면 파일만 연다.
  Future<OpenFileResult> openAt(String path, int line, int column) async {
    if (workspace.editorCommand.isEmpty) {
      final normalized = path.replaceAll(r'\', '/');
      final uri = Uri.parse(
        'vscode://file${normalized.startsWith('/') ? '' : '/'}${Uri.encodeFull(normalized)}:$line:$column',
      );
      try {
        if (await _launch(uri)) return OpenFileResult.opened;
      } on Object {
        // 주소를 처리하는 앱이 없으면 아래에서 파일만 연다.
      }
    }
    return open(path);
  }

  static Future<bool> _launchUrl(Uri uri) => launchUrl(uri);

  static Future<void> _spawn(List<String> command) async {
    await Process.start(
      command.first,
      command.sublist(1),
      mode: ProcessStartMode.detached,
      runInShell: Platform.isWindows,
    );
  }
}
