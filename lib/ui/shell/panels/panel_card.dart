// 확장 패널(탐색기·가운데)의 바깥 껍질: 도크 열의 Git & GitHub 칸과 같은 색 테마(주색 워시·테두리·글로우)의 둥근 카드 (PLAN.md §1.13). 패널 사이와 창 가장자리는
// [PanelWidths.pad]·[PanelWidths.handle] 만큼 띄운다. 도크 열 칸(`GlassCard`, 12)보다 조금 더 둥글다(사용자 결정, 14).

import 'package:flutter/material.dart';

import '../../style/glass_card.dart';

const double panelRadius = 14;

class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      GlassCard(radius: panelRadius, active: true, child: child);
}
