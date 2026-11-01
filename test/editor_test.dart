// 내장 에디터 (PLAN.md §1.13, 단계 15의 첫 차례): 탭 열기·저장·디스크 변경 감지, 탭 줄·저장 확인, 글자 크기 배율,
// 셸 안에서 탐색기 → 에디터 연결. 진짜 파일(임시 폴더)로 확인한다.

import 'dart:io';

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/editor/editor_controller.dart';
import 'package:daylight_taskbench/editor/editor_host.dart';
import 'package:daylight_taskbench/editor/editor_tab.dart';
import 'package:daylight_taskbench/editor/editor_zoom.dart';
import 'package:daylight_taskbench/explorer/file_opener.dart';
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
  late EditorController c;

  setUp(() async {
    dir = await tempDir('editor');
    c = EditorController();
  });

  tearDown(() async {
    c.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  File write(String name, String text) =>
      File('${dir.path}/$name')..writeAsStringSync(text);

  group('EditorController — 열기', () {
    test('파일을 탭으로 열고, 같은 파일을 다시 열면 새 탭 없이 그 탭으로 옮긴다', () async {
      final a = write('a.dart', 'void main() {}\n');
      final b = write('b.dart', 'x');
      await c.openFile(a.path);
      await c.openFile(b.path);
      expect(c.tabs.map((t) => t.name), ['a.dart', 'b.dart']);
      expect(c.activeTab?.name, 'b.dart');
      await c.openFile(a.path);
      expect(c.tabs, hasLength(2));
      expect(c.activeTab?.name, 'a.dart');
      expect(c.tabFor(a.path)?.controller.text, 'void main() {}\n');
    });

    test('열자마자 수정됨으로 보이지 않는다 (CRLF 파일 포함)', () async {
      final f = write('crlf.txt', 'a\r\nb\r\n');
      await c.openFile(f.path);
      expect(c.activeTab!.dirty, isFalse);
    });

    test('2MB 보다 큰 파일은 열지 않고 알린다', () async {
      final f = File('${dir.path}/big.txt')
        ..writeAsBytesSync(List.filled(EditorController.maxFileBytes + 1, 65));
      await c.openFile(f.path);
      expect(c.tabs, isEmpty);
      expect(c.message?.kind, EditorMessageKind.fileTooLarge);
      expect(c.message?.arg, 'big.txt');
    });

    test('글자 파일(UTF-8)이 아니면 열지 않고 알린다', () async {
      final f = File('${dir.path}/bin.dat')..writeAsBytesSync([0xff, 0xfe, 0x00, 0xc3]);
      await c.openFile(f.path);
      expect(c.tabs, isEmpty);
      expect(c.message?.kind, EditorMessageKind.notUtf8Open);
    });

    test('없는 파일은 읽기 실패로 알린다', () async {
      await c.openFile('${dir.path}/missing.txt');
      expect(c.tabs, isEmpty);
      expect(c.message?.kind, EditorMessageKind.readFailed);
    });

    test('openAt: 그 줄·칸에 커서를 두고 그 탭을 보인다 (범위를 벗어나면 맞춘다)', () async {
      final f = write('lines.txt', 'one\ntwo\nthree\n');
      await c.openAt(f.path, 2, 3);
      final sel = c.activeTab!.controller.selection;
      expect(sel.extentIndex, 1);
      expect(sel.extentOffset, 2);
      await c.openAt(f.path, 99, 99);
      expect(c.activeTab!.controller.selection.extentIndex, c.activeTab!.controller.codeLines.length - 1);
    });
  });

  group('EditorController — 탭', () {
    Future<void> openThree() async {
      for (final n in ['a', 'b', 'c']) {
        await c.openFile(write('$n.txt', n).path);
      }
    }

    test('closeTab: 보던 탭이 아닌 것을 닫아도 보던 탭은 그대로다', () async {
      await openThree();
      c.selectTab(2); // c
      c.closeTab(0); // a 를 닫는다
      expect(c.tabs.map((t) => t.name), ['b.txt', 'c.txt']);
      expect(c.activeTab?.name, 'c.txt');
    });

    test('closeTab: 보던 탭을 닫으면 이웃 탭이 보이고, 마지막이면 앞 탭이 보인다', () async {
      await openThree();
      c.selectTab(1);
      c.closeTab(1);
      expect(c.activeTab?.name, 'c.txt'); // 다음 탭
      c.closeTab(1);
      expect(c.activeTab?.name, 'a.txt'); // 마지막을 닫았으니 앞 탭
      c.closeTab(0);
      expect(c.tabs, isEmpty);
      expect(c.activeTab, isNull);
      expect(c.activeIndex, -1);
    });

    test('moveTab: 순서만 바꾸고 보던 탭은 그대로 본다', () async {
      await openThree();
      c.selectTab(0); // a
      c.moveTab(0, 2);
      expect(c.tabs.map((t) => t.name), ['b.txt', 'c.txt', 'a.txt']);
      expect(c.activeTab?.name, 'a.txt');
    });

    test('selectTab 은 범위를 벗어난 번호를 무시한다', () async {
      await openThree();
      c.selectTab(7);
      c.selectTab(-1);
      expect(c.activeIndex, 2);
    });
  });

  group('EditorController — 저장', () {
    test('고치면 수정됨, 저장하면 파일에 쓰고 수정됨이 풀린다', () async {
      final f = write('s.txt', 'old');
      await c.openFile(f.path);
      final tab = c.activeTab!;
      tab.controller.text = 'new text';
      expect(tab.dirty, isTrue);
      expect(c.hasUnsaved, isTrue);
      expect(await c.save(tab), isTrue);
      expect(f.readAsStringSync(), 'new text');
      expect(tab.dirty, isFalse);
      expect(c.hasUnsaved, isFalse);
    });

    test('saveAll: 고친 탭만 모두 저장한다', () async {
      final a = write('a.txt', '1');
      final b = write('b.txt', '2');
      await c.openFile(a.path);
      await c.openFile(b.path);
      c.tabFor(a.path)!.controller.text = 'A';
      expect(await c.saveAll(), isTrue);
      expect(a.readAsStringSync(), 'A');
      expect(b.readAsStringSync(), '2');
    });

    test('저장하지 못하면 false 와 알림 (폴더가 사라진 경우)', () async {
      final sub = Directory('${dir.path}/sub')..createSync();
      final f = File('${sub.path}/x.txt')..writeAsStringSync('x');
      await c.openFile(f.path);
      c.activeTab!.controller.text = 'y';
      sub.deleteSync(recursive: true);
      expect(await c.save(c.activeTab!), isFalse);
      expect(c.message?.kind, EditorMessageKind.saveFailed);
    });
  });

  group('EditorController — 디스크 변경 감지', () {
    Future<EditorTab> open(String name, String text) async {
      final f = write(name, text);
      await c.openFile(f.path);
      return c.tabFor(f.path)!;
    }

    /// 수정 시각이 같은 초에 겹치지 않도록 파일의 시각을 뒤로 민다.
    void touchLater(File f) =>
        f.setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));

    test('고치지 않은 탭은 디스크가 바뀌면 조용히 다시 읽고 알린다', () async {
      final tab = await open('r.txt', 'one');
      final f = File(tab.path)..writeAsStringSync('two');
      touchLater(f);
      await c.checkExternalChanges();
      expect(tab.controller.text, 'two');
      expect(tab.dirty, isFalse);
      expect(tab.external, ExternalChange.none);
      expect(c.message?.kind, EditorMessageKind.changedReloaded);
    });

    test('고치던 탭은 덮어쓰지 않고 표시만 한다. 저장도 막는다', () async {
      final tab = await open('m.txt', 'one');
      tab.controller.text = 'mine';
      final f = File(tab.path)..writeAsStringSync('theirs');
      touchLater(f);
      await c.checkExternalChanges();
      expect(tab.controller.text, 'mine');
      expect(tab.external, ExternalChange.modified);
      expect(await c.save(tab), isFalse);
      expect(c.message?.kind, EditorMessageKind.diskChangedSaveBlocked);
      expect(f.readAsStringSync(), 'theirs'); // 남의 수정을 덮어쓰지 않았다
    });

    test('keepMine 은 표시를 풀고, 그 뒤 저장하면 내 글로 덮어쓴다', () async {
      final tab = await open('k.txt', 'one');
      tab.controller.text = 'mine';
      final f = File(tab.path)..writeAsStringSync('theirs');
      touchLater(f);
      await c.checkExternalChanges();
      c.keepMine(tab);
      expect(tab.external, ExternalChange.none);
      expect(await c.save(tab), isTrue);
      expect(f.readAsStringSync(), 'mine');
    });

    test('reloadFromDisk 는 내 수정을 버리고 디스크 글을 읽는다', () async {
      final tab = await open('l.txt', 'one');
      tab.controller.text = 'mine';
      final f = File(tab.path)..writeAsStringSync('theirs');
      touchLater(f);
      await c.checkExternalChanges();
      await c.reloadFromDisk(tab);
      expect(tab.controller.text, 'theirs');
      expect(tab.dirty, isFalse);
      expect(tab.external, ExternalChange.none);
      expect(c.message?.kind, EditorMessageKind.reloadedFromDisk);
    });

    test('파일이 사라지면 deleted 로 표시하고 탭은 남긴다 (고치던 글을 잃지 않게)', () async {
      final tab = await open('d.txt', 'one');
      tab.controller.text = 'mine';
      File(tab.path).deleteSync();
      await c.checkExternalChanges();
      expect(tab.external, ExternalChange.deleted);
      expect(c.tabs, contains(tab));
      expect(tab.controller.text, 'mine');
    });

    test('글은 같고 시각만 바뀌었으면 아무 일도 없다', () async {
      final tab = await open('t.txt', 'same');
      touchLater(File(tab.path));
      await c.checkExternalChanges();
      expect(tab.external, ExternalChange.none);
      expect(c.message, isNull);
    });
  });

  group('EditorZoom', () {
    test('범위 안으로 맞추고, 바뀔 때만 알리고, 저장했다가 다시 읽는다', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final z = EditorZoom(prefs);
      var n = 0;
      z.addListener(() => n++);
      expect(z.isDefault, isTrue);
      z.zoomIn();
      expect(z.percent, 110);
      z.setValue(99);
      expect(z.value, EditorZoom.max);
      z.setValue(0);
      expect(z.value, EditorZoom.min);
      z.setValue(EditorZoom.min); // 같은 값은 알리지 않는다
      expect(n, 3);
      z.setValue(1.5);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(EditorZoom(prefs).value, 1.5);
      z.reset();
      expect(z.isDefault, isTrue);
    });
  });

  group('화면', () {
    Widget app(Widget home, {EditorZoom? zoom}) {
      Widget child = MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      );
      if (zoom != null) child = EditorZoomScope(zoom: zoom, child: child);
      return child;
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> pump(WidgetTester tester, {EditorZoom? zoom}) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(EditorHost(controller: c), zoom: zoom));
      await settle(tester);
    }

    testWidgets('탭이 없으면 안내 문구만 보인다', (tester) async {
      await pump(tester);
      expect(find.text('탐색기에서 파일을 열면 여기에 나타납니다'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('파일을 열면 탭 줄·언어 이름·편집 영역이 보이고, 고치면 ● 가 붙는다', (tester) async {
      final f = write('main.dart', 'void main() {}\n');
      await pump(tester);
      await tester.runAsync(() => c.openFile(f.path));
      await settle(tester);
      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(tester.takeException(), isNull);
      c.activeTab!.controller.text = 'void main() {}\n// 수정';
      await settle(tester);
      expect(find.text('● main.dart'), findsOneWidget);
    });

    testWidgets('저장 단추는 고쳤을 때만 켜지고, 누르면 저장한다', (tester) async {
      final f = write('s.txt', 'a');
      await pump(tester);
      await tester.runAsync(() => c.openFile(f.path));
      await settle(tester);
      IconButton save() => tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.save_outlined));
      expect(save().onPressed, isNull);
      c.activeTab!.controller.text = 'b';
      await settle(tester);
      expect(save().onPressed, isNotNull);
      save().onPressed!();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await settle(tester);
      expect(f.readAsStringSync(), 'b');
      expect(save().onPressed, isNull);
    });

    testWidgets('고친 탭을 닫으면 저장 여부를 묻는다: 취소 · 저장 안 함 · 저장', (tester) async {
      final f = write('q.txt', 'a');
      await pump(tester);
      await tester.runAsync(() => c.openFile(f.path));
      await settle(tester);
      c.activeTab!.controller.text = 'edited';
      await settle(tester);

      await tester.tap(find.byTooltip('닫기').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('q.txt 저장할까요?'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(c.tabs, hasLength(1)); // 취소하면 그대로

      await tester.tap(find.byTooltip('닫기').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.tap(find.text('저장 안 함'));
      await settle(tester);
      expect(c.tabs, isEmpty);
      expect(f.readAsStringSync(), 'a'); // 저장하지 않았다
    });

    testWidgets('저장하고 닫기', (tester) async {
      final f = write('w.txt', 'a');
      await pump(tester);
      await tester.runAsync(() => c.openFile(f.path));
      await settle(tester);
      c.activeTab!.controller.text = 'saved';
      await settle(tester);
      await tester.tap(find.byTooltip('닫기').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        await tester.tap(find.text('저장'));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await settle(tester);
      expect(f.readAsStringSync(), 'saved');
      expect(c.tabs, isEmpty);
    });

    testWidgets('고치지 않은 탭은 묻지 않고 닫힌다', (tester) async {
      final f = write('n.txt', 'a');
      await pump(tester);
      await tester.runAsync(() => c.openFile(f.path));
      await settle(tester);
      await tester.tap(find.byTooltip('닫기').last);
      await settle(tester);
      expect(c.tabs, isEmpty);
    });

    testWidgets('디스크에서 바뀐 파일을 고치던 중이면 배너로 고르게 한다', (tester) async {
      final f = write('e.txt', 'one');
      await pump(tester);
      await tester.runAsync(() => c.openFile(f.path));
      await settle(tester);
      c.activeTab!.controller.text = 'mine';
      f.writeAsStringSync('theirs');
      f.setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));
      await tester.runAsync(() => c.checkExternalChanges());
      await settle(tester);
      expect(find.textContaining('디스크의 파일이 바뀌었습니다'), findsOneWidget);
      await tester.tap(find.text('내 수정 유지'));
      await settle(tester);
      expect(find.textContaining('디스크의 파일이 바뀌었습니다'), findsNothing);
    });

    testWidgets('컨트롤러가 남긴 알림을 번역해 한 번 보이고 지운다', (tester) async {
      await pump(tester);
      await tester.runAsync(() => c.openFile('${dir.path}/missing.txt'));
      await settle(tester);
      expect(c.message, isNull); // 한 번 보이고 지웠다
      expect(find.textContaining('파일을 읽지 못했습니다'), findsOneWidget);
    });

    testWidgets('글자 크기: 배율 단추가 현재 비율을 보이고, 누르면 100%로 돌아간다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final zoom = EditorZoom(await SharedPreferences.getInstance())..setValue(1.5);
      final f = write('z.txt', 'a');
      await pump(tester, zoom: zoom);
      await tester.runAsync(() => c.openFile(f.path));
      await settle(tester);
      expect(find.text('150%'), findsOneWidget);
      await tester.tap(find.text('150%'));
      await settle(tester);
      expect(zoom.isDefault, isTrue);
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('셸 안에서', () {
    late Directory repo;
    setUp(() async => repo = await tempDir('editor_repo'));
    tearDown(() => repo.deleteSync(recursive: true));

    Future<({PanelLayout panels, EditorController editor, List<List<String>> started})> pumpShell(
      WidgetTester tester, {
      bool embedded = true,
    }) async {
      File('${repo.path}/lib/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}\n');
      tester.view.physicalSize = const Size(1240, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load();
      final panels = PanelLayout(await SharedPreferences.getInstance());
      if (!embedded) panels.setEmbeddedEditor(false);
      final ws = await makeWorkspace();
      await ws.setEditorCommand('myeditor');
      ws.attachForTest(
        FakeGitStateSource(GitState(root: repo.path, branch: 'main', sha: 'a1')),
        selectedDir: '${repo.path}/lib',
      );
      final editor = EditorController();
      addTearDown(editor.dispose);
      final started = <List<String>>[];
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
                opener: FileOpener(ws, start: (c) async => started.add(c)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      panels.setExplorer(true);
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      return (panels: panels, editor: editor, started: started);
    }

    Future<void> doubleTap(WidgetTester tester, Finder f) async {
      await tester.tap(f);
      await tester.pump();
      await tester.tap(f);
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('작업대에서 파일을 두 번 누르면 에디터 패널이 켜지고 내장 에디터 탭으로 열린다', (tester) async {
      final r = await pumpShell(tester);
      expect(r.panels.editor, isFalse);
      await doubleTap(tester, find.text('main.dart'));
      expect(r.panels.editor, isTrue); // 꺼져 있던 에디터 패널이 켜졌다
      expect(r.editor.tabs.map((t) => t.name), ['main.dart']);
      expect(r.started, isEmpty); // 외부 편집기는 쓰지 않았다
      expect(r.panels.center, CenterView.editor);
      expect(tester.takeException(), isNull);
    });

    testWidgets('내장 에디터를 껐으면 외부 편집기로 연다 (에디터 패널은 켜지지 않는다)', (tester) async {
      final r = await pumpShell(tester, embedded: false);
      await doubleTap(tester, find.text('main.dart'));
      expect(r.started, [
        ['myeditor', '${repo.path}/lib/main.dart'],
      ]);
      expect(r.editor.tabs, isEmpty);
      expect(r.panels.editorShown, isFalse);
    });

    testWidgets('에디터 패널을 껐다 켜도 열린 탭과 고치던 글이 남아 있다', (tester) async {
      final r = await pumpShell(tester);
      await doubleTap(tester, find.text('main.dart'));
      r.editor.activeTab!.controller.text = '// 고치던 글';
      r.panels.setEditor(false);
      await tester.pump(const Duration(milliseconds: 100));
      r.panels.setEditor(true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(r.editor.tabs, hasLength(1));
      expect(r.editor.activeTab!.controller.text, '// 고치던 글');
      expect(r.editor.activeTab!.dirty, isTrue);
    });
  });
}
