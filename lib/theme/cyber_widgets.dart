import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'cyberfly_theme.dart';

/// Animated neon glow border for cards
class NeonGlowCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final bool animate;
  final Duration animationDuration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double glowIntensity;

  const NeonGlowCard({
    super.key,
    required this.child,
    this.glowColor = CyberColors.neonCyan,
    this.borderRadius = 16,
    this.animate = true,
    this.animationDuration = const Duration(seconds: 2),
    this.padding,
    this.margin,
    this.glowIntensity = 1.0,
  });

  @override
  State<NeonGlowCard> createState() => _NeonGlowCardState();
}

class _NeonGlowCardState extends State<NeonGlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardGradient = isDark 
        ? CyberColors.cardGradient 
        : LinearGradient(
            colors: [CyberColorsLight.cardBackground, CyberColorsLight.backgroundMedium],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            gradient: cardGradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.glowColor.withOpacity(
                widget.animate ? _glowAnimation.value : 0.4,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(
                  (widget.animate ? _glowAnimation.value * 0.4 : 0.2) * widget.glowIntensity,
                ),
                blurRadius: widget.animate ? 12 + (_glowAnimation.value * 8) : 12,
                spreadRadius: widget.animate ? _glowAnimation.value * 2 * widget.glowIntensity : 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Animated gradient border
class GradientBorderCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool animate;

  const GradientBorderCard({
    super.key,
    required this.child,
    this.gradientColors = const [CyberColors.neonCyan, CyberColors.neonMagenta],
    this.borderRadius = 16,
    this.borderWidth = 2,
    this.padding,
    this.margin,
    this.animate = true,
  });

  @override
  State<GradientBorderCard> createState() => _GradientBorderCardState();
}

class _GradientBorderCardState extends State<GradientBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? CyberColors.backgroundCard : CyberColorsLight.cardBackground;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              startAngle: widget.animate ? _controller.value * 2 * math.pi : 0,
              colors: [
                ...widget.gradientColors,
                widget.gradientColors.first,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderWidth),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(
                widget.borderRadius - widget.borderWidth,
              ),
            ),
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Pulsing status indicator
class PulsingIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final bool pulse;

  const PulsingIndicator({
    super.key,
    this.color = CyberColors.neonGreen,
    this.size = 12,
    this.pulse = true,
  });

  @override
  State<PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_animation.value * 0.6),
                blurRadius: widget.size * _animation.value,
                spreadRadius: widget.size * 0.2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Status badge for peer states
class StatusBadge extends StatelessWidget {
  final dynamic status;
  final String? label;
  final bool showLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsingIndicator(
            color: config.color,
            size: 8,
            pulse: config.pulse,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              label ?? config.label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: config.color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    // Handle NodeConnectionStatus
    if (status is NodeConnectionStatus) {
      switch (status as NodeConnectionStatus) {
        case NodeConnectionStatus.online:
          return _StatusConfig(
            color: CyberColors.neonGreen,
            label: 'ONLINE',
            pulse: true,
          );
        case NodeConnectionStatus.offline:
          return _StatusConfig(
            color: CyberColors.offline,
            label: 'OFFLINE',
            pulse: false,
          );
        case NodeConnectionStatus.syncing:
          return _StatusConfig(
            color: CyberColors.neonCyan,
            label: 'SYNCING',
            pulse: true,
          );
        case NodeConnectionStatus.connecting:
          return _StatusConfig(
            color: CyberColors.neonOrange,
            label: 'CONNECTING',
            pulse: true,
          );
        case NodeConnectionStatus.error:
          return _StatusConfig(
            color: CyberColors.neonRed,
            label: 'ERROR',
            pulse: false,
          );
      }
    }
    
    // Handle PeerStatus
    if (status is PeerStatus) {
      switch (status as PeerStatus) {
        case PeerStatus.online:
          return _StatusConfig(
            color: CyberColors.neonGreen,
            label: 'ONLINE',
            pulse: true,
          );
        case PeerStatus.offline:
          return _StatusConfig(
            color: CyberColors.offline,
            label: 'OFFLINE',
            pulse: false,
          );
        case PeerStatus.syncing:
          return _StatusConfig(
            color: CyberColors.neonCyan,
            label: 'SYNCING',
            pulse: true,
          );
        case PeerStatus.connecting:
          return _StatusConfig(
            color: CyberColors.neonOrange,
            label: 'CONNECTING',
            pulse: true,
          );
        case PeerStatus.error:
          return _StatusConfig(
            color: CyberColors.neonRed,
            label: 'ERROR',
            pulse: false,
          );
      }
    }
    
    // Default fallback
    return _StatusConfig(
      color: CyberColors.textDim,
      label: 'UNKNOWN',
      pulse: false,
    );
  }
}

enum PeerStatus { online, offline, syncing, connecting, error }
enum NodeConnectionStatus { online, offline, syncing, connecting, error }

class _StatusConfig {
  final Color color;
  final String label;
  final bool pulse;

  _StatusConfig({
    required this.color,
    required this.label,
    required this.pulse,
  });
}

/// Neon button with glow effect
class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool loading;
  final bool outlined;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color = CyberColors.neonCyan,
    this.icon,
    this.loading = false,
    this.outlined = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.onPressed != null
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(
                          0.2 + (_glowAnimation.value * 0.3),
                        ),
                        blurRadius: 8 + (_glowAnimation.value * 12),
                        spreadRadius: _glowAnimation.value * 2,
                      ),
                    ]
                  : null,
            ),
            child: widget.outlined
                ? _buildOutlinedButton()
                : _buildFilledButton(),
          );
        },
      ),
    );
  }

  Widget _buildFilledButton() {
    return ElevatedButton(
      onPressed: widget.loading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color,
        foregroundColor: CyberColors.backgroundDark,
        disabledBackgroundColor: widget.color.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildOutlinedButton() {
    return OutlinedButton(
      onPressed: widget.loading ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.color,
        side: BorderSide(
          color: widget.color.withOpacity(_isHovered ? 1.0 : 0.6),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.loading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.outlined ? widget.color : CyberColors.backgroundDark,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// Stat display panel with neon styling
class StatPanel extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final Color? iconColor;
  final bool compact;

  const StatPanel({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildNormal();
  }

  Widget _buildNormal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: iconColor ?? CyberColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: CyberTextStyles.statLabel,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: CyberTextStyles.statValue.copyWith(
            color: valueColor ?? CyberColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: iconColor ?? CyberColors.textSecondary,
          ),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CyberColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: CyberColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Latency meter with color-coded ranges
class LatencyMeter extends StatelessWidget {
  final int latencyMs;
  final bool showLabel;
  final double height;

  const LatencyMeter({
    super.key,
    required this.latencyMs,
    this.showLabel = true,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? CyberColors.backgroundLight : CyberColorsLight.border;
    final color = _getLatencyColor();
    final progress = _getProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LATENCY',
                  style: CyberTextStyles.statLabel,
                ),
                Text(
                  '${latencyMs}ms',
                  style: CyberTextStyles.latencyColored(latencyMs),
                ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              // Progress bar
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getLatencyColor() {
    if (latencyMs < 50) return CyberColors.neonGreen;
    if (latencyMs < 100) return CyberColors.neonCyan;
    if (latencyMs < 200) return CyberColors.neonYellow;
    if (latencyMs < 500) return CyberColors.neonOrange;
    return CyberColors.neonRed;
  }

  double _getProgress() {
    // Scale: 0-1000ms mapped to 0-1
    return (latencyMs / 1000).clamp(0.0, 1.0);
  }
}

/// Glowing progress indicator
class GlowingProgressIndicator extends StatefulWidget {
  final double? value;
  final Color color;
  final double size;
  final double strokeWidth;

  const GlowingProgressIndicator({
    super.key,
    this.value,
    this.color = CyberColors.neonCyan,
    this.size = 40,
    this.strokeWidth = 4,
  });

  @override
  State<GlowingProgressIndicator> createState() =>
      _GlowingProgressIndicatorState();
}

class _GlowingProgressIndicatorState extends State<GlowingProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? CyberColors.backgroundLight : CyberColorsLight.border;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_glowAnimation.value * 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.value != null
              ? CircularProgressIndicator(
                  value: widget.value,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: bgColor,
                )
              : CircularProgressIndicator(
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                ),
        );
      },
    );
  }
}

/// Scanline overlay effect
class ScanlineOverlay extends StatelessWidget {
  final double opacity;
  final double lineSpacing;

  const ScanlineOverlay({
    super.key,
    this.opacity = 0.03,
    this.lineSpacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanlinePainter(
          opacity: opacity,
          lineSpacing: lineSpacing,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double opacity;
  final double lineSpacing;

  _ScanlinePainter({required this.opacity, required this.lineSpacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Grid overlay effect
class GridOverlay extends StatelessWidget {
  final double opacity;
  final double gridSize;
  final Color color;

  const GridOverlay({
    super.key,
    this.opacity = 0.05,
    this.gridSize = 30,
    this.color = CyberColors.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(
          opacity: opacity,
          gridSize: gridSize,
          color: color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double opacity;
  final double gridSize;
  final Color color;

  _GridPainter({
    required this.opacity,
    required this.gridSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated gradient border that rotates
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final List<Color> gradientColors;
  final Duration duration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.borderWidth = 2,
    this.gradientColors = const [
      CyberColors.neonCyan,
      CyberColors.neonMagenta,
      CyberColors.neonCyan,
    ],
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? CyberColors.backgroundCard : CyberColorsLight.cardBackground;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              startAngle: _controller.value * 2 * math.pi,
              colors: widget.gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderWidth),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(
                widget.borderRadius - widget.borderWidth,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.borderRadius - widget.borderWidth,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
