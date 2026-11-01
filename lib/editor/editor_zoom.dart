// daylight-workbench 의 theme/editor_zoom.dart 를 옮겼다.
// [Taskbench에서 달라진 곳] 저장은 앱이 들고 있는 SharedPreferences 하나를 주입받는다(처음부터 값을 안다).

/// 편집기 글자 크기 배율. Ctrl+스크롤, Ctrl+`+`/`-`/`0`으로 바꾸고, 다음 실행에도 유지한다.
///
/// 배율은 편집기 본문·줄 번호·Markdown 보기에만 곱한다 (앱 나머지 글자는 그대로).
/// 나중에 편집기 글꼴 이름·줄 간격 설정(PLAN.md "IDE 테마")을 이 옆에 붙인다.
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditorZoom extends ChangeNotifier {
  EditorZoom(this._prefs) {
    final saved = _prefs.getDouble(key);
    if (saved != null) _value = ((saved.clamp(min, max)) * 100).round() / 100;
  }

  /// 저장 키 — 앱 공통 목록(`keys_test`)에 있다.
  static const key = 'editor_zoom';
  static const min = 0.6;
  static const max = 3.0;
  static const step = 0.1;

  final SharedPreferences _prefs;
  double _value = 1;

  /// 1.0이 기본 크기.
  double get value => _value;

  int get percent => (_value * 100).round();

  bool get isDefault => _value == 1;

  void zoomIn() => _set(_value + step);

  void zoomOut() => _set(_value - step);

  void reset() => _set(1);

  /// 설정 화면의 슬라이더처럼 값을 직접 정할 때. 범위 밖이면 가장 가까운 값으로 맞춘다.
  void setValue(double value) => _set(value);

  void _set(double next, {bool save = true}) {
    // 0.1 단위로 맞춘다 (부동소수 오차가 쌓이지 않게).
    final clamped = ((next.clamp(min, max)) * 100).round() / 100;
    if (clamped == _value) return;
    _value = clamped;
    notifyListeners();
    if (save) _persist();
  }

  Future<void> _persist() async {
    try {
      await _prefs.setDouble(key, _value);
    } on Object {
      // 저장하지 못해도 이번 실행에는 적용된다.
    }
  }
}

/// 화면 아래쪽 위젯이 [EditorZoom]을 읽고, 값이 바뀌면 다시 그려지게 한다.
class EditorZoomScope extends InheritedNotifier<EditorZoom> {
  const EditorZoomScope({
    super.key,
    required EditorZoom zoom,
    required super.child,
  }) : super(notifier: zoom);

  /// 범위 밖(테스트 등)이면 null.
  static EditorZoom? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorZoomScope>()?.notifier;

  /// 지금 배율. 범위 밖이면 1.
  static double scaleOf(BuildContext context) => maybeOf(context)?.value ?? 1;
}

/// Ctrl(macOS는 Cmd)을 누른 채 마우스 휠을 굴리면 배율을 바꾼다.
///
/// 스크롤 가능한 자식은 같은 휠 이벤트로 스스로 스크롤하므로, 배율을 바꾸는 휠에서는
/// [scrollers]의 위치를 이벤트가 끝난 직후 원래대로 돌려 놓는다.
class ZoomWheel extends StatelessWidget {
  const ZoomWheel({super.key, this.scrollers = const [], required this.child});

  final List<ScrollController> scrollers;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final zoom = EditorZoomScope.maybeOf(context);
    return Listener(
      onPointerSignal: (event) {
        if (zoom == null || event is! PointerScrollEvent) return;
        final keyboard = HardwareKeyboard.instance;
        if (!keyboard.isControlPressed && !keyboard.isMetaPressed) return;
        final saved = <ScrollController, double>{
          for (final c in scrollers)
            if (c.hasClients) c: c.offset,
        };
        if (event.scrollDelta.dy < 0) {
          zoom.zoomIn();
        } else if (event.scrollDelta.dy > 0) {
          zoom.zoomOut();
        }
        // 스크롤 위젯이 이 이벤트를 처리한 뒤(같은 이벤트 처리가 끝난 직후, 다음 프레임 전)에 되돌린다.
        scheduleMicrotask(() {
          saved.forEach((c, offset) {
            if (c.hasClients && c.offset != offset) c.jumpTo(offset);
          });
        });
      },
      child: child,
    );
  }
}
