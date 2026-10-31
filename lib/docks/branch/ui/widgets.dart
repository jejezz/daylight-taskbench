import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import '../git/error_hints.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'help/concept_sheet.dart';
import 'help/concepts.dart';

// [Taskbench에서 달라진 곳] Tone·toneColor·StatusPill 은 앱 공통 위젯(lib/ui/style/status_pill.dart)을 쓴다 —
// 공유 영역과 Dock 안의 pill 이 같은 크기·색이 되도록.
import 'package:daylight_taskbench/ui/style/status_pill.dart';

export 'package:daylight_taskbench/ui/style/status_pill.dart';

/// 섹션 제목 + 주 행동 (UI_UX.md §3 E).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing, this.help});

  final String title;
  final Widget? trailing;
  final Concept? help;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Row(children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (help != null) HelpButton(concept: help!),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Align(alignment: Alignment.centerRight, child: trailing)),
      ]),
    );
  }
}

/// 접을 수 있는 그룹 머리 (변경 파일 그룹, 로컬/원격 브랜치).
class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    this.action,
    this.tone = Tone.neutral,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget? action;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 4, AppSpacing.md, 4),
        child: Row(children: [
          Icon(expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, size: 18,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                  color: tone == Tone.neutral ? null : toneColor(context, tone))),
          const SizedBox(width: 6),
          Text('$count', style: theme.textTheme.bodySmall),
          const Spacer(),
          if (action != null) SizedBox(height: 28, child: action),
        ]),
      ),
    );
  }
}

/// "실행될 명령" 블록 (UI_UX.md §5). 고정폭, 복사 버튼.
class CommandPreview extends StatelessWidget {
  const CommandPreview({super.key, required this.commands});

  final List<List<String>> commands;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = commands.map(formatCommandLine).join('\n');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.bdCommandPreviewLabel, style: theme.textTheme.labelMedium),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, 4, AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: SelectableText(text, style: AppFonts.mono.copyWith(fontSize: 12))),
          CopyButton(text: text),
        ]),
      ),
    ]);
  }
}

class CopyButton extends StatelessWidget {
  const CopyButton({super.key, required this.text, this.size = 16});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.bdCommonCopy,
      visualDensity: VisualDensity.compact,
      iconSize: size,
      icon: const Icon(Icons.content_copy_rounded),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.bdCommonCopied), duration: const Duration(seconds: 2)));
      },
    );
  }
}

/// 개념 도움말을 여는 `?` (PLAN.md 3.13, UI_UX.md §6.1).
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.concept});

  final Concept concept;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).bdHelpTooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 16,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: const Icon(Icons.help_outline_rounded),
      onPressed: () => showConceptSheet(context, concept),
    );
  }
}

/// 완료 알림: 4초 후 닫힘 (ui-ux.md §6).
void showDone(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 4)));
}

/// 오류 알림: 쉬운 설명 + 원문 복사 + (있으면) 해결 버튼 (UI_UX.md §3 F).
void showCommandError(
  BuildContext context,
  CommandResult result, {
  String? action,
  VoidCallback? onAction,
}) {
  final l10n = AppLocalizations.of(context);
  final hint = classifyError(result.combined, exitCode: result.exitCode);
  final raw = result.combined.trim();
  final explanation = hint == null ? null : errorHintText(l10n, hint, output: result.combined);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 10),
      showCloseIcon: true,
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(explanation ?? l10n.bdErrorGeneric, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (raw.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(raw.split('\n').where((l) => l.trim().isNotEmpty).take(3).join('\n'),
              maxLines: 3, overflow: TextOverflow.ellipsis, style: AppFonts.mono.copyWith(fontSize: 11)),
        ],
      ]),
      action: onAction != null && action != null
          ? SnackBarAction(label: action, onPressed: onAction)
          : SnackBarAction(
              label: l10n.bdCommonCopy,
              onPressed: () => Clipboard.setData(ClipboardData(text: raw)),
            ),
    ));
}

String errorHintText(AppLocalizations l10n, GitErrorKind hint, {String output = ''}) => switch (hint) {
      GitErrorKind.pushRejected => l10n.bdErrorPushRejected,
      GitErrorKind.authFailed => l10n.bdErrorAuthFailed,
      GitErrorKind.conflict => l10n.bdErrorConflict,
      GitErrorKind.localChangesWouldBeOverwritten => l10n.bdErrorLocalChanges,
      GitErrorKind.notFastForward => l10n.bdErrorNotFastForward,
      GitErrorKind.protectedBranch => l10n.bdErrorProtectedBranch,
      GitErrorKind.branchNotMerged => l10n.bdErrorBranchNotMerged,
      GitErrorKind.noUpstream => l10n.bdErrorNoUpstream,
      GitErrorKind.alreadyExists => l10n.bdErrorAlreadyExists,
      GitErrorKind.repositoryNotFound => l10n.bdErrorRepositoryNotFound,
      GitErrorKind.network => l10n.bdErrorNetwork,
      GitErrorKind.notInstalled => l10n.bdErrorNotInstalled,
      GitErrorKind.branchInOtherWorktree => l10n.bdErrorBranchInOtherWorktree(worktreePathFromError(output) ?? ''),
    };

/// 되돌릴 수 없는 작업 확인 (ui-ux.md §6): 위험 버튼은 error 색, 기본 포커스는 취소.
Future<bool> confirmDanger(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  List<List<String>> commands = const [],
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      // 좁은 창에서 긴 설명과 명령이 넘치지 않게.
      scrollable: true,
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message),
          if (commands.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), CommandPreview(commands: commands)],
        ]),
      ),
      actions: [
        TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 빈 상태 (ui-ux.md §6): 48px 아이콘, 한 줄 안내, 주 행동 하나.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(message!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
      ]),
    );
  }
}

/// 상대 시간: 방금, 5분 전, 3시간 전, 2일 전, 그 이상은 날짜.
String relativeTime(AppLocalizations l10n, DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l10n.bdTimeJustNow;
  if (d.inHours < 1) return l10n.bdTimeMinutesAgo(d.inMinutes);
  if (d.inDays < 1) return l10n.bdTimeHoursAgo(d.inHours);
  if (d.inDays < 30) return l10n.bdTimeDaysAgo(d.inDays);
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

/// 작은 선택 칩 (커밋 접두어, 브랜치 접두어, 편집기 이름). 좁은 창에서 한 줄에 들어가게.
class SmallChip extends StatelessWidget {
  const SmallChip({super.key, required this.label, required this.onPressed, this.tooltip});

  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.iconChip),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.iconChip),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(label, style: AppFonts.mono.copyWith(fontSize: 11.5, color: theme.colorScheme.onSurface)),
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// 되돌릴 수 없고 공개된 것을 지우는 작업의 확인 (v0.6.1): [expected]를 그대로
/// 입력해야 위험 버튼이 켜진다. 릴리스 삭제·되돌리기에 쓴다.
Future<bool> confirmTyped(
  BuildContext context, {
  required String title,
  required String message,
  required String expected,
  required String confirm,
  List<List<String>> commands = const [],
  Widget? extra,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _TypedConfirmDialog(
      title: title,
      message: message,
      expected: expected,
      confirm: confirm,
      commands: commands,
      extra: extra,
    ),
  );
  return result ?? false;
}

/// 입력 상자의 컨트롤러는 대화상자 State가 가진다 — 닫히는 애니메이션이
/// 끝난 뒤에 버려야 한다.
class _TypedConfirmDialog extends StatefulWidget {
  const _TypedConfirmDialog({
    required this.title,
    required this.message,
    required this.expected,
    required this.confirm,
    required this.commands,
    this.extra,
  });

  final String title;
  final String message;
  final String expected;
  final String confirm;
  final List<List<String>> commands;
  final Widget? extra;

  @override
  State<_TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<_TypedConfirmDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.message),
            ?widget.extra,
            const SizedBox(height: AppSpacing.md),
            Text(l10n.bdConfirmTypeToContinue(widget.expected), style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            TextField(
              controller: _typed,
              autofocus: true,
              style: AppFonts.mono.copyWith(fontSize: 13),
              decoration: InputDecoration(isDense: true, hintText: widget.expected),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.commands.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              CommandPreview(commands: widget.commands),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: _typed.text.trim() == widget.expected ? () => Navigator.pop(context, true) : null,
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}
