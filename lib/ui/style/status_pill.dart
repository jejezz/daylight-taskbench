// 작은 상태 표시 (ui-ux.md의 StatusPill). 색은 의미 색(성공·경고·위험)과 선택한 색 구성의 주색에서만 온다.

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum Tone { primary, success, warning, danger, neutral }

Color toneColor(BuildContext context, Tone tone) {
  final light = Theme.of(context).brightness == Brightness.light;
  final scheme = Theme.of(context).colorScheme;
  return switch (tone) {
    Tone.primary => scheme.primary,
    Tone.success => light ? AppColors.successTextLight : AppColors.success,
    Tone.warning => light ? AppColors.warningTextLight : AppColors.warning,
    Tone.danger => scheme.error,
    Tone.neutral => scheme.onSurfaceVariant,
  };
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = Tone.neutral, this.icon});

  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
