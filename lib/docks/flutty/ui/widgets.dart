import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

// [Taskbench에서 달라진 곳] InfoChip 은 core/ui/info_chip.dart 로 옮겼다 (Gradle 칸도 쓴다). 다시 내보낸다.
export '../../../core/ui/info_chip.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleSmall),
        ),
        ?trailing,
      ],
    ),
  );
}

/// 번호 붙은 여러 줄 안내를 접었다 펴는 칸.
class StepsBox extends StatelessWidget {
  const StepsBox(this.steps, {super.key});

  final String steps;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: SelectableText(
      steps,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
    ),
  );
}
