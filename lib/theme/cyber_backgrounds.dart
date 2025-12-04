import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'cyberfly_theme.dart';

/// Animated matrix rain background
class MatrixRainBackground extends StatefulWidget {
  final int columns;
  final double speed;
  final double opacity;

  const MatrixRainBackground({
    super.key,
    this.columns = 20,
    this.speed = 1.0,
    this.opacity = 0.15,
  });

  @override
  State<MatrixRainBackground> createState() => _MatrixRainBackgroundState();
}

class _MatrixRainBackgroundState extends State<MatrixRainBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_MatrixColumn> _columns;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..addListener(_updateColumns);
    _controller.repeat();
    _columns = List.generate(
      widget.columns,
      (i) => _MatrixColumn(_random),
    );
  }

  void _updateColumns() {
    setState(() {
      for (var column in _columns) {
        column.update(widget.speed);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _MatrixPainter(
          columns: _columns,
          opacity: widget.opacity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _MatrixColumn {
  final math.Random random;
  double y = 0;
  double speed = 0;
  List<String> chars = [];
  int length = 0;

  static const String _chars =
      'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF';

  _MatrixColumn(this.random) {
    _reset();
  }

  void _reset() {
    y = -random.nextDouble() * 500;
    speed = 2 + random.nextDouble() * 4;
    length = 5 + random.nextInt(15);
    chars = List.generate(
      length,
      (_) => _chars[random.nextInt(_chars.length)],
    );
  }

  void update(double speedMultiplier) {
    y += speed * speedMultiplier;
    if (random.nextDouble() < 0.1) {
      final idx = random.nextInt(chars.length);
      chars[idx] = _chars[random.nextInt(_chars.length)];
    }
  }
}

class _MatrixPainter extends CustomPainter {
  final List<_MatrixColumn> columns;
  final double opacity;

  _MatrixPainter({required this.columns, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final columnWidth = size.width / columns.length;
    final charHeight = 14.0;

    for (int i = 0; i < columns.length; i++) {
      final column = columns[i];
      final x = i * columnWidth + columnWidth / 2;

      for (int j = 0; j < column.chars.length; j++) {
        final charY = column.y - (j * charHeight);
        if (charY < -charHeight || charY > size.height + charHeight) continue;

        final fadeProgress = j / column.chars.length;
        final alpha = (1 - fadeProgress) * opacity;

        if (alpha <= 0) continue;

        final textPainter = TextPainter(
          text: TextSpan(
            text: column.chars[j],
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: j == 0
                  ? Colors.white.withOpacity(alpha)
                  : CyberColors.neonGreen.withOpacity(alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, charY),
        );
      }

      if (column.y > size.height + column.length * charHeight) {
        column._reset();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Animated hex grid background
class HexGridBackground extends StatefulWidget {
  final double hexSize;
  final double opacity;
  final Color color;

  const HexGridBackground({
    super.key,
    this.hexSize = 40,
    this.opacity = 0.1,
    this.color = CyberColors.neonCyan,
  });

  @override
  State<HexGridBackground> createState() => _HexGridBackgroundState();
}

class _HexGridBackgroundState extends State<HexGridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _HexGridPainter(
              hexSize: widget.hexSize,
              opacity: widget.opacity,
              color: widget.color,
              animationValue: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _HexGridPainter extends CustomPainter {
  final double hexSize;
  final double opacity;
  final Color color;
  final double animationValue;

  _HexGridPainter({
    required this.hexSize,
    required this.opacity,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final horizontalSpacing = hexSize * 1.5;
    final verticalSpacing = hexSize * math.sqrt(3);

    int row = 0;
    for (double y = -hexSize; y < size.height + hexSize; y += verticalSpacing / 2) {
      final offset = row.isOdd ? horizontalSpacing / 2 : 0.0;
      for (double x = -hexSize + offset; x < size.width + hexSize; x += horizontalSpacing) {
        _drawHexagon(canvas, Offset(x, y), hexSize * 0.9, paint);
      }
      row++;
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Animated data stream particles
class DataStreamBackground extends StatefulWidget {
  final int particleCount;
  final double speed;
  final Color color;

  const DataStreamBackground({
    super.key,
    this.particleCount = 50,
    this.speed = 1.0,
    this.color = CyberColors.neonCyan,
  });

  @override
  State<DataStreamBackground> createState() => _DataStreamBackgroundState();
}

class _DataStreamBackgroundState extends State<DataStreamBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_DataParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_updateParticles);
    _controller.repeat();
    _particles = List.generate(
      widget.particleCount,
      (i) => _DataParticle(_random),
    );
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.update(widget.speed);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DataStreamPainter(
          particles: _particles,
          color: widget.color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DataParticle {
  final math.Random random;
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double size = 0;
  double opacity = 0;

  _DataParticle(this.random) {
    _reset(random.nextDouble(), random.nextDouble());
  }

  void _reset(double startX, double startY) {
    x = startX;
    y = startY;
    final angle = random.nextDouble() * math.pi * 2;
    final speed = 0.001 + random.nextDouble() * 0.002;
    vx = math.cos(angle) * speed;
    vy = math.sin(angle) * speed;
    size = 1 + random.nextDouble() * 2;
    opacity = 0.1 + random.nextDouble() * 0.3;
  }

  void update(double speedMultiplier) {
    x += vx * speedMultiplier;
    y += vy * speedMultiplier;

    if (x < -0.1 || x > 1.1 || y < -0.1 || y > 1.1) {
      _reset(random.nextDouble(), random.nextDouble());
    }
  }
}

class _DataStreamPainter extends CustomPainter {
  final List<_DataParticle> particles;
  final Color color;

  _DataStreamPainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Network topology node visualizer
class NetworkTopologyVisualizer extends StatefulWidget {
  final List<TopologyNode> nodes;
  final List<TopologyConnection> connections;
  final double nodeSize;
  final bool animate;

  const NetworkTopologyVisualizer({
    super.key,
    required this.nodes,
    required this.connections,
    this.nodeSize = 12,
    this.animate = true,
  });

  @override
  State<NetworkTopologyVisualizer> createState() =>
      _NetworkTopologyVisualizerState();
}

class _NetworkTopologyVisualizerState extends State<NetworkTopologyVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
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
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _TopologyPainter(
            nodes: widget.nodes,
            connections: widget.connections,
            nodeSize: widget.nodeSize,
            pulseValue: _pulseAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class TopologyNode {
  final String id;
  final Offset position; // 0-1 normalized
  final bool isLocal;
  final bool isConnected;
  final int? latencyMs;

  TopologyNode({
    required this.id,
    required this.position,
    this.isLocal = false,
    this.isConnected = true,
    this.latencyMs,
  });
}

class TopologyConnection {
  final String fromId;
  final String toId;
  final bool isActive;
  final int? latencyMs;

  TopologyConnection({
    required this.fromId,
    required this.toId,
    this.isActive = true,
    this.latencyMs,
  });
}

class _TopologyPainter extends CustomPainter {
  final List<TopologyNode> nodes;
  final List<TopologyConnection> connections;
  final double nodeSize;
  final double pulseValue;

  _TopologyPainter({
    required this.nodes,
    required this.connections,
    required this.nodeSize,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (var n in nodes) n.id: n};

    // Draw connections
    for (var conn in connections) {
      final from = nodeMap[conn.fromId];
      final to = nodeMap[conn.toId];
      if (from == null || to == null) continue;

      final fromOffset = Offset(
        from.position.dx * size.width,
        from.position.dy * size.height,
      );
      final toOffset = Offset(
        to.position.dx * size.width,
        to.position.dy * size.height,
      );

      final color = conn.isActive
          ? CyberColors.neonCyan
          : CyberColors.textDim;

      final paint = Paint()
        ..color = color.withOpacity(conn.isActive ? 0.5 : 0.2)
        ..strokeWidth = conn.isActive ? 2 : 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(fromOffset, toOffset, paint);

      // Draw glow for active connections
      if (conn.isActive) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.2 * pulseValue)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawLine(fromOffset, toOffset, glowPaint);
      }
    }

    // Draw nodes
    for (var node in nodes) {
      final offset = Offset(
        node.position.dx * size.width,
        node.position.dy * size.height,
      );

      final color = node.isLocal
          ? CyberColors.neonMagenta
          : (node.isConnected ? CyberColors.neonGreen : CyberColors.textDim);

      // Glow
      if (node.isConnected) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.4 * pulseValue)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(offset, nodeSize * 1.5, glowPaint);
      }

      // Node
      final nodePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, nodeSize * (node.isLocal ? 1.2 : 1.0), nodePaint);

      // Border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(offset, nodeSize * (node.isLocal ? 1.2 : 1.0), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Cyberpunk-style app bar with gradient
class CyberAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showGradient;

  const CyberAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showGradient = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: showGradient
            ? LinearGradient(
                colors: [
                  CyberColors.backgroundDark,
                  CyberColors.backgroundDark.withOpacity(0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        border: Border(
          bottom: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: CyberColors.neonCyan.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: CyberTextStyles.neonTitle.copyWith(fontSize: 18),
        ),
        actions: actions,
        leading: leading,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
