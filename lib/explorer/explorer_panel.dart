// 확장 모드의 탐색기 패널 (PLAN.md §1.13): 머리줄(제목 · 빠른 열기 · 새로 고침) + 파일 트리.
// 저장소 루트를 보이고, 고른 하위 폴더(`selectedDir`)까지 펼친다. 파일을 누르면 [onOpenFile]로 넘긴다.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/shell/panels/panel_header.dart';
import '../workspace/workspace.dart';
import 'file_tree.dart';

class ExplorerPanel extends StatefulWidget {
  const ExplorerPanel({
    super.key,
    required this.workspace,
    required this.onOpenFile,
    this.onQuickOpen,
    this.onClose,
    this.quickOpenShortcut = '',
  });

  final Workspace workspace;
  final ValueChanged<String> onOpenFile;

  /// 머리줄의 "파일 이름으로 열기" 단추. null 이면 단추를 보이지 않는다.
  final VoidCallback? onQuickOpen;

  /// 머리줄 오른쪽 끝의 닫기(x) 단추. null 이면 단추를 보이지 않는다.
  final VoidCallback? onClose;

  /// 툴팁에 보일 단축키 (예: `⌘⇧O`).
  final String quickOpenShortcut;

  @override
  State<ExplorerPanel> createState() => _ExplorerPanelState();
}

class _ExplorerPanelState extends State<ExplorerPanel> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.workspace,
      builder: (context, _) {
        final root = widget.workspace.root;
        return Column(
          children: [
            PanelHeader(
              children: [
                Expanded(
                  child: Text(
                    l10n.panelExplorer,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onQuickOpen != null && root != null)
                  IconButton(
                    tooltip: l10n.explorerQuickOpenTooltip(
                      widget.quickOpenShortcut,
                    ),
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: const Icon(Icons.search_rounded),
                    onPressed: widget.onQuickOpen,
                  ),
                IconButton(
                  tooltip: l10n.explorerRefresh,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: root == null
                      ? null
                      : () => setState(() => _revision++),
                ),
                if (widget.onClose != null) PanelCloseButton(onPressed: widget.onClose!),
              ],
            ),
            Expanded(
              child: root == null
                  ? const SizedBox.shrink()
                  : FileTree(
                      key: ValueKey(root),
                      root: root,
                      expandTo: widget.workspace.selectedDir,
                      revision: _revision,
                      onOpenFile: widget.onOpenFile,
                    ),
            ),
          ],
        );
      },
    );
  }
}
