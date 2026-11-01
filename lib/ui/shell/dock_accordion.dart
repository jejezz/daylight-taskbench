// 아코디언(스택 카드): 제목은 항상 보이고, 제목을 누르면 그 칸의 내용이 남는 화면 전체로 펼쳐진다.
// 동시에 하나만 펼치고, 제목 순서는 고정이다 (PLAN.md §1.1). 접힌 칸도 위젯은 살아 있다 — 빌드 중에
// 접어도 출력이 이어진다 (§1.5). 장식은 [GlassCard]가 맡고, 이 위젯은 레이아웃만 한다.

import 'package:flutter/material.dart';

import '../../docks/dock_module.dart';
import '../../l10n/app_localizations.dart';
import '../../workspace/workspace.dart';
import '../style/glass_card.dart';
import '../style/pulse_dot.dart';
import '../../theme/taskbench_style.dart';

const double dockTitleHeight = 40;
const double _gap = 8;

/// 펼친 칸의 내용이 이보다 낮아지지 않는다. 창이 너무 낮으면 칸 안이 넘치는 대신 열 전체가 스크롤된다.
const double _minBodyHeight = 280;

class DockAccordion extends StatelessWidget {
  const DockAccordion({
    super.key,
    required this.docks,
    required this.workspace,
    required this.expandedId,
    required this.onSelect,
  });

  final List<DockModule> docks;
  final Workspace workspace;
  final String? expandedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 260);
    return LayoutBuilder(builder: (context, c) {
      // 카드 테두리(양쪽 1px, 고대비 2px)도 높이를 쓴다.
      final border = (context.style.enabled ? 2.0 : 4.0);
      final chrome = docks.length * (dockTitleHeight + border) + (docks.length + 1) * _gap;
      final bodyHeight = (c.maxHeight - chrome).clamp(0.0, double.infinity);
      // 평소에는 높이가 정확히 맞아 스크롤이 생기지 않는다. 창을 아주 낮게 줄였을 때만 스크롤된다 (넘침 오류 대신).
      return SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(_gap, _gap, _gap, 0),
        child: Column(
          children: [
            for (final dock in docks) ...[
              GlassCard(
                active: dock.id == expandedId,
                child: Column(children: [
                  _DockTitle(dock: dock, workspace: workspace, expanded: dock.id == expandedId, onTap: () => onSelect(dock.id)),
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOut,
                    height: dock.id == expandedId ? (bodyHeight < _minBodyHeight ? _minBodyHeight : bodyHeight) : 0,
                    child: TickerMode(
                      enabled: dock.id == expandedId,
                      // 접힌 칸은 그리지 않지만 State 는 유지한다.
                      child: Offstage(offstage: dock.id != expandedId, child: dock.body(context, workspace)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: _gap),
            ],
          ],
        ),
      ),
      );
    });
  }
}

class _DockTitle extends StatelessWidget {
  const _DockTitle({required this.dock, required this.workspace, required this.expanded, required this.onTap});

  final DockModule dock;
  final Workspace workspace;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = context.style;
    final mood = dock.mood(workspace);
    final busy = dock.busy(workspace);
    return Semantics(
      button: true,
      expanded: expanded,
      label: dock.title(l10n),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: dockTitleHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Icon(expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Icon(dock.icon, size: 18, color: expanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(dock.title(l10n), style: theme.textTheme.titleSmall),
              const SizedBox(width: 8),
              // 좁은 창에서 요약이 길면 넘치는 대신 줄어든다.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: dock.summary(context, workspace)),
                ),
              ),
              if (mood != TaskbenchMood.idle || busy) ...[
                const SizedBox(width: 8),
                PulseDot(color: style.moodColor(busy && mood == TaskbenchMood.idle ? TaskbenchMood.working : mood), pulsing: busy),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
