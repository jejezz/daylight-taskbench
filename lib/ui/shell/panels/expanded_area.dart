// 확장 모드에서 도크 열 왼쪽에 붙는 영역: 탐색기 + 가운데(에디터 | 터미널 전환). PLAN.md §1.13.
// 단계 11에서는 빈 자리표시자다 — 탐색기(13)·터미널(14)·에디터(15) 단계에서 알맹이를 꽂는다.
// 가운데의 두 패널은 서로 전환되어도 위젯을 살려 둔다 (열린 파일·터미널 세션이 유지돼야 하므로).

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../style/glass_card.dart';
import 'panel_layout.dart';

/// 도크 열의 폭 (확장 모드). 도킹 모드에서는 창 전체를 쓴다.
const double dockColumnWidth = 400;

/// 탐색기 폭. 이후 단계에서 끌어서 조절하게 할 수 있다.
const double explorerWidth = 240;

class ExpandedArea extends StatelessWidget {
  const ExpandedArea({super.key, required this.panels});

  final PanelLayout panels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
      child: Row(
        children: [
          if (panels.explorer) ...[
            const SizedBox(width: explorerWidth, child: ExplorerPlaceholder()),
            const SizedBox(width: 8),
          ],
          if (panels.hasCenter)
            Expanded(child: CenterArea(panels: panels))
          else
            const Spacer(),
        ],
      ),
    );
  }
}

class ExplorerPlaceholder extends StatelessWidget {
  const ExplorerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _PanelCard(
      icon: Icons.folder_copy_outlined,
      title: l10n.panelExplorer,
      body: l10n.panelPlaceholderBody,
    );
  }
}

/// 가운데: 에디터와 터미널 중 하나만 보인다. 둘 다 켜져 있으면 위에 전환 단추가 나온다.
class CenterArea extends StatelessWidget {
  const CenterArea({super.key, required this.panels});

  final PanelLayout panels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = panels.center;
    return Column(
      children: [
        if (panels.canSwitchCenter)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<CenterView>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: CenterView.editor,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: Text(l10n.panelEditor),
                ),
                ButtonSegment(
                  value: CenterView.terminal,
                  icon: const Icon(Icons.terminal_rounded, size: 18),
                  label: Text(l10n.panelTerminal),
                ),
              ],
              selected: {shown ?? CenterView.editor},
              onSelectionChanged: (s) => panels.showCenter(s.first),
            ),
          ),
        Expanded(
          // 안 보이는 쪽도 위젯을 살려 둔다 (State 유지).
          child: Stack(
            children: [
              if (panels.editorShown)
                _Switchable(
                  visible: shown == CenterView.editor,
                  child: _PanelCard(
                    icon: Icons.edit_note_rounded,
                    title: l10n.panelEditor,
                    body: l10n.panelPlaceholderBody,
                  ),
                ),
              if (panels.terminalShown)
                _Switchable(
                  visible: shown == CenterView.terminal,
                  child: _PanelCard(
                    icon: Icons.terminal_rounded,
                    title: l10n.panelTerminal,
                    body: l10n.panelPlaceholderBody,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Switchable extends StatelessWidget {
  const _Switchable({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Offstage(
      offstage: !visible,
      child: TickerMode(enabled: visible, child: child),
    ),
  );
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      active: false,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
