// 확장 패널 상태와 거기서 파생되는 모드 (PLAN.md §1.13).

import 'package:daylight_taskbench/ui/shell/panels/panel_layout.dart';
import 'package:daylight_taskbench/window/window_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PanelLayout> _layout([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return PanelLayout(await SharedPreferences.getInstance());
}

void main() {
  test('패널이 하나도 없으면 도킹 모드다', () async {
    final p = await _layout();
    expect(p.expanded, isFalse);
    expect(p.center, isNull);
    expect(p.hasCenter, isFalse);
  });

  test('탐색기·에디터·터미널 중 하나라도 켜면 확장 모드다', () async {
    for (final turnOn in <void Function(PanelLayout)>[
      (p) => p.setExplorer(true),
      (p) => p.setEditor(true),
      (p) => p.setTerminal(true),
    ]) {
      final p = await _layout();
      turnOn(p);
      expect(p.expanded, isTrue);
    }
  });

  test('모두 끄면 도킹 모드로 돌아간다', () async {
    final p = await _layout();
    p
      ..setExplorer(true)
      ..setTerminal(true);
    expect(p.expanded, isTrue);
    p
      ..setExplorer(false)
      ..setTerminal(false);
    expect(p.expanded, isFalse);
  });

  test('에디터만 끄면 터미널만, 둘 다 끄면 가운데가 없다 (탐색기는 그대로)', () async {
    final p = await _layout();
    p
      ..setExplorer(true)
      ..setEditor(true)
      ..setTerminal(true);
    expect(p.canSwitchCenter, isTrue);
    p.setEditor(false);
    expect(p.center, CenterView.terminal);
    expect(p.canSwitchCenter, isFalse);
    p.setTerminal(false);
    expect(p.center, isNull);
    expect(p.explorer, isTrue);
    expect(p.expanded, isTrue); // 탐색기만 남아도 확장
  });

  test('탐색기 없이 터미널만 켜는 조합을 허용한다', () async {
    final p = await _layout();
    p.setTerminal(true);
    expect(p.explorer, isFalse);
    expect(p.center, CenterView.terminal);
    expect(p.expanded, isTrue);
  });

  test('에디터와 터미널은 전환형이다: 마지막으로 켠·고른 쪽이 보인다', () async {
    final p = await _layout();
    p.setEditor(true);
    expect(p.center, CenterView.editor);
    p.setTerminal(true);
    expect(p.center, CenterView.terminal); // 방금 켠 쪽
    p.showCenter(CenterView.editor);
    expect(p.center, CenterView.editor);
  });

  test('전환 단추는 둘 다 켜져 있을 때만 동작한다', () async {
    final p = await _layout();
    p.setEditor(true);
    p.showCenter(CenterView.terminal);
    expect(p.center, CenterView.editor);
  });

  test('내장 에디터를 끄면 에디터 패널이 보이지 않는다 (켜 둔 값은 남는다)', () async {
    final p = await _layout();
    p.setEditor(true);
    expect(p.expanded, isTrue);
    p.setEmbeddedEditor(false);
    expect(p.editor, isTrue);
    expect(p.editorShown, isFalse);
    expect(p.expanded, isFalse);
    p.setTerminal(true);
    expect(p.center, CenterView.terminal);
    p.setEmbeddedEditor(true);
    expect(p.canSwitchCenter, isTrue);
  });

  test('저장했다가 다시 읽는다 — 시작 모드도 거기서 정해진다', () async {
    final p = await _layout();
    p
      ..setExplorer(true)
      ..setEditor(true)
      ..setTerminal(true)
      ..showCenter(CenterView.editor);
    final prefs = await SharedPreferences.getInstance();
    final again = PanelLayout(prefs);
    expect(again.explorer && again.editor && again.terminal, isTrue);
    expect(again.center, CenterView.editor);
    expect(PanelLayout.startsExpanded(prefs), isTrue);
  });

  test('알 수 없는 저장값은 기본(에디터)으로 읽는다', () async {
    final p = await _layout({'panel_center': 'nope', 'panel_editor': true, 'panel_terminal': true});
    expect(p.center, CenterView.editor);
  });

  test('창 크기 모드: 도킹 / 탐색기만(가운데 자리 없음) / 가운데가 있는 전체', () async {
    final p = await _layout();
    expect(p.windowMode, WindowMode.dock);
    p.setExplorer(true);
    expect(p.windowMode, WindowMode.explorer); // 탐색기만 — 창도 그만큼만
    p.setTerminal(true);
    expect(p.windowMode, WindowMode.expanded);
    p.setTerminal(false);
    expect(p.windowMode, WindowMode.explorer);
    p.setExplorer(false);
    p.setEditor(true);
    expect(p.windowMode, WindowMode.expanded); // 탐색기 없이 에디터만이어도 가운데가 있다
    p.setEmbeddedEditor(false); // 내장 에디터를 끄면 가운데가 사라진다
    expect(p.windowMode, WindowMode.dock);
  });

  test('바뀔 때만 알린다', () async {
    final p = await _layout();
    var n = 0;
    p.addListener(() => n++);
    p.setExplorer(false); // 이미 꺼짐
    expect(n, 0);
    p.setExplorer(true);
    p.setExplorer(true);
    expect(n, 1);
  });
}
