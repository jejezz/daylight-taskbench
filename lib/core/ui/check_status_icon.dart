// 점검 결과 아이콘 (통과·주의·실패·정보). Gradle Doctor 탭이 쓴다.

import 'package:flutter/material.dart';

import '../../ui/style/status_pill.dart';
import '../check_status.dart';

class CheckStatusIcon extends StatelessWidget {
  const CheckStatusIcon(this.status, {super.key});

  final CheckStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (status) {
      CheckStatus.ok => Icon(Icons.check_circle_rounded, size: 16, color: toneColor(context, Tone.success)),
      CheckStatus.warn => Icon(Icons.warning_amber_rounded, size: 16, color: toneColor(context, Tone.warning)),
      CheckStatus.fail => Icon(Icons.error_rounded, size: 16, color: theme.colorScheme.error),
      CheckStatus.info => Icon(Icons.info_outline_rounded, size: 16, color: theme.hintColor),
    };
  }
}
