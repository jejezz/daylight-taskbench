import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/settings/settings_dialog.dart';
import 'package:daylight_taskbench/settings/system_fonts.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _pump(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  // 테스트에서 OS 에 글꼴을 묻지 않는다 (진짜 프로세스 실행이 fake async 안에서 멈춘다).
  SystemFonts.instance.debugSet(['Segoe UI', 'Consolas', 'Cascadia Mono']);
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
    expect(find.byType(ChoiceChip), findsNWidgets(2 + 6)); // 구역 칩 둘(화면·언어) + 색 구성 칩 여섯
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
    await settings.setTextScale(1.15);
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
    SharedPreferences.setMockInitialValues({'theme_palette': 'nope', 'text_scale': 3.0, 'theme_mode': 'x', 'ui_font_family': ''});
    final s = await AppSettings.load();
    expect(s.palette, ColorPalette.saturn);
    expect(s.textScale, 1.0);
    expect(s.stateTint, isTrue);
    expect(s.uiFont, isNull);
  });

  test('글자 크기 배율은 5% 단위로 맞추고 범위 안으로 가둔다', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    await s.setTextScale(1.234);
    expect(s.textScale, 1.25);
    await s.setTextScale(0.1);
    expect(s.textScale, AppSettings.minTextScale);
    await s.setTextScale(9);
    expect(s.textScale, AppSettings.maxTextScale);
  });

  test('화면 글꼴은 저장되고 기본으로 되돌리면 키가 지워진다', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    await s.setUiFont('Segoe UI');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui_font_family'), 'Segoe UI');
    expect((await AppSettings.load()).uiFont, 'Segoe UI');
    await s.setUiFont(null);
    expect(prefs.containsKey('ui_font_family'), isFalse);
  });
}
