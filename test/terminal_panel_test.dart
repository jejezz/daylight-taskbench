// 확장 영역의 터미널 (PLAN.md §1.13, 단계 14): 처음 보일 때 저장소 루트에서 셸 자동 실행 · 탭 · 종료 안내 ·
// 세션 유지(껐다 켜기·에디터와 전환) · 설정. 진짜 셸·pty 는 띄우지 않는다(가짜 pty).

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/settings/settings_dialog.dart';
import 'package:daylight_taskbench/terminal/terminal_host.dart';
import 'package:daylight_taskbench/terminal/terminal_sessions_controller.dart';
import 'package:daylight_taskbench/terminal/terminal_settings.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_layout.dart';
import 'package:daylight_taskbench/ui/shell/taskbench_shell.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'terminal/helpers/fake_pty.dart';
import 'terminal/helpers/fake_shell_finder.dart';
import 'test_support.dart';

/// 커서 깜박임 같은 반복 애니메이션이 있어 pumpAndSettle 은 끝나지 않을 수 있다 — 시간만 조금 흘린다.
Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _host(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

void main() {
  late FakePtyFactory ptys;
  late Workspace ws;
  late TerminalSettings settings;

  setUp(() async {
    ptys = FakePtyFactory();
    ws = await makeWorkspace();
    ws.attachForTest(
      FakeGitStateSource(const GitState(root: '/repo', branch: 'main', sha: 'a1')),
      selectedDir: '/repo',
    );
    settings = TerminalSettings(ws.prefs);
  });

  tearDown(() => ws.dispose());

  Future<TerminalSessionsController> pumpHost(
    WidgetTester tester, {
    List shells = const [fakeBash],
    Size size = const Size(700, 600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = fakeTerminals(ptys, shells: [...shells]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(TerminalHost(controller: c, settings: settings, workspace: ws)),
    );
    await _flush(tester);
    return c;
  }

  group('TerminalHost', () {
    testWidgets('처음 보일 때 기본 셸을 저장소 루트에서 한 번 자동으로 띄운다', (tester) async {
      final c = await pumpHost(tester);
      expect(c.sessions, hasLength(1));
      expect(ptys.calls.single.cwd, '/repo');
      expect(ptys.calls.single.shell, fakeBash);
      expect(c.autoOpened, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('탭을 모두 닫으면 안내가 나오고, 다시 자동으로 띄우지 않는다', (tester) async {
      final c = await pumpHost(tester);
      c.closeAt(0);
      await _flush(tester);
      expect(c.sessions, isEmpty);
      expect(find.text('열린 터미널이 없습니다'), findsOneWidget);
      // 패널을 내렸다가 다시 올려도 자동으로 띄우지 않는다
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pumpWidget(
        _host(TerminalHost(controller: c, settings: settings, workspace: ws)),
      );
      await _flush(tester);
      expect(c.sessions, isEmpty);
      expect(ptys.made, hasLength(1));
    });

    testWidgets('새 터미널 단추로 같은 저장소 루트에서 탭을 더한다', (tester) async {
      final c = await pumpHost(tester);
      await tester.tap(find.byTooltip('새 터미널'));
      await _flush(tester);
      expect(c.sessions, hasLength(2));
      expect(ptys.calls.last.cwd, '/repo');
      expect(c.selected, 1);
    });

    testWidgets('셸이 둘 이상이면 새 터미널 단추가 목록을 보인다', (tester) async {
      final c = await pumpHost(tester, shells: [fakeBash, fakeZsh]);
      await tester.tap(find.byTooltip('새 터미널'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.tap(find.text('zsh').last);
      await _flush(tester);
      expect(c.sessions, hasLength(2));
      expect(ptys.calls.last.shell, fakeZsh);
    });

    testWidgets('탭을 누르면 선택이 옮겨 가고 닫기 단추로 닫는다', (tester) async {
      final c = await pumpHost(tester, shells: [fakeBash, fakeZsh]);
      c.add('/repo', fakeZsh);
      await _flush(tester);
      expect(c.selected, 1);
      await tester.tap(find.text('bash').first);
      await _flush(tester);
      expect(c.selected, 0);
      await tester.tap(find.byTooltip('터미널 닫기').first);
      await _flush(tester);
      expect(c.sessions, hasLength(1));
    });

    testWidgets('셸이 끝나면 종료 안내와 다시 시작 단추가 나오고, 누르면 같은 폴더에서 다시 띄운다', (tester) async {
      await pumpHost(tester);
      ptys.last.finish(3);
      await _flush(tester);
      expect(find.text('bash 종료됨 (코드 3)'), findsOneWidget);
      await tester.tap(find.text('다시 시작'));
      await _flush(tester);
      expect(ptys.made, hasLength(2));
      expect(ptys.calls.last.cwd, '/repo');
      expect(find.textContaining('종료됨'), findsNothing);
    });

    testWidgets('셸을 띄우지 못하면 오류 안내가 나온다', (tester) async {
      ptys.failWith = StateError('no pty');
      await pumpHost(tester);
      expect(find.textContaining('셸을 시작하지 못했습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('쓸 수 있는 셸이 없으면 안내만 나온다', (tester) async {
      final c = await pumpHost(tester, shells: const []);
      expect(c.sessions, isEmpty);
      expect(find.byTooltip('쓸 수 있는 셸을 찾지 못했습니다'), findsOneWidget);
    });
  });

  group('셸 안에서', () {
    Future<(PanelLayout, TerminalSessionsController)> pumpShell(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1240, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final appSettings = await AppSettings.load();
      final panels = PanelLayout(await SharedPreferences.getInstance());
      final c = fakeTerminals(ptys);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        PanelLayoutScope(
          panels: panels,
          child: TerminalSettingsScope(
            settings: settings,
            child: AppSettingsScope(
              settings: appSettings,
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
                  terminals: c,
                  terminalSettings: settings,
                ),
              ),
            ),
          ),
        ),
      );
      await _flush(tester);
      return (panels, c);
    }

    testWidgets('터미널을 켜면 셸이 저장소 루트에서 뜨고, 에디터와 전환해도 세션이 그대로다', (tester) async {
      final (panels, c) = await pumpShell(tester);
      expect(ptys.made, isEmpty); // 켜기 전에는 셸을 띄우지 않는다
      panels.setTerminal(true);
      await _flush(tester);
      expect(ptys.made, hasLength(1));
      expect(ptys.calls.single.cwd, '/repo');
      panels.setEditor(true); // 에디터가 켜지며 보이는 쪽이 에디터로 바뀐다
      await _flush(tester);
      panels.showCenter(CenterView.terminal);
      await _flush(tester);
      expect(ptys.made, hasLength(1)); // 새로 띄우지 않았다 — 같은 세션
      expect(c.sessions, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('터미널 패널을 껐다 켜도 세션이 살아 있고 새로 띄우지 않는다', (tester) async {
      final (panels, c) = await pumpShell(tester);
      panels.setTerminal(true);
      await _flush(tester);
      ptys.last.emit('hello\r\n');
      panels.setTerminal(false);
      await _flush(tester);
      expect(ptys.last.killed, isFalse); // 패널을 껐다고 셸을 끝내지 않는다
      panels.setTerminal(true);
      await _flush(tester);
      expect(ptys.made, hasLength(1));
      expect(c.sessions, hasLength(1));
    });
  });

  group('터미널 설정', () {
    test('크기와 스크롤백을 범위 안으로 맞추고 저장한다', () async {
      final ws2 = await makeWorkspace();
      final s = TerminalSettings(ws2.prefs);
      expect(s.size, TerminalSettings.defaultSize);
      expect(s.scrollback, TerminalSettings.defaultScrollback);
      await s.setSize(100);
      expect(s.size, TerminalSettings.maxSize);
      await s.setSize(1);
      expect(s.size, TerminalSettings.minSize);
      await s.setScrollback(10);
      expect(s.scrollback, TerminalSettings.minScrollback);
      await s.setSize(16);
      await s.setScrollback(50000);
      final again = TerminalSettings(ws2.prefs);
      expect(again.size, 16);
      expect(again.scrollback, 50000);
      ws2.dispose();
    });

    test('바뀔 때만 알린다', () async {
      var n = 0;
      settings.addListener(() => n++);
      await settings.setSize(settings.size);
      expect(n, 0);
      await settings.setSize(settings.size + 1);
      expect(n, 1);
    });

    testWidgets('설정 창에 터미널 구역이 있고 글자 크기를 바꾸면 반영된다', (tester) async {
      tester.view.physicalSize = const Size(700, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final appSettings = await AppSettings.load();
      await tester.pumpWidget(
        TerminalSettingsScope(
          settings: settings,
          child: AppSettingsScope(
            settings: appSettings,
            child: MaterialApp(
              theme: AppTheme.light(),
              locale: const Locale('ko'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: SettingsDialog(initial: SettingsSection.terminal)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('스크롤백 줄 수'), findsOneWidget);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, TerminalSettings.defaultSize);
      slider.onChanged!(18);
      await tester.pump();
      expect(settings.size, 18);
    });
  });
}
