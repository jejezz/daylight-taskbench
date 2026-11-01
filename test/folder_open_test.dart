// 저장소가 아닌 폴더를 열 때의 분기 (PLAN.md §1.13, 단계 12): 하위 저장소 목록 · git init 제안 조건 · 위험한 위치.

import 'dart:io';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/repo_choice.dart';
import 'package:daylight_taskbench/ui/start_screen.dart';
import 'package:daylight_taskbench/workspace/folder_scan.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

/// [home]을 홈 폴더로 삼는 작업 영역.
Future<Workspace> _workspace({String? home}) async {
  SharedPreferences.setMockInitialValues({});
  return Workspace(
    runner: CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? ''),
    prefs: await SharedPreferences.getInstance(),
    scanner: FolderScanner(home: home ?? '/nonexistent-home'),
  );
}

void _repoIn(String dir) => Directory('$dir/.git').createSync(recursive: true);

void main() {
  late Directory root;

  setUp(() async => root = await tempDir('scan'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  String at(String rel) => '${root.path}/$rel';

  group('FolderScanner.findChildRepos', () {
    test('바로 아래와 그 아래 한 단계까지 찾고 이름순으로 돌려준다', () async {
      _repoIn(at('b_app'));
      _repoIn(at('a_app'));
      _repoIn(at('group/c_app')); // 2단계
      _repoIn(at('group/deep/d_app')); // 3단계 — 찾지 않는다
      final found = await FolderScanner(home: '/x').findChildRepos(root.path);
      expect(found, [at('a_app'), at('b_app'), at('group/c_app')]);
    });

    test('저장소 안으로는 들어가지 않는다 (중첩 저장소·서브모듈을 따로 세지 않는다)', () async {
      _repoIn(at('app'));
      _repoIn(at('app/packages/inner'));
      final found = await FolderScanner(home: '/x').findChildRepos(root.path);
      expect(found, [at('app')]);
    });

    test('.git 이 파일인 worktree·서브모듈도 저장소로 센다', () async {
      Directory(at('wt')).createSync();
      File(at('wt/.git')).writeAsStringSync('gitdir: ../elsewhere');
      final found = await FolderScanner(home: '/x').findChildRepos(root.path);
      expect(found, [at('wt')]);
    });

    test('숨김 폴더와 빌드 산출물·의존성 폴더는 건너뛴다', () async {
      _repoIn(at('.hidden/app'));
      _repoIn(at('node_modules/pkg'));
      _repoIn(at('build/out'));
      _repoIn(at('real'));
      final found = await FolderScanner(home: '/x').findChildRepos(root.path);
      expect(found, [at('real')]);
    });

    test('maxRepos 에서 멈춘다', () async {
      for (var i = 0; i < 8; i++) {
        _repoIn(at('r$i'));
      }
      final found = await FolderScanner(home: '/x', maxRepos: 3).findChildRepos(root.path);
      expect(found, hasLength(3));
    });

    test('빈 폴더·읽을 수 없는 폴더는 빈 목록', () async {
      expect(await FolderScanner(home: '/x').findChildRepos(root.path), isEmpty);
      expect(await FolderScanner(home: '/x').findChildRepos(at('missing')), isEmpty);
    });
  });

  group('FolderScanner.isUnsafeInitLocation — 홈 전체가 저장소가 되는 사고를 막는다', () {
    final s = FolderScanner(home: '/Users/me');

    test('홈, 홈의 부모, 홈 아래 바탕화면·문서 같은 기본 폴더', () {
      for (final p in ['/Users/me', '/Users', '/Users/me/Desktop', '/Users/me/Documents', '/Users/me/Downloads', '/Users/me/Library']) {
        expect(s.isUnsafeInitLocation(p), isTrue, reason: p);
      }
    });

    test('기본 폴더 안의 프로젝트 폴더는 안전하다', () {
      for (final p in ['/Users/me/dev/app', '/Users/me/Documents/my_app', '/Users/me/FlutterProject']) {
        expect(s.isUnsafeInitLocation(p), isFalse, reason: p);
      }
    });

    test('파일 시스템 루트와 시스템 폴더', () {
      for (final p in ['/', '/usr', '/usr/local/bin', '/System/Library', '/etc', '/Applications']) {
        expect(s.isUnsafeInitLocation(p), isTrue, reason: p);
      }
    });

    test('끝의 구분자가 있어도 같다', () {
      expect(s.isUnsafeInitLocation('/Users/me/'), isTrue);
      expect(s.isUnsafeInitLocation('/Users/me/dev/app/'), isFalse);
    });
  });

  group('FolderScanner.analyze', () {
    test('하위에 저장소가 있으면 git init 을 허용하지 않는다', () async {
      _repoIn(at('app'));
      final info = await FolderScanner(home: '/x').analyze(root.path);
      expect(info.childRepos, [at('app')]);
      expect(info.initAllowed, isFalse);
    });

    test('하위에 저장소가 없고 안전한 위치면 허용한다', () async {
      final info = await FolderScanner(home: '/x').analyze(root.path);
      expect(info.childRepos, isEmpty);
      expect(info.initAllowed, isTrue);
    });

    test('위험한 위치(홈)면 하위에 저장소가 없어도 허용하지 않는다', () async {
      final info = await FolderScanner(home: root.path).analyze(root.path);
      expect(info.childRepos, isEmpty);
      expect(info.initAllowed, isFalse);
    });

    test('Flutter 프로젝트와 기존 .gitignore 를 알아본다', () async {
      File(at('pubspec.yaml')).writeAsStringSync('name: a\ndependencies:\n  flutter:\n    sdk: flutter\n');
      var info = await FolderScanner(home: '/x').analyze(root.path);
      expect(info.isFlutterProject, isTrue);
      expect(info.hasGitignore, isFalse);
      File(at('.gitignore')).writeAsStringSync('x');
      info = await FolderScanner(home: '/x').analyze(root.path);
      expect(info.hasGitignore, isTrue);
      File(at('pubspec.yaml')).writeAsStringSync('name: dart_only\n');
      info = await FolderScanner(home: '/x').analyze(root.path);
      expect(info.isFlutterProject, isFalse);
    });
  });

  group('Workspace — 저장소가 아닌 폴더', () {
    test('하위에 저장소가 있으면 실패 + 목록을 쥔다. git init 은 거부한다', () async {
      final ws = await _workspace();
      _repoIn(at('app'));
      Directory(at('app')).createSync(recursive: true);
      final outcome = await ws.open(root.path);
      expect(outcome, OpenOutcome.failed);
      expect(ws.failure, OpenFailure.notARepository);
      expect(ws.notRepoInfo?.childRepos, [at('app')]);
      expect(ws.notRepoInfo?.initAllowed, isFalse);
      // 하위에 저장소가 있는 폴더에는 init 하지 않는다 (중첩 저장소 방지)
      await ws.initRepository(root.path);
      expect(Directory(at('.git')).existsSync(), isFalse);
      expect(ws.isOpen, isFalse);
      ws.dispose();
    });

    test('위험한 위치에는 git init 하지 않는다', () async {
      final ws = await _workspace(home: root.path);
      expect(await ws.open(root.path), OpenOutcome.failed);
      expect(ws.notRepoInfo?.initAllowed, isFalse);
      await ws.initRepository(root.path);
      expect(Directory(at('.git')).existsSync(), isFalse);
      ws.dispose();
    });

    test('안전한 빈 폴더: git init(main 브랜치), 첫 커밋은 만들지 않는다', () async {
      final ws = await _workspace();
      expect(await ws.open(root.path), OpenOutcome.failed);
      expect(ws.notRepoInfo?.initAllowed, isTrue);
      expect(await ws.initRepository(root.path), OpenOutcome.opened);
      expect(Directory(at('.git')).existsSync(), isTrue);
      expect(ws.git?.branch, 'main');
      final log = await Process.run('git', ['log', '--oneline'], workingDirectory: root.path);
      expect(log.exitCode, isNot(0)); // 커밋이 하나도 없다
      ws.dispose();
    });

    test('Flutter 프로젝트: 선택하면 .gitignore 를 만들고, 이미 있으면 덮어쓰지 않는다', () async {
      File(at('pubspec.yaml')).writeAsStringSync('name: a\ndependencies:\n  flutter:\n    sdk: flutter\n');
      var ws = await _workspace();
      await ws.open(root.path);
      expect(ws.notRepoInfo?.isFlutterProject, isTrue);
      await ws.initRepository(root.path, flutterGitignore: true);
      expect(File(at('.gitignore')).readAsStringSync(), contains('.dart_tool/'));
      ws.dispose();

      final other = await tempDir('scan_existing');
      addTearDown(() => other.deleteSync(recursive: true));
      File('${other.path}/pubspec.yaml').writeAsStringSync('name: a\ndependencies:\n  flutter:\n    sdk: flutter\n');
      File('${other.path}/.gitignore').writeAsStringSync('mine\n');
      ws = await _workspace();
      await ws.open(other.path);
      await ws.initRepository(other.path, flutterGitignore: true);
      expect(File('${other.path}/.gitignore').readAsStringSync(), 'mine\n');
      ws.dispose();
    });

    test('.gitignore 는 선택하지 않으면 만들지 않는다', () async {
      File(at('pubspec.yaml')).writeAsStringSync('name: a\ndependencies:\n  flutter:\n    sdk: flutter\n');
      final ws = await _workspace();
      await ws.open(root.path);
      await ws.initRepository(root.path);
      expect(File(at('.gitignore')).existsSync(), isFalse);
      ws.dispose();
    });

    test('하위 폴더를 열면 저장소 루트로 열린다 (기존 동작) — 분석 정보는 비운다', () async {
      final r = await makeRepo('parent_open');
      addTearDown(() => r.deleteSync(recursive: true));
      Directory('${r.path}/lib').createSync();
      final ws = await _workspace();
      expect(await ws.open(root.path), OpenOutcome.failed);
      expect(ws.notRepoInfo, isNotNull);
      expect(await ws.open('${r.path}/lib'), OpenOutcome.opened);
      expect(ws.root, r.path);
      expect(ws.selectedDir, '${r.path}/lib');
      expect(ws.notRepoInfo, isNull);
      ws.dispose();
    });
  });

  group('시작 화면', () {
    Future<void> pump(WidgetTester tester, Workspace ws, {ValueChanged<String>? onOpenPath}) async {
      tester.view.physicalSize = const Size(440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: ws,
            builder: (context, _) => StartScreen(
              workspace: ws,
              onOpenFolder: () {},
              onOpenPath: onOpenPath ?? (_) {},
              onCheckEnvironment: () {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('하위에 저장소가 있으면 목록을 보이고 git init 단추는 없다. 누르면 그 저장소를 연다', (tester) async {
      final ws = await _workspace();
      _repoIn(at('alpha'));
      _repoIn(at('beta'));
      await tester.runAsync(() => ws.open(root.path));
      String? opened;
      await pump(tester, ws, onOpenPath: (p) => opened = p);
      expect(find.textContaining('안에 있는 저장소를 골라 여세요'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2)); // alpha, beta (이름순)
      expect(find.text('alpha'), findsWidgets);
      expect(find.text('git init으로 저장소 만들기'), findsNothing);
      await tester.tap(find.byType(ListTile).last);
      expect(opened, at('beta'));
      expect(tester.takeException(), isNull);
      ws.dispose();
    });

    testWidgets('안전한 빈 폴더면 git init 단추가 있고, 누르면 확인 창에서 명령과 안내를 보인 뒤 만든다', (tester) async {
      final ws = await _workspace();
      await tester.runAsync(() => ws.open(root.path));
      await pump(tester, ws);
      expect(find.text('git init으로 저장소 만들기'), findsOneWidget);
      await tester.tap(find.text('git init으로 저장소 만들기'));
      await tester.pumpAndSettle();
      expect(find.text('git 저장소로 만들까요?'), findsOneWidget);
      expect(find.text('git init -b main'), findsOneWidget);
      expect(find.textContaining('첫 커밋은 만들지 않습니다'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing); // Flutter 프로젝트가 아니면 .gitignore 제안 없음
      await tester.tap(find.text('저장소 만들기'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await tester.pumpAndSettle();
      expect(Directory(at('.git')).existsSync(), isTrue);
      ws.dispose();
    });

    testWidgets('확인 창에서 취소하면 아무것도 만들지 않는다', (tester) async {
      final ws = await _workspace();
      await tester.runAsync(() => ws.open(root.path));
      await pump(tester, ws);
      await tester.tap(find.text('git init으로 저장소 만들기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(Directory(at('.git')).existsSync(), isFalse);
      ws.dispose();
    });

    testWidgets('Flutter 프로젝트면 .gitignore 선택이 기본으로 켜져 있다', (tester) async {
      File(at('pubspec.yaml')).writeAsStringSync('name: a\ndependencies:\n  flutter:\n    sdk: flutter\n');
      final ws = await _workspace();
      await tester.runAsync(() => ws.open(root.path));
      await pump(tester, ws);
      await tester.tap(find.text('git init으로 저장소 만들기'));
      await tester.pumpAndSettle();
      final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(box.value, isTrue);
      ws.dispose();
    });

    testWidgets('위험한 위치면 안내만 있고 git init 단추는 없다', (tester) async {
      final ws = await _workspace(home: root.path);
      await tester.runAsync(() => ws.open(root.path));
      await pump(tester, ws);
      expect(find.textContaining('저장소로 만들지 않는 편이 안전한 위치'), findsOneWidget);
      expect(find.text('git init으로 저장소 만들기'), findsNothing);
      ws.dispose();
    });
  });

  testWidgets('저장소 고르기 창은 하위 저장소를 상대 경로와 함께 보이고 고른 경로를 돌려준다', (tester) async {
    final info = NotRepoInfo(
      path: root.path,
      childRepos: [at('group/one'), at('two')],
      initAllowed: false,
    );
    String? picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => picked = await showChildRepoChooser(context, info),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('저장소 고르기'), findsOneWidget);
    expect(find.text('group/one'), findsOneWidget); // 상대 경로
    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();
    expect(picked, at('group/one'));
  });
}
