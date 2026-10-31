// 진행 표시줄(0.5초 넘는 작업)이 일이 끝나면 멈춘다. 저장소 상태(GitState)가 그대로여도 — 예를 들어 이미
// 최신인데 `git pull` 을 한 뒤 — 본문이 다시 그려져야 한다. (Branch 이식 때 본문이 저장소를 직접 듣지 않게 되어
// 상태가 바뀌지 않으면 진행 표시줄이 남던 것.)

import 'dart:io';

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/docks/branch/ui/branch_dock_body.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

void main() {
  testWidgets('작업이 0.5초를 넘으면 진행 표시줄이 나타나고, 끝나면 상태가 그대로여도 사라진다', (tester) async {
    tester.view.physicalSize = const Size(440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Directory dir;
    late BranchDock dock;
    late dynamic ws;
    await tester.runAsync(() async {
      dir = await makeRepo('progressbar');
      ws = await makeWorkspace();
      await ws.open(dir.path);
      dock = BranchDock()..attach(ws);
    });
    addTearDown(() async {
      dock.detach(ws);
      dock.dispose();
      ws.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      dir.deleteSync(recursive: true);
    });
    await tester.pumpWidget(AppSettingsScope(
      settings: await AppSettings.load(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BranchDockBody(workspace: ws, dock: dock)),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // 상태를 바꾸지 않는 오래 걸리는 명령 (이미 최신인 pull 처럼).
    late Future<Object?> run;
    await tester.runAsync(() async {
      run = ws.repo!.execute(['sleep', '1']);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(LinearProgressIndicator), findsOneWidget, reason: '0.5초가 지나면 진행 표시줄');

    await tester.runAsync(() => run);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing, reason: '끝났는데도 남아 있다');
  });
}
