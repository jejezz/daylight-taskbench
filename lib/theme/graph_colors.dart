// 커밋 그래프의 줄(lane) 색 — 앱 고유 데이터 색이라 색 구성과 무관하게 고정이고, 한곳에 둔다
// (theming.md §2: 앱 고유 색은 lib/theme 에 라이트·다크 한 쌍으로).

import 'package:flutter/material.dart';

abstract final class GraphColors {
  /// 앞 네 줄은 의미 색(주색·성공·경고·위험)이고, 뒤는 구분용 고정 색이다.
  static const extraDark = [Color(0xFFB07CFF), Color(0xFF3CC8C8)];
  static const extraLight = [Color(0xFF7A3FE0), Color(0xFF117F85)];

  static List<Color> extra(Brightness b) => b == Brightness.dark ? extraDark : extraLight;
}
