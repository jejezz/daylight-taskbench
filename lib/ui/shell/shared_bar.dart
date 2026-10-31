// 모든 칸 위에 고정되는 공유 영역 두 줄 (PLAN.md §1.9): 디렉터리 바(44) + 브랜치 줄(32).
// 상태의 주인은 Workspace 하나이고 여기서는 읽기만 한다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/vscode.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../workspace/git_state.dart';
import '../../workspace/workspace.dart';
import '../style/app_mark.dart';
import '../style/status_pill.dart';

const double sharedBarHeight = 44;
const double branchBarHeight = 32;

String _name(String path) => path.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).lastOrNull ?? path;

/// ① 디렉터리 바.
class WorkspaceBar extends StatelessWidget {
  const WorkspaceBar({
    super.key,
    required this.workspace,
    required this.onOpenFolder,
    required this.onOpenRecent,
    required this.onSettings,
    required this.onAbout,
    this.alwaysOnTop,
    this.onToggleAlwaysOnTop,
  });

  final Workspace workspace;
  final VoidCallback onOpenFolder;
  final ValueChanged<String> onOpenRecent;
  final VoidCallback onSettings;
  final VoidCallback onAbout;
  final bool? alwaysOnTop;
  final VoidCallback? onToggleAlwaysOnTop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final root = workspace.root;
    final sel = workspace.selectedDir;
    return SizedBox(
      height: sharedBarHeight,
      child: Row(children: [
        const SizedBox(width: AppSpacing.md),
        const AppMark(size: 24),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: root == null
              ? const SizedBox.shrink()
              : PopupMenuButton<String>(
                  tooltip: sel ?? root,
                  position: PopupMenuPosition.under,
                  onSelected: (v) {
                    switch (v) {
                      case '\u0000open':
                        onOpenFolder();
                      case '\u0000close':
                        workspace.close();
                      default:
                        onOpenRecent(v);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(enabled: false, height: 28, child: Text(l10n.workspaceRecent, style: theme.textTheme.labelMedium)),
                    for (final p in workspace.recent.take(8)) PopupMenuItem(value: p, child: Text(_name(p), overflow: TextOverflow.ellipsis)),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: '\u0000open', child: Text(l10n.workspaceOpenFolder)),
                    PopupMenuItem(value: '\u0000close', child: Text(l10n.workspaceCloseRepo)),
                  ],
                  child: Row(children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: _name(root), style: theme.textTheme.titleSmall),
                          if (sel != null && sel != root && sel.startsWith(root))
                            TextSpan(text: ' / ${sel.substring(root.length).replaceFirst(RegExp(r'^[\\/]'), '')}', style: theme.textTheme.bodySmall),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.onSurfaceVariant),
                  ]),
                ),
        ),
        // 편집기에서 열기는 "이 폴더" 옆에 둔다 — 폴더에 하는 동작이라 폴더 이름과 붙어 있어야 한다.
        if (root != null) EditorOpenButton(workspace: workspace),
        const Spacer(),
        if (root != null) IconButton(tooltip: l10n.refreshTooltip, icon: const Icon(Icons.refresh_rounded), onPressed: workspace.refresh),
        if (onToggleAlwaysOnTop != null)
          IconButton(
            tooltip: l10n.alwaysOnTopTooltip,
            isSelected: alwaysOnTop ?? false,
            icon: const Icon(Icons.push_pin_outlined),
            selectedIcon: const Icon(Icons.push_pin_rounded),
            onPressed: onToggleAlwaysOnTop,
          ),
        IconButton(tooltip: l10n.settingsTooltip, icon: const Icon(Icons.settings_outlined), onPressed: onSettings),
        IconButton(tooltip: l10n.aboutTooltip, icon: const Icon(Icons.info_outline_rounded), onPressed: onAbout),
        const SizedBox(width: AppSpacing.sm),
      ]),
    );
  }
}

/// ② 브랜치 줄: 브랜치 칩 + 상태 pill. (편집기에서 열기는 ① 디렉터리 이름 옆)
class BranchBar extends StatelessWidget {
  const BranchBar({super.key, required this.workspace, this.onBranchTap});

  final Workspace workspace;
  final VoidCallback? onBranchTap;

  @override
  Widget build(BuildContext context) {
    final g = workspace.git;
    if (g == null) return const SizedBox(height: branchBarHeight);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final branch = g.branch ?? l10n.branchDetached;
    return SizedBox(
      height: branchBarHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
        child: LayoutBuilder(builder: (context, c) {
          final compact = c.maxWidth < 340;
          return Row(children: [
            Flexible(
              child: Tooltip(
                message: l10n.branchChipTooltip(branch),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  onTap: onBranchTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.call_split_rounded, size: 16, color: g.detached ? toneColor(context, Tone.warning) : theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Flexible(child: Text(branch, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall)),
                    ]),
                  ),
                ),
              ),
            ),
            if (!compact) ...[const SizedBox(width: AppSpacing.sm), ..._pills(l10n, g)] else ...[const SizedBox(width: 4), ..._pills(l10n, g).take(1)],
          ]);
        }),
      ),
    );
  }

  List<Widget> _pills(AppLocalizations l10n, GitState g) {
    Widget p(String label, Tone tone) => Padding(padding: const EdgeInsets.only(right: 4), child: StatusPill(label: label, tone: tone));
    if (g.operation != RepoOperation.none) {
      final label = g.operation == RepoOperation.rebasing ? l10n.stateRebasing(g.conflictCount) : l10n.stateMerging(g.conflictCount);
      return [p(label, Tone.danger)];
    }
    return [
      if (g.upstream == null && !g.detached) p(l10n.branchNoUpstream, Tone.neutral),
      if (g.ahead > 0) p('↑${g.ahead}', Tone.primary),
      if (g.behind > 0) p('↓${g.behind}', Tone.warning),
      if (g.changedCount > 0) p('● ${l10n.stateChanges(g.changedCount)}', Tone.neutral),
      if (g.clean && g.ahead == 0 && g.behind == 0) p('✓ ${l10n.stateUpToDate}', Tone.success),
    ];
  }
}

/// 편집기에서 열기 — 툴팁에 실제로 실행될 명령을 보인다. 편집기를 못 찾으면 설치 링크만 연다 (Branch 동작).
class EditorOpenButton extends StatefulWidget {
  const EditorOpenButton({super.key, required this.workspace});

  final Workspace workspace;

  @override
  State<EditorOpenButton> createState() => _EditorOpenButtonState();
}

class _EditorOpenButtonState extends State<EditorOpenButton> {
  Future<List<String>?>? _command;
  String? _forRoot;

  @override
  Widget build(BuildContext context) {
    final root = widget.workspace.root;
    if (root == null) return const SizedBox.shrink();
    if (_forRoot != root) {
      _forRoot = root;
      _command = vscodeOpenCommand(root, path: widget.workspace.runner.path);
    }
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<String>?>(
      future: _command,
      builder: (context, snap) {
        final cmd = snap.data;
        return IconButton(
          tooltip: !snap.hasData && snap.connectionState != ConnectionState.done
              ? ''
              : cmd == null
                  ? l10n.editorOpenNoEditor
                  : l10n.editorOpenTooltip(cmd.join(' ')),
          icon: const Icon(Icons.code_rounded),
          onPressed: snap.connectionState != ConnectionState.done ? null : () => _open(context, cmd),
        );
      },
    );
  }

  Future<void> _open(BuildContext context, List<String>? cmd) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (cmd == null) {
      await launchUrl(vscodeDownloadUrl);
      return;
    }
    try {
      await Process.start(cmd.first, cmd.sublist(1), mode: ProcessStartMode.detached, runInShell: Platform.isWindows);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.editorOpenFailed)));
    }
  }
}
