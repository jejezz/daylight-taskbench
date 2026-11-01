// 앱 전체(셸) 단축키 표 (PLAN.md §1.5·§1.13). 단축키를 한곳에 모아 두면 겹침을 테스트로 검사할 수 있고(`shell_shortcuts_test`),
// 터미널이 어떤 키를 셸(프로그램)로 보내지 않고 앱에 돌려줘야 하는지도 이 표 하나로 정한다.
//
// 규칙: macOS 는 ⌘, 그 밖은 Ctrl 이 "주 수정키"다. 새로 더하는 것은 Alt 조합을 피한다 — Windows 에서 Ctrl+Alt 는 AltGr
// (유럽 자판의 문자 입력)와 같아서 글자 입력과 겹칠 수 있다.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

enum ShellShortcut {
  /// 폴더 열기.
  openFolder,

  /// 새로 고침.
  refresh,

  /// 설정 창.
  settings,

  /// 파일 이름으로 열기 (빠른 열기).
  quickOpen,

  /// 탐색기 켜기/끄기.
  explorer,

  /// 에디터 보이기/끄기.
  editor,

  /// 터미널 보이기/끄기.
  terminal,

  /// 도크 열의 1~4번째 칸 펼치기.
  dock1,
  dock2,
  dock3,
  dock4,
}

bool get _mac => defaultTargetPlatform == TargetPlatform.macOS;

/// [shortcut]의 키 조합. [mac]을 주면 그 플랫폼 기준으로 (테스트용).
SingleActivator activatorOf(ShellShortcut shortcut, {bool? mac}) {
  final m = mac ?? _mac;
  SingleActivator primary(LogicalKeyboardKey key, {bool shift = false, bool alt = false}) =>
      SingleActivator(key, control: !m, meta: m, shift: shift, alt: alt);
  return switch (shortcut) {
    ShellShortcut.openFolder => primary(LogicalKeyboardKey.keyO),
    ShellShortcut.refresh => primary(LogicalKeyboardKey.keyR),
    ShellShortcut.settings => primary(LogicalKeyboardKey.comma),
    // ⌘P 는 Git 칸의 Push 가 쓰고 있어서 Shift+O 다 (⌘O 는 폴더 열기 — "열기" 계열끼리 묶었다).
    ShellShortcut.quickOpen => primary(LogicalKeyboardKey.keyO, shift: true),
    ShellShortcut.explorer => primary(LogicalKeyboardKey.keyE, shift: true),
    ShellShortcut.editor => primary(LogicalKeyboardKey.keyD, shift: true),
    // VS Code 와 같다: macOS 에서도 ⌘`(앱 창 전환)이 아니라 Ctrl+`.
    ShellShortcut.terminal => const SingleActivator(LogicalKeyboardKey.backquote, control: true),
    ShellShortcut.dock1 => primary(LogicalKeyboardKey.digit1, alt: true),
    ShellShortcut.dock2 => primary(LogicalKeyboardKey.digit2, alt: true),
    ShellShortcut.dock3 => primary(LogicalKeyboardKey.digit3, alt: true),
    ShellShortcut.dock4 => primary(LogicalKeyboardKey.digit4, alt: true),
  };
}

/// 터미널에 포커스가 있어도 셸(프로그램)로 보내지 않고 앱이 받아야 하는 것. `Ctrl+O`·`Ctrl+R` 은 셸의 줄 편집·기록 검색이라
/// 보내고, `Alt+숫자`는 macOS 에서 특수문자 입력이라 보낸다.
const forwardedFromTerminal = {
  ShellShortcut.settings,
  ShellShortcut.quickOpen,
  ShellShortcut.explorer,
  ShellShortcut.editor,
  ShellShortcut.terminal,
};

/// [event]가 터미널이 앱에 돌려줘야 하는 단축키인가.
bool isForwardedFromTerminal(KeyEvent event, HardwareKeyboard keyboard, {bool? mac}) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
  for (final s in forwardedFromTerminal) {
    if (activatorOf(s, mac: mac).accepts(event, keyboard)) return true;
  }
  return false;
}

/// 화면에 보이는 단축키 글자 (예: `⌘⇧E`, `Ctrl+Shift+E`).
String shortcutLabel(ShellShortcut shortcut, {bool? mac}) {
  final m = mac ?? _mac;
  final a = activatorOf(shortcut, mac: m);
  final key = _keyLabel(a.trigger);
  if (m) {
    return '${a.control ? '⌃' : ''}${a.alt ? '⌥' : ''}${a.shift ? '⇧' : ''}${a.meta ? '⌘' : ''}$key';
  }
  return [
    if (a.control) 'Ctrl',
    if (a.alt) 'Alt',
    if (a.shift) 'Shift',
    if (a.meta) 'Win',
    key,
  ].join('+');
}

String _keyLabel(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.comma) return ',';
  if (key == LogicalKeyboardKey.backquote) return '`';
  return key.keyLabel.toUpperCase();
}
