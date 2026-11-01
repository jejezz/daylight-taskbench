// 에디터 배율: Ctrl/Cmd + 휠, 트랙패드 두 손가락 쓸기·핀치 (ZoomWheel).

import 'package:daylight_taskbench/editor/editor_zoom.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late EditorZoom zoom;
  final scroll = ScrollController();

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    zoom = EditorZoom(await SharedPreferences.getInstance());
    addTearDown(zoom.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: EditorZoomScope(
          zoom: zoom,
          child: ZoomWheel(
            scrollers: [scroll],
            child: ListView(
              controller: scroll,
              children: [
                for (var i = 0; i < 100; i++)
                  SizedBox(height: 40, child: Text('line $i')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> swipe(
    WidgetTester tester,
    Offset total, {
    double scale = 1,
  }) async {
    final p = TestPointer(1, PointerDeviceKind.trackpad);
    const at = Offset(200, 200);
    await tester.sendEventToBinding(p.panZoomStart(at));
    const n = 8;
    for (var i = 1; i <= n; i++) {
      await tester.sendEventToBinding(
        p.panZoomUpdate(
          at,
          pan: total * (i / n),
          scale: 1 + (scale - 1) * i / n,
        ),
      );
    }
    await tester.sendEventToBinding(p.panZoomEnd());
    await tester.pump();
  }

  testWidgets('Ctrl + 트랙패드 두 손가락 위로 쓸기: 확대하고 스크롤은 움직이지 않는다', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await swipe(tester, const Offset(0, -120)); // 120 / 24 = 5단계
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(zoom.percent, 150);
    expect(scroll.offset, 0);
  });

  testWidgets('Cmd + 트랙패드 아래로 쓸기: 축소', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await swipe(tester, const Offset(0, 48));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(zoom.percent, 80);
  });

  testWidgets('수정키 없이 쓸기는 배율을 바꾸지 않는다', (tester) async {
    await pump(tester);
    await swipe(tester, const Offset(0, -240));
    expect(zoom.percent, 100);
  });

  testWidgets('Ctrl + 핀치: 배율에 곱한다', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await swipe(tester, Offset.zero, scale: 1.5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(zoom.percent, 150);
  });

  testWidgets('Ctrl + 마우스 휠은 그대로 동작한다', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final mouse = TestPointer(2, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(const Offset(200, 200)));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -40)));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -40)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(zoom.percent, 120);
    expect(scroll.offset, 0);
  });
}
