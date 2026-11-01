// 확장 모드의 셸 (PLAN.md §1.13): 패널이 켜지면 도크 열 왼쪽에 확장 영역이 붙고, 도크 열은 모드가 바뀌어도 살아 있다.

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/docks/dock_module.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/explorer/explorer_panel.dart';
import 'package:daylight_taskbench/ui/shell/panels/expanded_area.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_layout.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_widths.dart';
import 'package:daylight_taskbench/ui/shell/taskbench_shell.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'terminal/helpers/fake_pty.dart';
import 'terminal/helpers/fake_shell_finder.dart';
import 'test_support.dart';

/// 본문에 State 가 있는 칸 — 모드가 바뀌어도 그 State 가 유지되는지 본다.
class _ProbeDock extends DockModule {
  @override
  String get id => 'probe';
  @override
  IconData get icon => Icons.science_outlined;
  @override
  String title(AppLocalizations l10n) => 'Probe';
  @override
  Widget summary(BuildContext context, Workspace w) => const Text('요약');
  @override
  Widget body(BuildContext context, Workspace w) => const _Counter();
}

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;
  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: () => setState(() => n++), child: Text('count $n'));
}

/// 칸이 보는 화면 크기를 글자로 보인다.
class _SizeProbeDock extends DockModule {
  @override
  String get id => 'size-probe';
  @override
  IconData get icon => Icons.straighten_rounded;
  @override
  String title(AppLocalizations l10n) => 'SizeProbe';
  @override
  Widget summary(BuildContext context, Workspace w) => const Text('요약');
  @override
  Widget body(BuildContext context, Workspace w) {
    final size = MediaQuery.sizeOf(context);
    return Text('size ${size.width}x${size.height}');
  }
}

Future<PanelLayout> _pump(
  WidgetTester tester, {
  Size size = const Size(1240, 820),
  Map<String, Object> prefs = const {},
  List<DockModule>? docks,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await AppSettings.load();
  final panels = PanelLayout(await SharedPreferences.getInstance());
  final ws = await makeWorkspace();
  ws.attachForTest(
    FakeGitStateSource(
      const GitState(
        root: '/r',
        branch: 'main',
        sha: 'aaaaaaa1',
        upstream: 'origin/main',
      ),
    ),
    selectedDir: '/r',
  );
  await tester.pumpWidget(
    PanelLayoutScope(
      panels: panels,
      child: AppSettingsScope(
        settings: settings,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TaskbenchShell(
            workspace: ws,
            docks: docks ?? [_ProbeDock()],
            onAbout: () {},
            panels: panels,
            terminals: fakeTerminals(FakePtyFactory()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return panels;
}

void main() {
  testWidgets('패널이 없으면 도킹 모드: 확장 영역이 없고 도크 열이 창 전체를 쓴다', (tester) async {
    await _pump(tester);
    expect(find.byType(ExpandedArea), findsNothing);
    expect(tester.getSize(find.byType(Scaffold)).width, 1240);
    final column = tester.getRect(find.text('Probe'));
    expect(column.left, lessThan(200)); // 왼쪽에서 시작 — 창 전체를 쓴다
  });

  testWidgets('탐색기를 켜면 확장 모드: 도크 열은 오른쪽 440, 왼쪽에 탐색기 자리가 생긴다', (tester) async {
    final panels = await _pump(tester);
    panels.setExplorer(true);
    await tester.pumpAndSettle();
    expect(find.byType(ExpandedArea), findsOneWidget);
    expect(find.text('탐색기'), findsWidgets);
    final probe = tester.getRect(find.text('Probe'));
    expect(probe.left, greaterThan(1240 - dockColumnWidth - 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('도킹 ↔ 확장을 오가도 도크 열의 State 가 유지된다 (§1.13 완료 조건)', (tester) async {
    final panels = await _pump(tester);
    await tester.tap(find.text('count 0'));
    await tester.pump();
    await tester.tap(find.text('count 1'));
    await tester.pump();
    expect(find.text('count 2'), findsOneWidget);

    panels.setTerminal(true); // 도킹 → 확장
    await tester.pumpAndSettle();
    expect(find.text('count 2'), findsOneWidget);

    panels.setTerminal(false); // 확장 → 도킹
    await tester.pumpAndSettle();
    expect(find.text('count 2'), findsOneWidget);
    expect(find.byType(ExpandedArea), findsNothing);
  });

  testWidgets('탐색기만 켜면 가운데 빈칸이 없다: 탐색기가 남는 폭을 쓴다', (tester) async {
    final panels = await _pump(tester);
    panels.setExplorer(true);
    await tester.pumpAndSettle();
    final explorer = tester.getRect(find.byType(ExplorerPanel));
    final dock = tester.getRect(find.text('Probe')); // 도크 열 안
    expect(explorer.left, 0);
    // 도크 열 바로 앞(구분선 손잡이 폭만큼 앞)까지
    expect(
      explorer.right,
      greaterThan(1240 - dockColumnWidth - PanelWidths.handle - 2),
    );
    expect(dock.left, greaterThan(explorer.right - 1));
    expect(find.byType(CenterArea), findsNothing);
  });

  testWidgets('탐색기 머리줄의 x 로 탐색기를 닫는다 — 마지막 패널이면 도킹으로 돌아간다', (tester) async {
    final panels = await _pump(tester);
    panels.setExplorer(true);
    await tester.pumpAndSettle();
    expect(find.byTooltip('패널 닫기'), findsOneWidget);
    await tester.tap(find.byTooltip('패널 닫기'));
    await tester.pumpAndSettle();
    expect(panels.explorer, isFalse);
    expect(panels.expanded, isFalse);
    expect(find.byType(ExpandedArea), findsNothing);
  });

  testWidgets('가운데 머리줄의 x 는 지금 보이는 쪽만 닫는다 (둘 다 켜져 있으면 다른 쪽은 남는다)', (tester) async {
    final panels = await _pump(tester);
    panels
      ..setEditor(true)
      ..setTerminal(true); // 터미널이 보인다
    await tester.pumpAndSettle();
    expect(panels.center, CenterView.terminal);
    await tester.tap(find.byTooltip('패널 닫기'));
    await tester.pumpAndSettle();
    expect(panels.terminal, isFalse);
    expect(panels.editor, isTrue);
    expect(panels.center, CenterView.editor);
    expect(find.byType(SegmentedButton<CenterView>), findsNothing); // 하나만 남아 전환 단추가 없다
    await tester.tap(find.byTooltip('패널 닫기'));
    await tester.pumpAndSettle();
    expect(panels.expanded, isFalse); // 마지막 패널을 닫으면 도킹
  });

  testWidgets('탐색기와 가운데에 x 가 각각 있고, 서로 상대 패널은 건드리지 않는다', (tester) async {
    final panels = await _pump(tester);
    panels
      ..setExplorer(true)
      ..setTerminal(true);
    await tester.pumpAndSettle();
    expect(find.byTooltip('패널 닫기'), findsNWidgets(2));
    await tester.tap(find.byTooltip('패널 닫기').first); // 왼쪽 = 탐색기
    await tester.pumpAndSettle();
    expect(panels.explorer, isFalse);
    expect(panels.terminal, isTrue);
    expect(panels.expanded, isTrue);
  });

  testWidgets('에디터와 터미널이 둘 다 켜지면 전환 단추가 나오고, 전환해도 가운데는 한 번에 하나만 보인다', (
    tester,
  ) async {
    final panels = await _pump(tester);
    panels
      ..setEditor(true)
      ..setTerminal(true);
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<CenterView>), findsOneWidget);
    expect(find.byIcon(Icons.terminal_rounded).hitTestable(), findsWidgets);
    await tester.tap(find.text('에디터').last);
    await tester.pumpAndSettle();
    expect(panels.center, CenterView.editor);
    expect(tester.takeException(), isNull);
  });

  testWidgets('에디터만 끄면 전환 단추가 사라지고 터미널만 남는다', (tester) async {
    final panels = await _pump(tester);
    panels
      ..setEditor(true)
      ..setTerminal(true);
    await tester.pumpAndSettle();
    panels.setEditor(false);
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<CenterView>), findsNothing);
    expect(panels.center, CenterView.terminal);
  });

  testWidgets('확장 단추: 모두 켜고, 하나라도 켜져 있으면 모두 끈다', (tester) async {
    final panels = await _pump(tester);
    await tester.tap(find.byIcon(Icons.open_in_full_rounded));
    await tester.pumpAndSettle();
    expect(panels.explorer, isTrue);
    expect(panels.editorShown, isTrue);
    expect(panels.terminal, isTrue);
    // 개별 패널을 x 로 닫아도 확장 단추는 "접기"다.
    panels.setEditor(false);
    panels.setTerminal(false);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_fullscreen_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_fullscreen_rounded));
    await tester.pumpAndSettle();
    expect(panels.expanded, isFalse);
    expect(find.byType(ExpandedArea), findsNothing);
  });

  testWidgets('확장 단추 설명에 개별 패널 단축키가 보인다', (tester) async {
    await _pump(tester);
    final tip = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.open_in_full_rounded)).tooltip!;
    expect(tip, contains('탐색기'));
    expect(tip, contains('터미널'));
  });

  testWidgets('내장 에디터를 껐으면 확장 단추는 에디터를 켜지 않는다', (tester) async {
    final panels = await _pump(tester, prefs: {'editor_embedded': false});
    await tester.tap(find.byIcon(Icons.open_in_full_rounded));
    await tester.pumpAndSettle();
    expect(panels.explorer, isTrue);
    expect(panels.terminal, isTrue);
    expect(panels.editor, isFalse);
  });

  test('toggleAll 은 알림을 한 번만 보낸다 (창 크기가 여러 번 바뀌지 않게)', () async {
    SharedPreferences.setMockInitialValues({});
    final panels = PanelLayout(await SharedPreferences.getInstance());
    var n = 0;
    panels.addListener(() => n++);
    panels.toggleAll();
    expect(n, 1);
    panels.toggleAll();
    expect(n, 2);
    expect(panels.expanded, isFalse);
  });

  testWidgets('패널 켜짐은 저장되지 않아서 항상 도킹 모드로 시작한다', (tester) async {
    await _pump(
      tester,
      prefs: {'panel_explorer': true, 'panel_terminal': true},
    ); // 옛 저장값이 있어도
    expect(find.byType(ExpandedArea), findsNothing);
  });

  testWidgets('확장 모드에서 도크 열 안의 칸은 창이 아니라 자기 열의 크기를 화면 크기로 본다', (tester) async {
    // Git 칸은 MediaQuery 폭이 840 이상이면 "넓은 창 배치"(왼쪽 레일)로 바뀐다. 확장하면 창은 넓어도 열은 440이다.
    final panels = await _pump(tester, docks: [_SizeProbeDock()]);
    expect(find.text('size 1240x'), findsNothing);
    expect(find.textContaining('size 1240.0x'), findsOneWidget); // 도킹: 창 전체

    panels.setExplorer(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('size 440.0x'), findsOneWidget); // 확장: 도크 열 폭
    expect(find.textContaining('size 1240.0x'), findsNothing);

    panels.setExplorer(false);
    await tester.pumpAndSettle();
    expect(find.textContaining('size 1240.0x'), findsOneWidget);
  });

  testWidgets('창을 아주 낮게 줄여도 도크 열은 넘침 오류 대신 스크롤된다 (도킹·확장 모두)', (tester) async {
    final panels = await _pump(tester, size: const Size(440, 160), docks: [_ProbeDock(), _SizeProbeDock()]);
    expect(tester.takeException(), isNull); // 도킹, 높이 160
    panels.setExplorer(true);
    tester.view.physicalSize = const Size(1240, 160);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // 확장, 높이 160
  });

  testWidgets('확장 모드 최소 창(960×560)에서 오버플로 없이 그려진다', (tester) async {
    final panels = await _pump(
      tester,
      size: const Size(960, 560),
      docks: [BranchDock()],
    );
    panels
      ..setExplorer(true)
      ..setEditor(true)
      ..setTerminal(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('도킹 최소 창(380×560)에서도 확장 단추는 가려지지 않고 앱 바에 그대로 있다', (
    tester,
  ) async {
    final panels = await _pump(
      tester,
      size: const Size(380, 560),
      docks: [BranchDock()],
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.open_in_full_rounded));
    tester.view.physicalSize = const Size(1240, 820); // 모드가 바뀌면 창이 확장 크기로 커진다
    await tester.pumpAndSettle();
    expect(panels.expanded, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('확장 모드에서는 "항상 위" 단추가 숨고, 도킹으로 돌아오면 다시 보인다', (tester) async {
    final panels = await _pump(tester);
    final pin = find.byTooltip('항상 위에 표시');
    expect(pin, findsOneWidget);
    panels.setExplorer(true);
    await tester.pumpAndSettle();
    expect(pin, findsNothing);
    panels.setExplorer(false);
    await tester.pumpAndSettle();
    expect(pin, findsOneWidget);
  });
}
