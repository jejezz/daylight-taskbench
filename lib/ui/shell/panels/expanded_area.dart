// 확장 모드에서 도크 열 왼쪽에 붙는 영역: 탐색기 + 가운데(에디터 | 터미널 전환). PLAN.md §1.13.
// 모양은 daylight-workbench 를 따른다 — 떠 있는 카드가 아니라 얇은 구분선으로 나뉜 평평한 패널,
// 가운데 위쪽은 파일 탭 줄(오른쪽 끝에 에디터↔터미널 전환). 오른쪽의 도크 열(아코디언)은 taskbench 그대로다.
// 단계 11에서는 알맹이가 빈 자리표시자다 — 탐색기(13)·터미널(14)·에디터(15) 단계에서 꽂는다.
// 가운데의 두 패널은 서로 전환되어도 위젯을 살려 둔다 (열린 파일·터미널 세션이 유지돼야 하므로).

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'panel_layout.dart';

/// 도크 열의 폭 (확장 모드). 도킹 모드의 기본 폭(440)과 같게 해서 앱 바·브랜치 줄·아코디언이 도킹 모드와
/// 똑같이 보이게 한다 (좁은 막대 기준 420 이상). 도킹 모드에서는 창 전체를 쓴다.
const double dockColumnWidth = 440;

/// 탐색기 폭. 이후 단계에서 끌어서 조절하게 할 수 있다.
const double explorerWidth = 240;

/// 패널 위쪽 머리줄(탐색기 제목 · 파일 탭 줄)의 높이. 도크 열의 디렉터리 바(44)와 같아서 선이 이어진다.
const double panelHeaderHeight = 44;

class ExpandedArea extends StatelessWidget {
  const ExpandedArea({super.key, required this.panels});

  final PanelLayout panels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = BorderSide(color: Theme.of(context).dividerColor);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: divider),
      ),
      child: Row(
        children: [
          if (panels.explorer) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border(right: divider),
              ),
              child: const SizedBox(
                width: explorerWidth,
                child: ExplorerPlaceholder(),
              ),
            ),
          ],
          Expanded(
            child: panels.hasCenter
                ? CenterArea(panels: panels)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// 패널 머리줄: 아래에 선이 있는 [panelHeaderHeight] 높이의 줄.
class _Header extends StatelessWidget {
  const _Header({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: panelHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(children: children),
    );
  }
}

class ExplorerPlaceholder extends StatelessWidget {
  const ExplorerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        _Header(
          children: [
            Text(l10n.panelExplorer, style: theme.textTheme.titleSmall),
            const Spacer(),
            Icon(
              Icons.refresh_rounded,
              size: 18,
              color: theme.disabledColor,
            ),
          ],
        ),
        Expanded(
          child: _Placeholder(
            icon: Icons.folder_copy_outlined,
            body: l10n.panelPlaceholderBody,
          ),
        ),
      ],
    );
  }
}

/// 가운데: 위에 파일 탭 줄(오른쪽 끝에 에디터↔터미널 전환), 아래에 에디터 또는 터미널 중 하나만 보인다.
class CenterArea extends StatelessWidget {
  const CenterArea({super.key, required this.panels});

  final PanelLayout panels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shown = panels.center;
    return Column(
      children: [
        _Header(
          children: [
            // 파일 탭이 들어올 자리 (단계 15). 지금은 현재 보이는 패널 이름만 보인다.
            Icon(
              shown == CenterView.terminal
                  ? Icons.terminal_rounded
                  : Icons.edit_note_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              shown == CenterView.terminal
                  ? l10n.panelTerminal
                  : l10n.panelEditor,
              style: theme.textTheme.titleSmall,
            ),
            const Spacer(),
            if (panels.canSwitchCenter)
              SegmentedButton<CenterView>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: [
                  ButtonSegment(
                    value: CenterView.editor,
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text(l10n.panelEditor),
                  ),
                  ButtonSegment(
                    value: CenterView.terminal,
                    icon: const Icon(Icons.terminal_rounded, size: 16),
                    label: Text(l10n.panelTerminal),
                  ),
                ],
                selected: {shown ?? CenterView.editor},
                onSelectionChanged: (s) => panels.showCenter(s.first),
              ),
          ],
        ),
        Expanded(
          // 안 보이는 쪽도 위젯을 살려 둔다 (State 유지).
          child: Stack(
            children: [
              if (panels.editorShown)
                _Switchable(
                  visible: shown == CenterView.editor,
                  child: _Placeholder(
                    icon: Icons.edit_note_rounded,
                    body: l10n.panelPlaceholderBody,
                  ),
                ),
              if (panels.terminalShown)
                _Switchable(
                  visible: shown == CenterView.terminal,
                  child: _Placeholder(
                    icon: Icons.terminal_rounded,
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

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.body});

  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: muted),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
