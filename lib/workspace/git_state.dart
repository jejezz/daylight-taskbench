// 저장소의 지금 상태(브랜치·HEAD·병합 중 여부)와 그 변화 (PLAN.md §1.10).
//
// 감시의 주인은 Branch Dock 칸이 아니라 Workspace 다. 칸이 접혀 있어도, 터미널·편집기에서 바꿔도 같은
// 신호가 모든 칸과 공유 영역에 한 번씩 간다. 이 파일의 [ProcessGitStateSource]는 단계 1용 가벼운 구현이고,
// 단계 3에서 Branch의 RepoController 를 이식하면 같은 [GitStateSource] 뒤로 바뀐다.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../docks/branch/repo/repo_controller.dart';

export '../docks/branch/repo/repo_controller.dart' show RepoOperation;

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

/// Branch 의 [RepoController]를 [GitStateSource]로 보이게 한다 (PLAN.md §1.10, 단계 3).
///
/// RepoController 가 `.git` 감시·새로 읽기를 맡고, 여기서는 그 결과를 [GitState] 값으로 줄여 "바뀐 것만" 알린다.
/// 칸(Dock)은 RepoController 를 직접 쓰고, 그 밖의 앱(공유 영역·다른 칸)은 이 값만 본다.
class RepoGitStateSource implements GitStateSource {
  RepoGitStateSource(this.repo) {
    _current = _map();
    repo.addListener(_onRepo);
  }

  final RepoController repo;
  final _controller = StreamController<GitState>.broadcast();
  late GitState _current;
  bool _disposed = false;

  @override
  GitState get current => _current;

  @override
  Stream<GitState> get states => _controller.stream;

  GitState _map() {
    final s = repo.status;
    return GitState(
      root: repo.root,
      branch: s.head,
      sha: s.oid,
      upstream: s.hasUpstream ? s.upstream : null,
      operation: repo.operation,
      changedCount: s.changedCount,
      conflictCount: s.conflicts.length,
      ahead: s.ahead,
      behind: s.behind,
    );
  }

  void _onRepo() {
    if (_disposed) return;
    // checkout·commit 이 진행 중이면(index.lock) 반쯤 바뀐 상태를 알리지 않는다 — 끝나면 감시가 다시 읽는다.
    if (File('${repo.gitDir}/index.lock').existsSync()) return;
    final next = _map();
    if (next != _current) {
      _current = next;
      if (!_controller.isClosed) _controller.add(next);
    }
  }

  @override
  Future<void> refresh() => repo.refresh();

  @override
  void dispose() {
    _disposed = true;
    repo.removeListener(_onRepo);
    repo.dispose();
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
