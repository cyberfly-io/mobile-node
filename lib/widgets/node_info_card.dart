import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/node_service.dart';

class NodeInfoCard extends StatelessWidget {
  final NodeInfo nodeInfo;

  const NodeInfoCard({super.key, required this.nodeInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00D9FF).withOpacity(0.15),
            const Color(0xFF00FF88).withOpacity(0.05),
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
              Container(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Node Identity',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cyberfly P2P Node',
                      style: const TextStyle(
                        color: Colors.white,
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
            value: _truncateId(nodeInfo.nodeId),
            fullValue: nodeInfo.nodeId,
            icon: Icons.fingerprint,
            color: const Color(0xFF00D9FF),
          ),

          const SizedBox(height: 12),

          // Public Key
          _InfoRow(
            label: 'Public Key',
            value: _truncateId(nodeInfo.publicKey),
            fullValue: nodeInfo.publicKey,
            icon: Icons.key,
            color: const Color(0xFF00FF88),
          ),

          const SizedBox(height: 12),

          // Version
          _InfoRow(
            label: 'Version',
            value: nodeInfo.version,
            fullValue: nodeInfo.version,
            icon: Icons.info_outline,
            color: const Color(0xFFFFD93D),
            copyable: false,
          ),
        ],
      ),
    );
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
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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
