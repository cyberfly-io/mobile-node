import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/kadena_service.dart';
import '../services/wallet_service.dart';
import '../theme/theme.dart';

class NodeDetailsScreen extends StatefulWidget {
  final String peerId;

  const NodeDetailsScreen({super.key, required this.peerId});

  @override
  State<NodeDetailsScreen> createState() => _NodeDetailsScreenState();
}

class _NodeDetailsScreenState extends State<NodeDetailsScreen> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  NodeRegistrationStatus? _nodeInfo;
  NodeStakeInfo? _stakeInfo;
  RewardInfo? _claimableReward;
  double? _apy;

  @override
  void initState() {
    super.initState();
    _loadNodeData();
  }

  Future<void> _loadNodeData() async {
    setState(() => _isLoading = true);
    
    final kadenaService = context.read<KadenaService>();
    
    try {
      final results = await Future.wait([
        kadenaService.getNodeInfo(widget.peerId),
        kadenaService.getNodeStake(widget.peerId),
        kadenaService.calculateRewards(widget.peerId),
        kadenaService.getAPY(),
      ]);

      _nodeInfo = results[0] as NodeRegistrationStatus?;
      _stakeInfo = results[1] as NodeStakeInfo?;
      _claimableReward = results[2] as RewardInfo?;
      _apy = results[3] as double?;
    } catch (e) {
      debugPrint('Error loading node data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStake() async {
    final walletService = context.read<WalletService>();
    if (!walletService.hasWallet) {
      _showSnackBar('Please create a wallet first', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Stake 50,000 CFLY',
      message: 'Are you sure you want to stake 50,000 CFLY on this node? '
          'You will earn rewards based on the current APY.',
      confirmText: 'Stake',
      confirmColor: Colors.green,
    );

    if (!confirmed) return;

    setState(() => _isActionLoading = true);
    
    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.stakeOnNode(widget.peerId);
    
    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar('Staking transaction submitted successfully!', isSuccess: true);
      await Future.delayed(const Duration(seconds: 2));
      _loadNodeData();
    } else {
      _showSnackBar(kadenaService.error ?? 'Staking failed', isError: true);
    }
  }

  Future<void> _handleUnstake() async {
    final confirmed = await _showConfirmDialog(
      title: 'Unstake from Node',
      message: 'Are you sure you want to unstake from this node? '
          'Your 50,000 CFLY will be returned to your account.',
      confirmText: 'Unstake',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    setState(() => _isActionLoading = true);
    
    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.unstakeFromNode(widget.peerId);
    
    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar('Unstaking transaction submitted successfully!', isSuccess: true);
      await Future.delayed(const Duration(seconds: 2));
      _loadNodeData();
    } else {
      _showSnackBar(kadenaService.error ?? 'Unstaking failed', isError: true);
    }
  }

  Future<void> _handleClaim() async {
    if (_claimableReward == null || _claimableReward!.reward <= 0) {
      _showSnackBar('No rewards to claim', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Claim Rewards',
      message: 'Claim ${_claimableReward!.reward.toStringAsFixed(2)} CFLY in rewards?',
      confirmText: 'Claim',
      confirmColor: CyberTheme.primary(context),
    );

    if (!confirmed) return;

    setState(() => _isActionLoading = true);
    
    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.claimReward(widget.peerId);
    
    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar('Claim transaction submitted successfully!', isSuccess: true);
      await Future.delayed(const Duration(seconds: 2));
      _loadNodeData();
    } else {
      _showSnackBar(kadenaService.error ?? 'Claim failed', isError: true);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final isDark = CyberTheme.isDark(context);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? CyberColors.backgroundCard : CyberColorsLight.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(color: CyberTheme.textPrimary(context)),
        ),
        content: Text(
          message,
          style: TextStyle(color: CyberTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: CyberTheme.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Colors.red 
            : isSuccess 
                ? Colors.green 
                : CyberTheme.primary(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final walletService = context.watch<WalletService>();

    return Scaffold(
      backgroundColor: isDark ? CyberColors.backgroundDark : CyberColorsLight.backgroundLight,
      appBar: AppBar(
        title: const Text('Node Details'),
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
            onPressed: _isLoading ? null : _loadNodeData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nodeInfo == null
              ? _buildNotFound()
              : _buildContent(walletService),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: CyberTheme.textDim(context),
          ),
          const SizedBox(height: 24),
          Text(
            'Node Not Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CyberTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This node could not be found in the network',
            style: TextStyle(
              fontSize: 16,
              color: CyberTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(WalletService walletService) {
    final isActive = _nodeInfo?.isActive ?? false;
    final isStaked = _stakeInfo?.active ?? false;
    final canStake = !isStaked && walletService.hasWallet;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node Info Card
          _buildCard(
            title: 'Node Information',
            icon: Icons.dns,
            iconColor: CyberTheme.primary(context),
            children: [
              _buildInfoRow('Peer ID', widget.peerId, copyable: true),
              _buildInfoRow('Status', isActive ? 'Active' : 'Inactive',
                valueColor: isActive ? Colors.green : Colors.grey),
              _buildInfoRow('Multiaddr', _nodeInfo!.multiaddr, copyable: true),
              _buildInfoRow('Owner', _nodeInfo!.account),
              if (_nodeInfo?.registerDate != null)
                _buildInfoRow('Registered', _nodeInfo!.registerDate!),
            ],
          ),

          const SizedBox(height: 16),

          // Staking Stats Card
          _buildCard(
            title: 'Staking Information',
            icon: Icons.bolt,
            iconColor: Colors.orange,
            children: [
              _buildStatsGrid(),
            ],
          ),

          const SizedBox(height: 16),

          // Actions Card
          if (walletService.hasWallet)
            _buildActionsCard(canStake, isStaked)
          else
            _buildConnectWalletCard(),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final isDark = CyberTheme.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? CyberColors.backgroundCard : CyberColorsLight.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: CyberTheme.textSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      _showSnackBar('Copied to clipboard');
                    }
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? CyberTheme.textPrimary(context),
                        fontFamily: copyable ? 'monospace' : null,
                        fontSize: copyable ? 12 : 14,
                      ),
                    ),
                  ),
                  if (copyable)
                    Icon(
                      Icons.copy,
                      size: 16,
                      color: CyberTheme.textDim(context),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final isStaked = _stakeInfo?.active ?? false;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatBox(
          icon: Icons.bolt,
          label: 'Staking Status',
          value: isStaked ? 'Staked' : 'Not Staked',
          color: isStaked ? Colors.orange : Colors.grey,
        ),
        _buildStatBox(
          icon: Icons.access_time,
          label: 'Days Staked',
          value: _claimableReward?.days.toString() ?? '0',
          color: Colors.purple,
        ),
        _buildStatBox(
          icon: Icons.card_giftcard,
          label: 'Claimable',
          value: '${_claimableReward?.reward.toStringAsFixed(2) ?? '0.00'} CFLY',
          color: CyberTheme.primary(context),
        ),
        _buildStatBox(
          icon: Icons.trending_up,
          label: 'APY',
          value: '${_apy?.toStringAsFixed(2) ?? '0.00'}%',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = CyberTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: CyberTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(bool canStake, bool isStaked) {
    final isDark = CyberTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? CyberColors.backgroundCard : CyberColorsLight.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CyberTheme.primary(context).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CyberTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          
          if (canStake)
            _buildActionButton(
              label: 'Stake 50,000 CFLY',
              icon: Icons.arrow_upward,
              color: Colors.green,
              onPressed: _isActionLoading ? null : _handleStake,
            )
          else if (isStaked) ...[
            _buildActionButton(
              label: 'Unstake',
              icon: Icons.arrow_downward,
              color: Colors.red,
              onPressed: _isActionLoading ? null : _handleUnstake,
            ),
            const SizedBox(height: 12),
            if (_claimableReward != null && _claimableReward!.reward > 0)
              _buildActionButton(
                label: 'Claim ${_claimableReward!.reward.toStringAsFixed(2)} CFLY',
                icon: Icons.card_giftcard,
                color: CyberTheme.primary(context),
                onPressed: _isActionLoading ? null : _handleClaim,
              ),
          ],
          
          if (_isActionLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Processing transaction...',
                style: TextStyle(color: CyberTheme.textSecondary(context)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectWalletCard() {
    final isDark = CyberTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? CyberColors.backgroundCard : CyberColorsLight.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CyberTheme.primary(context).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: CyberTheme.textDim(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Connect Your Wallet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CyberTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your wallet to stake and claim rewards',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CyberTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/wallet'),
            icon: const Icon(Icons.add),
            label: const Text('Create Wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.primary(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
