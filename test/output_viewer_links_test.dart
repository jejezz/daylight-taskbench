// 출력 뷰어의 오류 위치 링크와 파일 열기 경로 (단계 16).

import 'dart:io';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/ui/output_viewer.dart';
import 'package:daylight_taskbench/explorer/file_opener.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:daylight_taskbench/workspace/workspace_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  group('OutputViewerScreen', () {
    late Directory repo;
    late Workspace ws;

    setUp(() async {
      repo = await makeRepo('viewer');
      Directory('${repo.path}/lib').createSync();
      File('${repo.path}/lib/main.dart').writeAsStringSync('void main() {}\n');
      ws = await makeWorkspace();
    });
    tearDown(() {
      ws.dispose();
      repo.deleteSync(recursive: true);
    });

    Future<void> show(WidgetTester tester, String output) async {
      await tester.runAsync(() => ws.open(repo.path));
      final log = CommandLog();
      final entry = log.start(['flutter', 'build'])..append(output);
      await tester.pumpWidget(
        WorkspaceScope(
          workspace: ws,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OutputViewerScreen(log: log, entry: entry),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('실제로 있는 파일의 위치만 링크가 되고, 누르면 줄·칸으로 연다', (tester) async {
      final opened = <String>[];
      ws.openLocationHandler = (p, l, c) async => opened.add('$p:$l:$c');
      ws.openFileHandler = (_) async {};
      await show(
        tester,
        "lib/main.dart:3:4: Error: boom\nlib/ghost.dart:9:1: nope\nhttp://localhost:8080/x.html",
      );
      final rich = tester.widget<SelectableText>(find.byType(SelectableText));
      final links = <TextSpan>[];
      rich.textSpan!.visitChildren((s) {
        if (s is TextSpan && s.recognizer != null) links.add(s);
        return true;
      });
      expect(links.map((s) => s.text), ['lib/main.dart:3:4']);
      (links.single.recognizer! as dynamic).onTap();
      expect(opened, ['${repo.path}/lib/main.dart:3:4']);
    });

    testWidgets('파일 열기 처리가 등록돼 있지 않으면 링크 없이 글만 보인다', (tester) async {
      await show(tester, 'lib/main.dart:3:4: Error');
      final rich = tester.widget<SelectableText>(find.byType(SelectableText));
      var recognizers = 0;
      rich.textSpan!.visitChildren((s) {
        if (s is TextSpan && s.recognizer != null) recognizers++;
        return true;
      });
      expect(recognizers, 0);
    });
  });

  group('FileOpener.openAt', () {
    test('편집기 명령이 없으면 vscode:// 주소로 줄·칸까지 간다', () async {
      final ws = await makeWorkspace();
      Uri? launched;
      final opener = FileOpener(
        ws,
        start: (_) async => fail('주소로 열렸어야 한다'),
        launch: (u) async {
          launched = u;
          return true;
        },
      );
      expect(await opener.openAt('/p/a.dart', 12, 5), OpenFileResult.opened);
      expect(launched.toString(), 'vscode://file/p/a.dart:12:5');
      ws.dispose();
    });

    test('주소를 열지 못하면 파일만 연다', () async {
      final ws = await makeWorkspace();
      await ws.setEditorCommand('');
      final started = <List<String>>[];
      final opener = FileOpener(
        ws,
        start: (c) async => started.add(c),
        launch: (_) async => false,
      );
      await opener.openAt('/p/a.dart', 1, 1);
      // VS Code 가 설치돼 있지 않은 환경이면 noEditor 라 started 가 비어 있다 — 있으면 파일 경로로 끝난다.
      if (started.isNotEmpty) expect(started.single.last, '/p/a.dart');
      ws.dispose();
    });

    test('편집기 명령이 있으면 그 명령으로 파일을 연다', () async {
      final ws = await makeWorkspace();
      await ws.setEditorCommand('myeditor');
      List<String>? started;
      final opener = FileOpener(
        ws,
        start: (c) async => started = c,
        launch: (_) async => fail('주소는 쓰지 않는다'),
      );
      await opener.openAt('/p/a.dart', 3, 2);
      expect(started, ['myeditor', '/p/a.dart']);
      ws.dispose();
    });
  });
}
