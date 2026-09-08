import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavingFlagWidget extends StatefulWidget {
  final Widget child;
  const WavingFlagWidget({required this.child, super.key});

  @override
  State<WavingFlagWidget> createState() => _WavingFlagWidgetState();
}

class _WavingFlagWidgetState extends State<WavingFlagWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Native Flutter GPU-accelerated animated tricolor wave (zero WebView / zero lag)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _NativeFlagWavePainter(progress: _controller.value),
              );
            },
          ),
        ),

        // Gradient overlay — keeps content readable
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFF6B1A).withValues(alpha: 0.15), // Saffron tint top
                  const Color(0xFF0C0A08).withValues(alpha: 0.7),   // Dark middle
                  const Color(0xFF138808).withValues(alpha: 0.15), // Emerald tint bottom
                ],
              ),
            ),
          ),
        ),
        // Additional dark overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0C0A08).withValues(alpha: 0.2),
                  const Color(0xFF0C0A08).withValues(alpha: 0.6),
                  const Color(0xFF0C0A08).withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),

        // Foreground content (top)
        widget.child,
      ],
    );
  }
}

class _NativeFlagWavePainter extends CustomPainter {
  final double progress;

  _NativeFlagWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base dark background
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0C0A08));

    final width = size.width;
    final height = size.height;
    final t = progress * 2 * math.pi;

    // Saffron wave (top section)
    final saffronPath = Path();
    saffronPath.moveTo(0, 0);
    saffronPath.lineTo(width, 0);
    saffronPath.lineTo(
      width,
      height * 0.28 + math.sin(t + 1.2) * 20 + math.cos(t * 1.5) * 12,
    );
    for (double x = width; x >= 0; x -= 10) {
      final normX = x / width;
      final wave1 = math.sin(normX * 2 * math.pi - t) * 22;
      final wave2 = math.cos(normX * 3 * math.pi + t * 0.8) * 14;
      final y = height * 0.28 + wave1 + wave2;
      saffronPath.lineTo(x, y);
    }
    saffronPath.close();

    final saffronPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF6B1A).withValues(alpha: 0.35),
          const Color(0xFFFF8C38).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawPath(saffronPath, saffronPaint);

    // Emerald wave (bottom section)
    final emeraldPath = Path();
    emeraldPath.moveTo(0, height);
    emeraldPath.lineTo(width, height);
    emeraldPath.lineTo(
      width,
      height * 0.72 + math.cos(t) * 18,
    );
    for (double x = width; x >= 0; x -= 10) {
      final normX = x / width;
      final wave1 = math.cos(normX * 2 * math.pi + t) * 20;
      final wave2 = math.sin(normX * 3 * math.pi - t * 0.9) * 12;
      final y = height * 0.72 + wave1 + wave2;
      emeraldPath.lineTo(x, y);
    }
    emeraldPath.close();

    final emeraldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF138808).withValues(alpha: 0.35),
          const Color(0xFF28A745).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawPath(emeraldPath, emeraldPaint);
  }

  @override
  bool shouldRepaint(covariant _NativeFlagWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
