import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/kadena_service.dart';
import '../services/wallet_service.dart';
import '../widgets/pin_input_dialog.dart';
import '../theme/theme.dart';

class NodeDetailsScreen extends StatefulWidget {
  final String peerId;

  const NodeDetailsScreen({super.key, required this.peerId});

  @override
  State<NodeDetailsScreen> createState() => _NodeDetailsScreenState();
}

class _NodeDetailsScreenState extends State<NodeDetailsScreen> {
  static const double _minStakeCfly = 50000;

  bool _isLoading = true;
  bool _isActionLoading = false;
  NodeRegistrationStatus? _nodeInfo;
  NodeStakeInfo? _stakeInfo;
  RewardInfo? _claimableReward;
  double? _apy;
  double? _cflyBalance;

  // Countdown timer state
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Schedule after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNodeData();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    if (_stakeInfo?.nextClaimTime == null) return;

    // Update immediately
    _updateRemainingTime();

    // Update every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    if (_stakeInfo?.nextClaimTime == null) return;

    final now = DateTime.now();
    final nextClaim = _stakeInfo!.nextClaimTime!;

    if (now.isBefore(nextClaim)) {
      setState(() {
        _remainingTime = nextClaim.difference(now);
      });
    } else {
      setState(() {
        _remainingTime = Duration.zero;
      });
      _countdownTimer?.cancel();
    }
  }

  String _formatCountdown(Duration duration) {
    if (duration.inSeconds <= 0) return '00:00:00';

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  Future<void> _loadNodeData() async {
    setState(() => _isLoading = true);

    final kadenaService = context.read<KadenaService>();
    final walletService = context.read<WalletService>();

    try {
      final results = await Future.wait([
        kadenaService.getNodeInfo(widget.peerId),
        kadenaService.getNodeStake(widget.peerId),
        kadenaService.calculateRewards(widget.peerId),
        kadenaService.getAPY(),
        walletService.hasWallet
            ? kadenaService.getCFLYBalance(walletService.account)
            : Future<double?>.value(null),
      ]);

      _nodeInfo = results[0] as NodeRegistrationStatus?;
      _stakeInfo = results[1] as NodeStakeInfo?;
      _claimableReward = results[2] as RewardInfo?;
      _apy = results[3] as double?;
      _cflyBalance = results[4] as double?;

      // Start countdown timer if stake info is available
      if (_stakeInfo != null && _stakeInfo!.active) {
        _startCountdownTimer();
      }
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

    if ((_cflyBalance ?? 0) < _minStakeCfly) {
      _showSnackBar(
        'Insufficient balance. You need at least ${_minStakeCfly.toStringAsFixed(0)} CFLY to stake.',
        isError: true,
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Stake 50,000 CFLY',
      message:
          'Are you sure you want to stake 50,000 CFLY on this node? '
          'You will earn rewards based on the current APY.',
      confirmText: 'Stake',
      confirmColor: Colors.green,
    );

    if (!confirmed) return;

    // Verify PIN or biometric before staking
    final authService = context.read<AuthService>();
    final authenticated = await authenticateUser(
      context,
      authService: authService,
      reason: 'Authenticate to stake CFLY',
    );
    if (!authenticated || !mounted) return;

    setState(() => _isActionLoading = true);

    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.stakeOnNode(widget.peerId);

    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar(
        'Staking transaction submitted successfully!',
        isSuccess: true,
      );
      await Future.delayed(const Duration(seconds: 2));
      _loadNodeData();
    } else {
      _showSnackBar(kadenaService.error ?? 'Staking failed', isError: true);
    }
  }

  Future<void> _handleUnstake() async {
    final confirmed = await _showConfirmDialog(
      title: 'Unstake from Node',
      message:
          'Are you sure you want to unstake from this node? '
          'Your 50,000 CFLY will be returned to your account.',
      confirmText: 'Unstake',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    // Verify PIN or biometric before unstaking
    final authService = context.read<AuthService>();
    final authenticated = await authenticateUser(
      context,
      authService: authService,
      reason: 'Authenticate to unstake CFLY',
    );
    if (!authenticated || !mounted) return;

    setState(() => _isActionLoading = true);

    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.unstakeFromNode(widget.peerId);

    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar(
        'Unstaking transaction submitted successfully!',
        isSuccess: true,
      );
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
      message:
          'Claim ${_claimableReward!.reward.toStringAsFixed(2)} CFLY in rewards?',
      confirmText: 'Claim',
      confirmColor: CyberTheme.primary(context),
    );

    if (!confirmed) return;

    setState(() => _isActionLoading = true);

    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.claimReward(widget.peerId);

    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar(
        'Claim transaction submitted successfully!',
        isSuccess: true,
      );
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
    final onPrimary = isDark ? Colors.black : Colors.white;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: CyberTheme.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  foregroundColor: onPrimary,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? CyberTheme.error(context)
            : isSuccess
            ? CyberTheme.success(context)
            : CyberTheme.primary(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<WalletService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Node Details'),
        backgroundColor: CyberTheme.appBarBackground(context),
        foregroundColor: CyberTheme.textPrimary(context),
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
                : Icon(Icons.refresh, color: CyberTheme.primary(context)),
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
    final canStake =
        !isStaked && walletService.hasWallet && (_cflyBalance ?? 0) >= _minStakeCfly;

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
              _buildInfoRow(
                'Status',
                isActive ? 'Active' : 'Inactive',
                valueColor: isActive ? Colors.green : Colors.grey,
              ),
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
            children: [_buildStatsGrid()],
          ),

          const SizedBox(height: 16),

          // Next Claim Countdown Card (only show if staked and no claimable rewards)
          if (_stakeInfo?.active == true &&
              _nodeInfo?.isActive == true &&
              (_claimableReward == null || _claimableReward!.reward <= 0) &&
              _remainingTime.inSeconds > 0)
            _buildCountdownCard(),

          if (_stakeInfo?.active == true &&
              _nodeInfo?.isActive == true &&
              (_claimableReward == null || _claimableReward!.reward <= 0) &&
              _remainingTime.inSeconds > 0)
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

  Widget _buildCountdownCard() {
    final isDark = CyberTheme.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
              : [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF2E7D32) : const Color(0xFF43E97B))
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Next Claim Countdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatCountdown(_remainingTime),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rewards can be claimed every 6 hours',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
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
        color: isDark
            ? CyberColors.backgroundCard
            : CyberColorsLight.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
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

  Widget _buildInfoRow(
    String label,
    String value, {
    bool copyable = false,
    Color? valueColor,
  }) {
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
    final hasClaimable = (_claimableReward?.reward ?? 0) > 0;

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
          icon: Icons.card_giftcard,
          label: 'Claimable',
          value:
              '${_claimableReward?.reward.toStringAsFixed(2) ?? '0.00'} CFLY',
          color: hasClaimable ? CyberTheme.primary(context) : Colors.grey,
        ),
        _buildStatBox(
          icon: Icons.trending_up,
          label: 'APY',
          value: '${_apy?.toStringAsFixed(2) ?? '0.00'}%',
          color: Colors.green,
        ),
        _buildStatBox(
          icon: Icons.schedule,
          label: 'Next Claim',
          value: _getNextClaimStatus(),
          color: _getNextClaimColor(),
        ),
      ],
    );
  }

  String _getNextClaimStatus() {
    if (!(_stakeInfo?.active ?? false)) return 'N/A';
    if ((_claimableReward?.reward ?? 0) > 0) return 'Ready!';
    if (_remainingTime.inSeconds <= 0) return 'Ready!';

    // Show short format for stat box
    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${_remainingTime.inSeconds % 60}s';
  }

  Color _getNextClaimColor() {
    if (!(_stakeInfo?.active ?? false)) return Colors.grey;
    if ((_claimableReward?.reward ?? 0) > 0) return Colors.green;
    if (_remainingTime.inSeconds <= 0) return Colors.green;
    return Colors.blue;
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CyberTheme.primary(context).withOpacity(0.3)),
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
              color: CyberTheme.success(context),
              onPressed: _isActionLoading ? null : _handleStake,
            )
          else if (isStaked) ...[
            _buildActionButton(
              label: 'Unstake',
              icon: Icons.arrow_downward,
              color: CyberTheme.error(context),
              onPressed: _isActionLoading ? null : _handleUnstake,
            ),
            const SizedBox(height: 12),
            if (_claimableReward != null && _claimableReward!.reward > 0)
              _buildActionButton(
                label:
                    'Claim ${_claimableReward!.reward.toStringAsFixed(2)} CFLY',
                icon: Icons.card_giftcard,
                color: CyberTheme.primary(context),
                onPressed: _isActionLoading ? null : _handleClaim,
              ),
          ],

          if (_isActionLoading) ...[
            const SizedBox(height: 16),
            Center(
              child: CircularProgressIndicator(
                color: CyberTheme.primary(context),
              ),
            ),
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
    final onPrimary = CyberTheme.isDark(context) ? Colors.black : Colors.white;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: onPrimary,
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
        color: isDark
            ? CyberColors.backgroundCard
            : CyberColorsLight.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CyberTheme.primary(context).withOpacity(0.3)),
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
            style: TextStyle(color: CyberTheme.textSecondary(context)),
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
