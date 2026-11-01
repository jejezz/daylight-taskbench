// 확장 모드에서 도크 열 왼쪽에 붙는 영역: 탐색기 + 가운데(에디터 | 터미널 전환). PLAN.md §1.13.
// 모양은 daylight-workbench 를 따른다 — 떠 있는 카드가 아니라 얇은 구분선으로 나뉜 평평한 패널,
// 가운데 위쪽은 파일 탭 줄(오른쪽 끝에 에디터↔터미널 전환). 오른쪽의 도크 열(아코디언)은 taskbench 그대로다.
// 단계 11에서는 알맹이가 빈 자리표시자다 — 탐색기(13)·터미널(14)·에디터(15) 단계에서 꽂는다.
// 가운데의 두 패널은 서로 전환되어도 위젯을 살려 둔다 (열린 파일·터미널 세션이 유지돼야 하므로).

import 'package:flutter/material.dart';

import '../../../editor/editor_controller.dart';
import '../../../editor/editor_host.dart';
import '../../../explorer/explorer_panel.dart';
import '../../../l10n/app_localizations.dart';
import '../../../terminal/terminal_host.dart';
import '../../../terminal/terminal_sessions_controller.dart';
import '../../../terminal/terminal_settings.dart';
import '../../../workspace/workspace.dart';
import 'panel_divider.dart';
import 'panel_header.dart';
import 'panel_layout.dart';
import 'panel_widths.dart';

/// 도크 열의 기본 폭 (확장 모드). 도킹 모드의 기본 폭(440)과 같게 해서 앱 바·브랜치 줄·아코디언이 도킹 모드와
/// 똑같이 보이게 한다. 구분선을 끌어 바꾼 폭은 [PanelWidths]가 쥔다. 도킹 모드에서는 창 전체를 쓴다.
const double dockColumnWidth = PanelWidths.defaultDock;

/// 탐색기의 기본 폭. 구분선을 끌어 바꾼 폭은 [PanelWidths]가 쥔다.
const double explorerWidth = PanelWidths.defaultExplorer;

class ExpandedArea extends StatelessWidget {
  const ExpandedArea({
    super.key,
    required this.panels,
    required this.workspace,
    required this.onOpenFile,
    required this.terminals,
    required this.terminalSettings,
    required this.editor,
    required this.widths,
    this.onQuickOpen,
    this.quickOpenShortcut = '',
  });

  final PanelLayout panels;
  final Workspace workspace;

  /// 탐색기·도크 열의 너비(끌어서 조절, 저장).
  final PanelWidths widths;

  /// 터미널 세션과 설정 — 터미널 패널을 껐다 켜도 세션이 살아 있도록 셸이 쥔다.
  final TerminalSessionsController terminals;
  final TerminalSettings terminalSettings;

  /// 열린 편집기 탭들 — 에디터 패널을 껐다 켜도 탭과 고치던 글이 남도록 셸이 쥔다.
  final EditorController editor;

  /// 탐색기에서 고른 파일을 연다 (내장 에디터 또는 외부 편집기 — 셸이 정한다).
  final ValueChanged<String> onOpenFile;
  final VoidCallback? onQuickOpen;
  final String quickOpenShortcut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surface),
      child: LayoutBuilder(
        builder: (context, c) {
          // 가운데가 없으면 탐색기가 남는 폭을 쓴다 (창이 이미 그 폭에 맞춰져 있어 빈칸이 생기지 않는다).
          // 가운데가 있으면 탐색기는 원하는 폭이되, 가운데가 최소 폭을 지킬 수 있게 줄여서 보인다.
          final explorer = PanelWidths.explorerFit(
            area: c.maxWidth,
            hasCenter: panels.hasCenter,
            preferred: widths.explorer,
          );
          return Row(
            children: [
              if (panels.explorer)
                _fit(
                  fill: !panels.hasCenter,
                  width: explorer,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                    ),
                    child: ExplorerPanel(
                      workspace: workspace,
                      onOpenFile: onOpenFile,
                      onQuickOpen: onQuickOpen,
                      onClose: () => panels.setExplorer(false),
                      quickOpenShortcut: quickOpenShortcut,
                    ),
                  ),
                ),
              if (panels.explorer && panels.hasCenter)
                PanelDivider(
                  semanticLabel: l10n.panelResizeHandle,
                  // 오른쪽으로 끌면 탐색기가 넓어진다 (지금 보이는 폭에서 시작한다).
                  onDelta: (dx) => widths.setExplorer(explorer + dx),
                  onReset: widths.resetExplorer,
                ),
              if (panels.hasCenter)
                Expanded(
                  child: CenterArea(
                    panels: panels,
                    workspace: workspace,
                    terminals: terminals,
                    terminalSettings: terminalSettings,
                    editor: editor,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Widget _fit({
  required bool fill,
  required double width,
  required Widget child,
}) => fill ? Expanded(child: child) : SizedBox(width: width, child: child);

/// 가운데: 위에 파일 탭 줄(오른쪽 끝에 에디터↔터미널 전환), 아래에 에디터 또는 터미널 중 하나만 보인다.
class CenterArea extends StatelessWidget {
  const CenterArea({
    super.key,
    required this.panels,
    required this.workspace,
    required this.terminals,
    required this.terminalSettings,
    required this.editor,
  });

  final PanelLayout panels;
  final Workspace workspace;
  final TerminalSessionsController terminals;
  final TerminalSettings terminalSettings;
  final EditorController editor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shown = panels.center;
    return Column(
      children: [
        PanelHeader(
          children: [
            if (panels.canSwitchCenter)
              // 둘 다 켜져 있으면 전환 단추가 곧 제목이다 (보이는 쪽이 강조된다). 좁은 창(최소 폭)에서는 줄어든다.
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<CenterView>(
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
                  ),
                ),
              )
            else ...[
              // 파일 탭이 들어올 자리 (단계 15). 지금은 현재 보이는 패널 이름만 보인다.
              Icon(
                shown == CenterView.terminal
                    ? Icons.terminal_rounded
                    : Icons.edit_note_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shown == CenterView.terminal
                      ? l10n.panelTerminal
                      : l10n.panelEditor,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            // 지금 보이는 쪽(에디터 또는 터미널)을 그 자리에서 끈다. 둘 다 켜져 있으면 다른 쪽은 그대로 남는다.
            PanelCloseButton(
              onPressed: () => shown == CenterView.terminal
                  ? panels.setTerminal(false)
                  : panels.setEditor(false),
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
                  child: EditorHost(controller: editor),
                ),
              if (panels.terminalShown)
                _Switchable(
                  visible: shown == CenterView.terminal,
                  child: TerminalHost(
                    controller: terminals,
                    settings: terminalSettings,
                    workspace: workspace,
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
