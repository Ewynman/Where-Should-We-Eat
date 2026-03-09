import 'package:flutter/material.dart';

/// Full-screen overlay that expands from center with pastel background and phase label.
class PhaseTransitionOverlay extends StatefulWidget {
  const PhaseTransitionOverlay({
    super.key,
    required this.label,
    required this.onDismiss,
    this.color,
    this.duration = const Duration(milliseconds: 600),
    this.holdDuration = const Duration(milliseconds: 1400),
  });

  final String label;
  final VoidCallback onDismiss;
  final Color? color;
  final Duration duration;
  final Duration holdDuration;

  @override
  State<PhaseTransitionOverlay> createState() => _PhaseTransitionOverlayState();
}

class _PhaseTransitionOverlayState extends State<PhaseTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
    Future.delayed(widget.duration + widget.holdDuration, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFFEBD6FB);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        final scale = 0.3 + 0.7 * t;
        final opacity = t;
        return Material(
          color: Colors.transparent,
          child: Container(
            color: color.withValues(alpha: opacity * 0.98),
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A2E3A),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
