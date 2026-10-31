import 'dart:io';

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/docks/dock_module.dart';
import 'package:daylight_taskbench/docks/flutty/flutty_dock.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/shell/taskbench_shell.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

Future<(Workspace, FakeGitStateSource, List<DockModule>)> _pump(WidgetTester tester, {Size size = const Size(440, 960), bool open = true, String? dir}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final settings = await AppSettings.load();
  final ws = await makeWorkspace();
  final source = FakeGitStateSource(GitState(root: dir ?? '/r', branch: 'main', sha: 'aaaaaaa1', upstream: 'origin/main', ahead: 2, changedCount: 3));
  final docks = <DockModule>[BranchDock(), FluttyDock()];
  if (open) ws.attachForTest(source, selectedDir: dir);
  await tester.pumpWidget(AppSettingsScope(
    settings: settings,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TaskbenchShell(workspace: ws, docks: docks, onAbout: () {}),
    ),
  ));
  await tester.pumpAndSettle();
  return (ws, source, docks);
}

void main() {
  flutterDockTests();
  testWidgets('저장소가 안 열렸으면 시작 화면만 보이고 아코디언·브랜치 줄은 없다 (§1.0)', (tester) async {
    await _pump(tester, open: false);
    expect(find.text('저장소를 열어 시작하세요'), findsOneWidget);
    expect(find.text('Branch Dock'), findsNothing);
    expect(find.byIcon(Icons.description_outlined), findsNothing);
  });

  testWidgets('열리면 공유 영역(디렉터리·브랜치·편집기)과 Branch 칸이 보인다 (§1.1)', (tester) async {
    await _pump(tester);
    expect(find.text('r'), findsWidgets); // 디렉터리 이름
    expect(find.text('main'), findsOneWidget); // 브랜치 칩
    expect(find.text('↑2'), findsOneWidget); // 공유 줄에만 (칸 제목 요약은 "다음 행동")
    expect(find.text('Push ↑2 가능'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.text('Branch Dock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('프로젝트가 없으면 Flutty 자리에 Run 안내 칸이 서고, 제목을 누르면 펼쳐진다', (tester) async {
    await _pump(tester);
    expect(find.text('Flutty Dock'), findsNothing);
    expect(find.text('Run'), findsOneWidget);
    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter 프로젝트 없음'), findsWidgets);
  });

  testWidgets('브랜치가 바뀌면 공유 영역과 접힌 칸까지 한 번에 따라간다 (§1.10)', (tester) async {
    final (ws, source, docks) = await _pump(tester);
    final branch = docks.first as BranchDock;
    expect(find.text('main'), findsOneWidget);
    source.set(const GitState(root: '/r', branch: 'feature/login', sha: 'bbbbbbb2'));
    await tester.pumpAndSettle();
    expect(find.text('main'), findsNothing);
    expect(find.text('feature/login'), findsOneWidget);
    expect(branch.received, hasLength(1)); // 칸은 신호를 한 번 받았다
    expect(ws.git?.branch, 'feature/login');
    // 병합이 시작되면 pill 이 danger 로 바뀐다
    source.set(const GitState(root: '/r', branch: 'feature/login', sha: 'bbbbbbb2', operation: RepoOperation.merging, conflictCount: 2));
    await tester.pumpAndSettle();
    expect(find.text('병합 중 · 충돌 2'), findsWidgets);
  });

  testWidgets('380×560(최소 창)에서 오버플로 없이 제목과 공유 영역이 모두 보인다 (§1.7)', (tester) async {
    await _pump(tester, size: const Size(380, 560));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
  });

  testWidgets('긴 브랜치 이름에도 편집기 단추는 디렉터리 이름 옆에 그대로 있다', (tester) async {
    final (_, source, _) = await _pump(tester, size: const Size(380, 560));
    source.set(GitState(root: '/r', branch: 'feature/${'very-long-branch-name-' * 5}', sha: 'c'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final rect = tester.getRect(find.byIcon(Icons.description_outlined));
    expect(rect.right, lessThanOrEqualTo(380));
    expect(rect.top, lessThan(44)); // 디렉터리 바(첫 줄)에 있다
    // 디렉터리 이름 바로 옆: 이름 끝에서 멀지 않다
    expect(rect.left - tester.getRect(find.byIcon(Icons.arrow_drop_down_rounded)).right, lessThan(32));
  });

  testWidgets('끌어다 놓기 규칙: 파일만 → 안내, 비-git 폴더 → 열린 저장소 유지 (§1.11)', (tester) async {
    final (ws, _, _) = await _pump(tester);
    late DropResult r;
    await tester.runAsync(() async {
      final plain = await tempDir('dropplain');
      addTearDown(() => plain.deleteSync(recursive: true));
      File('${plain.path}/f.txt').writeAsStringSync('x');
      r = await ws.openDropped(['${plain.path}/f.txt']);
      expect(r.outcome, OpenOutcome.ignoredFiles);
      r = await ws.openDropped([plain.path]);
      expect(r.outcome, OpenOutcome.failed);
    });
    expect(ws.isOpen, isTrue);
  });
}

void flutterDockTests() {
  test('Flutty 칸: 고른 폴더에서 프로젝트를 찾고, 브랜치가 바뀌면 다시 찾는다 (§1.4·§1.10)', () async {
    final d = await tempDir('fluttydock');
    addTearDown(() => d.deleteSync(recursive: true));
    final ws = await makeWorkspace();
    final source = FakeGitStateSource(GitState(root: d.path, branch: 'main', sha: '1'));
    ws.attachForTest(source, selectedDir: d.path);
    final dock = FluttyDock()..attach(ws);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(dock.appliesTo(ws), isFalse); // 프로젝트 없음 → 칸이 안 보인다
    File('${d.path}/pubspec.yaml').writeAsStringSync('name: demo_app\nversion: 2.0.0+1\ndependencies:\n  flutter:\n    sdk: flutter\n');
    source.set(GitState(root: d.path, branch: 'feature', sha: '2')); // 브랜치 전환 → 재감지
    ws.headChanges.listen((c) => dock.onHeadChange(ws, c));
    source.set(GitState(root: d.path, branch: 'other', sha: '3'));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(dock.appliesTo(ws), isTrue);
    expect(dock.projects.single.name, 'demo_app');
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });
}
