import 'dart:io';

import 'package:daylight_taskbench/core/tool_paths.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/settings/settings_dialog.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/workspace/workspace_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

void main() {
  branchSectionTests();
  test('저장한 경로는 runner 에 바로 반영되고, 다시 읽어도 남는다', () async {
    final ws = await makeWorkspace();
    final prefs = ws.prefs;
    final tools = ToolPaths(runner: ws.runner, prefs: prefs);
    var changed = 0;
    tools.onChanged = () => changed++;
    await tools.set('git', '/opt/git/bin/git');
    expect(ws.runner.executableFor('git'), '/opt/git/bin/git');
    expect(prefs.getString('tool_path_git'), '/opt/git/bin/git');
    expect(changed, 1);

    final again = ToolPaths(runner: (await makeWorkspace()).runner, prefs: prefs); // 같은 prefs 로 다시
    expect(again.customPath('git'), '/opt/git/bin/git');

    await tools.set('git', '  ');
    expect(ws.runner.gitPath, isNull);
    expect(prefs.containsKey('tool_path_git'), isFalse);
    ws.dispose();
  });

  test('칸이 더한 도구(flutter 등)도 같은 규칙으로 저장·반영된다', () async {
    final ws = await makeWorkspace();
    SharedPreferences.setMockInitialValues({'tool_path_flutter': '/sdk/flutter/bin/flutter'});
    final prefs = await SharedPreferences.getInstance();
    final tools = ToolPaths(runner: ws.runner, prefs: prefs);
    expect(ws.runner.toolPaths.containsKey('flutter'), isFalse); // 아직 모르는 도구
    tools.register(const ToolSpec('flutter', 'flutter'));
    expect(ws.runner.executableFor('flutter'), '/sdk/flutter/bin/flutter');
    expect(ws.runner.effectivePath.startsWith('/sdk/flutter/bin'), isTrue);
    ws.dispose();
  });

  Future<void> pumpSettings(WidgetTester tester, {ToolPaths? tools, Size size = const Size(480, 560)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    Widget app = AppSettingsScope(
      settings: settings,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsDialog()),
      ),
    );
    if (tools != null) app = ToolPathsScope(tools: tools, child: app);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  testWidgets('설정 창: ToolPaths 가 있을 때만 "도구" 구역이 생기고 좁은 창에서도 넘치지 않는다', (tester) async {
    await pumpSettings(tester);
    expect(find.widgetWithText(ChoiceChip, '도구'), findsNothing);

    final ws = await makeWorkspace();
    await pumpSettings(tester, tools: ToolPaths(runner: ws.runner, prefs: ws.prefs));
    expect(find.widgetWithText(ChoiceChip, '도구'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '도구'));
    await tester.pumpAndSettle();
    expect(find.text('gh (GitHub CLI)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    ws.dispose();
  });

  testWidgets('도구 줄: 지정 상태가 "직접 지정"으로 보이고, 지우기 단추가 지정을 지운다', (tester) async {
    // 입력창에 글을 치는 흐름은 포커스된 TextField 의 커서 깜빡임 때문에 위젯 테스트로 안정적이지 않다.
    // 저장·반영은 위 단위 테스트가 지키고, 여기서는 이미 지정된 값이 화면에 반영되는지만 본다.
    final ws = await makeWorkspace();
    final dir = (await tester.runAsync(() => tempDir('tooluit')))!; // 실제 파일 I/O 는 가짜 시계 밖에서
    addTearDown(() => dir.deleteSync(recursive: true));
    final exe = File('${dir.path}/git')..writeAsStringSync('#!/bin/sh\n');
    final tools = ToolPaths(runner: ws.runner, prefs: ws.prefs);
    await tools.set('git', exe.path);
    await pumpSettings(tester, tools: tools);
    await tester.tap(find.widgetWithText(ChoiceChip, '도구'));
    await tester.pumpAndSettle();
    expect(find.text('직접 지정'), findsOneWidget);
    expect(find.text('찾음: ${exe.path}'), findsOneWidget);
    await tester.tap(find.byTooltip('지정 지우기').first);
    await tester.pump();
    expect(tools.customPath('git'), isNull);
    expect(find.text('직접 지정'), findsNothing);
    ws.dispose();
  });
}

void branchSectionTests() {
  testWidgets('Branch 구역: WorkspaceScope 가 있을 때만 생기고, 편집기 명령·자동 fetch 가 저장된다', (tester) async {
    tester.view.physicalSize = const Size(480, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    final ws = await makeWorkspace();
    await tester.pumpWidget(WorkspaceScope(
      workspace: ws,
      child: AppSettingsScope(
        settings: settings,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsDialog()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Branch Dock'));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(ws.prefs.getBool('branch.auto_fetch'), isFalse);
    await ws.setEditorCommand('  code -r ');
    expect(ws.editorCommand, 'code -r');
    expect(ws.prefs.getString('editor_command'), 'code -r');
    expect(await ws.folderEditorCommand('/repo'), ['code', '-r', '/repo']);
    ws.dispose();
  });
}
