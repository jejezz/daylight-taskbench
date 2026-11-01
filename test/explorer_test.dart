// 탐색기 (PLAN.md §1.13, 단계 13): 파일 종류·점수·목록, 파일 트리, 탐색기 패널, 외부 편집기로 열기, 빠른 열기.

import 'dart:io';

import 'package:daylight_taskbench/docks/branch/branch_dock.dart';
import 'package:daylight_taskbench/explorer/explorer_panel.dart';
import 'package:daylight_taskbench/explorer/file_kind.dart';
import 'package:daylight_taskbench/explorer/file_opener.dart';
import 'package:daylight_taskbench/explorer/file_tree.dart';
import 'package:daylight_taskbench/explorer/project_files.dart';
import 'package:daylight_taskbench/explorer/quick_open.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_layout.dart';
import 'package:daylight_taskbench/ui/shell/taskbench_shell.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

/// 비동기 파일 읽기가 끝나도록 실제 시간을 조금 준다.
Future<void> _settle(WidgetTester tester) async {
  // initState 에서 시작한 파일 읽기는 가짜 시계 안에서 시작되므로, 실제 시간을 주고 프레임을 돌리는 일을 몇 번 되풀이한다.
  for (var i = 0; i < 16; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  group('fileKindOf', () {
    test('이름과 확장자만 보고 종류를 정한다', () {
      expect(fileKindOf('/a/lib/main.dart'), FileKind.dart);
      expect(fileKindOf('pubspec.yaml'), FileKind.package);
      expect(fileKindOf('/x/pubspec.lock'), FileKind.package);
      expect(fileKindOf('analysis_options.yaml'), FileKind.settings);
      expect(fileKindOf('a.yml'), FileKind.yaml);
      expect(fileKindOf('app_ko.arb'), FileKind.json);
      expect(fileKindOf('README.md'), FileKind.document);
      expect(fileKindOf('LICENSE'), FileKind.document);
      expect(fileKindOf('logo.PNG'), FileKind.image);
      expect(fileKindOf('run.sh'), FileKind.script);
      expect(fileKindOf('.gitignore'), FileKind.config);
      expect(fileKindOf('Main.kt'), FileKind.source);
      expect(fileKindOf('noext'), FileKind.other);
      expect(fileKindOf(r'C:\p\lib\main.dart'), FileKind.dart); // 윈도 경로
    });
  });

  group('빠른 열기 점수', () {
    test('글자가 차례로 들어 있어야 하고, 아니면 null', () {
      expect(fuzzyScore('mnt', 'lib/main.dart'), isNotNull);
      expect(fuzzyScore('mdn', 'lib/main.dart'), isNull); // d 다음에 n 이 없다
      expect(fuzzyScore('xyz', 'lib/main.dart'), isNull);
      expect(fuzzyScore('', 'anything'), 0);
    });

    test('파일 이름에서 맞는 쪽이 더 높다', () {
      final ranked = rankFiles('main', [
        'lib/main/other.dart',
        'lib/main.dart',
        'test/domain_test.dart',
      ]);
      expect(ranked.first, 'lib/main.dart');
    });

    test('limit 만큼만 돌려준다', () {
      final files = [for (var i = 0; i < 100; i++) 'f$i.dart'];
      expect(rankFiles('f', files, limit: 5), hasLength(5));
    });
  });

  group('listProjectFiles', () {
    late Directory root;
    setUp(() async => root = await tempDir('files'));
    tearDown(() => root.deleteSync(recursive: true));

    test('root 기준 `/` 경로를 이름순으로 주고 빌드 산출물·.git·의존성 폴더는 건너뛴다', () async {
      for (final f in [
        'lib/b.dart',
        'lib/a.dart',
        'README.md',
        '.git/config',
        'build/out.txt',
        'node_modules/x/y.js',
        '.dart_tool/z',
      ]) {
        File('${root.path}/$f')
          ..createSync(recursive: true)
          ..writeAsStringSync('x');
      }
      expect(await listProjectFiles(root.path), [
        'README.md',
        'lib/a.dart',
        'lib/b.dart',
      ]);
    });
  });

  group('FileTree', () {
    late Directory root;
    setUp(() async {
      root = await tempDir('tree');
      for (final f in [
        'zeta.txt',
        'Alpha.dart',
        'lib/deep/inner.dart',
        'lib/top.dart',
        '.git/HEAD',
      ]) {
        File('${root.path}/$f')
          ..createSync(recursive: true)
          ..writeAsStringSync('x');
      }
    });
    tearDown(() => root.deleteSync(recursive: true));

    Future<void> pump(
      WidgetTester tester, {
      String? expandTo,
      int revision = 0,
      ValueChanged<String>? onOpen,
    }) async {
      tester.view.physicalSize = const Size(300, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          FileTree(
            root: root.path,
            expandTo: expandTo,
            revision: revision,
            onOpenFile: onOpen ?? (_) {},
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('폴더가 먼저, 그다음 이름순(대소문자 무시). .git 은 보이지 않는다', (tester) async {
      await pump(tester);
      final names = [
        for (final t in tester.widgetList<Text>(find.byType(Text))) t.data,
      ];
      expect(names, contains('lib'));
      expect(names, isNot(contains('.git')));
      expect(names.indexOf('lib'), lessThan(names.indexOf('Alpha.dart')));
      expect(names.indexOf('Alpha.dart'), lessThan(names.indexOf('zeta.txt')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('폴더를 누르면 펼치고 다시 누르면 접는다. 파일을 누르면 경로를 돌려준다', (tester) async {
      String? opened;
      await pump(tester, onOpen: (p) => opened = p);
      expect(find.text('top.dart'), findsNothing);
      await tester.tap(find.text('lib'));
      await _settle(tester);
      expect(find.text('top.dart'), findsOneWidget);
      await tester.tap(find.text('top.dart'));
      expect(opened, '${root.path}/lib/top.dart');
      await tester.tap(find.text('lib'));
      await _settle(tester);
      expect(find.text('top.dart'), findsNothing);
    });

    testWidgets('expandTo 까지 길 위의 폴더를 펼친다 (하위 폴더를 열었을 때)', (tester) async {
      await pump(tester, expandTo: '${root.path}/lib/deep');
      expect(find.text('inner.dart'), findsOneWidget);
      expect(find.text('top.dart'), findsOneWidget); // lib 도 펼쳐졌다
    });

    testWidgets('revision 이 오르면 펼친 폴더를 다시 읽는다', (tester) async {
      await pump(tester);
      expect(find.text('new.dart'), findsNothing);
      File('${root.path}/new.dart').writeAsStringSync('x');
      await tester.pumpWidget(
        _app(
          FileTree(root: root.path, revision: 1, onOpenFile: (_) {}),
        ),
      );
      await _settle(tester);
      expect(find.text('new.dart'), findsOneWidget);
    });
  });

  group('FileOpener', () {
    testWidgets('편집기 명령 설정이 있으면 그 명령에 파일 경로를 붙여 실행한다', (tester) async {
      final ws = await makeWorkspace();
      await ws.setEditorCommand('myeditor --wait');
      List<String>? started;
      final opener = FileOpener(ws, start: (c) async => started = c);
      expect(await opener.open('/p/a.dart'), OpenFileResult.opened);
      expect(started, ['myeditor', '--wait', '/p/a.dart']);
      ws.dispose();
    });

    testWidgets('실행에 실패하면 failed 를 돌려주고 예외를 던지지 않는다', (tester) async {
      final ws = await makeWorkspace();
      await ws.setEditorCommand('myeditor');
      final opener = FileOpener(
        ws,
        start: (_) async => throw const ProcessException('x', []),
      );
      expect(await opener.open('/p/a.dart'), OpenFileResult.failed);
      ws.dispose();
    });
  });

  group('빠른 열기 창', () {
    late Directory root;
    setUp(() async => root = await tempDir('quick'));
    tearDown(() => root.deleteSync(recursive: true));

    testWidgets('목록을 읽는 동안 안내, 입력하면 걸러지고, 고르면 절대 경로를 돌려준다', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked = await showQuickOpen(
                context,
                root: root.path,
                files: Future.value(['lib/main.dart', 'lib/util.dart', 'README.md']),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('README.md'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'util');
      await tester.pumpAndSettle();
      expect(find.text('main.dart'), findsNothing);
      expect(find.text('util.dart'), findsOneWidget);
      await tester.tap(find.text('util.dart'));
      await tester.pumpAndSettle();
      expect(picked, '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}util.dart');
    });

    testWidgets('맞는 파일이 없으면 안내한다. Enter 로 첫 항목을 연다', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked = await showQuickOpen(
                context,
                root: root.path,
                files: Future.value(['a.dart']),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('맞는 파일이 없습니다'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(picked, endsWith('a.dart'));
    });
  });

  group('탐색기 패널 (셸 안에서)', () {
    late Directory repo;
    setUp(() async => repo = await tempDir('panel'));
    tearDown(() => repo.deleteSync(recursive: true));

    testWidgets('탐색기를 켜면 저장소 트리가 보이고, 파일을 누르면 외부 편집기로 연다', (tester) async {
      File('${repo.path}/lib/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('x');
      tester.view.physicalSize = const Size(1240, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load();
      final panels = PanelLayout(await SharedPreferences.getInstance());
      final ws = await makeWorkspace();
      await ws.setEditorCommand('myeditor');
      ws.attachForTest(
        FakeGitStateSource(GitState(root: repo.path, branch: 'main', sha: 'a1')),
        selectedDir: '${repo.path}/lib',
      );
      List<String>? started;
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
                opener: FileOpener(ws, start: (c) async => started = c),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      panels.setExplorer(true);
      await tester.pumpAndSettle();
      await _settle(tester);
      expect(find.byType(ExplorerPanel), findsOneWidget);
      // 고른 하위 폴더(lib)까지 펼쳐져 있다
      expect(find.text('main.dart'), findsOneWidget);
      await tester.tap(find.text('main.dart'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(started, ['myeditor', '${repo.path}/lib/main.dart']);
      expect(tester.takeException(), isNull);
      ws.dispose();
    });
  });
}
