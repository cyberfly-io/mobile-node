import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/kadena_service.dart';
import '../services/wallet_service.dart';
import '../widgets/pin_input_dialog.dart';
import '../widgets/animated_background.dart';
import '../widgets/ui_components.dart' hide StatusBadge;
import '../theme/theme.dart';

class NodeDetailsScreen extends StatefulWidget {
  final String peerId;

  const NodeDetailsScreen({super.key, required this.peerId});

  @override
  State<NodeDetailsScreen> createState() => _NodeDetailsScreenState();
}

class _NodeDetailsScreenState extends State<NodeDetailsScreen> with TickerProviderStateMixin {
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
    _updateRemainingTime();
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
        'Insufficient balance. Need ${_minStakeCfly.toStringAsFixed(0)} CFLY.',
        isError: true,
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Stake 50,000 CFLY',
      message: 'Are you sure you want to stake 50,000 CFLY on this node?',
      confirmText: 'Stake',
      confirmColor: CyberColors.neonGreen,
    );
    if (!confirmed) return;

    final authService = context.read<AuthService>();
    final authenticated = await authenticateUser(context, authService: authService, reason: 'Authenticate to stake');
    if (!mounted) return;
    if (!authenticated) return;

    setState(() => _isActionLoading = true);
    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.stakeOnNode(widget.peerId);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar('Staking successful!', isSuccess: true);
      _loadNodeData();
    } else {
      _showSnackBar(kadenaService.error ?? 'Staking failed', isError: true);
    }
  }

  Future<void> _handleUnstake() async {
    final confirmed = await _showConfirmDialog(
      title: 'Unstake',
      message: 'Are you sure you want to unstake?',
      confirmText: 'Unstake',
      confirmColor: CyberColors.neonRed,
    );
    if (!confirmed) return;

    final authService = context.read<AuthService>();
    final authenticated = await authenticateUser(context, authService: authService, reason: 'Authenticate to unstake');
    if (!mounted) return;
    if (!authenticated) return;

    setState(() => _isActionLoading = true);
    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.unstakeFromNode(widget.peerId);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar('Unstaking successful!', isSuccess: true);
      _loadNodeData();
    } else {
      _showSnackBar(kadenaService.error ?? 'Unstaking failed', isError: true);
    }
  }

  Future<void> _handleClaim() async {
    if (_claimableReward == null || _claimableReward!.reward <= 0) {
      _showSnackBar('No rewards!', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Claim Rewards',
      message: 'Claim ${_claimableReward!.reward.toStringAsFixed(2)} CFLY?',
      confirmText: 'Claim',
      confirmColor: CyberColors.neonCyan,
    );
    if (!confirmed) return;

    setState(() => _isActionLoading = true);
    final kadenaService = context.read<KadenaService>();
    final success = await kadenaService.claimReward(widget.peerId);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (success) {
      _showSnackBar('Rewards claimed!', isSuccess: true);
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
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: CyberTheme.card(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: confirmColor.withOpacity(0.5))),
            title: Text(title, style: TextStyle(color: CyberTheme.textPrimary(context), fontFamily: 'monospace')),
            content: Text(message, style: TextStyle(color: CyberTheme.textSecondary(context))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.black),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ?? false;
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'monospace')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? CyberTheme.error(context) : isSuccess ? CyberTheme.success(context) : CyberTheme.primary(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<WalletService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              if (_isLoading)
                const SliverFillRemaining(child: Center(child: GlowingProgressIndicator()))
              else if (_nodeInfo == null)
                SliverFillRemaining(child: _buildNotFound())
              else
                _buildSliversContent(context, walletService),
            ],
          ),
          if (_isActionLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: GlowingProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final primaryColor = CyberTheme.primary(context);
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          'NODE DETAILS',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: primaryColor.withOpacity(0.5), blurRadius: 8)],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _loadNodeData,
          color: primaryColor,
        ),
      ],
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dns_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text('Node not found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          NeonButton(text: 'Go Back', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildSliversContent(BuildContext context, WalletService walletService) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildStatusHeader(),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 24),
          _buildStakingStatsSection(),
          const SizedBox(height: 24),
          if (_stakeInfo?.active == true && _nodeInfo?.isActive == true) _buildCountdownSection(),
          const SizedBox(height: 32),
          _buildActionsSection(walletService),
        ]),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final isActive = _nodeInfo?.isActive ?? false;
    return Center(
      child: Column(
        children: [
          StatusBadge(
            status: isActive ? NodeConnectionStatus.online : NodeConnectionStatus.offline,
            label: isActive ? 'NODE ACTIVE' : 'NODE INACTIVE',
          ),
          const SizedBox(height: 12),
          Text(
            widget.peerId.length > 20 ? '${widget.peerId.substring(0, 12)}...${widget.peerId.substring(widget.peerId.length - 8)}' : widget.peerId,
            style: TextStyle(fontFamily: 'monospace', color: CyberTheme.textDim(context), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return NeonGlowCard(
      glowColor: CyberTheme.primary(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('IDENTIFIERS', Icons.fingerprint),
          const SizedBox(height: 16),
          InfoRow(icon: Icons.vpn_key_outlined, label: 'Peer ID', value: widget.peerId, copyable: true),
          InfoRow(icon: Icons.link, label: 'Multiaddr', value: _nodeInfo!.multiaddr, copyable: true),
          InfoRow(icon: Icons.account_circle_outlined, label: 'Owner', value: _nodeInfo!.account, copyable: true),
          if (_nodeInfo?.registerDate != null)
            InfoRow(icon: Icons.calendar_today_outlined, label: 'Registered', value: _nodeInfo!.registerDate!),
        ],
      ),
    );
  }

  Widget _buildStakingStatsSection() {
    final isStaked = _stakeInfo?.active ?? false;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'STAKED AMOUNT',
                value: isStaked ? '50,000' : '0',
                suffix: ' CFLY',
                icon: Icons.lock,
                color: isStaked ? CyberColors.neonGreen : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'CURRENT APY',
                value: _apy?.toStringAsFixed(1) ?? '0.0',
                suffix: '%',
                icon: Icons.trending_up,
                color: CyberColors.neonCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          label: 'CLAIMABLE REWARDS',
          value: _claimableReward?.reward.toStringAsFixed(2) ?? '0.00',
          suffix: ' CFLY',
          icon: Icons.card_giftcard,
          color: (_claimableReward?.reward ?? 0) > 0 ? CyberColors.neonMagenta : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildCountdownSection() {
    if (_claimableReward != null && _claimableReward!.reward > 0) return const SizedBox.shrink();
    if (_remainingTime.inSeconds <= 0) return const SizedBox.shrink();

    return NeonGlowCard(
      glowColor: CyberColors.neonGreen,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PulsingIndicator(color: CyberColors.neonGreen, size: 8),
              const SizedBox(width: 8),
              Text(
                'NEXT REWARD CYCLE',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: CyberColors.neonGreen),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCountdown(_remainingTime),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
          const SizedBox(height: 8),
          Text(
            'Distributed every 6 hours',
            style: TextStyle(fontSize: 11, color: CyberTheme.textDim(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(WalletService walletService) {
    if (!walletService.hasWallet) {
      return NeonGlowCard(
        glowColor: Colors.grey,
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Wallet Required', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Connect your wallet to participate in staking.', textAlign: TextAlign.center, style: TextStyle(color: CyberTheme.textDim(context))),
            const SizedBox(height: 20),
            NeonButton(text: 'Setup Wallet', onPressed: () => Navigator.pushNamed(context, '/wallet')),
          ],
        ),
      );
    }

    final isStaked = _stakeInfo?.active ?? false;
    final hasEnough = (_cflyBalance ?? 0) >= _minStakeCfly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isStaked)
          NeonButton(
            text: 'STAKE 50,000 CFLY',
            icon: Icons.lock_outline,
            color: hasEnough ? CyberColors.neonGreen : Colors.grey,
            onPressed: hasEnough ? _handleStake : null,
          )
        else ...[
          if (_claimableReward != null && _claimableReward!.reward > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeonButton(
                text: 'CLAIM REWARDS',
                icon: Icons.card_giftcard,
                color: CyberColors.neonMagenta,
                onPressed: _handleClaim,
              ),
            ),
          NeonButton(
            text: 'UNSTAKE FUNDS',
            icon: Icons.lock_open,
            color: CyberColors.neonRed,
            onPressed: _handleUnstake,
            outlined: true,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CyberTheme.primary(context)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 2,
            color: CyberTheme.textDim(context),
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeonGlowCard(
      glowColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CyberTheme.textDim(context), letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontFamily: 'monospace', fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                suffix,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
