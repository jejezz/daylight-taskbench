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

/// Ctrl(macOS는 Cmd)을 누른 채 마우스 휠을 굴리거나 트랙패드를 두 손가락으로 쓸면 배율을 바꾼다.
///
/// 트랙패드의 두 손가락 쓸기는 휠(`PointerScrollEvent`)이 아니라 `PointerPanZoom*` 이벤트로 온다 — 휠만 보면 트랙패드에서는
/// 아무 일도 안 일어난다. 쓸기는 [panStep] 픽셀마다 한 단계씩 바꾸고(이벤트가 아주 잦아서 그대로 쓰면 너무 빠르다), 핀치(`scale`)도
/// 시작 때의 배율에 누적 배율을 곱해 반영한다.
///
/// 스크롤 가능한 자식은 같은 이벤트로 스스로 스크롤하므로, 배율을 바꾸는 동안에는 [scrollers]의 위치를 이벤트가 끝난 직후
/// 원래대로 돌려 놓는다.
class ZoomWheel extends StatefulWidget {
  const ZoomWheel({super.key, this.scrollers = const [], required this.child});

  final List<ScrollController> scrollers;
  final Widget child;

  /// 트랙패드로 쓸어서 한 단계(10%)를 바꾸는 데 필요한 거리.
  static const panStep = 24.0;

  @override
  State<ZoomWheel> createState() => _ZoomWheelState();
}

class _ZoomWheelState extends State<ZoomWheel> {
  Map<ScrollController, double> _saved = const {};
  bool _zooming = false;
  double _panned = 0;
  double? _pinchBase;

  static bool get _modifier {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  Map<ScrollController, double> _snapshot() => {
    for (final c in widget.scrollers)
      if (c.hasClients) c: c.offset,
  };

  /// 스크롤 위젯이 이 이벤트를 처리한 뒤(같은 이벤트 처리가 끝난 직후, 다음 프레임 전)에 되돌린다.
  void _restoreAfterEvent() {
    final saved = _saved;
    scheduleMicrotask(() {
      saved.forEach((c, offset) {
        if (c.hasClients && c.offset != offset) c.jumpTo(offset);
      });
    });
  }

  void _wheel(PointerSignalEvent event) {
    final zoom = EditorZoomScope.maybeOf(context);
    if (zoom == null || event is! PointerScrollEvent || !_modifier) return;
    _saved = _snapshot();
    if (event.scrollDelta.dy < 0) {
      zoom.zoomIn();
    } else if (event.scrollDelta.dy > 0) {
      zoom.zoomOut();
    }
    _restoreAfterEvent();
  }

  void _panZoomStart(PointerPanZoomStartEvent event) {
    _zooming = _modifier;
    _panned = 0;
    _pinchBase = null;
    if (_zooming) _saved = _snapshot();
  }

  void _panZoomUpdate(PointerPanZoomUpdateEvent event) {
    final zoom = EditorZoomScope.maybeOf(context);
    if (zoom == null) return;
    // 도중에 키를 눌렀다 떼도 따라간다: 시작 때 수정키가 없었어도 지금 눌려 있으면 배율 쪽으로 넘어간다.
    if (!_zooming && _modifier) {
      _zooming = true;
      _saved = _snapshot();
    }
    if (!_zooming) return;
    // 핀치: 시작할 때의 배율에 누적 배율을 곱한다 (이벤트마다 곱하면 반올림 오차가 쌓인다).
    if (event.scale != 1) {
      _pinchBase ??= zoom.value;
      zoom.setValue(_pinchBase! * event.scale);
    }
    // 쓸기: 위로(dy<0) 확대, 아래로 축소. 마우스 휠과 같은 방향.
    _panned += event.panDelta.dy;
    while (_panned <= -ZoomWheel.panStep) {
      zoom.zoomIn();
      _panned += ZoomWheel.panStep;
    }
    while (_panned >= ZoomWheel.panStep) {
      zoom.zoomOut();
      _panned -= ZoomWheel.panStep;
    }
    _restoreAfterEvent();
  }

  void _panZoomEnd(PointerPanZoomEndEvent event) {
    _restoreAfterEvent();
    _zooming = false;
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _wheel,
    onPointerPanZoomStart: _panZoomStart,
    onPointerPanZoomUpdate: _panZoomUpdate,
    onPointerPanZoomEnd: _panZoomEnd,
    child: widget.child,
  );
}
