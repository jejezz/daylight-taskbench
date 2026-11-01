// 열린 파일 보호 (PLAN.md §1.10 확장, 단계 16 앞당김): ① 브랜치·커밋이 바뀐 뒤 열린 파일 정리 ② 저장하지 않은 수정이
// 있을 때 앱 종료 확인. 진짜 파일(임시 폴더)로 확인한다.

import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/editor/editor_controller.dart';
import 'package:daylight_taskbench/editor/editor_tab.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_layout.dart';
import 'package:daylight_taskbench/ui/shell/taskbench_shell.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'terminal/helpers/fake_pty.dart';
import 'terminal/helpers/fake_shell_finder.dart';
import 'test_support.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await tempDir('guard'));
  tearDown(() => dir.deleteSync(recursive: true));

  File write(String name, String text) => File('${dir.path}/$name')..writeAsStringSync(text);

  /// 파일을 바꾸고 수정 시각을 확실히 뒤로 민다 (브랜치 전환이 파일을 새로 쓰는 것을 흉내).
  void checkout(File f, String text) {
    f.writeAsStringSync(text);
    f.setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));
  }

  group('브랜치·커밋이 바뀐 뒤 열린 파일 정리', () {
    late EditorController c;
    setUp(() => c = EditorController());
    tearDown(() => c.dispose());

    Future<EditorTab> open(File f) async {
      await c.openFile(f.path);
      return c.tabFor(f.path)!;
    }

    test('고치지 않은 탭은 다시 읽고, 파일별 알림 없이 한 번의 요약만 남긴다', () async {
      final f = write('a.txt', 'main');
      final tab = await open(f);
      checkout(f, 'feature');
      await c.handleHeadChange();
      expect(tab.controller.text, 'feature');
      expect(tab.dirty, isFalse);
      expect(c.message?.kind, EditorMessageKind.headChanged);
      expect(c.message?.counts, [1, 0, 0]); // 다시 읽음 · 닫음 · 남김
    });

    test('이 브랜치에 없는 파일의 고치지 않은 탭은 닫는다 (보기만 하던 탭)', () async {
      final keep = await open(write('keep.txt', 'k'));
      final gone = write('gone.txt', 'g');
      await open(gone);
      expect(c.activeTab?.name, 'gone.txt');
      gone.deleteSync();
      await c.handleHeadChange();
      expect(c.tabs, [keep]);
      expect(c.activeTab, keep); // 보던 탭이 없어졌으니 남은 탭으로
      expect(c.message?.counts, [0, 1, 0]);
    });

    test('마지막 탭이 닫히면 보던 탭이 없는 상태가 된다', () async {
      final f = write('only.txt', 'x');
      await open(f);
      f.deleteSync();
      await c.handleHeadChange();
      expect(c.tabs, isEmpty);
      expect(c.activeIndex, -1);
      expect(c.activeTab, isNull);
    });

    test('고치던 탭은 닫지도 덮어쓰지도 않는다 — 표시만 하고 개수에 센다', () async {
      final f = write('mine.txt', 'one');
      final tab = await open(f);
      tab.controller.text = 'my edit';
      checkout(f, 'theirs');
      await c.handleHeadChange();
      expect(tab.controller.text, 'my edit');
      expect(tab.external, ExternalChange.modified);
      expect(c.tabs, contains(tab));
      expect(c.message?.counts, [0, 0, 1]);
      expect(await c.save(tab), isFalse); // 저장도 막는다
      expect(f.readAsStringSync(), 'theirs');
    });

    test('고치던 탭의 파일이 이 브랜치에 없으면 탭을 남기고 deleted 로 표시한다', () async {
      final f = write('edited.txt', 'one');
      final tab = await open(f);
      tab.controller.text = 'my edit';
      f.deleteSync();
      await c.handleHeadChange();
      expect(c.tabs, contains(tab));
      expect(tab.external, ExternalChange.deleted);
      expect(tab.controller.text, 'my edit');
      expect(c.message?.counts, [0, 0, 1]);
    });

    test('다시 읽음·닫음·남김이 섞여도 하나의 요약으로 센다', () async {
      final a = write('a.txt', '1');
      final b = write('b.txt', '2');
      final d = write('d.txt', '3');
      await open(a);
      await open(b);
      final dirty = await open(d);
      dirty.controller.text = 'edit';
      checkout(a, 'A');
      b.deleteSync();
      checkout(d, 'D');
      await c.handleHeadChange();
      expect(c.message?.counts, [1, 1, 1]);
      expect(c.tabs.map((t) => t.name), ['a.txt', 'd.txt']);
    });

    test('바뀐 것이 없으면 알림도 남기지 않는다', () async {
      await open(write('same.txt', 'x'));
      await c.handleHeadChange();
      expect(c.message, isNull);
    });

    test('주기 확인(afterHeadChange 아님)은 전과 같다: 파일별 알림, 없어진 탭은 남긴다', () async {
      final f = write('p.txt', 'one');
      final tab = await open(f);
      checkout(f, 'two');
      await c.checkExternalChanges();
      expect(c.message?.kind, EditorMessageKind.changedReloaded);
      f.deleteSync();
      await c.checkExternalChanges();
      expect(c.tabs, contains(tab)); // 닫지 않는다
      expect(tab.external, ExternalChange.deleted);
    });
  });

  group('셸 안에서', () {
    /// 가짜 시계 안에서 시작한 파일 쓰기가 끝나도록 실제 시간을 주면서 프레임을 돌려 [f]가 끝나길 기다린다.
    Future<T> finish<T>(WidgetTester tester, Future<T> f) async {
      T? value;
      var done = false;
      f.then((v) {
        value = v;
        done = true;
      });
      for (var i = 0; i < 100 && !done; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(done, isTrue, reason: '끝나지 않았다');
      return value as T;
    }

    late EditorController editor;
    late FakeGitStateSource source;

    Future<PanelLayout> pumpShell(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1240, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load();
      final panels = PanelLayout(await SharedPreferences.getInstance());
      final ws = await makeWorkspace();
      source = FakeGitStateSource(GitState(root: dir.path, branch: 'main', sha: 'a1'));
      ws.attachForTest(source, selectedDir: dir.path);
      editor = EditorController();
      addTearDown(editor.dispose);
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
                editor: editor,
                terminals: fakeTerminals(FakePtyFactory()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return panels;
    }

    /// 가짜 시계 안에서 시작한 파일 읽기(탭마다 여러 번)가 끝나도록 실제 시간을 주고 프레임을 돌린다.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 16; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    group('종료 확인', () {
      testWidgets('에디터에 열린 것이 없으면 묻지 않고 종료를 허락한다', (tester) async {
        await pumpShell(tester);
        expect(await tester.binding.handleRequestAppExit(), AppExitResponse.exit);
      });

      testWidgets('고치지 않은 탭만 있으면 묻지 않는다', (tester) async {
        await pumpShell(tester);
        await tester.runAsync(() => editor.openFile(write('clean.txt', 'x').path));
        expect(await tester.binding.handleRequestAppExit(), AppExitResponse.exit);
      });

      testWidgets('저장하지 않은 수정이 있으면 파일 이름을 보이며 묻고, 취소하면 종료를 막는다', (tester) async {
        await pumpShell(tester);
        await tester.runAsync(() => editor.openFile(write('dirty.txt', 'x').path));
        editor.activeTab!.controller.text = 'changed';
        final result = tester.binding.handleRequestAppExit();
        await tester.pumpAndSettle();
        expect(find.text('저장하지 않은 수정이 있습니다'), findsOneWidget);
        expect(find.textContaining('dirty.txt'), findsOneWidget);
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        expect(await result, AppExitResponse.cancel);
        expect(editor.activeTab!.dirty, isTrue);
      });

      testWidgets('저장하지 않고 종료: 파일을 건드리지 않고 종료를 허락한다', (tester) async {
        await pumpShell(tester);
        final f = write('discard.txt', 'orig');
        await tester.runAsync(() => editor.openFile(f.path));
        editor.activeTab!.controller.text = 'changed';
        final result = tester.binding.handleRequestAppExit();
        await tester.pumpAndSettle();
        await tester.tap(find.text('저장하지 않고 종료'));
        await tester.pumpAndSettle();
        expect(await result, AppExitResponse.exit);
        expect(f.readAsStringSync(), 'orig');
      });

      testWidgets('모두 저장하고 종료: 고친 파일을 모두 저장한 뒤 종료를 허락한다', (tester) async {
        await pumpShell(tester);
        final a = write('a.txt', '1');
        final b = write('b.txt', '2');
        await tester.runAsync(() async {
          await editor.openFile(a.path);
          await editor.openFile(b.path);
        });
        editor.tabFor(a.path)!.controller.text = 'A';
        editor.tabFor(b.path)!.controller.text = 'B';
        final result = tester.binding.handleRequestAppExit();
        await tester.pumpAndSettle();
        expect(find.textContaining('2개 파일'), findsOneWidget);
        await tester.tap(find.text('모두 저장하고 종료'));
        expect(await finish(tester, result), AppExitResponse.exit);
        expect(a.readAsStringSync(), 'A');
        expect(b.readAsStringSync(), 'B');
      });

      testWidgets('저장하지 못한 파일이 있으면 종료를 취소하고 알린다 (잃지 않게)', (tester) async {
        await pumpShell(tester);
        final sub = Directory('${dir.path}/sub')..createSync();
        final f = File('${sub.path}/x.txt')..writeAsStringSync('x');
        await tester.runAsync(() => editor.openFile(f.path));
        editor.activeTab!.controller.text = 'y';
        sub.deleteSync(recursive: true); // 저장할 곳이 사라졌다
        final result = tester.binding.handleRequestAppExit();
        await tester.pumpAndSettle();
        await tester.tap(find.text('모두 저장하고 종료'));
        expect(await finish(tester, result), AppExitResponse.cancel);
        await tester.pump();
        expect(find.textContaining('종료를 취소했습니다'), findsOneWidget);
        expect(editor.activeTab!.dirty, isTrue);
      });

      testWidgets('이미 묻는 중에 또 종료 요청이 오면 그 요청은 취소한다', (tester) async {
        await pumpShell(tester);
        await tester.runAsync(() => editor.openFile(write('twice.txt', 'x').path));
        editor.activeTab!.controller.text = 'changed';
        final first = tester.binding.handleRequestAppExit();
        await tester.pumpAndSettle();
        expect(await tester.binding.handleRequestAppExit(), AppExitResponse.cancel);
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        expect(await first, AppExitResponse.cancel);
      });
    });

    group('브랜치 전환', () {
      testWidgets('브랜치가 바뀌면 열린 파일을 바로 정리하고 한 번 알린다', (tester) async {
        final panels = await pumpShell(tester);
        panels
          ..setExplorer(true)
          ..setEditor(true);
        final keep = write('keep.txt', 'main');
        final gone = write('gone.txt', 'g');
        await tester.runAsync(() async {
          await editor.openFile(keep.path);
          await editor.openFile(gone.path);
        });
        await settle(tester);
        checkout(keep, 'feature');
        gone.deleteSync();
        source.set(GitState(root: dir.path, branch: 'feature', sha: 'b2'));
        await settle(tester);
        expect(editor.tabs.map((t) => t.name), ['keep.txt']);
        expect(editor.tabs.single.controller.text, 'feature');
        // 요약 알림(에디터가 보이므로 한 번 보이고 지운다)
        expect(find.textContaining('브랜치가 바뀌어 열린 파일을 정리했습니다'), findsOneWidget);
        expect(find.textContaining('다시 읽음 1개'), findsOneWidget);
        expect(find.textContaining('닫은 탭 1개'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('에디터 패널이 꺼져 있는 동안의 정리 요약은 에디터를 다시 켰을 때 보인다', (tester) async {
        final panels = await pumpShell(tester);
        final f = write('later.txt', 'main');
        await tester.runAsync(() => editor.openFile(f.path));
        checkout(f, 'feature');
        source.set(GitState(root: dir.path, branch: 'feature', sha: 'b2'));
        await settle(tester);
        expect(editor.message?.kind, EditorMessageKind.headChanged); // 아직 보이지 않았다
        panels
          ..setExplorer(true)
          ..setEditor(true);
        await settle(tester);
        expect(find.textContaining('다시 읽음 1개'), findsOneWidget);
      });
    });
  });
}
