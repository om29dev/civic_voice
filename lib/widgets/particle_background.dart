import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A floating particle in the background animation.
class _Particle {
  double x, y;
  double vx, vy;
  double radius;
  double opacity;
  double pulsePhase;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
    required this.pulsePhase,
    required this.color,
  });
}

/// Animated particle background using a CustomPainter.
/// 60 slowly drifting particles in cyan and electric blue tones.
/// Wrapped in RepaintBoundary for isolation from parent widget tree.
class ParticleBackground extends StatefulWidget {
  final Widget? child;

  const ParticleBackground({super.key, this.child});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _rng = Random();

  static const int _particleCount = 60;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    // Particles are spawned lazily once we have layout size
    _particles = [];
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    final colors = [
      AppColors.accent,         // Neon Cyan
      AppColors.primary,        // Electric Blue
      AppColors.accentDim,      // Dimmer Cyan
      AppColors.primaryLight,   // Lighter Blue
      const Color(0xFF00B4D8),  // Info Blue
    ];

    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble() * size.width,
        y: _rng.nextDouble() * size.height,
        vx: (_rng.nextDouble() - 0.5) * 0.4,
        vy: (_rng.nextDouble() - 0.5) * 0.4,
        radius: _rng.nextDouble() * 2.5 + 0.5,
        opacity: _rng.nextDouble() * 0.4 + 0.05,
        pulsePhase: _rng.nextDouble() * 2 * pi,
        color: colors[_rng.nextInt(colors.length)],
      ));
    }
  }

  void _updateParticles(Size size, double dt) {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.pulsePhase += 0.02;

      // Wrap around screen edges
      if (p.x < -5) p.x = size.width + 5;
      if (p.x > size.width + 5) p.x = -5;
      if (p.y < -5) p.y = size.height + 5;
      if (p.y > size.height + 5) p.y = -5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          _initParticles(size);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              _updateParticles(size, 0.016);
              return Stack(
                children: [
                  // Particle layer
                  CustomPaint(
                    size: size,
                    painter: _ParticlePainter(_particles),
                  ),
                  // Child (app content on top)
                  if (widget.child != null)
                    SizedBox.expand(child: widget.child),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final pulsedOpacity =
          (p.opacity + 0.08 * sin(p.pulsePhase)).clamp(0.02, 0.55);
      final pulsedRadius = p.radius + 0.4 * sin(p.pulsePhase + pi / 4);

      // Glow halo
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: pulsedOpacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(p.x, p.y), pulsedRadius * 2.5, glowPaint);

      // Core dot
      final corePaint = Paint()
        ..color = p.color.withValues(alpha: pulsedOpacity);
      canvas.drawCircle(Offset(p.x, p.y), pulsedRadius, corePaint);
    }

    // Subtle connection lines between nearby particles
    final linePaint = Paint()
      ..strokeWidth = 0.3;
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].x - particles[j].x;
        final dy = particles[i].y - particles[j].y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 80) {
          final alpha = (1 - dist / 80) * 0.08;
          linePaint.color = AppColors.accent.withValues(alpha: alpha);
          canvas.drawLine(
            Offset(particles[i].x, particles[i].y),
            Offset(particles[j].x, particles[j].y),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
