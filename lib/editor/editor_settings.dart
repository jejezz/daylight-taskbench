// 편집기 동작 설정: 들여쓰기 선, 저장할 때 정렬. 글자 크기는 [EditorZoom]이 따로 맡는다.
// (daylight-workbench 의 settings/editor_settings.dart 에서 이 두 가지만 옮겼다 — 글꼴 이름·줄 간격·합자는 아직 없다.)
// 저장은 앱이 들고 있는 SharedPreferences 하나를 주입받는다.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditorSettings extends ChangeNotifier {
  EditorSettings(this._prefs)
    : _indentGuides = _prefs.getBool(indentGuidesKey) ?? true,
      _formatOnSave = _prefs.getBool(formatOnSaveKey) ?? false;

  /// 저장 키 — 앱 공통 목록(`keys_test`)에 있다.
  static const indentGuidesKey = 'indent_guides';
  static const formatOnSaveKey = 'format_on_save';

  final SharedPreferences _prefs;
  bool _indentGuides;
  bool _formatOnSave;

  /// 들여쓰기 쌍을 깊이별 색의 세로선으로 표시한다. 기본은 켬.
  bool get indentGuides => _indentGuides;

  /// 저장하기 직전에 Dart·JSON·ARB 글을 정렬한다. 기본은 끔.
  bool get formatOnSave => _formatOnSave;

  Future<void> setIndentGuides(bool value) async {
    if (value == _indentGuides) return;
    _indentGuides = value;
    notifyListeners();
    await _store(() => _prefs.setBool(indentGuidesKey, value));
  }

  Future<void> setFormatOnSave(bool value) async {
    if (value == _formatOnSave) return;
    _formatOnSave = value;
    notifyListeners();
    await _store(() => _prefs.setBool(formatOnSaveKey, value));
  }

  Future<void> _store(Future<bool> Function() write) async {
    try {
      await write();
    } on Object {
      // 저장하지 못해도 이번 실행에는 적용된다.
    }
  }
}

/// 설정 창이 앱 안 어디서나 같은 코드로 뜨므로(MaterialApp 위의 Navigator) 앱 루트에서 내려보낸다.
class EditorSettingsScope extends InheritedNotifier<EditorSettings> {
  const EditorSettingsScope({
    super.key,
    required EditorSettings settings,
    required super.child,
  }) : super(notifier: settings);

  /// 범위 밖(테스트 등)이면 null.
  static EditorSettings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EditorSettingsScope>()
      ?.notifier;
}
