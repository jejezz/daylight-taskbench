// Avalonia 칸 화면: 최소 창(380)에서 넘치지 않고, 고른 동작이 명령 미리보기에 그대로 보인다.

import 'dart:io';

import 'package:daylight_taskbench/docks/avalonia/avalonia_dock.dart';
import 'package:daylight_taskbench/docks/avalonia/run/avalonia_controller.dart';
import 'package:daylight_taskbench/docks/avalonia/run/avalonia_plan.dart';
import 'package:daylight_taskbench/docks/avalonia/ui/avalonia_dock_body.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

class _FakeDiagnostics implements AvaloniaDiagnosticsService {
  @override
  Future<String?> dotnetVersion() async => '10.0.402';

  @override
  bool vswhereAvailable() => false;
}

void main() {
  late Directory dir;

  setUp(() async => dir = await tempDir('avaloniaui'));
  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    dir.deleteSync(recursive: true);
  });

  void write(String rel, String text) => (File('${dir.path}/$rel')..createSync(recursive: true)).writeAsStringSync(text);

  Future<(AvaloniaDock, Workspace)> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(380, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    write('App.slnx', '<Solution/>');
    write('src/App/App.csproj', '<Project><PropertyGroup><OutputType>WinExe</OutputType></PropertyGroup><ItemGroup><PackageReference Include="Avalonia" Version="1" /></ItemGroup></Project>');
    late AvaloniaDock dock;
    late Workspace ws;
    await tester.runAsync(() async {
      ws = await makeWorkspace();
      ws.attachForTest(FakeGitStateSource(GitState(root: dir.path, branch: 'main', sha: '1')), selectedDir: dir.path);
      dock = AvaloniaDock(
        controller: AvaloniaController(
          runner: ws.runner,
          prefs: ws.prefs,
          diagnosticsService: _FakeDiagnostics(),
          hostIsWindows: true,
          vswhereDirExists: true,
        ),
      )..attach(ws);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AvaloniaDockBody(dock: dock, workspace: ws)),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    addTearDown(() {
      dock.detach(ws);
      dock.dispose();
      ws.dispose();
    });
    return (dock, ws);
  }

  for (final locale in const [Locale('en'), Locale('ko')]) {
    testWidgets('380px 에서 넘치지 않고 실행 명령이 그대로 보인다 (${locale.languageCode})', (tester) async {
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('dotnet run -c Release --project', findRichText: true), findsOneWidget);
      expect(find.textContaining('DOTNET_CLI_TELEMETRY_OPTOUT=1', findRichText: true), findsOneWidget);
    });
  }

  testWidgets('동작을 바꾸면 미리보기가 바뀌고, AOT 는 단계 둘과 PATH 안내가 보인다', (tester) async {
    final (dock, _) = await pump(tester);
    dock.controller!.selectAction(AvaloniaAction.aotRun);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('-p:PublishAot=true', findRichText: true), findsOneWidget);
    expect(find.textContaining(r'publish\aot\App.exe', findRichText: true), findsOneWidget);
    expect(find.textContaining('vswhere', findRichText: true), findsWidgets);
    dock.controller!.selectAction(AvaloniaAction.test);
    await tester.pump();
    expect(find.textContaining('dotnet test App.slnx', findRichText: true), findsOneWidget);
  });

  testWidgets('환경 점검 결과가 한 줄씩 보인다', (tester) async {
    await pump(tester);
    await tester.runAsync(() => dockControllerChecks(tester));
    await tester.pump();
    expect(find.textContaining('.NET SDK 10.0.402'), findsOneWidget);
    expect(find.textContaining('vswhere.exe'), findsOneWidget); // vswhere 없음 경고
  });
}

Future<void> dockControllerChecks(WidgetTester tester) async {
  final body = tester.widget<AvaloniaDockBody>(find.byType(AvaloniaDockBody));
  await body.dock.controller!.runDiagnostics();
}
