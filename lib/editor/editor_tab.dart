// 편집기 탭 하나 (daylight-workbench 의 studio_controller.dart 에서 EditorTab 을 줄여 옮겼다).
// [Taskbench에서 달라진 곳] git HEAD 비교(변경 표시·변경점 보기)는 아직 없다 (단계 15의 뒤 차례).

import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

import 'file_language.dart';

/// 파일의 마지막 수정 시각과 크기 — 디스크에서 바뀌었는지 가볍게 확인하는 데 쓴다.
class FileStamp {
  const FileStamp(this.modified, this.size);

  final DateTime modified;
  final int size;

  @override
  bool operator ==(Object other) =>
      other is FileStamp && other.modified == modified && other.size == size;

  @override
  int get hashCode => Object.hash(modified, size);
}

/// 열려 있는 파일이 디스크에서 어떻게 달라졌는가.
enum ExternalChange {
  none,

  /// 내가 수정 중인데 디스크의 파일도 바뀌었다 — 저장하면 그쪽 수정을 덮어쓴다.
  modified,

  /// 디스크에서 파일이 사라졌다 (삭제·이름 변경·worktree 정리).
  deleted,
}

/// 저장된 글과 지금 글을 비교해 수정 여부를 아는 탭.
class EditorTab {
  EditorTab(this.path, String text)
    : language = FileLanguage.of(path),
      controller = CodeLineEditingController.fromText(
        text,
        CodeLineOptions(
          lineBreak: text.contains('\r\n')
              ? TextLineBreak.crlf
              : TextLineBreak.lf,
        ),
      ) {
    // 줄 끝이 섞인 파일을 열자마자 "수정됨"으로 보이지 않게, 편집기가 정리한 글을 기준으로 삼는다.
    savedText = controller.text;
  }

  final String path;
  final FileLanguage language;
  late String savedText;
  final CodeLineEditingController controller;

  /// 디스크에서 마지막으로 확인한 상태. 파일이 없으면 null.
  FileStamp? stamp;

  /// 사용자가 골라야 하는 외부 변경. [ExternalChange.none]이면 아무 일도 없다.
  ExternalChange external = ExternalChange.none;

  /// Markdown 만: 렌더링된 모양으로 보는 중인가 (아니면 글을 편집하는 중).
  bool preview = false;

  /// 편집기가 만든 접기 제어. 편집기가 화면에 올라온 뒤에 채워진다.
  CodeChunkController? chunks;

  /// 이 탭의 찾기·바꾸기 제어. 탭이 들고 있어서 메뉴가 포커스와 상관없이 바로 찾기 줄을 열 수 있다.
  late final CodeFindController find = CodeFindController(controller);

  /// 편집기의 포커스. 다른 곳(탐색기·오류 목록)에서 이 탭으로 이동했을 때 커서가 보이게 포커스를 옮기는 데 쓴다.
  final FocusNode focusNode = FocusNode(debugLabel: 'editor');

  bool get dirty => controller.text != savedText;

  String get name => path.split(RegExp(r'[/\\]')).last;

  void dispose() {
    find.dispose();
    focusNode.dispose();
    controller.dispose();
  }
}
