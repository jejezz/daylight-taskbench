// 상태 점. 일이 진행 중([pulsing])이면 1.4초 주기로 깜빡이고, 접히거나 "동작 줄이기"면 멈춘다.

import 'package:flutter/material.dart';

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.pulsing = false, this.size = 8});

  final Color color;
  final bool pulsing;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  bool get _shouldRun => widget.pulsing && !MediaQuery.disableAnimationsOf(context) && TickerMode.valuesOf(context).enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PulseDot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (_shouldRun) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      );
}
