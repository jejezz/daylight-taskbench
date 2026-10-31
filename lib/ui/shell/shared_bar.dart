// 모든 칸 위에 고정되는 공유 영역 두 줄 (PLAN.md §1.9): 디렉터리 바(44) + 브랜치 줄(32).
// 상태의 주인은 Workspace 하나이고 여기서는 읽기만 한다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/vscode.dart' show vscodeDownloadUrl;
import '../../docks/branch/git/refs.dart' show Branch;
import '../../docks/branch/ui/repo_actions.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../workspace/git_state.dart';
import '../../workspace/workspace.dart';
import '../style/app_mark.dart';
import '../style/status_pill.dart';

const double sharedBarHeight = 44;
const double branchBarHeight = 36;

/// 이 폭보다 좁으면 새로 고침·항상 위를 "더 보기" 메뉴로 묶고 아이콘 단추를 좁혀 폴더 이름에 자리를 준다.
const double _narrowBelow = 420;
const double _narrowIconWidth = 32;

String _name(String path) =>
    path.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).lastOrNull ?? path;

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
    // [Taskbench에서 달라진 곳] 폴더 이름이 이 줄에서 가장 중요하다 (최소 창 380에서도 읽혀야 한다).
    // ① 이름 + 편집기 단추를 한 덩어리로 묶어 남는 폭을 모두 받게 했다. 전에는 Spacer 와 남는 폭을 반씩
    //    나눠 가져서 이름이 절반으로 잘렸다. ② 좁으면 오른쪽 아이콘 단추의 간격을 줄인다.
    return LayoutBuilder(builder: (context, constraints) {
    final narrow = constraints.maxWidth < _narrowBelow;
    return SizedBox(
      height: sharedBarHeight,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          const AppMark(size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(children: [
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
                      PopupMenuItem(
                        enabled: false,
                        height: 28,
                        child: Text(
                          l10n.workspaceRecent,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      for (final p in workspace.recent.take(8))
                        PopupMenuItem(
                          value: p,
                          child: Text(
                            _name(p),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: '\u0000open',
                        child: Text(l10n.workspaceOpenFolder),
                      ),
                      PopupMenuItem(
                        value: '\u0000close',
                        child: Text(l10n.workspaceCloseRepo),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _name(root),
                                  style: theme.textTheme.titleSmall,
                                ),
                                if (sel != null &&
                                    sel != root &&
                                    sel.startsWith(root))
                                  TextSpan(
                                    text:
                                        ' / ${sel.substring(root.length).replaceFirst(RegExp(r'^[\\/]'), '')}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
          ),
          // 편집기에서 열기는 "이 폴더" 옆에 둔다 — 폴더에 하는 동작이라 폴더 이름과 붙어 있어야 한다.
          if (root != null) EditorOpenButton(workspace: workspace),
            ]),
          ),
          if (narrow && (root != null || onToggleAlwaysOnTop != null))
            // 좁으면 새로 고침·항상 위를 한 메뉴로 묶어 폴더 이름에 자리를 준다.
            PopupMenuButton<String>(
              tooltip: l10n.moreTooltip,
              position: PopupMenuPosition.under,
              padding: EdgeInsets.zero,
              onSelected: (v) => v == 'refresh' ? workspace.refresh() : onToggleAlwaysOnTop?.call(),
              itemBuilder: (_) => [
                if (root != null)
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(children: [
                      const Icon(Icons.refresh_rounded, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.refreshTooltip),
                    ]),
                  ),
                // 체크 표시 대신 넓은 막대의 압정 아이콘과 같은 아이콘(꺼짐 = 윤곽선, 켜짐 = 채움)을 둔다.
                // 체크는 켜졌을 때만 나타나 글자 위치가 흔들렸다.
                if (onToggleAlwaysOnTop != null)
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(children: [
                      Icon((alwaysOnTop ?? false) ? Icons.push_pin_rounded : Icons.push_pin_outlined, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.alwaysOnTopTooltip),
                    ]),
                  ),
              ],
              child: SizedBox(
                width: _narrowIconWidth,
                height: sharedBarHeight,
                child: Icon(Icons.more_horiz_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else ...[
            if (root != null)
              IconButton(
                tooltip: l10n.refreshTooltip,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: workspace.refresh,
              ),
            if (onToggleAlwaysOnTop != null)
              IconButton(
                tooltip: l10n.alwaysOnTopTooltip,
                isSelected: alwaysOnTop ?? false,
                icon: const Icon(Icons.push_pin_outlined),
                selectedIcon: const Icon(Icons.push_pin_rounded),
                onPressed: onToggleAlwaysOnTop,
              ),
          ],
          IconButton(
            padding: narrow ? EdgeInsets.zero : null,
            style: narrow ? IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap) : null,
            constraints: narrow ? const BoxConstraints.tightFor(width: _narrowIconWidth, height: sharedBarHeight) : null,
            tooltip: l10n.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettings,
          ),
          IconButton(
            padding: narrow ? EdgeInsets.zero : null,
            style: narrow ? IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap) : null,
            constraints: narrow ? const BoxConstraints.tightFor(width: _narrowIconWidth, height: sharedBarHeight) : null,
            tooltip: l10n.aboutTooltip,
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: onAbout,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
    });
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
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.sm,
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final compact = c.maxWidth < 340;
            return Row(
              children: [
                Flexible(
                  child: Tooltip(
                    message: l10n.branchChipTooltip(branch),
                    child: PopupMenuButton<String>(
                      tooltip: '',
                      position: PopupMenuPosition.under,
                      enabled: workspace.repo != null,
                      onSelected: (name) => _select(context, name),
                      itemBuilder: (_) => _menu(context, l10n),
                      // 칩을 누르면 로컬 브랜치 목록 — 고르면 바로 전환한다. Dock 이 접혀 있어도 된다.
                      child: Container(
                        // pill 과 같은 높이·가운데 정렬 — 아이콘·이름·pill 의 눈높이가 한 줄로 맞는다.
                        height: pillHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.call_split_rounded,
                              size: 20,
                              color: g.detached
                                  ? toneColor(context, Tone.warning)
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                branch,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                strutStyle: const StrutStyle(
                                  fontSize: 15,
                                  height: 1.2,
                                  forceStrutHeight: true,
                                  leading: 0,
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ..._pills(l10n, g),
                ] else ...[
                  const SizedBox(width: 4),
                  ..._pills(l10n, g).take(1),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static const _openTab = '\u0000tab';

  List<PopupMenuEntry<String>> _menu(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final repo = workspace.repo;
    final locals = repo?.localBranches ?? const <Branch>[];
    return [
      for (final b in locals)
        CheckedPopupMenuItem<String>(
          value: b.name,
          checked: b.current,
          child: Text(
            b.name,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.userContent,
          ),
        ),
      if (locals.isNotEmpty) const PopupMenuDivider(),
      PopupMenuItem<String>(value: _openTab, child: Text(l10n.bdTabBranches)),
    ];
  }

  Future<void> _select(BuildContext context, String name) async {
    if (name == _openTab) {
      onBranchTap?.call();
      return;
    }
    final repo = workspace.repo;
    if (repo == null) return;
    final target = repo.localBranches.where((b) => b.name == name).firstOrNull;
    if (target == null || target.current) return;
    final l10n = AppLocalizations.of(context);
    await RepoActions.withStashRetry(
      context,
      repo,
      () => repo.switchTo(target),
      done: l10n.bdDoneSwitch(name),
      openRepo: workspace.requestOpen,
    );
  }

  List<Widget> _pills(AppLocalizations l10n, GitState g) {
    Widget p(String label, Tone tone) => Padding(
      padding: const EdgeInsets.only(right: 4),
      child: StatusPill(label: label, tone: tone),
    );
    if (g.operation != RepoOperation.none) {
      final n = g.conflictCount;
      final label = switch (g.operation) {
        RepoOperation.rebasing => l10n.bdHeaderRebasing(n),
        RepoOperation.cherryPicking => l10n.bdHeaderCherryPicking(n),
        RepoOperation.reverting => l10n.bdHeaderReverting(n),
        _ => l10n.bdHeaderMerging(n),
      };
      return [
        StatusPill(
          label: label,
          tone: Tone.danger,
          icon: Icons.warning_amber_rounded,
        ),
      ];
    }
    return [
      if (g.upstream == null && !g.detached)
        p(l10n.branchNoUpstream, Tone.neutral),
      if (g.ahead > 0) p('↑${g.ahead}', Tone.primary),
      if (g.behind > 0) p('↓${g.behind}', Tone.warning),
      if (g.changedCount > 0)
        p('● ${l10n.stateChanges(g.changedCount)}', Tone.neutral),
      if (g.clean && g.ahead == 0 && g.behind == 0)
        p('✓ ${l10n.stateUpToDate}', Tone.success),
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
      _command = widget.workspace.folderEditorCommand(root);
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
          icon: const Icon(Icons.description_outlined),
          onPressed: snap.connectionState != ConnectionState.done
              ? null
              : () => _open(context, cmd),
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
      await Process.start(
        cmd.first,
        cmd.sublist(1),
        mode: ProcessStartMode.detached,
        runInShell: Platform.isWindows,
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.editorOpenFailed)));
    }
  }
}
