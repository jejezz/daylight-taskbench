// 앱 바의 "확장" 단추: 탐색기·에디터·터미널을 모두 켜고 모두 끄는 토글 (PLAN.md §1.13).
// 도킹 모드에서도 보여야 하므로 앱 바에 둔다. 패널 하나만 닫는 일은 각 패널 머리줄의 x 가 맡는다.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../shell_shortcuts.dart';
import 'panel_layout.dart';

/// 단추 설명: 지금 누르면 무슨 일이 일어나는지 + 개별 패널 단축키.
String expandTooltip(BuildContext context, PanelLayout panels) {
  final l10n = AppLocalizations.of(context);
  final keys =
      '${l10n.panelExplorer} ${shortcutLabel(ShellShortcut.explorer)} · '
      '${l10n.panelEditor} ${shortcutLabel(ShellShortcut.editor)} · '
      '${l10n.panelTerminal} ${shortcutLabel(ShellShortcut.terminal)}';
  final action = panels.expanded
      ? l10n.panelsCollapseTooltip
      : l10n.panelsExpandTooltip;
  return '$action\n$keys';
}

/// "더 보기" 메뉴용 항목 (좁은 앱 바).
PopupMenuItem<String> expandMenuItem(BuildContext context, PanelLayout panels) {
  final l10n = AppLocalizations.of(context);
  return PopupMenuItem(
    value: expandChoice,
    child: Row(
      children: [
        Icon(_icon(panels), size: 18),
        const SizedBox(width: 8),
        Text(
          panels.expanded
              ? l10n.panelsCollapseTooltip
              : l10n.panelsExpandTooltip,
        ),
      ],
    ),
  );
}

/// "더 보기" 메뉴 항목 값.
const expandChoice = 'expand';

IconData _icon(PanelLayout panels) => panels.expanded
    ? Icons.close_fullscreen_rounded
    : Icons.open_in_full_rounded;

class ExpandButton extends StatelessWidget {
  const ExpandButton({super.key, required this.panels});

  final PanelLayout panels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: expandTooltip(context, panels),
      isSelected: panels.expanded,
      icon: Icon(
        _icon(panels),
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      selectedIcon: Icon(
        _icon(panels),
        size: 20,
        color: theme.colorScheme.primary,
      ),
      onPressed: panels.toggleAll,
    );
  }
}
