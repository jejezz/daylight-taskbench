// 앱 바의 "패널" 단추: 탐색기·에디터·터미널을 켜고 끈다 (PLAN.md §1.13).
// 도킹 모드에서도 보여야 하므로 앱 바에 둔다. 패널이 하나라도 켜져 있으면 "모두 닫으면 도킹으로 돌아간다"는 안내를 보인다.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'panel_layout.dart';

/// 패널 메뉴 항목 값. 좁은 앱 바에서는 "더 보기" 메뉴에 같은 항목을 끼워 넣는다.
const panelChoices = {'explorer', 'editor', 'terminal'};

void applyPanelChoice(PanelLayout panels, String value) {
  switch (value) {
    case 'explorer':
      panels.setExplorer(!panels.explorer);
    case 'editor':
      panels.setEditor(!panels.editor);
    case 'terminal':
      panels.setTerminal(!panels.terminal);
  }
}

List<PopupMenuEntry<String>> panelMenuEntries(BuildContext context, PanelLayout panels) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  return [
    CheckedPopupMenuItem(value: 'explorer', checked: panels.explorer, child: Text(l10n.panelExplorer)),
    CheckedPopupMenuItem(
      value: 'editor',
      checked: panels.editorShown,
      enabled: panels.embeddedEditor,
      child: Text(panels.embeddedEditor ? l10n.panelEditor : '${l10n.panelEditor} — ${l10n.panelEditorOff}'),
    ),
    CheckedPopupMenuItem(value: 'terminal', checked: panels.terminal, child: Text(l10n.panelTerminal)),
    if (panels.expanded) ...[
      const PopupMenuDivider(),
      PopupMenuItem(enabled: false, height: 32, child: Text(l10n.panelsDockHint, style: theme.textTheme.bodySmall)),
    ],
  ];
}

class PanelsMenuButton extends StatelessWidget {
  const PanelsMenuButton({super.key, required this.panels, this.width});

  final PanelLayout panels;

  /// 좁은 앱 바에서 쓰는 단추 폭 (null이면 기본 IconButton 크기).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.panelsTooltip,
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      onSelected: (v) => applyPanelChoice(panels, v),
      itemBuilder: (_) => panelMenuEntries(context, panels),
      child: SizedBox(
        width: width ?? 40,
        height: 44,
        child: Icon(
          panels.expanded
              ? Icons.view_sidebar_rounded
              : Icons.view_sidebar_outlined,
          size: 20,
          color: panels.expanded
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
