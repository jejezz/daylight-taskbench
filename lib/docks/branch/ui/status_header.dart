import 'package:flutter/material.dart';

import 'package:daylight_taskbench/core/command_log.dart';
import '../git/commands.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import '../repo/next_action.dart';
import '../repo/repo_controller.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'action_sheet.dart';
import 'help/concepts.dart';
import 'repo_actions.dart';
import 'repo_scope.dart';
import 'services.dart';
import 'tabs/branches_tab.dart';
import 'tabs/pr_tab.dart';
import 'widgets.dart';

/// 상태 헤더 (UI_UX.md §3 B): 추적 브랜치와 Fetch/Pull/Push.
///
/// [Taskbench에서 달라진 곳] 브랜치 칩·상태 pill·편집기 단추(원래 1·2행)는 모든 칸 위의 공유 영역
/// (lib/ui/shell/shared_bar.dart)으로 올라갔다 — 같은 정보를 두 번 보이지 않는다.
class StatusHeader extends StatelessWidget {
  const StatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = repo.status;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Row(children: [
              Icon(Icons.arrow_forward_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              if (s.hasUpstream)
                Flexible(
                  child: Text(s.upstream!,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.merge(AppFonts.userContent)),
                )
              else if (repo.headMergedAndGone)
                StatusPill(label: l10n.bdHeaderMergedAndGone, tone: Tone.primary, tooltip: l10n.bdHeaderMergedAndGoneTooltip)
              else
                StatusPill(label: l10n.bdHeaderNoUpstream, tooltip: l10n.bdHeaderNoUpstreamTooltip),
              const HelpButton(concept: Concept.upstream),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        if (repo.operation != RepoOperation.none) const _OperationButtons() else const _SyncButtons(),
      ]),
    );
  }
}

class _SyncButtons extends StatelessWidget {
  const _SyncButtons();

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final prefs = ServicesScope.of(context).prefs;
    final s = repo.status;
    final hasRemote = repo.remotes.isNotEmpty;
    final idle = !repo.busy;

    final canPull = idle && s.hasUpstream && !s.detached;
    final publish = repo.needsPublish && !s.unborn;
    final canPush = idle && hasRemote && !s.detached && !s.unborn && (publish || s.ahead > 0);
    final pullStyle = s.behind > 0;
    final mode = prefs.pullMode(repo.root);

    Widget tip(String command, Widget child) => Tooltip(message: command, child: child);
    // 병합되어 원격에서 지워진 브랜치는 게시·Push를 끄고 이유를 보여 준다.
    final pushTooltip = repo.headMergedAndGone ? l10n.bdHeaderMergedAndGoneTooltip : formatCommandLine(repo.pushCommand);

    final pullLabel = s.behind > 0
        ? '${l10n.bdHeaderPull} ↓${s.behind}'
        : l10n.bdHeaderPull;
    final pushLabel = publish
        ? l10n.bdHeaderPublish
        : (s.ahead > 0
              ? '${l10n.bdHeaderPush} ↑${s.ahead}'
              : l10n.bdHeaderPush);

    // [Taskbench에서 달라진 곳] 좁은 창(최소 380)에서 라벨이 두 줄로 꺾이거나 "P…"로 잘리던 문제.
    // 폭에 따라 두 단계로 나눈다: 넓으면 아이콘+라벨, 좁으면 Fetch 는 아이콘만, Pull·Push 는 글자만.
    // 라벨은 항상 한 줄이고, 그래도 모자라면 글자를 줄인다 (자르지 않는다).
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _compactBelow;
        final fetchPressed = idle && hasRemote
            ? () => RepoActions.fetch(context, repo)
            : null;
        final fetchCommand = formatCommandLine(GitCommands.fetch());

        return Row(
          children: [
            if (compact)
              SizedBox(
                width: 44,
                child: tip(
                  fetchCommand,
                  OutlinedButton(
                    onPressed: fetchPressed,
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Icon(Icons.sync_rounded, size: 16),
                  ),
                ),
              )
            else
              Expanded(
                flex: 2,
                child: tip(
                  fetchCommand,
                  OutlinedButton.icon(
                    onPressed: fetchPressed,
                    style: OutlinedButton.styleFrom(padding: _buttonPadding),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: _OneLine(l10n.bdHeaderFetch),
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: tip(
                formatCommandLine(GitCommands.pull(mode)),
                _SplitButton(
                  filled: pullStyle,
                  compact: compact,
                  icon: Icons.south_rounded,
                  label: pullLabel,
                  onPressed: canPull
                      ? () => RepoActions.pull(context, repo)
                      : null,
                  menuTooltip: l10n.bdPullModeTooltip,
                  onMenu: () => showPullModeSheet(context, repo),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: tip(
                pushTooltip,
                _SplitButton(
                  filled: true,
                  compact: compact,
                  icon: publish
                      ? Icons.cloud_upload_rounded
                      : Icons.north_rounded,
                  label: pushLabel,
                  onPressed: canPush
                      ? () => RepoActions.push(context, repo)
                      : null,
                  menuTooltip: l10n.bdPushOptionsTooltip,
                  onMenu: () => showPushOptionsSheet(context, repo),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 이 폭보다 좁으면 Fetch 는 아이콘만, Pull·Push 는 글자만 보인다.
const _compactBelow = 360.0;

const _buttonPadding = EdgeInsets.symmetric(horizontal: 10);

/// 한 줄 라벨. 모자라면 줄바꿈이나 말줄임 대신 글자를 줄인다.
class _OneLine extends StatelessWidget {
  const _OneLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}

/// 본체 단추 + 붙어 있는 ▾ 단추. 본체는 왼쪽만, ▾ 는 오른쪽만 둥글다.
class _SplitButton extends StatelessWidget {
  const _SplitButton({
    required this.filled,
    required this.compact,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.menuTooltip,
    required this.onMenu,
  });

  final bool filled;
  final bool compact;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String menuTooltip;
  final VoidCallback onMenu;

  static const _radius = Radius.circular(AppRadius.button);
  static const _arrowWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final mainShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(left: _radius),
    );
    final arrowShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: _radius),
    );
    final mainStyle = (filled
        ? FilledButton.styleFrom
        : OutlinedButton.styleFrom)(padding: _buttonPadding, shape: mainShape);
    final child = _OneLine(label);
    final main = compact
        ? (filled
              ? FilledButton(
                  onPressed: onPressed,
                  style: mainStyle,
                  child: child,
                )
              : OutlinedButton(
                  onPressed: onPressed,
                  style: mainStyle,
                  child: child,
                ))
        : (filled
              ? FilledButton.icon(
                  onPressed: onPressed,
                  style: mainStyle,
                  icon: Icon(icon, size: 16),
                  label: child,
                )
              : OutlinedButton.icon(
                  onPressed: onPressed,
                  style: mainStyle,
                  icon: Icon(icon, size: 16),
                  label: child,
                ));

    // ▾ 는 본체가 켜져 있을 때만 같은 색이고, 꺼져 있어도 눌러서 옵션을 볼 수 있다 (윤곽선 모양).
    final arrowFilled = filled && onPressed != null;
    final arrowStyle =
        (arrowFilled ? FilledButton.styleFrom : OutlinedButton.styleFrom)(
          padding: EdgeInsets.zero,
          minimumSize: const Size(_arrowWidth, 0),
          maximumSize: const Size(_arrowWidth, double.infinity),
          shape: arrowShape,
        );
    const arrowIcon = Icon(Icons.arrow_drop_down_rounded, size: 20);
    Widget arrow = Tooltip(
      message: menuTooltip,
      child: arrowFilled
          ? FilledButton(onPressed: onMenu, style: arrowStyle, child: arrowIcon)
          : OutlinedButton(
              onPressed: onMenu,
              style: arrowStyle,
              child: arrowIcon,
            ),
    );
    // 윤곽선끼리는 테두리가 겹치도록 1px 당기고, 채운 단추끼리는 1px 틈을 구분선으로 쓴다.
    arrow = arrowFilled
        ? Padding(padding: const EdgeInsets.only(left: 1), child: arrow)
        : Transform.translate(offset: const Offset(-1, 0), child: arrow);

    // 본체와 ▾ 의 높이를 맞춘다 (▾ 는 최소 높이가 0 이라 그대로 두면 더 낮아진다).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: main),
          SizedBox(width: _arrowWidth, child: arrow),
        ],
      ),
    );
  }
}

class _OperationButtons extends StatelessWidget {
  const _OperationButtons();

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final conflicts = repo.status.conflicts.length;
    final skip = repo.skipCommand;
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: repo.busy
              ? null
              : () async {
                  final ok = await confirmDanger(
                    context,
                    title: l10n.bdOperationAbortTitle,
                    message: switch (repo.operation) {
                      RepoOperation.rebasing => l10n.bdOperationAbortRebaseMessage,
                      RepoOperation.cherryPicking || RepoOperation.reverting => l10n.bdOperationAbortPickMessage,
                      _ => l10n.bdOperationAbortMergeMessage,
                    },
                    confirm: l10n.bdOperationAbort,
                    commands: [repo.abortCommand],
                  );
                  if (ok && context.mounted) {
                    await RepoActions.report(context, repo.abortOperation(), done: l10n.bdDoneAbort);
                  }
                },
          child: Text(l10n.bdOperationAbort),
        ),
      ),
      if (skip != null) ...[
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Tooltip(
            message: l10n.bdOperationSkipTooltip,
            child: OutlinedButton(
              onPressed: repo.busy
                  ? null
                  : () => RepoActions.report(context, repo.execute(skip), done: l10n.bdDoneSkip),
              child: Text(l10n.bdOperationSkip),
            ),
          ),
        ),
      ],
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Tooltip(
          message: conflicts > 0 ? l10n.bdOperationContinueBlocked : '',
          child: FilledButton(
            onPressed: repo.busy || conflicts > 0
                ? null
                : () => RepoActions.report(context, repo.continueOperation(), done: l10n.bdDoneContinue),
            child: Text(l10n.bdOperationContinue),
          ),
        ),
      ),
    ]);
  }
}

/// Pull 방식 비교 (UI_UX.md §6.1 비교 화면의 축소판). 고르면 저장소별로 기억한다.
Future<void> showPullModeSheet(BuildContext context, RepoController repo) {
  final prefs = ServicesScope.of(context).prefs;
  return showActionSheet<void>(context, (context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = prefs.pullMode(repo.root);
    Widget tile(PullMode mode, String title, String when, Concept concept) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          leading: Icon(mode == current ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: mode == current ? theme.colorScheme.primary : null),
          title: Text(title),
          subtitle: Text(when),
          trailing: HelpButton(concept: concept),
          onTap: () async {
            await prefs.setPullMode(repo.root, mode);
            repo.refresh();
            if (context.mounted) Navigator.pop(context);
          },
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(children: [
              Text(l10n.bdPullModeTitle, style: theme.textTheme.titleLarge),
              const HelpButton(concept: Concept.fetchVsPull),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
          tile(PullMode.merge, l10n.bdPullModeMerge, l10n.bdPullModeMergeWhen, Concept.mergeCommit),
          tile(PullMode.rebase, l10n.bdPullModeRebase, l10n.bdPullModeRebaseWhen, Concept.rebase),
          tile(PullMode.fastForwardOnly, l10n.bdPullModeFastForward, l10n.bdPullModeFastForwardWhen, Concept.fastForward),
        ]),
      ),
    );
  });
}

/// 추천 행동 배너 (UI_UX.md §3 C). 닫으면 상태가 바뀔 때까지 숨긴다.
class NextActionBanner extends StatelessWidget {
  const NextActionBanner({
    super.key,
    required this.action,
    required this.onDismiss,
    required this.onShowChanges,
    required this.onShowRemotes,
  });

  final NextAction action;
  final VoidCallback onDismiss;
  final VoidCallback onShowChanges;
  final VoidCallback onShowRemotes;

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (String text, String button, VoidCallback onPressed) = switch (action.kind) {
      NextActionKind.resolveConflicts => (l10n.bdBannerConflicts(action.count), l10n.bdBannerShow, onShowChanges),
      NextActionKind.detached => (
          l10n.bdBannerDetached,
          l10n.bdHistoryBranchHere,
          () => showCreateBranchSheet(context, repo),
        ),
      NextActionKind.pull => (l10n.bdBannerPull(action.count), l10n.bdHeaderPull, () => RepoActions.pull(context, repo)),
      NextActionKind.switchToDefault => (
          l10n.bdBannerMergedAndGone(repo.defaultBranch ?? 'main'),
          l10n.bdBannerSwitchTo(repo.defaultBranch ?? 'main'),
          () => RepoActions.report(context, repo.switchToDefault(),
              done: l10n.bdDoneSwitch(repo.defaultBranch ?? 'main')),
        ),
      NextActionKind.publish => (l10n.bdBannerPublish, l10n.bdHeaderPublish, () => RepoActions.push(context, repo)),
      NextActionKind.push => (l10n.bdBannerPush(action.count), l10n.bdHeaderPush, () => RepoActions.push(context, repo)),
      NextActionKind.createPr => (
          l10n.bdBannerCreatePr(repo.status.head ?? ''),
          l10n.bdPrCreate,
          () => showCreatePrSheet(context, repo),
        ),
      NextActionKind.publishToGitHub => (l10n.bdBannerNoRemote, l10n.bdBannerShow, onShowRemotes),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, 4, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.lightbulb_outline_rounded, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        TextButton(onPressed: repo.busy ? null : onPressed, child: Text(button)),
        IconButton(
          tooltip: l10n.commonClose,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          icon: const Icon(Icons.close_rounded),
          onPressed: onDismiss,
        ),
      ]),
    );
  }
}


/// Push 옵션 (PLAN.md 3.3 P1): 태그 함께 push, 강제 push(force-with-lease).
Future<void> showPushOptionsSheet(BuildContext context, RepoController repo) {
  final prefs = ServicesScope.of(context).prefs;
  return showActionSheet<void>(context, (context) {
    return StatefulBuilder(builder: (context, setState) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final s = repo.status;
      final head = s.head;
      final remote = repo.defaultRemote;
      final followTags = prefs.followTags(repo.root);
      // 기본 브랜치에서는 강제 push를 막는다 — 다른 사람의 기록을 덮어쓸 수 있다.
      final onDefault = head == repo.defaultBranch;
      final canForce = head != null && remote != null && s.hasUpstream && !onDefault && !repo.busy;
      final force = head == null || remote == null ? null : GitCommands.forcePush(remote, head);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.bdPushOptionsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: followTags,
              onChanged: (v) async {
                await prefs.setFollowTags(repo.root, v);
                setState(() {});
              },
              title: Text(l10n.bdPushFollowTags),
              subtitle: Text(l10n.bdPushFollowTagsWhy),
            ),
            const Divider(),
            Row(children: [
              Expanded(child: Text(l10n.bdPushForceTitle, style: theme.textTheme.titleSmall)),
              const HelpButton(concept: Concept.forceWithLease),
            ]),
            Text(
              onDefault ? l10n.bdPushForceBlockedDefault(repo.defaultBranch ?? 'main') : l10n.bdPushForceWhy,
              style: theme.textTheme.bodySmall?.copyWith(color: onDefault ? toneColor(context, Tone.warning) : null),
            ),
            if (force != null) ...[
              const SizedBox(height: AppSpacing.sm),
              CommandPreview(commands: [force]),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: !canForce
                    ? null
                    : () async {
                        final ok = await confirmDanger(
                          context,
                          title: l10n.bdPushForceConfirmTitle(head),
                          message: l10n.bdPushForceConfirmMessage(head, s.upstream ?? ''),
                          confirm: l10n.bdPushForce,
                          commands: [force!],
                        );
                        if (!ok || !context.mounted) return;
                        Navigator.pop(context);
                        await RepoActions.report(context, repo.execute(force), done: l10n.bdDonePush);
                      },
                child: Text(l10n.bdPushForce),
              ),
            ),
          ]),
        ),
      );
    });
  });
}
