import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/node_service.dart';
import '../services/wallet_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_indicator.dart';
import '../widgets/peer_list.dart';
import '../widgets/node_info_card.dart';
import '../theme/theme.dart';

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
          // Cyberpunk animated background with matrix rain
          const MatrixRainBackground(
            columns: 15,
            speed: 0.8,
            opacity: 0.1,
          ),

          // Hex grid overlay
          const HexGridBackground(
            hexSize: 50,
            opacity: 0.05,
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  backgroundColor: CyberColors.backgroundDark.withOpacity(0.9),
                  actions: [
                    // Refresh button
                    if (nodeService.isRunning)
                      IconButton(
                        onPressed: () => nodeService.refreshStatus(),
                        icon: const Icon(Icons.refresh, color: CyberColors.neonCyan),
                        tooltip: 'Refresh',
                      ),
                    IconButton(
                      onPressed: () => _showWalletInfo(context),
                      icon: const Icon(Icons.account_balance_wallet, color: CyberColors.neonMagenta),
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
                                        CyberColors.neonCyan,
                                        CyberColors.neonGreen,
                                        _pulseController.value,
                                      )
                                    : CyberColors.textDim,
                                boxShadow: nodeService.isRunning
                                    ? [
                                        BoxShadow(
                                          color: CyberColors.neonCyan
                                              .withOpacity(0.6 * _pulseController.value),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'CYBERFLY',
                          style: CyberTextStyles.neonTitle.copyWith(
                            fontSize: 18,
                            letterSpacing: 4,
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
                            'CONNECTED PEERS',
                            style: CyberTextStyles.label.copyWith(
                              color: CyberColors.neonCyan,
                              letterSpacing: 2,
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

    return NeonGlowCard(
      glowColor: CyberColors.neonMagenta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CyberColors.neonMagenta.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CyberColors.neonMagenta.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: CyberColors.neonMagenta,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'WALLET',
                style: CyberTextStyles.label.copyWith(
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              StatusBadge(
                status: NodeConnectionStatus.online,
                label: 'Connected',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'ACCOUNT',
            style: CyberTextStyles.caption.copyWith(
              color: CyberColors.textDim,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  walletService.account ?? '',
                  style: CyberTextStyles.mono.copyWith(
                    fontSize: 12,
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
                    SnackBar(
                      content: Text(
                        'Account copied to clipboard',
                        style: CyberTextStyles.body,
                      ),
                      backgroundColor: CyberColors.cardDark,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                color: CyberColors.neonCyan,
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
          color: CyberColors.neonCyan,
          subtitle: 'Active connections',
        ),
        StatCard(
          title: 'Discovered Peers',
          value: status.discoveredPeers.toString(),
          icon: Icons.radar,
          color: CyberColors.neonGreen,
          subtitle: 'Found via gossip',
        ),
        StatCard(
          title: 'Storage Keys',
          value: '${status.totalKeys}',
          icon: Icons.storage,
          color: CyberColors.neonRed,
          subtitle: _formatBytes(status.storageSizeBytes),
        ),
        StatCard(
          title: 'Gossip Messages',
          value: status.gossipMessagesReceived.toString(),
          icon: Icons.message,
          color: CyberColors.neonYellow,
          subtitle: 'Received',
        ),
        StatCard(
          title: 'Latency Checks',
          value: status.latencyRequestsSent.toString(),
          icon: Icons.speed,
          color: CyberColors.neonMagenta,
          subtitle: '${status.latencyResponsesReceived} responses',
        ),
        StatCard(
          title: 'Sync Operations',
          value: status.totalOperations.toString(),
          icon: Icons.sync,
          color: CyberColors.neonOrange,
          subtitle: 'Total synced',
        ),
      ],
    );
  }

  Widget _buildEmptyPeersCard() {
    return NeonGlowCard(
      glowColor: CyberColors.neonCyan,
      glowIntensity: 0.3,
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: CyberColors.textDim,
          ),
          const SizedBox(height: 12),
          Text(
            'No peers connected yet',
            style: CyberTextStyles.body.copyWith(
              color: CyberColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discovering peers via gossip protocol...',
            style: CyberTextStyles.caption.copyWith(
              color: CyberColors.textDim,
            ),
          ),
          const SizedBox(height: 16),
          const GlowingProgressIndicator(
            color: CyberColors.neonCyan,
            size: 24,
          ),
        ],
      ),
    );
  }

  void _showWalletInfo(BuildContext context) {
    final walletService = context.read<WalletService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: CyberColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WALLET DETAILS',
              style: CyberTextStyles.neonTitle.copyWith(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Account', walletService.account ?? ''),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showBackupWarning(context),
                icon: const Icon(Icons.key),
                label: const Text('Show Recovery Phrase'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CyberColors.neonOrange,
                  side: const BorderSide(color: CyberColors.neonOrange),
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
          label.toUpperCase(),
          style: CyberTextStyles.caption.copyWith(
            color: CyberColors.textDim,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: CyberTextStyles.mono.copyWith(
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Copied to clipboard',
                      style: CyberTextStyles.body,
                    ),
                    backgroundColor: CyberColors.cardDark,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              color: CyberColors.neonCyan,
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
        backgroundColor: CyberColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: CyberColors.neonOrange.withOpacity(0.5),
          ),
        ),
        title: Text(
          '⚠️ WARNING',
          style: CyberTextStyles.label.copyWith(
            color: CyberColors.neonOrange,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Your recovery phrase gives full access to your wallet. Never share it with anyone. Make sure no one is watching your screen.',
          style: CyberTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: CyberTextStyles.body.copyWith(color: CyberColors.textDim),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRecoveryPhrase(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberColors.neonOrange,
              foregroundColor: CyberColors.backgroundDark,
            ),
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
      backgroundColor: CyberColors.cardDark,
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
            Text(
              'RECOVERY PHRASE',
              style: CyberTextStyles.neonTitle.copyWith(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CyberColors.neonOrange.withOpacity(0.3),
                ),
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
                      color: CyberColors.cardDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: CyberColors.neonCyan.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '${index + 1}. ${words[index]}',
                      style: CyberTextStyles.mono.copyWith(
                        fontSize: 11,
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
                    SnackBar(
                      content: Text(
                        'Recovery phrase copied',
                        style: CyberTextStyles.body,
                      ),
                      backgroundColor: CyberColors.cardDark,
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberColors.neonCyan,
                  foregroundColor: CyberColors.backgroundDark,
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
