// 확장 모드의 탐색기 패널 (PLAN.md §1.13): 머리줄(제목 · 빠른 열기 · 새로 고침) + 파일 트리.
// 저장소 루트를 보이고, 고른 하위 폴더(`selectedDir`)까지 펼친다. 파일을 누르면 [onOpenFile]로 넘긴다.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/shell/panels/panel_header.dart';
import '../workspace/workspace.dart';
import 'file_tree.dart';
import 'new_file.dart';

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

  /// 새 파일 이름을 묻고 만든 뒤 트리를 새로 읽고 에디터로 연다. 위치는 고른 하위 폴더(없으면 저장소 루트).
  Future<void> _newFile(String root) async {
    final base = widget.workspace.selectedDir ?? root;
    final outcome = await showDialog<NewFileOutcome>(
      context: context,
      builder: (_) => _NewFileDialog(rootDir: root, baseDir: base),
    );
    if (outcome == null || !mounted) return;
    setState(() => _revision++);
    final path = outcome.path;
    if (path != null) widget.onOpenFile(path);
  }

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
                  tooltip: l10n.explorerNewFile,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.note_add_outlined),
                  onPressed: root == null ? null : () => _newFile(root),
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

/// 새 파일 이름 입력 대화상자. 만들면 [NewFileOutcome]을, 취소하면 null 을 돌려준다.
class _NewFileDialog extends StatefulWidget {
  const _NewFileDialog({required this.rootDir, required this.baseDir});

  final String rootDir;
  final String baseDir;

  @override
  State<_NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<_NewFileDialog> {
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final outcome = await createNewFile(
      rootDir: widget.rootDir,
      baseDir: widget.baseDir,
      input: _name.text,
    );
    if (!mounted) return;
    switch (outcome.result) {
      case NewFileResult.created:
        Navigator.pop(context, outcome);
      case NewFileResult.exists:
        setState(() {
          _busy = false;
          _error = l10n.explorerNewFileExists;
        });
      case NewFileResult.invalid:
        setState(() {
          _busy = false;
          _error = l10n.explorerNewFileInvalid;
        });
      case NewFileResult.failed:
        setState(() {
          _busy = false;
          _error = l10n.explorerNewFileFailed(outcome.error ?? '');
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.explorerNewFileTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.explorerNewFileBase(widget.baseDir),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.explorerNewFileHint,
                errorText: _error,
                errorMaxLines: 3,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _create(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: Text(l10n.explorerNewFileCreate),
        ),
      ],
    );
  }
}
