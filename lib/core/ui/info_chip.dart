import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11)),
  );
}
