import 'package:flutter/material.dart';

import '../components/buttons/app_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static const _createRoomHeroTag = 'create-room-cta';
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4E8), Color(0xFFFFEFD8)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 20,
              left: 18,
              child: _BackgroundOrb(
                size: 130,
                color: Color(0x66FFBDBD),
              ),
            ),
            const Positioned(
              top: 170,
              right: 20,
              child: _BackgroundOrb(
                size: 120,
                color: Color(0x66EBD6FB),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FloatingIn(
                          controller: _controller,
                          intervalStart: 0.0,
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF7FA3), Color(0xFFFFA88A)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55FF8FB4),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: Color(0xFFFFF4E8),
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FloatingIn(
                          controller: _controller,
                          intervalStart: 0.12,
                          child: const Text(
                            'Where Should We Eat?',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4A2E3A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _FloatingIn(
                          controller: _controller,
                          intervalStart: 0.24,
                          child: const Text(
                            'Pick a winner together.\nFast, fun, and fair.',
                            style: TextStyle(
                              color: Color(0xFF8A6272),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _FloatingIn(
                          controller: _controller,
                          intervalStart: 0.36,
                          child: SizedBox(
                            width: double.infinity,
                            child: Hero(
                              tag: _createRoomHeroTag,
                              child: Material(
                                type: MaterialType.transparency,
                                child: AppButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/create'),
                                  icon: Icons.add_rounded,
                                  text: 'Create Room',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _FloatingIn(
                          controller: _controller,
                          intervalStart: 0.48,
                          child: SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              onPressed: () => Navigator.pushNamed(context, '/join'),
                              icon: Icons.login_rounded,
                              text: 'Join Room',
                              variant: AppButtonVariant.outlined,
                              backgroundColor: const Color(0xFFFFE8D2),
                              foregroundColor: const Color(0xFF5F3A47),
                              borderColor: const Color(0xFFF4C2B7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingIn extends StatelessWidget {
  const _FloatingIn({
    required this.controller,
    required this.intervalStart,
    required this.child,
  });

  final AnimationController controller;
  final double intervalStart;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, 1, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        return Transform.translate(
          offset: Offset(0, (1 - t) * 36),
          child: Opacity(
            opacity: t,
            child: child,
          ),
        );
      },
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
