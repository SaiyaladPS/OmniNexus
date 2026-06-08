import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final AppThemeMode mode;
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.mode,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = resolveTheme(widget.mode);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  colors.gradientColors[0],
                  colors.gradientColors[1],
                  _controller.value,
                )!,
                Color.lerp(
                  colors.gradientColors[1],
                  colors.gradientColors[2],
                  _controller.value,
                )!,
                Color.lerp(
                  colors.gradientColors[2],
                  colors.gradientColors[0],
                  _controller.value,
                )!,
              ],
            ),
          ),
          child: Stack(
            children: [
              child!,
              if (widget.mode == AppThemeMode.rainy)
                ..._buildRaindrops(),
              if (widget.mode == AppThemeMode.night)
                ..._buildStars(),
              if (widget.mode == AppThemeMode.sunny)
                ..._buildSunbeams(),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  List<Widget> _buildRaindrops() {
    return List.generate(20, (i) {
      final x = (_random.nextDouble() * 1.2 - 0.1);
      final delay = _random.nextDouble();
      final speed = 0.5 + _random.nextDouble() * 1.0;
      return Positioned(
        left: MediaQuery.of(context).size.width * x,
        top: ((_controller.value * speed + delay) % 1.2 - 0.1) *
            MediaQuery.of(context).size.height,
        child: Opacity(
          opacity: 0.3 + _random.nextDouble() * 0.3,
          child: Container(
            width: 1.5,
            height: 12 + _random.nextDouble() * 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildStars() {
    return List.generate(30, (i) {
      final x = (_random.nextDouble() * 1.1 - 0.05);
      final y = (_random.nextDouble() * 0.8);
      final size = 1.0 + _random.nextDouble() * 2.0;
      final twinkleDelay = _random.nextDouble() * 2 * pi;
      final twinkle = (sin(_controller.value * 4 + twinkleDelay) + 1) / 2;
      return Positioned(
        left: MediaQuery.of(context).size.width * x,
        top: MediaQuery.of(context).size.height * y,
        child: Opacity(
          opacity: 0.3 + twinkle * 0.7,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3 + twinkle * 0.5),
                  blurRadius: size,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildSunbeams() {
    return List.generate(8, (i) {
      final angle = (i / 8) * 2 * pi + _controller.value * 0.3;
      final radius = 100.0 + _controller.value * 30;
      final x = 0.5 + cos(angle) * 0.4;
      final y = 0.3 + sin(angle) * 0.3;
      return Positioned(
        left: MediaQuery.of(context).size.width * x,
        top: MediaQuery.of(context).size.height * y,
        child: Transform.translate(
          offset: Offset(-radius / 2, -radius / 2),
          child: Container(
            width: radius,
            height: radius,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.08),
                  Colors.amber.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
