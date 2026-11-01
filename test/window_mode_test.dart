// 모드별 창 크기 계산 (PLAN.md §1.13). 화면에 아무것도 하지 않는 순수 함수만 본다.

import 'dart:ui';

import 'package:daylight_taskbench/window/window_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const work = Rect.fromLTWH(0, 25, 1600, 875);

  group('anchoredRight — 도크 열이 있는 오른쪽 가장자리를 고정하고 왼쪽으로 늘어난다', () {
    test('확장: 오른쪽 가장자리가 그대로다', () {
      const current = Rect.fromLTWH(1100, 50, 440, 960);
      final r = WindowModeMath.anchoredRight(current, const Size(1240, 820), work: work);
      expect(r.right, current.right.clamp(work.left + 1240, work.right));
      expect(r.width, 1240);
    });

    test('왼쪽이 화면 밖으로 나가면 화면 안으로 민다', () {
      const current = Rect.fromLTWH(300, 50, 440, 700);
      final r = WindowModeMath.anchoredRight(current, const Size(1240, 600), work: work);
      expect(r.left, greaterThanOrEqualTo(work.left));
      expect(r.right, lessThanOrEqualTo(work.right));
      expect(r.width, 1240);
    });

    test('작업 영역보다 크면 줄인다', () {
      const current = Rect.fromLTWH(0, 25, 440, 960);
      final r = WindowModeMath.anchoredRight(current, const Size(2400, 1200), work: work);
      expect(r.width, work.width);
      expect(r.height, work.height);
      expect(r.left, work.left);
    });

    test('도킹으로 돌아오면 오른쪽 가장자리를 유지한 채 줄어든다', () {
      const current = Rect.fromLTWH(360, 80, 1240, 820);
      final r = WindowModeMath.anchoredRight(current, const Size(440, 960), work: work);
      expect(r.right, current.right);
      expect(r.width, 440);
    });

    test('모니터 정보가 없어도 계산한다', () {
      final r = WindowModeMath.anchoredRight(const Rect.fromLTWH(100, 100, 440, 900), const Size(1240, 820));
      expect(r.right, 540);
      expect(r.width, 1240);
    });
  });

  group('sanitize — 저장한 크기가 이상하면 기본으로 돌린다', () {
    test('없거나 최소보다 작으면 기본 크기', () {
      expect(WindowModeMath.sanitize(null, dockSpec), dockSpec.size);
      expect(WindowModeMath.sanitize(const Size(200, 200), expandedSpec), expandedSpec.size);
      expect(WindowModeMath.sanitize(const Size(double.nan, 600), dockSpec), dockSpec.size);
    });

    test('정상이면 그대로', () {
      expect(WindowModeMath.sanitize(const Size(1000, 700), expandedSpec), const Size(1000, 700));
    });
  });

  test('parseSize', () {
    expect(WindowModeMath.parseSize('440.0,960.0'), const Size(440, 960));
    expect(WindowModeMath.parseSize('abc'), isNull);
    expect(WindowModeMath.parseSize('1,2,3'), isNull);
    expect(WindowModeMath.parseSize(null), isNull);
  });

  test('도크 열 440 + 확장 영역이 들어가도록 확장 최소 폭을 정했다', () {
    expect(expandedSpec.minimum.width, greaterThanOrEqualTo(440 + 240 + 270));
    expect(dockSpec.minimum, const Size(380, 560)); // PLAN §1.5 그대로
  });
}
