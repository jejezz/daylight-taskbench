// 확장 패널 위쪽 머리줄 (탐색기 제목 · 파일 탭 줄). 도크 열의 디렉터리 바(44)와 같은 높이라 구분선이 이어진다.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

const double panelHeaderHeight = 44;

/// 패널 머리줄 오른쪽 끝의 닫기(x) 단추 — 패널을 그 자리에서 바로 끈다 (§1.13).
class PanelCloseButton extends StatelessWidget {
  const PanelCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).panelClose,
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      icon: const Icon(Icons.close_rounded),
      onPressed: onPressed,
    );
  }
}

/// 아래에 선이 있는 [panelHeaderHeight] 높이의 줄.
class PanelHeader extends StatelessWidget {
  const PanelHeader({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: panelHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(children: children),
    );
  }
}
