import 'dart:io';

import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  late Workspace ws;
  final cleanup = <Directory>[];

  setUp(() async => ws = await makeWorkspace());
  tearDown(() async {
    ws.dispose();
    for (final d in cleanup) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
    cleanup.clear();
  });

  Future<Directory> repo(String n) async {
    final d = await makeRepo(n);
    cleanup.add(d);
    return d;
  }

  test('저장소가 아닌 폴더는 열리지 않고 failure 가 채워진다', () async {
    final d = await tempDir('plain');
    cleanup.add(d);
    expect(await ws.open(d.path), OpenOutcome.failed);
    expect(ws.isOpen, isFalse);
    expect(ws.failure, OpenFailure.notARepository);
  });

  test('열려 있는 저장소는 비-git 폴더를 놓아도 닫히지 않는다 (§1.11)', () async {
    final r = await repo('keep');
    await ws.open(r.path);
    final plain = await tempDir('plain2');
    cleanup.add(plain);
    expect(await ws.open(plain.path), OpenOutcome.failed);
    expect(ws.isOpen, isTrue);
    expect(ws.root, r.path);
  });

  test('저장소를 열면 브랜치·sha 를 읽고 최근 목록에 쌓인다', () async {
    final r = await repo('open');
    expect(await ws.open(r.path), OpenOutcome.opened);
    expect(ws.git?.branch, 'main');
    expect(ws.git?.sha, isNotNull);
    expect(ws.recent, [r.path]);
  });

  test('하위 폴더는 저장소를 그대로 두고 selectedDir 만 바꾼다', () async {
    final r = await repo('sub');
    Directory('${r.path}/gui').createSync();
    await ws.open(r.path);
    expect(await ws.open('${r.path}/gui'), OpenOutcome.selectedDirChanged);
    expect(ws.root, r.path);
    expect(ws.selectedDir, '${r.path}/gui');
  });

  test('저장소 안에 중첩된 worktree 는 다른 저장소로 열린다', () async {
    final r = await repo('wt');
    await git(r.path, ['worktree', 'add', '-b', 'feat', '${r.path}/.claude-wt']);
    await ws.open(r.path);
    expect(await ws.open('${r.path}/.claude-wt'), OpenOutcome.opened);
    expect(ws.root, '${r.path}/.claude-wt');
    expect(ws.git?.branch, 'feat');
  });

  test('파일만 놓으면 무시하고, 폴더 여럿이면 첫 번째만 연다', () async {
    final r = await repo('drop');
    final other = await repo('drop2');
    expect((await ws.openDropped(['${r.path}/a.txt'])).outcome, OpenOutcome.ignoredFiles);
    final res = await ws.openDropped([r.path, other.path]);
    expect(res.outcome, OpenOutcome.opened);
    expect(res.extraIgnored, isTrue);
    expect(ws.root, r.path);
  });

  test('작업 중에 다른 저장소를 놓으면 확인을 요구하고, force 면 연다', () async {
    final a = await repo('busyA');
    final b = await repo('busyB');
    await ws.open(a.path);
    ws.registerBusyCheck(() => true);
    expect(await ws.open(b.path), OpenOutcome.needsConfirm);
    expect(ws.root, a.path);
    expect(await ws.open(b.path, force: true), OpenOutcome.opened);
    expect(ws.root, b.path);
  });

  test('같은 저장소의 하위 폴더 전환은 작업 중이어도 확인하지 않는다', () async {
    final a = await repo('busyC');
    Directory('${a.path}/x').createSync();
    await ws.open(a.path);
    ws.registerBusyCheck(() => true);
    expect(await ws.open('${a.path}/x'), OpenOutcome.selectedDirChanged);
  });

  test('저장소 닫기: 시작 화면 상태로 돌아간다', () async {
    final r = await repo('close');
    await ws.open(r.path);
    ws.close();
    expect(ws.isOpen, isFalse);
    expect(ws.selectedDir, isNull);
  });

  test('git init 은 사용자가 요청했을 때만 저장소를 만든다', () async {
    final d = await tempDir('init');
    cleanup.add(d);
    expect(Directory('${d.path}/.git').existsSync(), isFalse);
    expect(await ws.initRepository(d.path), OpenOutcome.opened);
    expect(Directory('${d.path}/.git').existsSync(), isTrue);
  });

  test('실제 git checkout 은 HeadChange(branch) 를 한 번만 낸다 (§1.10)', () async {
    final r = await repo('head');
    await git(r.path, ['branch', 'other']);
    await ws.open(r.path);
    final events = <HeadChange>[];
    final sub = ws.headChanges.listen(events.add);
    await git(r.path, ['switch', 'other']);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await sub.cancel();
    final branchEvents = events.where((e) => e.kind == HeadChangeKind.branch).toList();
    expect(branchEvents, hasLength(1));
    expect(branchEvents.single.from.branch, 'main');
    expect(branchEvents.single.to.branch, 'other');
    expect(ws.git?.branch, 'other');
  });

  test('HeadChange.between: branch > operation > commit, 다른 루트는 무시', () {
    const a = GitState(root: '/r', branch: 'main', sha: '1');
    expect(HeadChange.between(a, const GitState(root: '/r', branch: 'x', sha: '2'))?.kind, HeadChangeKind.branch);
    expect(HeadChange.between(a, const GitState(root: '/r', branch: 'main', sha: '2', operation: RepoOperation.merging))?.kind,
        HeadChangeKind.operation);
    expect(HeadChange.between(a, const GitState(root: '/r', branch: 'main', sha: '2'))?.kind, HeadChangeKind.commit);
    expect(HeadChange.between(a, const GitState(root: '/r', branch: 'main', sha: '1', changedCount: 3)), isNull);
    expect(HeadChange.between(a, const GitState(root: '/other', branch: 'x', sha: '9')), isNull);
  });

  test('분리된 HEAD 도 branch 변화로 알린다', () async {
    final r = await repo('detach');
    await ws.open(r.path);
    final events = <HeadChange>[];
    final sub = ws.headChanges.listen(events.add);
    await git(r.path, ['checkout', '--detach']);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await sub.cancel();
    expect(events.where((e) => e.kind == HeadChangeKind.branch), hasLength(1));
    expect(ws.git?.detached, isTrue);
  });
}
