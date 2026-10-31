// 창 전체 배경 (PLAN.md §1.12). 대각선 그라디언트에 주색을 아주 약하게 번지게 하고, 상태색 배경이 켜져
// 있으면 지금 상태(작업 중·실패·성공)의 색으로 천천히 바뀐다.

import 'package:flutter/material.dart';

import '../../theme/taskbench_style.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child, this.mood = TaskbenchMood.idle, this.moodEnabled = true});

  final Widget child;
  final TaskbenchMood mood;

  /// 설정의 "상태색 배경". 꺼져 있으면 늘 주색.
  final bool moodEnabled;

  @override
  Widget build(BuildContext context) {
    final style = context.style;
    final base = Theme.of(context).colorScheme.surface;
    if (!style.enabled) return ColoredBox(color: base, child: child);
    final tint = style.moodColor(moodEnabled ? mood : TaskbenchMood.idle);
    final k = style.intensity;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.alphaBlend(tint.withValues(alpha: 0.08 * k), base), base],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: child,
    );
  }
}
