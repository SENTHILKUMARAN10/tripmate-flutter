import 'dart:math' as math;

import 'package:flutter/material.dart';

class TripMateColors {
  static const navy950 = Color(0xFF021024);
  static const navy800 = Color(0xFF052659);
  static const blue600 = Color(0xFF5483B3);
  static const blue400 = Color(0xFF7DA0CA);
  static const ice = Color(0xFFC1E8FF);
  static const canvas = Color(0xFFF4F8FC);
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFF07152C);
  static const muted = Color(0xFF6B7890);
}

class TripMateGradient {
  static const hero = LinearGradient(
    colors: [TripMateColors.navy950, TripMateColors.navy800, TripMateColors.blue600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const soft = LinearGradient(
    colors: [Color(0xFFF9FCFF), Color(0xFFEAF5FF), Color(0xFFD7EEFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class TripMateSurface extends StatelessWidget {
  const TripMateSurface({super.key, required this.child, this.padding, this.margin, this.onTap, this.gradient, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .65)),
        boxShadow: const [
          BoxShadow(color: Color(0x14052659), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return _Pressable(onTap: onTap!, child: content);
  }
}

class TripMatePageHeader extends StatelessWidget {
  const TripMatePageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(), style: const TextStyle(color: TripMateColors.blue600, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: TripMateColors.text, fontSize: 34, height: 1.02, fontWeight: FontWeight.w900, letterSpacing: -1.3)),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(color: TripMateColors.muted, fontSize: 15, height: 1.45, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class TripMateIconBubble extends StatelessWidget {
  const TripMateIconBubble(this.icon, {super.key, this.size = 50, this.dark = false});
  final IconData icon;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: dark ? TripMateGradient.hero : const LinearGradient(colors: [Color(0xFFEAF6FF), TripMateColors.ice]),
          borderRadius: BorderRadius.circular(size * .34),
        ),
        child: Icon(icon, color: dark ? Colors.white : TripMateColors.navy800, size: size * .45),
      );
}

class TripMateWaveBackground extends StatefulWidget {
  const TripMateWaveBackground({super.key, required this.child});
  final Widget child;

  @override
  State<TripMateWaveBackground> createState() => _TripMateWaveBackgroundState();
}

class _TripMateWaveBackgroundState extends State<TripMateWaveBackground> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, child) => Container(
          decoration: const BoxDecoration(gradient: TripMateGradient.soft),
          child: Stack(
            children: [
              Positioned(top: -70 + 22 * controller.value, right: -60, child: _orb(210, TripMateColors.ice.withValues(alpha: .55))),
              Positioned(top: 180 - 28 * controller.value, left: -90, child: _orb(200, TripMateColors.blue400.withValues(alpha: .16))),
              Positioned(bottom: -80 + 18 * controller.value, right: -40, child: _orb(220, TripMateColors.navy800.withValues(alpha: .08))),
              child!,
            ],
          ),
        ),
        child: widget.child,
      );

  Widget _orb(double size, Color color) => Transform.rotate(
        angle: math.pi / 10,
        child: Container(width: size, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * .4))),
      );
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => down = true),
        onTapCancel: () => setState(() => down = false),
        onTapUp: (_) => setState(() => down = false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: down ? .97 : 1, duration: const Duration(milliseconds: 120), child: widget.child),
      );
}
