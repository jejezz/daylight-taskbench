// 에디터 부가 기능 (단계 15-2의 첫 묶음): 들여쓰기 선 계산·표시, 정렬(JSON·Dart), 저장할 때 정렬, Markdown 보기, 설정.
// 들여쓰기 계산·정렬 테스트는 daylight-workbench 의 같은 테스트를 옮긴 것이다.

import 'dart:io';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/editor/editor_controller.dart';
import 'package:daylight_taskbench/editor/editor_host.dart';
import 'package:daylight_taskbench/editor/editor_settings.dart';
import 'package:daylight_taskbench/editor/formatters.dart';
import 'package:daylight_taskbench/editor/indent_guides.dart';
import 'package:daylight_taskbench/editor/indent_levels.dart';
import 'package:daylight_taskbench/editor/markdown_view.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/settings/app_settings.dart';
import 'package:daylight_taskbench/settings/settings_dialog.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/shell/panels/panel_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

void main() {
  group('들여쓰기 계산 (workbench 테스트를 옮김)', () {
    test('앞 공백 칸 수 (탭은 2칸), 빈 줄은 null', () {
      expect(leadingColumns('    foo'), 4);
      expect(leadingColumns('\tfoo'), 2);
      expect(leadingColumns('foo'), 0);
      expect(leadingColumns(''), isNull);
      expect(leadingColumns('   '), isNull);
    });

    test('한 단계 폭: 들여쓰기가 늘어나는 가장 작은 폭', () {
      expect(detectIndentUnit(['a', '  b', '    c', '  d']), 2);
      expect(detectIndentUnit(['a', '    b', '        c']), 4);
      expect(detectIndentUnit(['a', 'b']), 2, reason: '알 수 없으면 Dart 관례의 2칸');
    });

    int level(List<String> lines, int i, {int unit = 2}) =>
        indentLevelAt(lines.length, (n) => lines[n], i, unit);

    test('글자 있는 줄은 자기 깊이', () {
      final lines = ['void f() {', '  if (x) {', '    y();', '  }', '}'];
      expect([for (var i = 0; i < lines.length; i++) level(lines, i)], [0, 1, 2, 1, 0]);
    });

    test('블록 안의 빈 줄은 선이 이어지고, 블록 사이의 빈 줄은 끊긴다', () {
      expect(level(['void f() {', '  a();', '', '  b();', '}'], 2), 1);
      expect(level(['void f() {', '  a();', '}', '', 'void g() {', '  b();', '}'], 3), 0);
    });

    test('줄 목록의 처음·끝의 빈 줄은 0', () {
      expect(level(['', '  a'], 0), 0);
      expect(level(['  a', ''], 1), 0);
    });
  });

  group('formatJson', () {
    test('들여쓰기 2칸으로 정렬하고 키 순서와 끝 줄바꿈을 지킨다', () {
      final r = formatJson('{"b":1,"a":["x","한글"]}\n');
      expect(r.ok, isTrue);
      expect(r.text, '{\n  "b": 1,\n  "a": [\n    "x",\n    "한글"\n  ]\n}\n');
      expect(formatJson('[1]').text, '[\n  1\n]');
    });

    test('문법 오류는 실패 이유(종류 + 파서 문구)로 알린다', () {
      final r = formatJson('{"a": }');
      expect(r.ok, isFalse);
      expect(r.failure?.kind, FormatFailureKind.jsonInvalid);
      expect(r.failure?.detail, isNotEmpty);
    });
  });

  group('DartFormatter (진짜 dart format)', () {
    late Directory dir;
    late DartFormatter formatter;

    setUp(() async {
      dir = await tempDir('dart_format');
      formatter = DartFormatter(
        CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? ''),
      );
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('들여쓰기를 정렬하고 원본 파일과 임시 파일을 남기지 않는다', () async {
      final file = File('${dir.path}/a.dart')..writeAsStringSync('void main(){print( 1 );}\n');
      final r = await formatter.format(file.path, 'void main(){print( 1 );}\n');
      expect(r.ok, isTrue, reason: '${r.failure?.kind} ${r.failure?.detail}');
      expect(r.text, contains('void main() {\n'));
      expect(r.text, contains('  print(1);'));
      expect(file.readAsStringSync(), 'void main(){print( 1 );}\n');
      expect(dir.listSync().map((e) => e.path.split('/').last), ['a.dart']);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('구문 오류는 이유를 돌려주고, 임시 파일 이름 대신 열린 파일 이름을 쓰며, 임시 파일을 지운다', () async {
      final file = File('${dir.path}/b.dart')..writeAsStringSync('');
      final r = await formatter.format(file.path, 'void main( {');
      expect(r.ok, isFalse);
      expect(r.failure?.kind, FormatFailureKind.failedDetail);
      expect(r.failure?.detail, isNot(contains('.studio_format_')));
      expect(dir.listSync(), hasLength(1));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('EditorController — 정렬·저장 시 정렬·미리보기', () {
    late Directory dir;
    setUp(() async => dir = await tempDir('editor_fmt'));
    tearDown(() => dir.deleteSync(recursive: true));

    Future<(EditorController, File)> open(
      String name,
      String text, {
      bool on = false,
      Future<FormatResult> Function(String, String)? dart,
    }) async {
      final file = File('${dir.path}/$name')..writeAsStringSync(text);
      final c = EditorController(formatDart: dart, formatOnSave: () => on);
      addTearDown(c.dispose);
      await c.openFile(file.path);
      return (c, file);
    }

    test('저장할 때 정렬: 켜져 있으면 저장하기 직전에 정렬한다', () async {
      final (c, file) = await open('app_ko.arb', '{"a":1}', on: true);
      expect(await c.save(c.activeTab!), isTrue);
      expect(file.readAsStringSync(), '{\n  "a": 1\n}');
      expect(c.activeTab!.dirty, isFalse);
    });

    test('꺼져 있으면 글을 그대로 저장한다', () async {
      final (c, file) = await open('app_ko.arb', '{"a":1}');
      c.activeTab!.controller.text = '{"a":2}';
      await c.save(c.activeTab!);
      expect(file.readAsStringSync(), '{"a":2}');
    });

    test('문법 오류가 있어도 저장은 한다', () async {
      final (c, file) = await open('x.json', '{"a":1}', on: true);
      c.activeTab!.controller.text = '{"a": ';
      expect(await c.save(c.activeTab!), isTrue);
      expect(file.readAsStringSync(), '{"a": ');
    });

    test('canFormat: Dart·JSON·ARB 만', () async {
      final (c, _) = await open('a.dart', 'x');
      await c.openFile((File('${dir.path}/b.arb')..writeAsStringSync('{}')).path);
      await c.openFile((File('${dir.path}/c.txt')..writeAsStringSync('x')).path);
      expect(c.canFormat(c.tabFor('${dir.path}/a.dart')!), isTrue);
      expect(c.canFormat(c.tabFor('${dir.path}/b.arb')!), isTrue);
      expect(c.canFormat(c.tabFor('${dir.path}/c.txt')!), isFalse);
    });

    test('formatActive: 정렬하면 알리고 실행 취소할 수 있고, 이미 정렬돼 있으면 그렇게 알린다', () async {
      final (c, _) = await open('f.json', '{"a":1}');
      await c.formatActive();
      expect(c.activeTab!.controller.text, '{\n  "a": 1\n}');
      expect(c.message?.kind, EditorMessageKind.formatted);
      c.activeTab!.controller.undo();
      expect(c.activeTab!.controller.text, '{"a":1}');
      c.activeTab!.controller.text = '{\n  "a": 1\n}';
      await c.formatActive();
      expect(c.message?.kind, EditorMessageKind.alreadyFormatted);
    });

    test('formatActive: JSON 문법 오류는 종류와 이유를 알리고 글은 그대로 둔다', () async {
      final (c, _) = await open('bad.json', '{"a": ');
      await c.formatActive();
      expect(c.message?.kind, EditorMessageKind.formatJsonInvalid);
      expect(c.message?.arg, isNotEmpty);
      expect(c.activeTab!.controller.text, '{"a": ');
    });

    test('Dart 는 주입된 정렬기를 쓰고, 없으면 아무 일도 하지 않는다', () async {
      final (c, _) = await open(
        'd.dart',
        'void main(){}',
        dart: (path, text) async => const FormatResult.ok('void main() {}\n'),
      );
      await c.formatActive();
      expect(c.activeTab!.controller.text, 'void main() {}\n');

      final (none, _) = await open('e.dart', 'void main(){}');
      await none.formatActive();
      expect(none.activeTab!.controller.text, 'void main(){}');
      expect(none.message, isNull);
    });

    test('Dart 정렬 실패 이유가 종류별로 알림이 된다', () async {
      final kinds = {
        FormatFailureKind.noDart: EditorMessageKind.formatNoDart,
        FormatFailureKind.tempWriteFailed: EditorMessageKind.formatTempWriteFailed,
        FormatFailureKind.failed: EditorMessageKind.formatFailed,
        FormatFailureKind.failedDetail: EditorMessageKind.formatFailedDetail,
      };
      for (final entry in kinds.entries) {
        final (c, _) = await open(
          'k${entry.key.name}.dart',
          'x',
          dart: (p, t) async => FormatResult.failed(FormatFailure(entry.key, 'why')),
        );
        await c.formatActive();
        expect(c.message?.kind, entry.value, reason: '${entry.key}');
        expect(c.message?.arg, 'why');
      }
    });

    test('togglePreview 와 openAt: Markdown 보기에서 줄로 이동하면 편집으로 돌아온다', () async {
      final (c, file) = await open('r.md', '# 제목\n\n본문\n');
      final tab = c.activeTab!;
      expect(tab.preview, isFalse);
      c.togglePreview(tab);
      expect(tab.preview, isTrue);
      await c.openAt(file.path, 3, 1);
      expect(tab.preview, isFalse);
    });
  });

  group('EditorSettings', () {
    test('기본값은 들여쓰기 선 켬 · 저장 시 정렬 끔. 바꾸면 저장했다가 다시 읽는다', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final s = EditorSettings(prefs);
      expect(s.indentGuides, isTrue);
      expect(s.formatOnSave, isFalse);
      var n = 0;
      s.addListener(() => n++);
      await s.setIndentGuides(true); // 같은 값
      expect(n, 0);
      await s.setIndentGuides(false);
      await s.setFormatOnSave(true);
      expect(n, 2);
      final again = EditorSettings(prefs);
      expect(again.indentGuides, isFalse);
      expect(again.formatOnSave, isTrue);
    });
  });

  group('화면', () {
    late Directory dir;
    late EditorController c;
    late EditorSettings settings;

    setUp(() async {
      dir = await tempDir('editor_ui');
      SharedPreferences.setMockInitialValues({});
      settings = EditorSettings(await SharedPreferences.getInstance());
      c = EditorController();
    });
    tearDown(() {
      c.dispose();
      dir.deleteSync(recursive: true);
    });

    File write(String name, String text) => File('${dir.path}/$name')..writeAsStringSync(text);

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> pump(WidgetTester tester, {Size size = const Size(800, 600)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        EditorSettingsScope(
          settings: settings,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: EditorHost(controller: c)),
          ),
        ),
      );
      await settle(tester);
    }

    testWidgets('정렬 단추는 Dart·JSON 탭에서만 보이고 누르면 정렬한다', (tester) async {
      await pump(tester);
      await tester.runAsync(() => c.openFile(write('a.txt', 'x').path));
      await settle(tester);
      expect(find.byTooltip('정렬 (Ctrl+Alt+L)'), findsNothing);
      await tester.runAsync(() => c.openFile(write('b.json', '{"a":1}').path));
      await settle(tester);
      expect(find.byTooltip('정렬 (Ctrl+Alt+L)'), findsOneWidget);
      await tester.tap(find.byTooltip('정렬 (Ctrl+Alt+L)'));
      await settle(tester);
      expect(c.activeTab!.controller.text, '{\n  "a": 1\n}');
      expect(find.text('정렬했습니다'), findsOneWidget); // 알림
    });

    testWidgets('Markdown 탭: 보기 단추로 렌더링된 모양과 편집을 오간다', (tester) async {
      await pump(tester);
      await tester.runAsync(() => c.openFile(write('r.md', '# 큰 제목\n\n본문 글\n').path));
      await settle(tester);
      expect(find.byType(MarkdownView), findsNothing);
      await tester.tap(find.byTooltip('보기'));
      await settle(tester);
      expect(find.byType(MarkdownView), findsOneWidget);
      expect(find.textContaining('큰 제목'), findsWidgets);
      // 보기에서는 접기 단추가 없다
      expect(find.byTooltip('모두 접기'), findsNothing);
      await tester.tap(find.byTooltip('편집'));
      await settle(tester);
      expect(find.byType(MarkdownView), findsNothing);
      expect(find.byTooltip('모두 접기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('들여쓰기 선: 설정이 켜져 있으면 그리고 끄면 그리지 않는다', (tester) async {
      await pump(tester);
      await tester.runAsync(() => c.openFile(write('i.dart', 'void f() {\n  if (x) {\n    y();\n  }\n}\n').path));
      await settle(tester);
      expect(find.byType(IndentGuides), findsOneWidget);
      await settings.setIndentGuides(false);
      await settle(tester);
      expect(find.byType(IndentGuides), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('최소 폭(280)에서도 Markdown 도구 줄이 넘치지 않는다', (tester) async {
      await pump(tester, size: const Size(300, 600));
      await tester.runAsync(() => c.openFile(write('narrow.md', '# a\n').path));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('설정 창의 에디터 구역에 들여쓰기 선·저장 시 정렬 스위치가 있다', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final app = await AppSettings.load();
      final panels = PanelLayout(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        PanelLayoutScope(
          panels: panels,
          child: EditorSettingsScope(
            settings: settings,
            child: AppSettingsScope(
              settings: app,
              child: MaterialApp(
                theme: AppTheme.light(),
                locale: const Locale('ko'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(body: SettingsDialog(initial: SettingsSection.editor)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('들여쓰기 선'), findsOneWidget);
      expect(find.text('저장할 때 자동 정렬'), findsOneWidget);
      await tester.tap(find.text('저장할 때 자동 정렬'));
      await tester.pumpAndSettle();
      expect(settings.formatOnSave, isTrue);
    });
  });
}
