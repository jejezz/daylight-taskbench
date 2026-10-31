// 단추 라벨 + 단축키 힌트. 좁은 창(최소 380)에서는 힌트를 빼서 라벨이 두 줄로 꺾이거나 "…"로 잘리지 않게 한다.

import 'package:flutter/material.dart';

/// 이 폭보다 좁은 창에서는 단축키 힌트를 보이지 않는다 (단축키 자체는 그대로 동작한다).
const double shortcutHintMinWindowWidth = 420;

class LabelWithShortcut extends StatelessWidget {
  const LabelWithShortcut(this.label, this.shortcut, {super.key});

  final String label;
  final String shortcut;

  @override
  Widget build(BuildContext context) {
    final showHint = MediaQuery.sizeOf(context).width >= shortcutHintMinWindowWidth;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(showHint ? '$label  $shortcut' : label, maxLines: 1, softWrap: false),
    );
  }
}
