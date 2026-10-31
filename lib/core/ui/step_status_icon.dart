// 단계 상태 아이콘 (대기·실행 중·완료·실패·취소). Flutty Run 탭에서 옮겼다.

import 'package:flutter/material.dart';

import '../../ui/style/status_pill.dart';
import '../run_session.dart';

class StepStatusIcon extends StatelessWidget {
  const StepStatusIcon(this.status, {super.key});

  final StepStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (status) {
      StepStatus.running => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      StepStatus.done => Icon(Icons.check_circle_rounded, size: 16, color: toneColor(context, Tone.success)),
      StepStatus.failed => Icon(Icons.error_rounded, size: 16, color: theme.colorScheme.error),
      StepStatus.cancelled => Icon(Icons.cancel_rounded, size: 16, color: theme.hintColor),
      _ => Icon(Icons.radio_button_unchecked_rounded, size: 16, color: theme.hintColor),
    };
  }
}
