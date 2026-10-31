import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/settings/settings_dialog.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _pump(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  final settings = await AppSettings.load();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppSettingsScope(
    settings: settings,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SettingsDialog()),
    ),
  ));
  await tester.pumpAndSettle();
  return settings;
}

void main() {
  testWidgets('도킹 크기(480×480)에서 오버플로 없이 뜨고, 구역은 위쪽 칩이다', (tester) async {
    await _pump(tester, const Size(480, 480));
    expect(tester.takeException(), isNull);
    expect(find.byType(ChoiceChip), findsNWidgets(2 + 6)); // 구역 칩 둘 + 색 구성 칩 여섯
    expect(find.byType(VerticalDivider), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, '언어'));
    await tester.pumpAndSettle();
    expect(find.text('한국어'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('가장 좁은 창(380×560)과 낮은 창(440×300)에서도 넘치지 않는다', (tester) async {
    for (final size in const [Size(380, 560), Size(440, 300)]) {
      await _pump(tester, size);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('넓은 창(1000×700)에서는 왼쪽 구역 목록이다', (tester) async {
    await _pump(tester, const Size(1000, 700));
    expect(find.byType(VerticalDivider), findsOneWidget);
    await tester.tap(find.text('언어'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('선택지를 누르면 바로 바뀌고 규약 키로 저장된다', (tester) async {
    final settings = await _pump(tester, const Size(480, 560));
    await tester.tap(find.text('청록'));
    await tester.pump();
    expect(settings.palette, ColorPalette.teal);
    await tester.tap(find.text('크게'));
    await tester.pump();
    expect(settings.textScale, 1.15);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(settings.stateTint, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_palette'), 'teal');
    expect(prefs.getDouble('text_scale'), 1.15);
    expect(prefs.getBool('style_state_tint'), isFalse);
    // 규약 키는 그대로 읽는다
    final reloaded = await AppSettings.load();
    expect(reloaded.palette, ColorPalette.teal);
    expect(reloaded.textScale, 1.15);
  });

  test('알 수 없는 저장값은 기본값으로 돌아간다', () async {
    SharedPreferences.setMockInitialValues({'theme_palette': 'nope', 'text_scale': 3.0, 'theme_mode': 'x'});
    final s = await AppSettings.load();
    expect(s.palette, ColorPalette.saturn);
    expect(s.textScale, 1.0);
    expect(s.stateTint, isTrue);
  });
}
