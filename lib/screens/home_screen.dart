import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/node_service.dart';
import '../services/wallet_service.dart';
import '../services/kadena_service.dart';
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
  
  // Balance and staking state
  double? _cflyBalance;
  NodeStakeInfo? _stakeInfo;
  bool _isLoadingBalance = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Load balance and staking info after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalanceAndStaking();
    });
  }

  Future<void> _loadBalanceAndStaking() async {
    final walletService = context.read<WalletService>();
    final kadenaService = context.read<KadenaService>();
    
    if (!walletService.hasWallet) return;
    
    setState(() => _isLoadingBalance = true);
    
    try {
      final account = walletService.account;
      final publicKey = walletService.publicKey;
      
      // Load balance and stake info in parallel
      final results = await Future.wait([
        kadenaService.getCFLYBalance(account),
        if (publicKey != null) kadenaService.getNodeStake(publicKey),
      ]);
      
      if (mounted) {
        setState(() {
          _cflyBalance = results[0] as double?;
          if (results.length > 1) {
            _stakeInfo = results[1] as NodeStakeInfo?;
          }
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
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
    final isDark = CyberTheme.isDark(context);

    return Scaffold(
      body: Stack(
        children: [
          // Cyberpunk animated background with matrix rain (dark mode only)
          // Wrapped in RepaintBoundary to isolate repaints
          if (isDark) ...[
            const RepaintBoundary(
              child: MatrixRainBackground(
                columns: 15,
                speed: 0.8,
                opacity: 0.1,
              ),
            ),

            // Hex grid overlay
            const RepaintBoundary(
              child: HexGridBackground(
                hexSize: 50,
                opacity: 0.05,
              ),
            ),
          ],

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  backgroundColor: CyberTheme.appBarBackground(context),
                  actions: [
                    // Refresh button
                    if (nodeService.isRunning)
                      IconButton(
                        onPressed: () => nodeService.refreshStatus(),
                        icon: Icon(Icons.refresh, color: CyberTheme.primary(context)),
                        tooltip: 'Refresh',
                      )
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'CYBERFLY',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CyberTheme.primary(context),
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
                        _buildWalletCard(context, walletService),

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
                        _buildStatsGrid(context, nodeService),

                        const SizedBox(height: 24),

                        // Peers section - always show
                        if (nodeService.isRunning) ...[
                          Text(
                            'CONNECTED PEERS',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: CyberTheme.primary(context),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          nodeService.peers.isEmpty
                              ? _buildEmptyPeersCard(context)
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

  Widget _buildWalletCard(BuildContext context, WalletService walletService) {
    if (!walletService.hasWallet) return const SizedBox.shrink();
    
    final isDark = CyberTheme.isDark(context);
    final primaryColor = CyberTheme.primary(context);
    final magentaColor = isDark ? CyberColors.neonMagenta : CyberColorsLight.primaryMagenta;

    return NeonGlowCard(
      glowColor: magentaColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: magentaColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: magentaColor.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: magentaColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'WALLET',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary(context),
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
            style: TextStyle(
              fontSize: 12,
              color: CyberTheme.textDim(context),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  walletService.account ?? '',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: CyberTheme.textPrimary(context),
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
                        style: TextStyle(color: CyberTheme.textPrimary(context)),
                      ),
                      backgroundColor: CyberTheme.card(context),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                color: primaryColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // CFLY Balance and Staking Status row
          Row(
            children: [
              // CFLY Balance
              Expanded(
                child: _buildBalanceItem(
                  context,
                  label: 'CFLY BALANCE',
                  value: _isLoadingBalance 
                      ? '...' 
                      : _cflyBalance != null 
                          ? _formatBalance(_cflyBalance!)
                          : '0.00',
                  icon: Icons.token,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              // Staking Status
              Expanded(
                child: _buildBalanceItem(
                  context,
                  label: 'STAKING',
                  value: _isLoadingBalance 
                      ? '...' 
                      : _stakeInfo?.active == true 
                          ? '${(_stakeInfo!.amount ?? 50000).toStringAsFixed(0)} CFLY'
                          : 'Not Staked',
                  icon: Icons.lock,
                  color: _stakeInfo?.active == true 
                      ? CyberTheme.success(context)
                      : CyberTheme.textDim(context),
                  isActive: _stakeInfo?.active == true,
                ),
              ),
            ],
          ),
          
          // Refresh button
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _isLoadingBalance ? null : _loadBalanceAndStaking,
              icon: _isLoadingBalance 
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    )
                  : Icon(Icons.refresh, size: 14, color: primaryColor),
              label: Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isActive = true,
  }) {
    final isDark = CyberTheme.isDark(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: CyberTheme.textDim(context),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? color : CyberTheme.textDim(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(2)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(2)}K';
    }
    return balance.toStringAsFixed(2);
  }

  Widget _buildStatsGrid(BuildContext context, NodeService nodeService) {
    final status = nodeService.status;
    final primaryColor = CyberTheme.primary(context);
    final successColor = CyberTheme.success(context);

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
          color: primaryColor,
          subtitle: 'Active connections',
        ),
        StatCard(
          title: 'Discovered Peers',
          value: status.discoveredPeers.toString(),
          icon: Icons.radar,
          color: successColor,
          subtitle: 'Found via gossip',
        ),
        StatCard(
          title: 'Storage Keys',
          value: '${status.totalKeys}',
          icon: Icons.storage,
          color: CyberTheme.error(context),
          subtitle: _formatBytes(status.storageSizeBytes),
        ),
        StatCard(
          title: 'Gossip Messages',
          value: status.gossipMessagesReceived.toString(),
          icon: Icons.message,
          color: CyberTheme.warning(context),
          subtitle: 'Received',
        ),
        StatCard(
          title: 'Latency Checks',
          value: status.latencyRequestsSent.toString(),
          icon: Icons.speed,
          color: CyberTheme.isDark(context) ? CyberColors.neonMagenta : CyberColorsLight.primaryMagenta,
          subtitle: '${status.latencyResponsesReceived} responses',
        ),
        StatCard(
          title: 'Sync Operations',
          value: status.totalOperations.toString(),
          icon: Icons.sync,
          color: CyberTheme.isDark(context) ? CyberColors.neonOrange : CyberColorsLight.primaryOrange,
          subtitle: 'Total synced',
        ),
      ],
    );
  }

  Widget _buildEmptyPeersCard(BuildContext context) {
    final primaryColor = CyberTheme.primary(context);
    
    return NeonGlowCard(
      glowColor: primaryColor,
      glowIntensity: 0.3,
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: CyberTheme.textDim(context),
          ),
          const SizedBox(height: 12),
          Text(
            'No peers connected yet',
            style: TextStyle(
              fontSize: 14,
              color: CyberTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discovering peers via gossip protocol...',
            style: TextStyle(
              fontSize: 12,
              color: CyberTheme.textDim(context),
            ),
          ),
          const SizedBox(height: 16),
          GlowingProgressIndicator(
            color: primaryColor,
            size: 24,
          ),
        ],
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
