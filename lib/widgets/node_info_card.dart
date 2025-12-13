import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/node_service.dart';
import '../theme/theme.dart';

class NodeInfoCard extends StatefulWidget {
  final NodeInfo nodeInfo;
  final int uptimeSeconds;

  const NodeInfoCard({super.key, required this.nodeInfo, this.uptimeSeconds = 0});

  @override
  State<NodeInfoCard> createState() => _NodeInfoCardState();
}

class _NodeInfoCardState extends State<NodeInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _iconRotation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    final secondaryTextColor = isDarkMode 
        ? Colors.white.withOpacity(0.7) 
        : CyberColorsLight.textSecondary;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00D9FF).withOpacity(isDarkMode ? 0.15 : 0.1),
            const Color(0xFF00FF88).withOpacity(isDarkMode ? 0.05 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Animated rotating hub icon
              AnimatedBuilder(
                animation: _iconRotation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _iconRotation.value * 2 * 3.14159,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.hub,
                        color: Color(0xFF00D9FF),
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Node Identity',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cyberfly P2P Node',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Node ID
          _InfoRow(
            label: 'Node ID',
            value: _truncateId(widget.nodeInfo.nodeId),
            fullValue: widget.nodeInfo.nodeId,
            icon: Icons.fingerprint,
            color: const Color(0xFF00D9FF),
          ),

          const SizedBox(height: 12),

          // App Version
          _InfoRow(
            label: 'App Version',
            value: _appVersion.isNotEmpty ? _appVersion : 'Loading...',
            fullValue: _appVersion,
            icon: Icons.info_outline,
            color: const Color(0xFFFFD93D),
            copyable: false,
          ),

          const SizedBox(height: 12),

          // Uptime
          _InfoRow(
            label: 'Uptime',
            value: _formatUptime(widget.uptimeSeconds),
            fullValue: _formatUptime(widget.uptimeSeconds),
            icon: Icons.timer_outlined,
            color: const Color(0xFF00FF88),
            copyable: false,
          ),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    if (seconds <= 0) return '0s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _truncateId(String id) {
    if (id.length <= 20) return id;
    return '${id.substring(0, 10)}...${id.substring(id.length - 10)}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String fullValue;
  final IconData icon;
  final Color color;
  final bool copyable;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.fullValue,
    required this.icon,
    required this.color,
    this.copyable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    final secondaryTextColor = isDarkMode 
        ? Colors.white.withOpacity(0.5) 
        : CyberColorsLight.textSecondary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor.withOpacity(0.9),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: fullValue));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.copy, color: color, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
