import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final int _particleCount = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate particles
    final random = math.Random();
    for (var i = 0; i < _particleCount; i++) {
      _particles.add(
        _Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 3 + 1,
          speedX: (random.nextDouble() - 0.5) * 0.002,
          speedY: (random.nextDouble() - 0.5) * 0.002,
          opacity: random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particle positions
        for (var particle in _particles) {
          particle.x += particle.speedX;
          particle.y += particle.speedY;

          // Wrap around edges
          if (particle.x < 0) particle.x = 1;
          if (particle.x > 1) particle.x = 0;
          if (particle.y < 0) particle.y = 1;
          if (particle.y > 1) particle.y = 0;
        }

        return CustomPaint(
          painter: _BackgroundPainter(
            particles: _particles,
            animation: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class _BackgroundPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animation;

  _BackgroundPainter({required this.particles, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw gradient background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0D0D1A),
        const Color(0xFF1A1A2E),
        const Color(0xFF0D0D1A),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Draw animated grid lines
    _drawGrid(canvas, size);

    // Draw particles
    _drawParticles(canvas, size);

    // Draw connection lines between nearby particles
    _drawConnections(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    final offset = (animation * spacing) % spacing;

    // Vertical lines
    for (var x = offset; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (var y = offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = const Color(0xFF00D9FF).withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    const maxDistance = 0.15;
    final paint = Paint()..strokeWidth = 0.5;

    for (var i = 0; i < particles.length; i++) {
      for (var j = i + 1; j < particles.length; j++) {
        final dx = particles[i].x - particles[j].x;
        final dy = particles[i].y - particles[j].y;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < maxDistance) {
          final opacity = (1 - distance / maxDistance) * 0.2;
          paint.color = const Color(0xFF00D9FF).withOpacity(opacity);

          canvas.drawLine(
            Offset(particles[i].x * size.width, particles[i].y * size.height),
            Offset(particles[j].x * size.width, particles[j].y * size.height),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}
