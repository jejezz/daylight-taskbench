// 셸 단축키 표: 서로·Branch 칸의 단축키와 겹치지 않는지, 패널 토글 규칙, 터미널 전달, 표시 글자.

import 'package:daylight_taskbench/ui/shell/panels/panel_layout.dart';
import 'package:daylight_taskbench/ui/shell/shell_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PanelLayout> _layout([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return PanelLayout(await SharedPreferences.getInstance());
}

String _sig(SingleActivator a) =>
    '${a.control ? 'C' : ''}${a.meta ? 'M' : ''}${a.alt ? 'A' : ''}${a.shift ? 'S' : ''}+${a.trigger.keyId}';

void main() {
  for (final mac in [true, false]) {
    test('단축키 조합이 서로 겹치지 않는다 (mac=$mac)', () {
      final sigs = ShellShortcut.values
          .map((s) => _sig(activatorOf(s, mac: mac)))
          .toList();
      expect(sigs.toSet(), hasLength(sigs.length));
    });

    test('Branch 칸의 알려진 단축키와 겹치지 않는다 (mac=$mac)', () {
      // 주 수정키(+Shift) 조합: K, J, T, Shift+R, P, Shift+P, Shift+F, B, 숫자 1~8. F5 는 수정키 없음.
      final known = <String>{
        for (final k in [
          LogicalKeyboardKey.keyK,
          LogicalKeyboardKey.keyJ,
          LogicalKeyboardKey.keyT,
          LogicalKeyboardKey.keyP,
          LogicalKeyboardKey.keyB,
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit4,
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit6,
          LogicalKeyboardKey.digit7,
          LogicalKeyboardKey.digit8,
        ])
          _sig(SingleActivator(k, control: !mac, meta: mac)),
        for (final k in [
          LogicalKeyboardKey.keyR,
          LogicalKeyboardKey.keyP,
          LogicalKeyboardKey.keyF,
        ])
          _sig(SingleActivator(k, control: !mac, meta: mac, shift: true)),
        _sig(const SingleActivator(LogicalKeyboardKey.f5)),
      };
      for (final s in ShellShortcut.values) {
        // 폴더 열기·새로 고침·설정은 셸이 원래 쓰던 것이라 Branch 칸이 피해 갔다 — 새로 더한 것만 검사한다.
        if ({
          ShellShortcut.openFolder,
          ShellShortcut.refresh,
          ShellShortcut.settings,
        }.contains(s)) {
          continue;
        }
        expect(
          known,
          isNot(contains(_sig(activatorOf(s, mac: mac)))),
          reason: '$s',
        );
      }
    });
  }

  group('PanelLayout 토글', () {
    test('탐색기는 켜고 끈다', () async {
      final p = await _layout();
      p.toggleExplorer();
      expect(p.explorer, isTrue);
      p.toggleExplorer();
      expect(p.explorer, isFalse);
    });

    test('에디터: 꺼짐→켬, 보이는 중→끔, 터미널 뒤→앞으로', () async {
      final p = await _layout();
      p.toggleEditor();
      expect(p.editorShown, isTrue);
      p.toggleEditor();
      expect(p.editor, isFalse);

      p
        ..setEditor(true)
        ..setTerminal(true)
        ..showCenter(CenterView.terminal);
      p.toggleEditor();
      expect(p.editor, isTrue);
      expect(p.center, CenterView.editor);
    });

    test('내장 에디터를 껐으면 에디터 토글은 아무 일도 하지 않는다', () async {
      final p = await _layout({'editor_embedded': false});
      p.toggleEditor();
      expect(p.editor, isFalse);
      expect(p.expanded, isFalse);
    });

    test('터미널: 꺼짐→켬, 보이는 중→끔, 에디터 뒤→앞으로', () async {
      final p = await _layout();
      p.toggleTerminal();
      expect(p.terminalShown, isTrue);
      p.toggleTerminal();
      expect(p.terminal, isFalse);

      p
        ..setTerminal(true)
        ..setEditor(true)
        ..showCenter(CenterView.editor);
      p.toggleTerminal();
      expect(p.terminal, isTrue);
      expect(p.center, CenterView.terminal);
    });
  });

  group('표시 글자', () {
    test('macOS', () {
      expect(shortcutLabel(ShellShortcut.explorer, mac: true), '⇧⌘E');
      expect(shortcutLabel(ShellShortcut.settings, mac: true), '⌘,');
      expect(shortcutLabel(ShellShortcut.terminal, mac: true), '⌃`');
      expect(shortcutLabel(ShellShortcut.dock1, mac: true), '⌥⌘1');
    });

    test('Windows', () {
      expect(shortcutLabel(ShellShortcut.explorer, mac: false), 'Ctrl+Shift+E');
      expect(shortcutLabel(ShellShortcut.terminal, mac: false), 'Ctrl+`');
      expect(
        shortcutLabel(ShellShortcut.quickOpen, mac: false),
        'Ctrl+Shift+O',
      );
    });
  });

  testWidgets('터미널이 앱에 돌려줄 키 / 셸로 보낼 키', (tester) async {
    KeyDownEvent down(LogicalKeyboardKey l, PhysicalKeyboardKey p) =>
        KeyDownEvent(physicalKey: p, logicalKey: l, timeStamp: Duration.zero);
    final kb = HardwareKeyboard.instance;
    await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
    // Ctrl+O / Ctrl+R 은 셸의 줄 편집·기록 검색이라 보낸다.
    expect(
      isForwardedFromTerminal(
        down(LogicalKeyboardKey.keyO, PhysicalKeyboardKey.keyO),
        kb,
        mac: false,
      ),
      isFalse,
    );
    expect(
      isForwardedFromTerminal(
        down(LogicalKeyboardKey.keyR, PhysicalKeyboardKey.keyR),
        kb,
        mac: false,
      ),
      isFalse,
    );
    // Ctrl+` 은 앱이 받는다.
    expect(
      isForwardedFromTerminal(
        down(LogicalKeyboardKey.backquote, PhysicalKeyboardKey.backquote),
        kb,
        mac: false,
      ),
      isTrue,
    );
    await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(
      isForwardedFromTerminal(
        down(LogicalKeyboardKey.keyE, PhysicalKeyboardKey.keyE),
        kb,
        mac: false,
      ),
      isTrue,
    );
    await simulateKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
    // 수정키 없는 E 는 보낸다.
    expect(
      isForwardedFromTerminal(
        down(LogicalKeyboardKey.keyE, PhysicalKeyboardKey.keyE),
        kb,
        mac: false,
      ),
      isFalse,
    );
    expect(forwardedFromTerminal, isNot(contains(ShellShortcut.dock1)));
  });
}
