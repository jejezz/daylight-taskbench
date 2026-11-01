// 패널 사이의 구분선 겸 크기 조절 손잡이 (PLAN.md §1.13). 위로 보이는 선은 1px 이지만 끄는 자리는
// [PanelWidths.handle] 폭이다. 끌면 [onDelta]에 가로로 움직인 만큼(오른쪽이 +)을 넘기고, 두 번 누르면 [onReset]을 부른다.

import 'package:flutter/material.dart';

import 'panel_widths.dart';

class PanelDivider extends StatefulWidget {
  const PanelDivider({
    super.key,
    required this.onDelta,
    required this.onReset,
    this.semanticLabel,
  });

  final ValueChanged<double> onDelta;
  final VoidCallback onReset;
  final String? semanticLabel;

  @override
  State<PanelDivider> createState() => _PanelDividerState();
}

class _PanelDividerState extends State<PanelDivider> {
  bool _hover = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _hover || _dragging;
    return Semantics(
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => setState(() => _dragging = true),
          onHorizontalDragUpdate: (d) => widget.onDelta(d.delta.dx),
          onHorizontalDragEnd: (_) => setState(() => _dragging = false),
          onHorizontalDragCancel: () => setState(() => _dragging = false),
          onDoubleTap: widget.onReset,
          child: SizedBox(
            width: PanelWidths.handle,
            child: Center(
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 120),
                // 카드 사이의 틈이 곧 손잡이다. 평소에는 보이지 않고, 올리거나 끄는 동안만 선이 나타난다.
                width: 2,
                decoration: BoxDecoration(
                  color: active ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
