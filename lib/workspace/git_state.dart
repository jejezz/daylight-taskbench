// 저장소의 지금 상태(브랜치·HEAD·병합 중 여부)와 그 변화 (PLAN.md §1.10).
//
// 감시의 주인은 Branch Dock 칸이 아니라 Workspace 다. 칸이 접혀 있어도, 터미널·편집기에서 바꿔도 같은
// 신호가 모든 칸과 공유 영역에 한 번씩 간다. 이 파일의 [ProcessGitStateSource]는 단계 1용 가벼운 구현이고,
// 단계 3에서 Branch의 RepoController 를 이식하면 같은 [GitStateSource] 뒤로 바뀐다.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/command_runner.dart';
import '../docks/branch/git/commands.dart';
import '../docks/branch/git/status.dart';

enum RepoOperation { none, merging, rebasing, cherryPicking, reverting }

/// 불변 값. 같으면 알리지 않는다.
@immutable
class GitState {
  const GitState({
    required this.root,
    this.branch,
    this.sha,
    this.upstream,
    this.operation = RepoOperation.none,
    this.changedCount = 0,
    this.conflictCount = 0,
    this.ahead = 0,
    this.behind = 0,
  });

  /// 저장소(worktree) 루트.
  final String root;

  /// 분리된 HEAD면 null.
  final String? branch;
  final String? sha;
  final String? upstream;
  final RepoOperation operation;
  final int changedCount;
  final int conflictCount;
  final int ahead;
  final int behind;

  bool get detached => branch == null;
  bool get clean => changedCount == 0;

  @override
  bool operator ==(Object other) =>
      other is GitState &&
      other.root == root &&
      other.branch == branch &&
      other.sha == sha &&
      other.upstream == upstream &&
      other.operation == operation &&
      other.changedCount == changedCount &&
      other.conflictCount == conflictCount &&
      other.ahead == ahead &&
      other.behind == behind;

  @override
  int get hashCode => Object.hash(root, branch, sha, upstream, operation, changedCount, conflictCount, ahead, behind);
}

/// 이름이 바뀜 / 같은 브랜치에서 커밋이 움직임 / 병합·rebase 시작·끝.
enum HeadChangeKind { branch, commit, operation }

class HeadChange {
  const HeadChange(this.from, this.to, this.kind);

  final GitState from;
  final GitState to;
  final HeadChangeKind kind;

  /// [from]→[to] 에서 칸들이 반응해야 하는 변화를 고른다. 변화 없으면 null.
  /// 브랜치 전환은 대개 커밋도 바꾸므로 branch > operation > commit 순으로 하나만 고른다.
  static HeadChange? between(GitState from, GitState to) {
    if (from.root != to.root) return null; // 루트 변경은 디렉터리 변경이지 HEAD 변화가 아니다
    if (from.branch != to.branch) return HeadChange(from, to, HeadChangeKind.branch);
    if (from.operation != to.operation) return HeadChange(from, to, HeadChangeKind.operation);
    if (from.sha != to.sha) return HeadChange(from, to, HeadChangeKind.commit);
    return null;
  }
}

abstract class GitStateSource {
  GitState? get current;
  Stream<GitState> get states;
  Future<void> refresh();
  void dispose();
}

/// `git status` 로 읽고 `.git` 변화를 감시한다. 감시가 안 되면 5초마다 읽는다.
class ProcessGitStateSource implements GitStateSource {
  ProcessGitStateSource({required this.runner, required this.root, required this.gitDir, this.debounce = const Duration(milliseconds: 400)});

  final CommandRunner runner;
  final String root;
  final String gitDir;
  final Duration debounce;

  final _controller = StreamController<GitState>.broadcast();
  GitState? _current;
  StreamSubscription<FileSystemEvent>? _watch;
  Timer? _debounce;
  Timer? _poll;
  bool _disposed = false;
  bool _reading = false;

  @override
  GitState? get current => _current;

  @override
  Stream<GitState> get states => _controller.stream;

  Future<void> start() async {
    await refresh();
    try {
      _watch = Directory(gitDir).watch(recursive: Platform.isMacOS || Platform.isWindows).listen(_onEvent, onError: (_) {});
    } on Object {
      _watch = null;
    }
    if (_watch == null) _poll = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  void _onEvent(FileSystemEvent _) {
    _debounce?.cancel();
    _debounce = Timer(debounce, refresh);
  }

  @override
  Future<void> refresh() async {
    if (_disposed || _reading) return;
    _reading = true;
    try {
      // index.lock 이 있는 동안(checkout·commit 진행 중)은 알리지 않고 가라앉기를 기다린다.
      for (var i = 0; i < 40 && File('$gitDir/index.lock').existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (_disposed) return;
      }
      final r = await runner.run(GitCommands.status, workingDirectory: root, quiet: true);
      if (!r.ok || _disposed) return;
      final s = RepoStatus.parse(r.stdout);
      final next = GitState(
        root: root,
        branch: s.head,
        sha: s.oid,
        upstream: s.hasUpstream ? s.upstream : null,
        operation: _operation(),
        changedCount: s.changedCount,
        conflictCount: s.conflicts.length,
        ahead: s.ahead,
        behind: s.behind,
      );
      if (next != _current) {
        _current = next;
        if (!_controller.isClosed) _controller.add(next);
      }
    } finally {
      _reading = false;
    }
  }

  RepoOperation _operation() {
    bool exists(String n) => FileSystemEntity.typeSync('$gitDir/$n') != FileSystemEntityType.notFound;
    if (exists('MERGE_HEAD')) return RepoOperation.merging;
    if (exists('rebase-merge') || exists('rebase-apply')) return RepoOperation.rebasing;
    if (exists('CHERRY_PICK_HEAD')) return RepoOperation.cherryPicking;
    if (exists('REVERT_HEAD')) return RepoOperation.reverting;
    return RepoOperation.none;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _poll?.cancel();
    _watch?.cancel();
    _controller.close();
  }
}

/// 테스트·자리표시자용: 직접 [set] 으로 상태를 바꾼다.
class FakeGitStateSource implements GitStateSource {
  FakeGitStateSource(GitState initial) : _current = initial;

  final _controller = StreamController<GitState>.broadcast();
  GitState _current;

  @override
  GitState get current => _current;

  @override
  Stream<GitState> get states => _controller.stream;

  void set(GitState next) {
    if (next == _current) return;
    _current = next;
    _controller.add(next);
  }

  @override
  Future<void> refresh() async {}

  @override
  void dispose() => _controller.close();
}
