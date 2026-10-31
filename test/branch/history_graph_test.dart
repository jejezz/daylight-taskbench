// 기록 탭의 커밋 그래프: 병합이 섞인 실제 저장소를 좁은 창(380px)에 그려 본다.

import 'dart:io';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/docks/branch/repo/environment.dart';
import 'package:daylight_taskbench/docks/branch/repo/repo_controller.dart';
import 'package:daylight_taskbench/docks/branch/repo/repo_prefs.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/docks/branch/ui/commit_graph_gutter.dart';
import 'package:daylight_taskbench/docks/branch/ui/repo_scope.dart';
import 'package:daylight_taskbench/docks/branch/ui/services.dart';
import 'package:daylight_taskbench/docks/branch/ui/tabs/history_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> git(String cwd, List<String> args) async {
  final r = await Process.run('git', args, workingDirectory: cwd);
  if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
  return (r.stdout as String).trim();
}

void main() {
  late Directory tmp;
  late String dir;
  late AppServices services;
  late RepoController repo;
  var n = 0;

  Future<void> commit(String msg) async {
    n++;
    File('$dir/f$n.txt').writeAsStringSync('$n\n');
    await git(dir, ['add', '-A']);
    await git(dir, ['commit', '-q', '-m', msg]);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('bd_hgraph');
    dir = '${tmp.path}/repo';
    Directory(dir).createSync();
    n = 0;
    await git(dir, ['init', '-q', '-b', 'main']);
    for (final c in [['user.email', 't@e.com'], ['user.name', 'T'], ['commit.gpgsign', 'false']]) {
      await git(dir, ['config', ...c]);
    }
    await commit('init');
    await commit('add base');
    await git(dir, ['switch', '-q', '-c', 'feature']);
    await commit('feature: start');
    await commit('feature: finish');
    await git(dir, ['switch', '-q', 'main']);
    await commit('main: hotfix');
    await git(dir, ['merge', '-q', '--no-ff', '-m', 'Merge feature', 'feature']);
    await git(dir, ['switch', '-q', '-c', 'wip', 'HEAD~2']);
    await commit('wip: idea');
    await git(dir, ['switch', '-q', 'main']);
    await commit('main: release');
    services = AppServices(
      runner: CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? ''),
      prefs: await RepoPrefs.load(),
    );
    repo = (await RepoController.open(services.runner, dir)).$1!;
  });

  tearDown(() {
    repo.dispose();
    tmp.deleteSync(recursive: true);
  });

  /// 실제 git 실행(실제 시간)과 화면 갱신(가짜 시간)을 번갈아, 불러오기가 끝날 때까지 기다린다.
  Future<void> wait(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty && i > 1) break;
    }
  }

  Future<void> pumpTab(WidgetTester tester, {Locale locale = const Locale('ko')}) async {
    tester.view.physicalSize = const Size(380, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const env = EnvironmentStatus(gitVersion: '2', ghVersion: '2', ghLogins: {}, checked: true);
    await tester.pumpWidget(ServicesScope(
      services: services,
      child: MaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RepoScope(repo: repo, environment: env, child: const HistoryTab())),
      ),
    ));
    await wait(tester);
  }

  for (final locale in const [Locale('ko'), Locale('en')]) {
    testWidgets('graph and list render at 380px (${locale.languageCode})', (tester) async {
      await pumpTab(tester, locale: locale);
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.byType(CommitGraphGutter), findsNWidgets(7)); // main 줄기: init, base, hotfix, merge, feature 2개, release
      expect(find.text(l10n.bdHistoryGraph), findsOneWidget);

      // 모든 브랜치: wip 커밋이 더해진다.
      await tester.tap(find.text(l10n.bdHistoryAllBranches));
      await tester.pump();
      await wait(tester);
      expect(find.byType(CommitGraphGutter), findsNWidgets(8));

      // 목록 모드로: 그래프 열이 사라지고 모든 브랜치 칩도 사라진다.
      await tester.tap(find.text(l10n.bdHistoryGraph));
      await tester.pump();
      await wait(tester);
      expect(find.byType(CommitGraphGutter), findsNothing);
      expect(find.text(l10n.bdHistoryAllBranches), findsNothing);
    });
  }
}
