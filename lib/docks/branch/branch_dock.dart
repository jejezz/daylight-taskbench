// Branch Dock 칸 — 단계 1 자리표시자. 단계 3에서 branch-dock-flutter 의 화면이 이 칸 안으로 들어온다.
// 지금은 칸이 공유 상태(GitState)와 브랜치 전환 신호(HeadChange)를 제대로 받는지 눈으로 확인하게 한다.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/taskbench_style.dart';
import '../../ui/style/status_pill.dart';
import '../../workspace/git_state.dart';
import '../../workspace/workspace.dart';
import '../dock_module.dart';
import 'ui/branch_dock_body.dart';

class BranchDock extends DockModule {
  /// 브랜치가 바뀔 때마다 늘어난다 — 본문이 "닫아 둔 안내"를 다시 보이게 하는 신호.
  int epoch = 0;

  int? _tabRequest;

  /// 공유 영역 등 바깥에서 특정 탭으로 가 달라고 요청한다.
  void showTab(int index) {
    _tabRequest = index;
    notifyListeners();
  }

  int? takeTabRequest() {
    final t = _tabRequest;
    _tabRequest = null;
    return t;
  }

  /// 받은 HeadChange 를 최근 순으로 적어 둔다 (자리표시자 확인용, 계약 테스트도 이것을 본다).
  final List<HeadChange> received = [];

  @override
  String get id => 'branch';

  @override
  IconData get icon => Icons.call_split_rounded;

  @override
  String title(AppLocalizations l10n) => l10n.dockBranchTitle;

  @override
  TaskbenchMood mood(Workspace w) => w.git?.operation == RepoOperation.none || w.git == null ? TaskbenchMood.idle : TaskbenchMood.failed;

  @override
  bool busy(Workspace w) => w.repo?.busy ?? false;

  @override
  void onHeadChange(Workspace w, HeadChange change) {
    received.insert(0, change);
    if (change.kind == HeadChangeKind.branch) epoch++;
    if (received.length > 20) received.removeLast();
    notifyListeners();
  }

  @override
  Widget summary(BuildContext context, Workspace w) {
    final l10n = AppLocalizations.of(context);
    final g = w.git;
    if (g == null) return const SizedBox.shrink();
    final (String label, Tone tone) = switch (g) {
      GitState(operation: != RepoOperation.none) => (l10n.stateMerging(g.conflictCount), Tone.danger),
      GitState(behind: > 0) => (l10n.summaryPull(g.behind), Tone.warning),
      GitState(ahead: > 0) => (l10n.summaryPush(g.ahead), Tone.primary),
      _ => (l10n.stateUpToDate, Tone.success),
    };
    return StatusPill(label: label, tone: tone);
  }

  @override
  Widget body(BuildContext context, Workspace w) => BranchDockBody(workspace: w, dock: this);
}
