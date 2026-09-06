import 'package:flutter/material.dart';

import '../core/design.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController intro;
  late final AnimationController pulse;

  @override
  void initState() {
    super.initState();
    intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1450))..forward();
    pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))..repeat(reverse: true);
    Future<void>.delayed(const Duration(milliseconds: 2050), widget.onFinished);
  }

  @override
  void dispose() {
    intro.dispose();
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: intro, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: TripMateColors.navy950,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TripMateColors.navy950, TripMateColors.navy800, TripMateColors.blue700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(top: -90, right: -80, child: _orb(260, TripMateColors.blue400.withValues(alpha: .18))),
          Positioned(bottom: -110, left: -95, child: _orb(280, TripMateColors.ice.withValues(alpha: .10))),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: curve,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .72, end: 1).animate(CurvedAnimation(parent: intro, curve: Curves.easeOutBack)),
                      child: Container(
                        width: 112,
                        height: 112,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 34, offset: Offset(0, 18))],
                        ),
                        child: const TripMateMark(size: 62),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, .22), end: Offset.zero).animate(curve),
                    child: FadeTransition(
                      opacity: curve,
                      child: const Text(
                        'TripMate',
                        style: TextStyle(color: Colors.white, fontSize: 43, fontWeight: FontWeight.w900, letterSpacing: -1.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: CurvedAnimation(parent: intro, curve: const Interval(.35, 1)),
                    child: const Text(
                      'YOUR TRAVEL OS',
                      style: TextStyle(color: TripMateColors.ice, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.2),
                    ),
                  ),
                  const SizedBox(height: 38),
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) => Container(
                      width: 62 + 20 * pulse.value,
                      height: 5,
                      decoration: BoxDecoration(
                        color: TripMateColors.ice.withValues(alpha: .42 + .45 * pulse.value),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * .42)),
      );
}
