// 들여쓰기 쌍 표시: 들여쓴 줄마다 깊이별로 색이 다른 긴 세로선을 글 위에 그린다 (git 이력 그래프처럼).
// daylight-workbench 의 ui/indent_guides.dart 를 옮겼다. [Taskbench에서 달라진 곳] 깊이별 색은 ColorScheme·상태색에서 고른다.
//
// 줄 번호 옆 표시(indicator) 줄의 맨 끝에 폭 0으로 놓고, 줄 위치는 편집기가 알려 주는 보이는 줄들의 위치(접힌 구간
// 포함)를 그대로 쓴다. 선은 이 위젯 오른쪽, 곧 글이 시작하는 곳부터 그린다. 글자 폭은 고정폭 글꼴이라고 보고
// [charWidth]로 계산한다.

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../theme/taskbench_style.dart';
import 'indent_levels.dart';

class IndentGuides extends StatelessWidget {
  const IndentGuides({
    super.key,
    required this.editing,
    required this.indicator,
    required this.horizontal,
    required this.charWidth,
    required this.textInset,
  });

  final CodeLineEditingController editing;
  final CodeIndicatorValueNotifier indicator;

  /// 가로 스크롤 — 글이 옆으로 밀리면 선도 같이 밀린다.
  final ScrollController horizontal;

  /// 글자 하나의 폭.
  final double charWidth;

  /// 이 위젯의 왼쪽 가장자리에서 글의 첫 글자까지의 거리.
  final double textInset;

  /// 깊이별 색: 테마의 강조색들을 돌려 쓴다.
  static List<Color> palette(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = context.style;
    return [
      scheme.primary,
      scheme.secondary,
      style.success,
      style.warning,
      scheme.error,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(0, double.infinity),
      painter: _GuidePainter(
        editing: editing,
        indicator: indicator,
        horizontal: horizontal,
        charWidth: charWidth,
        textInset: textInset,
        colors: palette(context),
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter({
    required this.editing,
    required this.indicator,
    required this.horizontal,
    required this.charWidth,
    required this.textInset,
    required this.colors,
  }) : super(repaint: Listenable.merge([indicator, horizontal, editing]));

  final CodeLineEditingController editing;
  final CodeIndicatorValueNotifier indicator;
  final ScrollController horizontal;
  final double charWidth;
  final double textInset;
  final List<Color> colors;

  CodeLines? _unitFor;
  int _unit = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final value = indicator.value;
    if (value == null || value.paragraphs.isEmpty) return;
    final codeLines = editing.codeLines;
    if (!identical(_unitFor, codeLines)) {
      _unitFor = codeLines;
      _unit = detectIndentUnit(
        Iterable.generate(
          codeLines.length > 400 ? 400 : codeLines.length,
          (i) => codeLines[i].text,
        ),
      );
    }
    final scroll = horizontal.hasClients ? horizontal.offset : 0.0;
    final step = _unit * charWidth;
    final paint = Paint()..strokeWidth = 1.2;
    for (final p in value.paragraphs) {
      final level = indentLevelAt(
        codeLines.length,
        (i) => codeLines[i].text,
        p.index,
        _unit,
      );
      for (var k = 0; k < level; k++) {
        final x = textInset + k * step - scroll + 0.5;
        if (x < -1) continue; // 옆으로 밀려 글 영역 왼쪽으로 나간 선
        canvas.drawLine(
          Offset(x, p.top),
          Offset(x, p.top + p.height),
          paint..color = colors[k % colors.length].withValues(alpha: 0.38),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.charWidth != charWidth ||
      old.textInset != textInset ||
      old.editing != editing ||
      old.indicator != indicator ||
      old.colors != colors;
}
