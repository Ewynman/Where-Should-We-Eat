import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shown while backend fetches restaurants from Google Places (cooking-themed animation).
/// Polls [onRefresh] every 2s until room status changes.
class FetchingRestaurantsSection extends StatefulWidget {
  const FetchingRestaurantsSection({
    super.key,
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  State<FetchingRestaurantsSection> createState() =>
      _FetchingRestaurantsSectionState();
}

class _FetchingRestaurantsSectionState extends State<FetchingRestaurantsSection>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _steamController;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => widget.onRefresh(),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    _steamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _steamController]),
              builder: (context, child) {
                final scale = 0.92 + (_pulseController.value * 0.1);
                final steamT = _steamController.value;
                return SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(160, 160),
                        painter: _SteamPainter(progress: steamT),
                      ),
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFFFBDBD),
                                const Color(0xFFFFA88A),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFA88A)
                                    .withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            size: 48,
                            color: Color(0xFF4A2E3A),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Finding spots near you',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A2E3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Using your top cuisines',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6F4A59),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SteamPainter extends CustomPainter {
  _SteamPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * math.pi + progress * 2 * math.pi;
      final r = 55.0 + (i * 4.0) + math.sin(progress * 8) * 4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy - r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 6 + (i * 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
