import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/kadena_service.dart';
import '../services/wallet_service.dart';
import '../theme/theme.dart';
import 'node_details_screen.dart';

class StakingScreen extends StatefulWidget {
  const StakingScreen({super.key});

  @override
  State<StakingScreen> createState() => _StakingScreenState();
}

class _StakingScreenState extends State<StakingScreen> {
  bool _isLoading = true;
  NodeRegistrationStatus? _myNode;
  NodeStakeInfo? _stakeInfo;
  double? _apy;
  StakeStats? _stakeStats;
  String? _publicKey;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final kadenaService = context.read<KadenaService>();
    final walletService = context.read<WalletService>();
    
    try {
      // Get APY and stats
      final results = await Future.wait([
        kadenaService.getAPY(),
        kadenaService.getStakeStats(),
      ]);

      _apy = results[0] as double?;
      _stakeStats = results[1] as StakeStats?;

      // Get node using wallet's publicKey as peerId
      final publicKey = walletService.publicKey;
      _publicKey = publicKey;
      if (publicKey != null) {
        _myNode = await kadenaService.getNodeInfo(publicKey);
        // Use publicKey directly for stake lookup since get-node doesn't return peer_id
        if (_myNode != null) {
          _stakeInfo = await kadenaService.getNodeStake(publicKey);
        }
      }
    } catch (e) {
      debugPrint('Error loading staking data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<WalletService>();
    final isDark = CyberTheme.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? CyberColors.backgroundDark : CyberColorsLight.backgroundLight,
      appBar: AppBar(
        title: const Text('My Node'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CyberTheme.primary(context),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: CyberTheme.primary(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Stats Header
              _buildStatsHeader(context),
              
              // Node content
              Padding(
                padding: const EdgeInsets.all(16),
                child: walletService.hasWallet
                    ? _buildNodeContent(context)
                    : _buildConnectWalletPrompt(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [CyberColors.neonCyan.withOpacity(0.2), CyberColors.neonMagenta.withOpacity(0.2)]
              : [CyberColorsLight.primaryCyan.withOpacity(0.1), CyberColorsLight.primaryMagenta.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CyberTheme.primary(context).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.trending_up,
            label: 'APY',
            value: _apy != null ? '${_apy!.toStringAsFixed(2)}%' : '--',
            color: Colors.green,
          ),
          _buildStatItem(
            context,
            icon: Icons.people,
            label: 'Total Stakes',
            value: _stakeStats?.totalStakes.toString() ?? '--',
            color: CyberTheme.primary(context),
          ),
          _buildStatItem(
            context,
            icon: Icons.account_balance,
            label: 'Total Staked',
            value: _stakeStats != null 
                ? '${(_stakeStats!.totalStakedAmount / 1000).toStringAsFixed(0)}K'
                : '--',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CyberTheme.textPrimary(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CyberTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectWalletPrompt(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: CyberTheme.textDim(context),
          ),
          const SizedBox(height: 24),
          Text(
            'Wallet Required',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CyberTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Connect your wallet to view your nodes',
            style: TextStyle(
              fontSize: 16,
              color: CyberTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/wallet'),
            icon: const Icon(Icons.add),
            label: const Text('Create Wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.primary(context),
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_myNode == null) {
      return _buildNoNodeFound(context);
    }

    return _buildNodeCard(context, _myNode!, _stakeInfo, _publicKey);
  }

  Widget _buildNoNodeFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 64,
            color: CyberTheme.textDim(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Node Not Registered',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CyberTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your wallet does not have a registered node',
            style: TextStyle(
              fontSize: 14,
              color: CyberTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(
    BuildContext context,
    NodeRegistrationStatus node,
    NodeStakeInfo? stakeInfo,
    String? publicKey,
  ) {
    final isDark = CyberTheme.isDark(context);
    final isActive = node.isActive;
    final isStaked = stakeInfo?.active == true;
    final nodeId = node.peerId ?? publicKey;

    return Card(
      color: isDark ? CyberColors.backgroundCard : CyberColorsLight.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isStaked 
              ? Colors.orange.withOpacity(0.5)
              : CyberTheme.primary(context).withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: nodeId != null ? () => _openNodeDetails(nodeId) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CyberTheme.primary(context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.dns,
                      color: CyberTheme.primary(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Node',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: CyberTheme.textPrimary(context),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (nodeId != null) {
                              Clipboard.setData(ClipboardData(text: nodeId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Peer ID copied')),
                              );
                            }
                          },
                          child: Text(
                            nodeId ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 11,
                              color: CyberTheme.textDim(context),
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(
                        isActive ? 'Active' : 'Inactive',
                        isActive ? Colors.green : Colors.grey,
                      ),
                      if (isStaked) ...[
                        const SizedBox(height: 4),
                        _buildStatusBadge('Staked', Colors.orange),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Node info
              _buildInfoRow(context, 'Account', node.account),
              const SizedBox(height: 8),
              _buildInfoRow(context, 'Status', node.status),
              if (node.multiaddr.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(context, 'Multiaddr', node.multiaddr),
              ],
              
              // Stake info
              if (stakeInfo != null && isStaked) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Staked: ${(stakeInfo.amount ?? 50000).toStringAsFixed(0)} CFLY',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: nodeId != null ? () => _openNodeDetails(nodeId) : null,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.primary(context).withOpacity(0.15),
                    foregroundColor: CyberTheme.primary(context),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: CyberTheme.textSecondary(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: CyberTheme.textPrimary(context),
              fontFamily: 'monospace',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openNodeDetails(String peerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NodeDetailsScreen(peerId: peerId),
      ),
    ).then((_) => _loadData()); // Refresh after returning
  }
}
