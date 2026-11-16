// 편집기 동작 설정: 들여쓰기 선, 저장할 때 정렬. 글자 크기는 [EditorZoom]이 따로 맡는다.
// (daylight-workbench 의 settings/editor_settings.dart 에서 옮겼다. [Taskbench에서 달라진 곳] 글꼴 이름·색상 구성표를 더했다 — 줄 간격·합자는 아직 없다.)
// 저장은 앱이 들고 있는 SharedPreferences 하나를 주입받는다.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/editor_schemes.dart';

class EditorSettings extends ChangeNotifier {
  EditorSettings(this._prefs)
    : _indentGuides = _prefs.getBool(indentGuidesKey) ?? true,
      _formatOnSave = _prefs.getBool(formatOnSaveKey) ?? false,
      _fontFamily = _nonEmpty(_prefs.getString(fontFamilyKey)),
      _schemeId = _prefs.getString(colorSchemeKey) ?? EditorScheme.followAppId;

  static String? _nonEmpty(String? v) => v == null || v.isEmpty ? null : v;

  /// 저장 키 — 앱 공통 목록(`keys_test`)에 있다.
  static const indentGuidesKey = 'indent_guides';
  static const formatOnSaveKey = 'format_on_save';
  static const fontFamilyKey = 'editor_font_family';
  static const colorSchemeKey = 'editor_color_scheme';

  final SharedPreferences _prefs;
  bool _indentGuides;
  bool _formatOnSave;
  String? _fontFamily;
  String _schemeId;

  /// 들여쓰기 쌍을 깊이별 색의 세로선으로 표시한다. 기본은 켬.
  bool get indentGuides => _indentGuides;

  /// 저장하기 직전에 Dart·JSON·ARB 글을 정렬한다. 기본은 끔.
  bool get formatOnSave => _formatOnSave;

  /// 편집기 글꼴(고정폭). null = 앱 기본 고정폭 글꼴.
  String? get fontFamily => _fontFamily;

  /// 고른 색상 구성표. null = 앱 테마를 따른다.
  EditorScheme? get scheme => EditorScheme.byId(_schemeId);

  /// 저장된 구성표 id ([EditorScheme.followAppId] 면 앱 테마를 따른다).
  String get schemeId => scheme?.id ?? EditorScheme.followAppId;

  Future<void> setFontFamily(String? family) async {
    final v = _nonEmpty(family);
    if (v == _fontFamily) return;
    _fontFamily = v;
    notifyListeners();
    await _store(
      () => v == null ? _prefs.remove(fontFamilyKey) : _prefs.setString(fontFamilyKey, v),
    );
  }

  Future<void> setSchemeId(String id) async {
    if (id == _schemeId) return;
    _schemeId = id;
    notifyListeners();
    await _store(() => _prefs.setString(colorSchemeKey, id));
  }

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
