// Branch Dock 칸 — 단계 1 자리표시자. 단계 3에서 branch-dock-flutter 의 화면이 이 칸 안으로 들어온다.
// 지금은 칸이 공유 상태(GitState)와 브랜치 전환 신호(HeadChange)를 제대로 받는지 눈으로 확인하게 한다.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/taskbench_style.dart';
import '../../ui/style/status_pill.dart';
import '../../workspace/git_state.dart';
import '../../workspace/workspace.dart';
import '../dock_module.dart';

class BranchDock extends DockModule {
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
  void onHeadChange(Workspace w, HeadChange change) {
    received.insert(0, change);
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
  Widget body(BuildContext context, Workspace w) => _PlaceholderBody(dock: this, workspace: w);
}

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({required this.dock, required this.workspace});

  final BranchDock dock;
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([dock, workspace]),
      builder: (context, _) {
        final g = workspace.git;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(l10n.dockPlaceholderBranch, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (g != null)
              SelectableText(
                'root: ${g.root}\nbranch: ${g.branch ?? '(detached)'}  sha: ${(g.sha == null ? '-' : g.sha!.substring(0, g.sha!.length < 7 ? g.sha!.length : 7))}\n'
                'upstream: ${g.upstream ?? '-'}  ↑${g.ahead} ↓${g.behind}  changes: ${g.changedCount}  op: ${g.operation.name}',
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Menlo'),
              ),
            const SizedBox(height: 12),
            for (final c in dock.received.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.dockLastChange(switch (c.kind) {
                    HeadChangeKind.branch => l10n.dockChangeBranch(c.from.branch ?? l10n.branchDetached, c.to.branch ?? l10n.branchDetached),
                    HeadChangeKind.commit => l10n.dockChangeCommit,
                    HeadChangeKind.operation => l10n.dockChangeOperation,
                  }),
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }
}
