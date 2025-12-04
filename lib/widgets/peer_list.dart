import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/node_service.dart';

class PeerList extends StatelessWidget {
  final List<PeerInfo> peers;

  const PeerList({super.key, required this.peers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: peers.length,
        separatorBuilder: (_, __) =>
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
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
    final statusColor = peer.isConnected
        ? const Color(0xFF00FF88)
        : const Color(0xFFFFD93D);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            peer.isConnected ? Icons.link : Icons.link_off,
            color: statusColor,
            size: 24,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _truncateNodeId(peer.nodeId),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 12,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              _formatLastSeen(peer.lastSeen),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.speed, size: 12, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 4),
            Text(
              peer.latencyMs != null ? '${peer.latencyMs}ms' : 'N/A',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.copy, color: Colors.white.withOpacity(0.5), size: 18),
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
