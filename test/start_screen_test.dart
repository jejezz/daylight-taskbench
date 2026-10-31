import 'package:daylight_taskbench/docks/branch/repo/environment.dart';
import 'package:daylight_taskbench/docks/branch/ui/environment_sheet.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/ui/start_screen.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

const _ready = EnvironmentStatus(gitVersion: '2.45.0', ghVersion: '2.81.0', ghLogins: {'github.com': 'me'}, checked: true);

Future<void> _pump(WidgetTester tester, Workspace ws, {VoidCallback? onClone, VoidCallback? onOpenFolder, Size size = const Size(440, 900)}) async {
  tester.view.physicalSize = size;
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
          onOpenFolder: onOpenFolder ?? () {},
          onOpenPath: (_) {},
          onCheckEnvironment: () {},
          onClone: onClone,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('시작 화면: 안내, 폴더 열기 단추, 환경이 준비되면 복제 단추가 보인다', (tester) async {
    final ws = await makeWorkspace();
    ws.environment = _ready;
    var cloned = 0;
    await _pump(tester, ws, onClone: () => cloned++);
    expect(find.text('저장소를 열어 시작하세요'), findsOneWidget);
    expect(find.textContaining('폴더 열기'), findsOneWidget);
    await tester.tap(find.text('GitHub에서 복제'));
    expect(cloned, 1);
    expect(tester.takeException(), isNull);
    ws.dispose();
  });

  testWidgets('gh 로그인이 없으면 복제 단추는 없고 환경 점검 카드가 보인다', (tester) async {
    final ws = await makeWorkspace();
    ws.environment = const EnvironmentStatus(gitVersion: '2.45.0', ghVersion: '2.81.0', checked: true);
    await _pump(tester, ws, onClone: () {});
    expect(find.text('GitHub에서 복제'), findsNothing);
    expect(find.byType(EnvironmentCard), findsOneWidget);
    ws.dispose();
  });

  testWidgets('git 이 없으면 폴더 열기가 막히고 안내가 보인다', (tester) async {
    final ws = await makeWorkspace();
    ws.environment = const EnvironmentStatus(checked: true);
    await _pump(tester, ws);
    final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
    expect(button.onPressed, isNull);
    expect(find.byType(EnvironmentCard), findsOneWidget);
    ws.dispose();
  });

  testWidgets('저장소가 아닌 폴더를 열면 실패 안내와 git init 단추가 보인다', (tester) async {
    final ws = await makeWorkspace();
    ws.environment = _ready;
    final dir = (await tester.runAsync(() => tempDir('startplain')))!;
    addTearDown(() => dir.deleteSync(recursive: true));
    await tester.runAsync(() => ws.open(dir.path));
    await _pump(tester, ws);
    expect(find.textContaining('git 저장소가 아닙니다'), findsOneWidget);
    // 단추를 눌렀을 때의 동작(git init → 열기)은 workspace_test 의 initRepository 가 지킨다 — 위젯 테스트의
    // 가짜 시계 안에서는 실제 프로세스 실행이 끝나지 않는다.
    expect(find.text('git init으로 저장소 만들기'), findsOneWidget);
    ws.dispose();
  });

  testWidgets('380px 폭에서도 넘치지 않는다', (tester) async {
    final ws = await makeWorkspace();
    ws.environment = _ready;
    await _pump(tester, ws, onClone: () {}, size: const Size(380, 560));
    expect(tester.takeException(), isNull);
    ws.dispose();
  });
}
