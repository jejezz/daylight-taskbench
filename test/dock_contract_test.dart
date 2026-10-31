// 모든 칸이 지켜야 할 약속 (PLAN.md §4.1). 새 runner 는 createDocks() 에 더하는 것만으로 이 검사를 받는다.

import 'package:daylight_taskbench/docks/registry.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  test('칸 id 는 서로 다르고 소문자 식별자다', () {
    final ids = createDocks().map((d) => d.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[a-z][a-z0-9-]*$')));
    }
  });

  test('접혀 있어도(화면에 안 올라와 있어도) 모든 칸이 onHeadChange 를 받는다', () async {
    final ws = await makeWorkspace();
    final source = FakeGitStateSource(const GitState(root: '/r', branch: 'main', sha: '1'));
    ws.attachForTest(source);
    final docks = createDocks();
    final seen = <String, List<HeadChange>>{for (final d in docks) d.id: []};
    for (final d in docks) {
      d.attach(ws);
    }
    final sub = ws.headChanges.listen((c) {
      for (final d in docks) {
        d.onHeadChange(ws, c);
        seen[d.id]!.add(c);
      }
    });
    source.set(const GitState(root: '/r', branch: 'other', sha: '2'));
    await Future<void>.delayed(Duration.zero);
    for (final d in docks) {
      expect(seen[d.id], hasLength(1), reason: '${d.id} 가 브랜치 전환 신호를 못 받았다');
    }
    await sub.cancel();
    for (final d in docks) {
      d.detach(ws);
      d.dispose();
    }
    ws.dispose();
  });

  testWidgets('appliesTo·mood·busy 는 저장소가 닫혀 있어도 던지지 않고, summary 는 그려진다', (tester) async {
    final ws = await makeWorkspace();
    ws.attachForTest(FakeGitStateSource(const GitState(root: '/r', branch: 'main', sha: '1')));
    for (final d in [...createDocks(), RunEmptyDock()]) {
      d.attach(ws);
      expect(() => d.appliesTo(ws), returnsNormally);
      expect(() => d.mood(ws), returnsNormally);
      expect(() => d.busy(ws), returnsNormally);
      await tester.pumpWidget(_host(Builder(builder: (c) => Row(children: [Expanded(child: d.summary(c, ws))]))));
      expect(tester.takeException(), isNull, reason: d.id);
      d.detach(ws);
    }
    ws.dispose();
  });

  testWidgets('실행기가 하나도 없으면 안내 칸 하나가 대신 선다', (tester) async {
    final ws = await makeWorkspace();
    ws.attachForTest(FakeGitStateSource(const GitState(root: '/nonexistent', branch: 'main')), selectedDir: '/nonexistent');
    final docks = createDocks();
    final empty = RunEmptyDock();
    final shown = visibleDocks(docks, empty, ws);
    expect(shown.map((d) => d.id), ['branch', 'run-empty']);
    ws.dispose();
  });
}
