// 앱 마크: 앱 아이콘과 같은 판 위의 글리프 (PLAN.md §1.12). 모서리는 Apple 아이콘 격자 비율.

import 'package:flutter/material.dart';

import '../../app_identity.dart';

class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2237),
        child: Image.asset(AppIdentity.iconAsset, width: size, height: size, filterQuality: FilterQuality.medium),
      );
}
