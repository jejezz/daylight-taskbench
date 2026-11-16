// 편집기 색상 구성표. 앱 테마와 따로 고르는 바탕·글자·구문 강조 색 묶음이다.
// 색 값은 lib/theme/ 에만 둔다 (CLAUDE.md 테마 규칙).
// [Taskbench에서 달라진 곳] daylight-terminal-flutter 의 terminal_schemes.dart(ANSI 16색 표)를 옮겨, 터미널 색 이름을
// 구문 강조 이름표에 대응시켰다: 마젠타=키워드, 초록=문자열, 노랑=숫자, 청록=타입, 파랑=함수, 빨강=변수·속성,
// 밝은 검정=주석. VS Code·Visual Studio 는 실제 편집기 색을 그대로 쓴다.

import 'package:flutter/material.dart' show Brightness, Color;

class EditorScheme {
  const EditorScheme({
    required this.id,
    required this.name,
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.selection,
    required this.cursor,
    required this.comment,
    required this.keyword,
    required this.string,
    required this.number,
    required this.type,
    required this.function,
    required this.variable,
    required this.meta,
  });

  /// 터미널 색상표(ANSI 8색 + 밝은 8색)로 만든다. 순서: 검정 빨강 초록 노랑 파랑 마젠타 청록 흰색.
  factory EditorScheme.ansi(
    String id,
    String name, {
    required Brightness brightness,
    required int fg,
    required int bg,
    required int cursor,
    required int sel,
    required List<int> ansi,
    required List<int> bright,
  }) => EditorScheme(
    id: id,
    name: name,
    brightness: brightness,
    background: Color(bg),
    foreground: Color(fg),
    selection: Color(sel),
    cursor: Color(cursor),
    comment: Color(bright[0]),
    keyword: Color(ansi[5]),
    string: Color(ansi[2]),
    number: Color(ansi[3]),
    type: Color(ansi[6]),
    function: Color(ansi[4]),
    variable: Color(ansi[1]),
    meta: Color(bright[6]),
  );

  /// 저장되는 값(`editor_color_scheme`). 번역하지 않는 고유 이름이 [name].
  final String id;
  final String name;
  final Brightness brightness;
  final Color background;
  final Color foreground;
  final Color selection;
  final Color cursor;
  final Color comment;
  final Color keyword;
  final Color string;
  final Color number;
  final Color type;
  final Color function;
  final Color variable;
  final Color meta;

  /// 설정에 없거나 `null`: 구성표를 쓰지 않고 앱 테마를 따른다.
  static const followAppId = 'app';

  static const defaultId = followAppId;

  /// 고르는 목록 (앱 테마를 따름은 여기 없고 [followAppId]로 따로 다룬다).
  static const all = <EditorScheme>[
    EditorScheme(
      id: 'vscode-dark',
      name: 'VS Code Dark',
      brightness: Brightness.dark,
      background: Color(0xFF1E1E1E),
      foreground: Color(0xFFD4D4D4),
      selection: Color(0xFF264F78),
      cursor: Color(0xFFAEAFAD),
      comment: Color(0xFF6A9955),
      keyword: Color(0xFF569CD6),
      string: Color(0xFFCE9178),
      number: Color(0xFFB5CEA8),
      type: Color(0xFF4EC9B0),
      function: Color(0xFFDCDCAA),
      variable: Color(0xFF9CDCFE),
      meta: Color(0xFFC586C0),
    ),
    EditorScheme(
      id: 'vscode-light',
      name: 'VS Code Light',
      brightness: Brightness.light,
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF000000),
      selection: Color(0xFFADD6FF),
      cursor: Color(0xFF000000),
      comment: Color(0xFF008000),
      keyword: Color(0xFF0000FF),
      string: Color(0xFFA31515),
      number: Color(0xFF098658),
      type: Color(0xFF267F99),
      function: Color(0xFF795E26),
      variable: Color(0xFF001080),
      meta: Color(0xFFAF00DB),
    ),
    EditorScheme(
      id: 'vs-dark',
      name: 'Visual Studio Dark',
      brightness: Brightness.dark,
      background: Color(0xFF1E1E1E),
      foreground: Color(0xFFDCDCDC),
      selection: Color(0xFF264F78),
      cursor: Color(0xFFDCDCDC),
      comment: Color(0xFF57A64A),
      keyword: Color(0xFF569CD6),
      string: Color(0xFFD69D85),
      number: Color(0xFFB5CEA8),
      type: Color(0xFF4EC9B0),
      function: Color(0xFFDCDCAA),
      variable: Color(0xFF9CDCFE),
      meta: Color(0xFFD8A0DF),
    ),
    EditorScheme(
      id: 'vs-light',
      name: 'Visual Studio Light',
      brightness: Brightness.light,
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF000000),
      selection: Color(0xFFADD6FF),
      cursor: Color(0xFF000000),
      comment: Color(0xFF008000),
      keyword: Color(0xFF0000FF),
      string: Color(0xFFA31515),
      number: Color(0xFF000000),
      type: Color(0xFF2B91AF),
      function: Color(0xFF74531F),
      variable: Color(0xFF1F377F),
      meta: Color(0xFF6F008A),
    ),
  ];

  /// daylight-terminal-flutter 의 터미널 색상표와 같은 값에서 만든 구성표.
  static final List<EditorScheme> _ansiSchemes = [
    EditorScheme.ansi(
      'solarized-dark', 'Solarized Dark', brightness: Brightness.dark,
      fg: 0xFF839496, bg: 0xFF002B36, cursor: 0xFF93A1A1, sel: 0xFF073642,
      ansi: [0xFF586E75, 0xFFDC322F, 0xFF859900, 0xFFB58900, 0xFF268BD2, 0xFFD33682, 0xFF2AA198, 0xFFEEE8D5],
      bright: [0xFF657B83, 0xFFF2605A, 0xFFA4B800, 0xFFDDA800, 0xFF4BA3E8, 0xFFE8599D, 0xFF3CC0B5, 0xFFFDF6E3],
    ),
    EditorScheme.ansi(
      'solarized-light', 'Solarized Light', brightness: Brightness.light,
      fg: 0xFF657B83, bg: 0xFFFDF6E3, cursor: 0xFF586E75, sel: 0xFFEEE8D5,
      ansi: [0xFF073642, 0xFFDC322F, 0xFF738A05, 0xFFB58900, 0xFF268BD2, 0xFFD33682, 0xFF2AA198, 0xFF93A1A1],
      bright: [0xFF93A1A1, 0xFFE0443F, 0xFF859900, 0xFFC99A00, 0xFF1E7DC4, 0xFFE0468F, 0xFF1FB0A4, 0xFF839496],
    ),
    EditorScheme.ansi(
      'dracula', 'Dracula', brightness: Brightness.dark,
      fg: 0xFFF8F8F2, bg: 0xFF282A36, cursor: 0xFFF8F8F2, sel: 0xFF44475A,
      ansi: [0xFF21222C, 0xFFFF5555, 0xFF50FA7B, 0xFFF1FA8C, 0xFFBD93F9, 0xFFFF79C6, 0xFF8BE9FD, 0xFFF8F8F2],
      bright: [0xFF6272A4, 0xFFFF6E6E, 0xFF69FF94, 0xFFFFFFA5, 0xFFD6ACFF, 0xFFFF92DF, 0xFFA4FFFF, 0xFFFFFFFF],
    ),
    EditorScheme.ansi(
      'one-dark', 'One Dark', brightness: Brightness.dark,
      fg: 0xFFABB2BF, bg: 0xFF282C34, cursor: 0xFF528BFF, sel: 0xFF3E4451,
      ansi: [0xFF282C34, 0xFFE06C75, 0xFF98C379, 0xFFE5C07B, 0xFF61AFEF, 0xFFC678DD, 0xFF56B6C2, 0xFFABB2BF],
      bright: [0xFF5C6370, 0xFFE06C75, 0xFF98C379, 0xFFE5C07B, 0xFF61AFEF, 0xFFC678DD, 0xFF56B6C2, 0xFFFFFFFF],
    ),
    EditorScheme.ansi(
      'tokyo-night', 'Tokyo Night', brightness: Brightness.dark,
      fg: 0xFFC0CAF5, bg: 0xFF1A1B26, cursor: 0xFFC0CAF5, sel: 0xFF33467C,
      ansi: [0xFF15161E, 0xFFF7768E, 0xFF9ECE6A, 0xFFE0AF68, 0xFF7AA2F7, 0xFFBB9AF7, 0xFF7DCFFF, 0xFFA9B1D6],
      bright: [0xFF565F89, 0xFFF7768E, 0xFF9ECE6A, 0xFFE0AF68, 0xFF7AA2F7, 0xFFBB9AF7, 0xFF7DCFFF, 0xFFC0CAF5],
    ),
    EditorScheme.ansi(
      'gruvbox-dark', 'Gruvbox Dark', brightness: Brightness.dark,
      fg: 0xFFEBDBB2, bg: 0xFF282828, cursor: 0xFFEBDBB2, sel: 0xFF504945,
      ansi: [0xFF282828, 0xFFCC241D, 0xFF98971A, 0xFFD79921, 0xFF458588, 0xFFB16286, 0xFF689D6A, 0xFFA89984],
      bright: [0xFF928374, 0xFFFB4934, 0xFFB8BB26, 0xFFFABD2F, 0xFF83A598, 0xFFD3869B, 0xFF8EC07C, 0xFFEBDBB2],
    ),
    EditorScheme.ansi(
      'nord', 'Nord', brightness: Brightness.dark,
      fg: 0xFFD8DEE9, bg: 0xFF2E3440, cursor: 0xFFD8DEE9, sel: 0xFF434C5E,
      ansi: [0xFF3B4252, 0xFFBF616A, 0xFFA3BE8C, 0xFFEBCB8B, 0xFF81A1C1, 0xFFB48EAD, 0xFF88C0D0, 0xFFE5E9F0],
      bright: [0xFF616E88, 0xFFBF616A, 0xFFA3BE8C, 0xFFEBCB8B, 0xFF81A1C1, 0xFFB48EAD, 0xFF8FBCBB, 0xFFECEFF4],
    ),
    EditorScheme.ansi(
      'monokai', 'Monokai', brightness: Brightness.dark,
      fg: 0xFFF8F8F2, bg: 0xFF272822, cursor: 0xFFF8F8F0, sel: 0xFF49483E,
      ansi: [0xFF272822, 0xFFF92672, 0xFFA6E22E, 0xFFF4BF75, 0xFF66D9EF, 0xFFAE81FF, 0xFFA1EFE4, 0xFFF8F8F2],
      bright: [0xFF75715E, 0xFFF92672, 0xFFA6E22E, 0xFFF4BF75, 0xFF66D9EF, 0xFFAE81FF, 0xFFA1EFE4, 0xFFF9F8F5],
    ),
    EditorScheme.ansi(
      'github-light', 'GitHub Light', brightness: Brightness.light,
      fg: 0xFF24292F, bg: 0xFFFFFFFF, cursor: 0xFF0969DA, sel: 0xFFB6D6FB,
      ansi: [0xFF24292F, 0xFFCF222E, 0xFF1A9F3F, 0xFFB08800, 0xFF0969DA, 0xFF8250DF, 0xFF0E8A9B, 0xFF6E7781],
      bright: [0xFF6E7781, 0xFFFA4549, 0xFF2DB24F, 0xFFD4A000, 0xFF218BFF, 0xFFA475F9, 0xFF1CB0C4, 0xFF8C959F],
    ),
  ];

  /// 고를 수 있는 모든 구성표, 목록에 보이는 순서대로.
  static final List<EditorScheme> choices = [...all, ..._ansiSchemes];

  /// 저장된 id 에 맞는 구성표. [followAppId]·없는 값·모르는 id 는 null (앱 테마를 따른다).
  static EditorScheme? byId(String? id) {
    for (final s in choices) {
      if (s.id == id) return s;
    }
    return null;
  }
}
