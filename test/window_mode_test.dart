// 모드별 창 크기 계산 (PLAN.md §1.13). 화면에 아무것도 하지 않는 순수 함수만 본다.

import 'dart:ui';

import 'package:daylight_taskbench/window/window_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const work = Rect.fromLTWH(0, 25, 1600, 875);

  group('anchoredRight — 도크 열이 있는 오른쪽 가장자리를 고정하고 왼쪽으로 늘어난다', () {
    test('확장: 오른쪽 가장자리가 그대로다', () {
      const current = Rect.fromLTWH(1100, 50, 440, 960);
      final r = WindowModeMath.anchoredRight(
        current,
        const Size(1240, 820),
        work: work,
      );
      expect(r.right, current.right.clamp(work.left + 1240, work.right));
      expect(r.width, 1240);
    });

    test('왼쪽이 화면 밖으로 나가면 화면 안으로 민다', () {
      const current = Rect.fromLTWH(300, 50, 440, 700);
      final r = WindowModeMath.anchoredRight(
        current,
        const Size(1240, 600),
        work: work,
      );
      expect(r.left, greaterThanOrEqualTo(work.left));
      expect(r.right, lessThanOrEqualTo(work.right));
      expect(r.width, 1240);
    });

    test('작업 영역보다 크면 줄인다', () {
      const current = Rect.fromLTWH(0, 25, 440, 960);
      final r = WindowModeMath.anchoredRight(
        current,
        const Size(2400, 1200),
        work: work,
      );
      expect(r.width, work.width);
      expect(r.height, work.height);
      expect(r.left, work.left);
    });

    test('도킹으로 돌아오면 오른쪽 가장자리를 유지한 채 줄어든다', () {
      const current = Rect.fromLTWH(360, 80, 1240, 820);
      final r = WindowModeMath.anchoredRight(
        current,
        const Size(440, 960),
        work: work,
      );
      expect(r.right, current.right);
      expect(r.width, 440);
    });

    test('모니터 정보가 없어도 계산한다', () {
      final r = WindowModeMath.anchoredRight(
        const Rect.fromLTWH(100, 100, 440, 900),
        const Size(1240, 820),
      );
      expect(r.right, 540);
      expect(r.width, 1240);
    });
  });

  group('sanitize — 저장한 크기가 이상하면 기본으로 돌린다', () {
    test('없거나 최소보다 작으면 기본 크기', () {
      expect(WindowModeMath.sanitize(null, dockSpec), dockSpec.size);
      expect(
        WindowModeMath.sanitize(const Size(200, 200), expandedSpec),
        expandedSpec.size,
      );
      expect(
        WindowModeMath.sanitize(const Size(double.nan, 600), dockSpec),
        dockSpec.size,
      );
    });

    test('정상이면 그대로', () {
      expect(
        WindowModeMath.sanitize(const Size(1000, 700), expandedSpec),
        const Size(1000, 700),
      );
    });
  });

  group('target — 모드가 바뀌어도 높이는 그대로, 너비만 그 모드의 것', () {
    test('저장한 너비가 있으면 그것, 높이는 지금 높이', () {
      final t = WindowModeMath.target(
        savedWidth: 1100,
        currentHeight: 700,
        spec: expandedSpec,
      );
      expect(t, const Size(1100, 700));
    });

    test('저장한 너비가 없거나 이상하면 그 모드의 기본 너비', () {
      expect(
        WindowModeMath.target(
          savedWidth: null,
          currentHeight: 700,
          spec: expandedSpec,
        ).width,
        expandedSpec.size.width,
      );
      expect(
        WindowModeMath.target(
          savedWidth: 100,
          currentHeight: 700,
          spec: expandedSpec,
        ).width,
        expandedSpec.size.width,
      );
      expect(
        WindowModeMath.target(
          savedWidth: double.nan,
          currentHeight: 700,
          spec: dockSpec,
        ).width,
        dockSpec.size.width,
      );
    });

    test('높이는 그 모드의 최소 높이보다 작아지지 않는다', () {
      expect(
        WindowModeMath.target(
          savedWidth: null,
          currentHeight: 300,
          spec: dockSpec,
        ).height,
        dockSpec.minimum.height,
      );
    });

    test('탐색기만 → 전체: 높이가 바뀌지 않는다 (기본 높이로 되돌아가지 않는다)', () {
      final t = WindowModeMath.target(
        savedWidth: null,
        currentHeight: 640,
        spec: expandedSpec,
      );
      expect(t.height, 640);
      expect(t.height, isNot(expandedSpec.size.height));
    });
  });

  test('parseSize', () {
    expect(WindowModeMath.parseSize('440.0,960.0'), const Size(440, 960));
    expect(WindowModeMath.parseSize('abc'), isNull);
    expect(WindowModeMath.parseSize('1,2,3'), isNull);
    expect(WindowModeMath.parseSize(null), isNull);
  });

  test('탐색기만 켠 창은 탐색기 240 + 도크 열 440 이상이다', () {
    expect(explorerSpec.minimum.width, greaterThanOrEqualTo(240 + 440));
    expect(explorerSpec.size.width, lessThan(expandedSpec.size.width));
  });

  test('도크 열 440 + 확장 영역이 들어가도록 확장 최소 폭을 정했다', () {
    expect(expandedSpec.minimum.width, greaterThanOrEqualTo(440 + 240 + 270));
    expect(dockSpec.minimum, const Size(380, 560)); // PLAN §1.5 그대로
  });

  group('도킹 창 위치 기억 (macOS)', () {
    const screens = [Rect.fromLTWH(0, 25, 1600, 875)];
    const size = Size(440, 960);

    test('모니터 안의 위치는 그대로 쓴다', () {
      expect(WindowModeMath.positionVisible(const Offset(1100, 40), size, screens), isTrue);
    });

    test('거의 화면 밖(가로 100 미만만 걸침)이면 쓰지 않는다 — 모니터를 뗐을 때', () {
      expect(WindowModeMath.positionVisible(const Offset(1550, 40), size, screens), isFalse);
      expect(WindowModeMath.positionVisible(const Offset(3000, 40), size, screens), isFalse);
      expect(WindowModeMath.positionVisible(const Offset(100, 880), size, screens), isFalse);
    });

    test('다른 모니터에 걸쳐 있으면 그 모니터 기준으로 본다', () {
      const two = [Rect.fromLTWH(0, 25, 1600, 875), Rect.fromLTWH(1600, 0, 1920, 1080)];
      expect(WindowModeMath.positionVisible(const Offset(2000, 100), size, two), isTrue);
    });

    test('저장한 위치를 읽고, 이상한 값은 무시한다', () async {
      SharedPreferences.setMockInitialValues({WindowModeController.dockPosKey: '120.5,48'});
      var c = WindowModeController(await SharedPreferences.getInstance());
      expect(c.savedPosition, const Offset(120.5, 48));
      SharedPreferences.setMockInitialValues({WindowModeController.dockPosKey: 'x,y'});
      c = WindowModeController(await SharedPreferences.getInstance());
      expect(c.savedPosition, isNull);
      SharedPreferences.setMockInitialValues({});
      c = WindowModeController(await SharedPreferences.getInstance());
      expect(c.savedPosition, isNull);
    });
  });
}
