// 아코디언 칸과 목록 카드의 바깥 껍질 (PLAN.md §1.12). 평소에는 평평하고, [active] 면 주색 워시와
// 은은한 글로우를 얻는다. 레이아웃 높이는 건드리지 않는다 — 패딩·테두리·그림자만 쓴다.

import 'package:flutter/material.dart';

import '../../theme/taskbench_style.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.active = false, this.padding = EdgeInsets.zero, this.radius});

  final Widget child;

  /// 펼친 칸. 워시와 글로우가 이 하나에만 붙는다.
  final bool active;
  final EdgeInsetsGeometry padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final style = context.style;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = BorderRadius.circular(radius ?? style.radius);
    final k = style.intensity;
    final wash = style.enabled && active;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: wash
              ? [
                  Color.alphaBlend(style.accent.withValues(alpha: 0.10 * k), style.cardTop),
                  Color.alphaBlend(style.accent.withValues(alpha: 0.03 * k), style.cardBottom),
                ]
              : [style.cardTop, style.cardBottom],
        ),
        border: Border.all(color: wash ? style.accent.withValues(alpha: 0.45) : style.border, width: style.enabled ? 1 : 2),
        boxShadow: [
          if (wash)
            BoxShadow(
              color: style.accent.withValues(alpha: (dark ? 0.16 : 0.12) * k),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(borderRadius: r, child: child),
    );
  }
}

/// 로그·명령 출력처럼 글자가 많은 영역 뒤에 까는 불투명한 안쪽 판 — 장식과 글자 배경을 분리한다.
class InsetPanel extends StatelessWidget {
  const InsetPanel({super.key, required this.child, this.padding = const EdgeInsets.all(8)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: context.style.inset, borderRadius: BorderRadius.circular(8)),
        child: Padding(padding: padding, child: child),
      );
}
