import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/node_service.dart';
import '../theme/theme.dart';

class PeerList extends StatelessWidget {
  final List<PeerInfo> peers;

  const PeerList({super.key, required this.peers});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.white.withOpacity(0.05)
            : CyberColorsLight.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : CyberColorsLight.border,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: peers.length,
        separatorBuilder: (_, __) => Divider(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : CyberColorsLight.divider,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final peer = peers[index];
          return _PeerTile(peer: peer);
        },
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  final PeerInfo peer;

  const _PeerTile({required this.peer});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = peer.isConnected
        ? (isDarkMode ? const Color(0xFF00FF88) : CyberColorsLight.online)
        : (isDarkMode ? const Color(0xFFFFD93D) : CyberColorsLight.warning);
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    final secondaryTextColor = isDarkMode 
        ? Colors.white.withOpacity(0.5) 
        : CyberColorsLight.textSecondary;
    final accentColor = isDarkMode ? const Color(0xFF00D9FF) : CyberColorsLight.primaryCyan;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                  Icons.device_unknown,
                  color: statusColor,
                  size: 24,
                ),
            ),
            // Connection status indicator
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  border: Border.all(
                    color: isDarkMode ? Colors.black : Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _truncateNodeId(peer.nodeId),
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (peer.region != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                peer.region!,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: latency and version
            Row(
              children: [
                Icon(Icons.speed, size: 12, color: secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  peer.latencyMs != null ? '${peer.latencyMs}ms' : 'N/A',
                  style: TextStyle(
                    color: peer.latencyMs != null 
                        ? _getLatencyColor(peer.latencyMs!, isDarkMode) 
                        : secondaryTextColor,
                    fontSize: 12,
                    fontWeight: peer.latencyMs != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                if (peer.version != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.tag, size: 12, color: secondaryTextColor),
                  const SizedBox(width: 4),
                  Text(
                    'v${peer.version}',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            // Second row: address if available
            if (peer.address != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.dns, size: 12, color: secondaryTextColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      peer.address!,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.copy, color: secondaryTextColor, size: 18),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: peer.nodeId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Node ID copied to clipboard'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF00D9FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Color _getLatencyColor(int latencyMs, bool isDarkMode) {
    if (latencyMs < 50) {
      return isDarkMode ? const Color(0xFF00FF88) : CyberColorsLight.online;
    } else if (latencyMs < 150) {
      return isDarkMode ? const Color(0xFFFFD93D) : CyberColorsLight.warning;
    } else {
      return isDarkMode ? const Color(0xFFFF6B6B) : Colors.red;
    }
  }

  String _truncateNodeId(String nodeId) {
    if (nodeId.length <= 16) return nodeId;
    return '${nodeId.substring(0, 8)}...${nodeId.substring(nodeId.length - 8)}';
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
