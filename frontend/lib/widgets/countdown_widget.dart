import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class CountdownWidget extends StatefulWidget {
  const CountdownWidget({
    super.key,
    required this.endTime,
    required this.onDone,
  });

  final DateTime? endTime;
  final Future<void> Function() onDone;

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  int _secondsLeft = 0;
  int _initialSeconds = 60;
  int _popTick = 0;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final end = widget.endTime;
    if (end == null) return;
    final secs = (end.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil()
        .clamp(0, 999)
        .toInt();
    if (!mounted) return;
    setState(() {
      if (_secondsLeft != secs) _popTick++;
      _secondsLeft = secs;
      if (_secondsLeft > _initialSeconds) _initialSeconds = _secondsLeft;
    });
    if (secs == 0) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final critical = _secondsLeft <= 10;
    final progress = (_secondsLeft / _initialSeconds).clamp(0.0, 1.0);
    final pulseScale = _popTick.isEven ? 1.0 : 1.08;

    return Center(
      child: AnimatedScale(
        scale: pulseScale,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 12,
                left: 20,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0x66EBD6FB),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 20,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0x66FFBDBD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              CustomPaint(
                size: const Size.square(170),
                painter: _RingPainter(
                  progress: progress,
                  ringColor: critical
                      ? const Color(0xFFFF8A8A)
                      : const Color(0xFFA5D0CB),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 136,
                height: 136,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: critical
                      ? const Color(0xFFFFA4A4)
                      : const Color(0xFFBADFDB),
                  borderRadius: BorderRadius.circular(68),
                  border: Border.all(
                    color: critical
                        ? const Color(0xFFFF8A8A)
                        : const Color(0xFFA5D0CB),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (critical ? const Color(0xFFFFA4A4) : const Color(0xFFBADFDB))
                              .withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.35),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: Text(
                    '$_secondsLeft',
                    key: ValueKey(_secondsLeft),
                    style: const TextStyle(
                      color: Color(0xFF4A2E3A),
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.ringColor});

  final double progress;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 6;
    final base = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final active = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, base);
    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ringColor != ringColor;
  }
}
