import 'package:daylight_taskbench/editor/editor_settings.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/settings/settings_dialog.dart';
import 'package:daylight_taskbench/settings/system_fonts.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('외형 구역: 편집기 글꼴·색상 구성표를 고르면 바로 적용되고 저장된다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    SystemFonts.instance.debugSet(['Segoe UI', 'Consolas', 'Cascadia Mono']);
    final prefs = await SharedPreferences.getInstance();
    final app = await AppSettings.load();
    final editor = EditorSettings(prefs);
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      EditorSettingsScope(
        settings: editor,
        child: AppSettingsScope(
          settings: app,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingsDialog()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('편집기 글꼴'), findsOneWidget);
    expect(find.text('편집기 색상 구성표'), findsOneWidget);

    // 구성표: 목록에서 Dracula 를 고른다.
    final picker = find.byType(DropdownMenu<String>).at(2);
    await tester.ensureVisible(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: picker, matching: find.byIcon(Icons.arrow_drop_down)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dracula').last);
    await tester.tap(find.text('Dracula').last);
    await tester.pumpAndSettle();
    expect(editor.scheme?.id, 'dracula');
    expect(prefs.getString('editor_color_scheme'), 'dracula');

    // 편집기 글꼴과 화면 글꼴은 설정 값으로 저장된다.
    await editor.setFontFamily('Cascadia Mono');
    expect(prefs.getString('editor_font_family'), 'Cascadia Mono');
    await editor.setFontFamily(null);
    expect(prefs.containsKey('editor_font_family'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
