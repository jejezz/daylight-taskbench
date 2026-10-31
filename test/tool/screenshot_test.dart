// 화면 확인용 스크린샷을 만든다 (PLAN.md §1.7). 평소 테스트 실행에서는 건너뛰고,
//   SHOTS_DIR=/경로 flutter test test/tool/screenshot_test.dart
// 로 실행하면 폭 380/440, 라이트/다크 PNG 를 쓴다.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/docks/flutty/flutty_dock.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/settings/settings_dialog.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/shell/taskbench_shell.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_support.dart';

Future<void> _loadFonts() async {
  final l = FontLoader('SeoulNamsan');
  for (final f in ['regular', 'bold', 'extra_bold']) {
    l.addFont(rootBundle.load('assets/fonts/seoul_namsan_$f.ttf'));
  }
  await l.load();
}

void main() {
  final out = Platform.environment['SHOTS_DIR'];

  Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  for (final dark in [false, true]) {
    for (final size in const [Size(440, 960), Size(380, 560)]) {
      testWidgets('shot ${dark ? 'dark' : 'light'} ${size.width.toInt()}', skip: out == null, (tester) async {
        await tester.runAsync(_loadFonts);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final settings = await AppSettings.load();
        final ws = await makeWorkspace();
        ws.attachForTest(FakeGitStateSource(const GitState(root: '/Users/me/dev/my_app', branch: 'feature/login', sha: 'abc1234', upstream: 'origin/feature/login', ahead: 2, changedCount: 3)));
        final key = GlobalKey();
        Future<void> pump(Widget home) async {
          await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: AppSettingsScope(
              settings: settings,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                locale: const Locale('ko'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: home,
              ),
            ),
          ));
          await tester.pumpAndSettle();
        }

        final tag = '${dark ? 'dark' : 'light'}_${size.width.toInt()}';
        await pump(TaskbenchShell(workspace: ws, docks: [BranchDock(), FluttyDock()], onAbout: () {}));
        await shot(tester, key, 'open_$tag');
        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();
        await shot(tester, key, 'run_$tag');
        ws.close();
        await tester.pumpAndSettle();
        await shot(tester, key, 'start_$tag');
        await pump(const Scaffold(body: SettingsDialog()));
        await shot(tester, key, 'settings_$tag');
      });
    }
  }
}
