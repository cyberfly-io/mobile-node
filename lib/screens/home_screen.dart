import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/node_service.dart';
import '../services/wallet_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_indicator.dart';
import '../widgets/peer_list.dart';
import '../widgets/node_info_card.dart';
import '../widgets/animated_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodeService = context.watch<NodeService>();
    final walletService = context.watch<WalletService>();

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          const AnimatedBackground(),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  actions: [
                    // Refresh button
                    if (nodeService.isRunning)
                      IconButton(
                        onPressed: () => nodeService.refreshStatus(),
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                    IconButton(
                      onPressed: () => _showWalletInfo(context),
                      icon: const Icon(Icons.account_balance_wallet),
                      tooltip: 'Wallet',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: nodeService.isRunning
                                    ? Color.lerp(
                                        const Color(0xFF00D9FF),
                                        const Color(0xFF00FF88),
                                        _pulseController.value,
                                      )
                                    : Colors.grey,
                                boxShadow: nodeService.isRunning
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00D9FF)
                                              .withValues(
                                                alpha:
                                                    0.5 *
                                                    _pulseController.value,
                                              ),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Cyberfly Node',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    centerTitle: true,
                  ),
                ),

                // Status section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wallet card
                        _buildWalletCard(walletService),

                        const SizedBox(height: 16),

                        // Node info card
                        if (nodeService.nodeInfo != null)
                          NodeInfoCard(nodeInfo: nodeService.nodeInfo!),

                        const SizedBox(height: 16),

                        // Status indicator
                        StatusIndicator(
                          status: nodeService.status,
                          isStarting: nodeService.isStarting,
                        ),

                        const SizedBox(height: 24),

                        // Stats grid
                        _buildStatsGrid(nodeService),

                        const SizedBox(height: 24),

                        // Peers section - always show
                        if (nodeService.isRunning) ...[
                          Text(
                            'Connected Peers',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          nodeService.peers.isEmpty
                              ? _buildEmptyPeersCard()
                              : PeerList(peers: nodeService.peers),
                        ],

                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(WalletService walletService) {
    if (!walletService.hasWallet) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1D1E33),
            const Color(0xFF1D1E33).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(color: Color(0xFF00FF88), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Account',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  walletService.account ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: walletService.account ?? ''),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account copied to clipboard'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                color: Colors.white.withValues(alpha: 0.5),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(NodeService nodeService) {
    final status = nodeService.status;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Connected Peers',
          value: status.connectedPeers.toString(),
          icon: Icons.people,
          color: const Color(0xFF00D9FF),
          subtitle: 'Active connections',
        ),
        StatCard(
          title: 'Discovered Peers',
          value: status.discoveredPeers.toString(),
          icon: Icons.radar,
          color: const Color(0xFF00FF88),
          subtitle: 'Found via gossip',
        ),
        StatCard(
          title: 'Storage Usage',
          value: _formatBytes(status.storageSizeBytes),
          icon: Icons.storage,
          color: const Color(0xFFFF6B6B),
          subtitle: '${status.totalKeys} keys',
        ),
        StatCard(
          title: 'Gossip Messages',
          value: status.gossipMessagesReceived.toString(),
          icon: Icons.message,
          color: const Color(0xFFFFD93D),
          subtitle: 'Received',
        ),
        StatCard(
          title: 'Latency Checks',
          value: status.latencyRequestsSent.toString(),
          icon: Icons.speed,
          color: const Color(0xFF9B59B6),
          subtitle: '${status.latencyResponsesReceived} responses',
        ),
        StatCard(
          title: 'Sync Operations',
          value: status.totalOperations.toString(),
          icon: Icons.sync,
          color: const Color(0xFFE67E22),
          subtitle: 'Total synced',
        ),
      ],
    );
  }

  Widget _buildEmptyPeersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No peers connected yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discovering peers via gossip protocol...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF00D9FF).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showWalletInfo(BuildContext context) {
    final walletService = context.read<WalletService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallet Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Public Key', walletService.publicKey ?? ''),
            const SizedBox(height: 12),
            _buildDetailRow('Account', walletService.account ?? ''),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showBackupWarning(context),
                icon: const Icon(Icons.key),
                label: const Text('Show Recovery Phrase'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ],
    );
  }

  void _showBackupWarning(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text('⚠️ Warning', style: TextStyle(color: Colors.orange)),
        content: const Text(
          'Your recovery phrase gives full access to your wallet. Never share it with anyone. Make sure no one is watching your screen.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRecoveryPhrase(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Show Phrase'),
          ),
        ],
      ),
    );
  }

  void _showRecoveryPhrase(BuildContext context) {
    final walletService = context.read<WalletService>();
    final mnemonic = walletService.getMnemonic();

    if (mnemonic == null) return;

    final words = mnemonic.split(' ');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1E33),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recovery Phrase',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(words.length, (index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1E33),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}. ${words[index]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: mnemonic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recovery phrase copied')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
