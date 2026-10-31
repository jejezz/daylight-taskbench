import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/theme/taskbench_style.dart';
import 'package:daylight_taskbench/ui/style/aurora_background.dart';
import 'package:daylight_taskbench/ui/style/glass_card.dart';
import 'package:daylight_taskbench/ui/style/pulse_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('색 구성 6종 모두 TaskbenchStyle 을 갖고, 주색에서 파생한다', () {
    for (final p in ColorPalette.values) {
      for (final theme in [AppTheme.dark(palette: p), AppTheme.light(palette: p)]) {
        final style = theme.extension<TaskbenchStyle>()!;
        expect(style.accent, theme.colorScheme.primary, reason: '$p');
        expect(style.enabled, p != ColorPalette.highContrast, reason: '$p');
      }
    }
  });

  test('고대비에서는 장식이 꺼지고 카드는 평평한 면이다', () {
    final s = AppTheme.dark(palette: ColorPalette.highContrast).extension<TaskbenchStyle>()!;
    expect(s.enabled, isFalse);
    expect(s.cardTop, s.cardBottom);
  });

  test('ThemeData.dividerColor 가 팔레트 값이다 (settings.md)', () {
    for (final p in ColorPalette.values) {
      final t = AppTheme.dark(palette: p);
      expect(t.dividerColor, t.colorScheme.outlineVariant);
    }
  });

  Widget host(Widget child, {bool reduce = false, ColorPalette palette = ColorPalette.saturn}) => MaterialApp(
        theme: AppTheme.dark(palette: palette),
        builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: w!),
        home: Scaffold(body: child),
      );

  testWidgets('GlassCard: 활성이면 글로우(BoxShadow)가 붙고, 고대비에서는 붙지 않는다', (tester) async {
    BoxDecoration deco() => tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;
    await tester.pumpWidget(host(const GlassCard(active: true, child: SizedBox(width: 50, height: 50))));
    expect(deco().boxShadow, isNotEmpty);
    await tester.pumpWidget(host(const GlassCard(child: SizedBox(width: 50, height: 50))));
    await tester.pumpAndSettle();
    expect(deco().boxShadow, isEmpty);
    await tester.pumpWidget(host(const GlassCard(active: true, child: SizedBox(width: 50, height: 50)), palette: ColorPalette.highContrast));
    await tester.pumpAndSettle();
    expect(deco().boxShadow, isEmpty);
  });

  testWidgets('"동작 줄이기"에서는 맥박 점이 돌지 않는다', (tester) async {
    await tester.pumpWidget(host(const PulseDot(color: Colors.green, pulsing: true), reduce: true));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(host(const PulseDot(color: Colors.green, pulsing: true)));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(host(const SizedBox())); // 정리
  });

  testWidgets('AuroraBackground: 고대비는 평평한 색, 그 밖에는 그라디언트', (tester) async {
    await tester.pumpWidget(host(const AuroraBackground(child: SizedBox.expand())));
    final wash = find.descendant(of: find.byType(AuroraBackground), matching: find.byType(AnimatedContainer));
    expect(wash, findsOneWidget);
    await tester.pumpWidget(host(const AuroraBackground(child: SizedBox.expand()), palette: ColorPalette.highContrast));
    await tester.pumpAndSettle(); // 테마가 바뀌는 전환이 끝난 뒤
    expect(wash, findsNothing);
  });
}
