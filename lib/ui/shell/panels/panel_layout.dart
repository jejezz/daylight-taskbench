// 확장 패널(탐색기·에디터·터미널)의 켜짐 상태와 거기서 **파생되는 모드** (PLAN.md §1.13).
// 도킹 모드는 설정값이 아니다 — 패널이 하나라도 보이면 확장, 하나도 없으면 도킹이다.
// 상태는 여기 하나에만 두고 셸·창 크기 조절·설정 창이 읽는다.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 가운데 영역에 보이는 것. 에디터와 터미널은 동시에 보이지 않고 서로 전환된다.
enum CenterView { editor, terminal }

class PanelLayout extends ChangeNotifier {
  PanelLayout(this._prefs)
    : _explorer = _prefs.getBool(explorerKey) ?? false,
      _editor = _prefs.getBool(editorKey) ?? false,
      _terminal = _prefs.getBool(terminalKey) ?? false,
      _embeddedEditor = _prefs.getBool(embeddedEditorKey) ?? true,
      _preferred =
          CenterView.values.asNameMap()[_prefs.getString(centerKey)] ??
          CenterView.editor;

  /// 저장 키 — 앱 공통 목록(`keys_test`)에 있다.
  static const explorerKey = 'panel_explorer';
  static const editorKey = 'panel_editor';
  static const terminalKey = 'panel_terminal';
  static const centerKey = 'panel_center';
  static const embeddedEditorKey = 'editor_embedded';

  final SharedPreferences _prefs;
  bool _explorer;
  bool _editor;
  bool _terminal;
  bool _embeddedEditor;
  CenterView _preferred;

  /// 창을 만들기 전에(저장된 값만으로) 확장 모드로 시작할지 안다.
  static bool startsExpanded(SharedPreferences prefs) =>
      PanelLayout(prefs).expanded;

  bool get explorer => _explorer;

  /// 에디터 패널을 켜 두었는지. 내장 에디터를 끄면 켜 둔 값이 있어도 보이지 않는다.
  bool get editor => _editor;
  bool get terminal => _terminal;

  /// 설정 "내장 에디터 사용". 끄면 에디터 패널이 없고 파일은 외부 VS Code로 열린다.
  bool get embeddedEditor => _embeddedEditor;

  bool get editorShown => _editor && _embeddedEditor;
  bool get terminalShown => _terminal;
  bool get hasCenter => editorShown || terminalShown;

  /// 가운데에 지금 보이는 것. 둘 다 켜져 있으면 마지막으로 고른 쪽, 없으면 null.
  CenterView? get center {
    if (editorShown && terminalShown) return _preferred;
    if (editorShown) return CenterView.editor;
    if (terminalShown) return CenterView.terminal;
    return null;
  }

  /// 에디터와 터미널이 둘 다 켜져 있어 전환 단추가 필요한 상태.
  bool get canSwitchCenter => editorShown && terminalShown;

  /// 확장 모드 = 보이는 패널이 하나라도 있음. 아니면 도킹 모드다.
  bool get expanded => _explorer || hasCenter;

  void setExplorer(bool on) {
    if (on == _explorer) return;
    _explorer = on;
    _prefs.setBool(explorerKey, on);
    notifyListeners();
  }

  /// 켜면 가운데에 바로 그 패널이 나타난다 (마지막 선택으로 기억).
  void setEditor(bool on) {
    if (on == _editor) return;
    _editor = on;
    _prefs.setBool(editorKey, on);
    if (on) _remember(CenterView.editor);
    notifyListeners();
  }

  void setTerminal(bool on) {
    if (on == _terminal) return;
    _terminal = on;
    _prefs.setBool(terminalKey, on);
    if (on) _remember(CenterView.terminal);
    notifyListeners();
  }

  /// 가운데 전환 단추. 둘 다 켜져 있지 않으면 아무 일도 하지 않는다.
  void showCenter(CenterView view) {
    if (!canSwitchCenter || view == _preferred) return;
    _remember(view);
    notifyListeners();
  }

  void setEmbeddedEditor(bool on) {
    if (on == _embeddedEditor) return;
    _embeddedEditor = on;
    _prefs.setBool(embeddedEditorKey, on);
    notifyListeners();
  }

  void _remember(CenterView view) {
    _preferred = view;
    _prefs.setString(centerKey, view.name);
  }
}

class PanelLayoutScope extends InheritedNotifier<PanelLayout> {
  const PanelLayoutScope({
    super.key,
    required PanelLayout panels,
    required super.child,
  }) : super(notifier: panels);

  static PanelLayout of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PanelLayoutScope>()!.notifier!;

  static PanelLayout? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PanelLayoutScope>()
      ?.notifier;
}
