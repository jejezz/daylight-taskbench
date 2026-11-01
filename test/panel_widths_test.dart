// 확장 모드 패널 너비 조절 (PLAN.md §1.13): 계산(순수 함수) · 저장 · 구분선을 끌어 조절 · 창이 좁아졌을 때.

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/shell/panels/expanded_area.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_divider.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_layout.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_widths.dart';
import 'package:daylight_taskbench/ui/shell/taskbench_shell.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'terminal/helpers/fake_pty.dart';
import 'terminal/helpers/fake_shell_finder.dart';
import 'test_support.dart';

/// 끌기: 터치 한계(처음 20px 는 끌기로 치지 않는다)만큼 더 끌어서 실제로 [dx]만큼 움직인 것으로 만든다.
Future<void> dragBy(WidgetTester tester, Finder finder, double dx) =>
    tester.drag(finder, Offset(dx + (dx < 0 ? -kDragSlopDefault : kDragSlopDefault), 0));

void main() {
  group('PanelWidths — 계산', () {
    test('도크 열: 원하는 폭을 최소·최대 안으로 맞추고, 왼쪽 영역이 최소 폭을 지키게 줄인다', () {
      // 넉넉한 창: 원하는 폭 그대로
      expect(PanelWidths.dockFit(total: 1600, areaMin: 700, preferred: 500), 500);
      // 원하는 폭이 너무 작으면 최소 폭
      expect(PanelWidths.dockFit(total: 1600, areaMin: 700, preferred: 100), PanelWidths.minDock);
      // 창이 좁으면 왼쪽 영역 최소 폭(700)을 남기도록 줄인다
      expect(
        PanelWidths.dockFit(total: 1240, areaMin: 700, preferred: 700),
        1240 - PanelWidths.handle - 700,
      );
      // 너무 좁은 창에서는 도크 열의 최소 폭을 우선한다
      expect(PanelWidths.dockFit(total: 600, areaMin: 700, preferred: 500), PanelWidths.minDock);
    });

    test('탐색기: 가운데가 없으면 영역 전체, 있으면 가운데 최소 폭을 지키게 줄인다', () {
      expect(PanelWidths.explorerFit(area: 700, hasCenter: false, preferred: 240), 700);
      expect(PanelWidths.explorerFit(area: 800, hasCenter: true, preferred: 300), 300);
      expect(
        PanelWidths.explorerFit(area: 500, hasCenter: true, preferred: 400),
        500 - PanelWidths.handle - PanelWidths.minCenter,
      );
      expect(PanelWidths.explorerFit(area: 300, hasCenter: true, preferred: 400), PanelWidths.minExplorer);
    });

    test('areaMin: 있는 패널의 최소 폭과 구분선을 더한다', () {
      expect(PanelWidths.areaMin(hasExplorer: true, hasCenter: false), PanelWidths.minExplorer);
      expect(PanelWidths.areaMin(hasExplorer: false, hasCenter: true), PanelWidths.minCenter);
      expect(
        PanelWidths.areaMin(hasExplorer: true, hasCenter: true),
        PanelWidths.minExplorer + PanelWidths.minCenter + PanelWidths.handle,
      );
    });

    test('기본 너비로 최소 창(960)에 모두 들어간다', () {
      const w = 960.0;
      final areaMin = PanelWidths.areaMin(hasExplorer: true, hasCenter: true);
      final dock = PanelWidths.dockFit(total: w, areaMin: areaMin, preferred: PanelWidths.defaultDock);
      final area = w - PanelWidths.handle - dock;
      final explorer = PanelWidths.explorerFit(area: area, hasCenter: true, preferred: PanelWidths.defaultExplorer);
      expect(explorer, greaterThanOrEqualTo(PanelWidths.minExplorer));
      expect(area - explorer - PanelWidths.handle, greaterThanOrEqualTo(PanelWidths.minCenter));
    });
  });

  group('PanelWidths — 저장', () {
    test('범위 안으로 맞추고, 바뀔 때만 알리고, 저장했다가 다시 읽는다', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final w = PanelWidths(prefs);
      expect(w.explorer, PanelWidths.defaultExplorer);
      expect(w.dock, PanelWidths.defaultDock);
      var n = 0;
      w.addListener(() => n++);
      await w.setDock(PanelWidths.defaultDock); // 같은 값
      expect(n, 0);
      await w.setDock(9999);
      expect(w.dock, PanelWidths.maxDock);
      await w.setDock(1);
      expect(w.dock, PanelWidths.minDock);
      await w.setExplorer(300);
      expect(n, 3);
      final again = PanelWidths(prefs);
      expect(again.dock, PanelWidths.minDock);
      expect(again.explorer, 300);
      await w.resetDock();
      await w.resetExplorer();
      expect(w.dock, PanelWidths.defaultDock);
      expect(w.explorer, PanelWidths.defaultExplorer);
    });

    test('이상한 저장값은 기본값으로 읽는다', () async {
      SharedPreferences.setMockInitialValues({
        'panel_width_explorer': double.nan,
        'panel_width_dock': 5.0,
      });
      final w = PanelWidths(await SharedPreferences.getInstance());
      expect(w.explorer, PanelWidths.defaultExplorer);
      expect(w.dock, PanelWidths.minDock); // 범위 밖은 가까운 값으로
    });
  });

  group('셸 안에서 끌어 조절', () {
    late PanelWidths widths;
    late PanelLayout panels;

    Future<void> pump(WidgetTester tester, {Size size = const Size(1400, 820)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      widths = PanelWidths(prefs);
      panels = PanelLayout(prefs);
      final settings = await AppSettings.load();
      final ws = await makeWorkspace();
      ws.attachForTest(
        FakeGitStateSource(const GitState(root: '/r', branch: 'main', sha: 'a1')),
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
                docks: [BranchDock()],
                onAbout: () {},
                panels: panels,
                panelWidths: widths,
                terminals: fakeTerminals(FakePtyFactory()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// 도크 열의 왼쪽 가장자리(= 도크 열 폭 계산용). 도크 열은 창 오른쪽 끝에 붙어 있다.
    double dockWidth(WidgetTester tester, double windowWidth) {
      final box = find.byType(MediaQuery).evaluate().map((e) => e.widget).length; // 존재만 확인
      expect(box, greaterThan(0));
      final handle = tester.getRect(find.byType(PanelDivider).last);
      return windowWidth - handle.right;
    }

    testWidgets('도크 열 구분선을 왼쪽으로 끌면 도크 열이 넓어지고 오른쪽으로 끌면 좁아진다. 값은 저장된다', (tester) async {
      await pump(tester);
      panels
        ..setExplorer(true)
        ..setTerminal(true);
      await tester.pumpAndSettle();
      expect(dockWidth(tester, 1400), PanelWidths.defaultDock);
      await dragBy(tester, find.byType(PanelDivider).last, -100);
      await tester.pumpAndSettle();
      expect(widths.dock, PanelWidths.defaultDock + 100);
      expect(dockWidth(tester, 1400), PanelWidths.defaultDock + 100);
      await dragBy(tester, find.byType(PanelDivider).last, 60);
      await tester.pumpAndSettle();
      expect(widths.dock, PanelWidths.defaultDock + 40);
    });

    testWidgets('탐색기 구분선을 끌면 탐색기 폭이 바뀐다 (오른쪽이 넓어짐)', (tester) async {
      await pump(tester);
      panels
        ..setExplorer(true)
        ..setTerminal(true);
      await tester.pumpAndSettle();
      expect(find.byType(PanelDivider), findsNWidgets(2)); // 탐색기|가운데, 가운데|도크
      await dragBy(tester, find.byType(PanelDivider).first, 80);
      await tester.pumpAndSettle();
      expect(widths.explorer, PanelWidths.defaultExplorer + 80);
      expect(tester.takeException(), isNull);
    });

    testWidgets('끌어도 최소·최대 폭을 넘지 않는다', (tester) async {
      await pump(tester);
      panels
        ..setExplorer(true)
        ..setTerminal(true);
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await dragBy(tester, find.byType(PanelDivider).first, -200);
        await tester.pumpAndSettle();
      }
      expect(widths.explorer, PanelWidths.minExplorer);
      for (var i = 0; i < 6; i++) {
        await dragBy(tester, find.byType(PanelDivider).last, 200);
        await tester.pumpAndSettle();
      }
      expect(widths.dock, PanelWidths.minDock);
      expect(tester.takeException(), isNull);
    });

    testWidgets('구분선을 두 번 누르면 기본 너비로 돌아간다', (tester) async {
      await pump(tester);
      panels
        ..setExplorer(true)
        ..setTerminal(true);
      await tester.pumpAndSettle();
      await widths.setDock(600);
      await widths.setExplorer(350);
      await tester.pumpAndSettle();
      Future<void> doubleTap(Finder f) async {
        await tester.tap(f);
        await tester.pump(const Duration(milliseconds: 40));
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await doubleTap(find.byType(PanelDivider).last);
      expect(widths.dock, PanelWidths.defaultDock);
      await doubleTap(find.byType(PanelDivider).first);
      expect(widths.explorer, PanelWidths.defaultExplorer);
    });

    testWidgets('탐색기만 켠 상태에서도 도크 열 구분선을 끌 수 있다 (탐색기가 남는 폭을 쓴다)', (tester) async {
      await pump(tester, size: const Size(900, 820));
      panels.setExplorer(true);
      await tester.pumpAndSettle();
      expect(find.byType(PanelDivider), findsOneWidget); // 도크 열 구분선 하나
      await dragBy(tester, find.byType(PanelDivider), -60);
      await tester.pumpAndSettle();
      expect(widths.dock, PanelWidths.defaultDock + 60);
      expect(tester.takeException(), isNull);
    });

    testWidgets('원하는 폭이 커도 창이 좁으면 가운데 최소 폭을 지키게 줄여서 보인다(저장값은 그대로)', (tester) async {
      await pump(tester, size: const Size(960, 820));
      panels
        ..setExplorer(true)
        ..setTerminal(true);
      await tester.pumpAndSettle();
      await widths.setDock(PanelWidths.maxDock);
      await widths.setExplorer(PanelWidths.maxExplorer);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull); // 넘치지 않는다
      expect(widths.dock, PanelWidths.maxDock); // 저장값은 그대로
      final center = tester.getSize(find.byType(CenterArea));
      expect(center.width, greaterThanOrEqualTo(PanelWidths.minCenter));
      expect(dockWidth(tester, 960), greaterThanOrEqualTo(PanelWidths.minDock));
    });

    testWidgets('도킹 모드에는 구분선이 없다', (tester) async {
      await pump(tester);
      expect(find.byType(PanelDivider), findsNothing);
    });
  });
}
