// 터미널 패널의 글자 크기·스크롤백 설정. 색은 설정 없이 늘 현재 테마를 따른다 ([terminal_theme.dart]).
// [Taskbench에서 달라진 곳] workbench 는 "편집기와 같은 글꼴 쓰기"·글꼴 이름도 있었는데, 내장 에디터가 아직 없어서
// 크기와 스크롤백만 둔다. 저장은 앱이 들고 있는 SharedPreferences 하나를 쓴다.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TerminalSettings extends ChangeNotifier {
  TerminalSettings(this._prefs)
    : _size = (_prefs.getDouble(sizeKey) ?? defaultSize).clamp(
        minSize,
        maxSize,
      ),
      _scrollback = (_prefs.getInt(scrollbackKey) ?? defaultScrollback).clamp(
        minScrollback,
        maxScrollback,
      );

  static const defaultScrollback = 10000;
  static const minScrollback = 500;
  static const maxScrollback = 100000;

  static const minSize = 9.0;
  static const maxSize = 24.0;
  static const defaultSize = 13.0;

  /// 저장 키 — 앱 공통 목록(`keys_test`)에 있다.
  static const sizeKey = 'terminal_font_size';
  static const scrollbackKey = 'terminal_scrollback';

  final SharedPreferences _prefs;
  double _size;
  int _scrollback;

  double get size => _size;
  int get scrollback => _scrollback;

  Future<void> setSize(double value) async {
    final v = value.clamp(minSize, maxSize);
    if (v == _size) return;
    _size = v;
    notifyListeners();
    await _prefs.setDouble(sizeKey, v);
  }

  /// 새로 여는 터미널 탭부터 적용된다 (이미 열린 탭의 줄 수는 그대로).
  Future<void> setScrollback(int value) async {
    final v = value.clamp(minScrollback, maxScrollback);
    if (v == _scrollback) return;
    _scrollback = v;
    notifyListeners();
    await _prefs.setInt(scrollbackKey, v);
  }
}

/// 설정 창이 앱 안 어디서나 같은 코드로 뜨므로(MaterialApp 위의 Navigator) 앱 루트에서 내려보낸다.
class TerminalSettingsScope extends InheritedNotifier<TerminalSettings> {
  const TerminalSettingsScope({
    super.key,
    required TerminalSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static TerminalSettings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TerminalSettingsScope>()
      ?.notifier;
}
