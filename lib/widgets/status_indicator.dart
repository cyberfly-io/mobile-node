import 'package:flutter/material.dart';
import '../services/node_service.dart';
import '../theme/theme.dart';

class StatusIndicator extends StatefulWidget {
  final NodeStatus status;
  final bool isStarting;

  const StatusIndicator({
    super.key,
    required this.status,
    this.isStarting = false,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isRunning = widget.status.isRunning;
    final statusColor = isRunning
        ? CyberColors.neonGreen
        : widget.isStarting
        ? CyberColors.neonYellow
        : CyberColors.neonRed;
    final statusText = isRunning
        ? 'ONLINE'
        : widget.isStarting
        ? 'STARTING...'
        : 'OFFLINE';
    final cardBgColor = isDarkMode 
        ? CyberColors.backgroundCard 
        : CyberColorsLight.backgroundCard;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(isDarkMode ? 0.12 : 0.08),
            cardBgColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(isDarkMode ? 0.15 : 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated status orb
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(0.15),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: isRunning || widget.isStarting
                      ? [
                          BoxShadow(
                            color: statusColor.withOpacity(
                              0.4 * _animation.value,
                            ),
                            blurRadius: 24 * _animation.value,
                            spreadRadius: 6 * _animation.value,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: widget.isStarting
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CyberColors.backgroundDark,
                            ),
                          )
                        : Icon(
                            isRunning ? Icons.check : Icons.power_settings_new,
                            color: CyberColors.backgroundDark,
                            size: 16,
                          ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 20),

          // Status info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: statusColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: statusColor.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.status.health.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (isRunning) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDarkMode ? CyberColors.textSecondary : CyberColorsLight.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Uptime: ${_formatUptime(widget.status.uptimeSeconds)}',
                        style: CyberTextStyles.mono.copyWith(
                          fontSize: 13,
                          color: isDarkMode ? CyberColors.textSecondary : CyberColorsLight.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.sync,
                        size: 14,
                        color: isDarkMode ? CyberColors.textDim : CyberColorsLight.textDim,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.status.totalOperations} operations synced',
                        style: CyberTextStyles.caption.copyWith(
                          color: isDarkMode ? CyberColors.textDim : CyberColorsLight.textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ] else if (!widget.isStarting) ...[
                  Text(
                    'Tap "Start Node" to connect',
                    style: CyberTextStyles.caption.copyWith(
                      color: isDarkMode ? CyberColors.textDim : CyberColorsLight.textDim,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes}m ${secs}s';
    }
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }
}
