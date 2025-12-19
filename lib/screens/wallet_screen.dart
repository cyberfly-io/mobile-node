import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/wallet_service.dart';
import '../services/kadena_service.dart';
import '../theme/theme.dart';
import 'send_screen.dart';
import 'stake_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with TickerProviderStateMixin {
  double? _cflyBalance;
  NodeStakeInfo? _stakeInfo;
  bool _isLoadingBalance = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalanceAndStaking();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadBalanceAndStaking() async {
    final walletService = context.read<WalletService>();
    final kadenaService = context.read<KadenaService>();
    
    if (!walletService.hasWallet) return;
    
    setState(() => _isLoadingBalance = true);
    
    try {
      final account = walletService.account;
      final publicKey = walletService.publicKey;
      
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

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(2)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(2)}K';
    }
    return balance.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<WalletService>();
    final isDark = CyberTheme.isDark(context);
    final primaryColor = CyberTheme.primary(context);
    final magentaColor = isDark ? CyberColors.neonMagenta : CyberColorsLight.primaryMagenta;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBalanceAndStaking,
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: magentaColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'WALLET',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.textPrimary(context),
                        letterSpacing: 4,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isLoadingBalance ? null : _loadBalanceAndStaking,
                      icon: _isLoadingBalance 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor,
                              ),
                            )
                          : Icon(Icons.refresh, color: primaryColor),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Balance Card
                _buildMainBalanceCard(context, walletService),
                const SizedBox(height: 16),

                // Account Card
                _buildAccountCard(context, walletService),
                const SizedBox(height: 16),

                // Staking Card
                _buildStakingCard(context),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(context, walletService),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard(BuildContext context, WalletService walletService) {
    final isDark = CyberTheme.isDark(context);
    final primaryColor = CyberTheme.primary(context);

    return NeonGlowCard(
      glowColor: primaryColor,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text(
            'TOTAL BALANCE',
            style: TextStyle(
              fontSize: 12,
              color: CyberTheme.textDim(context),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Text(
                _isLoadingBalance 
                    ? '...' 
                    : _cflyBalance != null 
                        ? '${_formatBalance(_cflyBalance!)} CFLY'
                        : '0.00 CFLY',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  shadows: isDark ? [
                    Shadow(
                      color: primaryColor.withOpacity(0.3 + (_pulseController.value * 0.2)),
                      blurRadius: 10,
                    ),
                  ] : null,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          StatusBadge(
            status: walletService.hasWallet ? NodeConnectionStatus.online : NodeConnectionStatus.offline,
            label: walletService.hasWallet ? 'Connected' : 'Not Connected',
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, WalletService walletService) {
    final primaryColor = CyberTheme.primary(context);

    return NeonGlowCard(
      glowColor: CyberTheme.textSecondary(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'ACCOUNT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textDim(context),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyberTheme.card(context).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CyberTheme.textSecondary(context).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    walletService.account ?? 'No account',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: CyberTheme.textPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
                  icon: Icon(Icons.copy, size: 18, color: primaryColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy Account',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakingCard(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final isStaked = _stakeInfo?.active == true;
    final stakeColor = isStaked 
        ? CyberTheme.success(context)
        : CyberTheme.textDim(context);

    return NeonGlowCard(
      glowColor: stakeColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isStaked ? Icons.lock : Icons.lock_open,
                color: stakeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'STAKING STATUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textDim(context),
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              StatusBadge(
                status: isStaked ? NodeConnectionStatus.online : NodeConnectionStatus.offline,
                label: isStaked ? 'Active' : 'Inactive',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STAKED AMOUNT',
                      style: TextStyle(
                        fontSize: 10,
                        color: CyberTheme.textDim(context),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoadingBalance 
                          ? '...' 
                          : isStaked 
                              ? '${(_stakeInfo!.amount ?? 50000).toStringAsFixed(0)} CFLY'
                              : '0 CFLY',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: stakeColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isStaked && (_cflyBalance ?? 0) >= 50000)
                ElevatedButton.icon(
                  onPressed: _isLoadingBalance ? null : () => _showStakeDialog(context),
                  icon: const Icon(Icons.lock, size: 16),
                  label: const Text('Stake Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.success(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WalletService walletService) {
    final isDark = CyberTheme.isDark(context);
    final magentaColor = isDark ? CyberColors.neonMagenta : CyberColorsLight.primaryMagenta;
    final primaryColor = CyberTheme.primary(context);

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.send,
            label: 'Send',
            color: magentaColor,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SendScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.qr_code,
            label: 'Receive',
            color: primaryColor,
            onPressed: () => _showReceiveDialog(context, walletService),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReceiveDialog(BuildContext context, WalletService walletService) {
    final account = walletService.account ?? '';
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CyberTheme.card(dialogContext),
        title: Row(
          children: [
            Icon(Icons.qr_code, color: CyberTheme.primary(dialogContext)),
            const SizedBox(width: 8),
            Text(
              'Receive CFLY',
              style: TextStyle(color: CyberTheme.textPrimary(dialogContext)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Code with fixed size
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: account.isNotEmpty
                    ? QrImageView(
                        data: account,
                        version: QrVersions.auto,
                        size: 176,
                      )
                    : const Center(child: Text('No address')),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan to receive CFLY tokens',
                style: TextStyle(
                  color: CyberTheme.textSecondary(dialogContext),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              // Account address
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CyberTheme.card(dialogContext),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CyberTheme.textSecondary(dialogContext).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  account,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: CyberTheme.textPrimary(dialogContext),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: account));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Account copied to clipboard'),
                  backgroundColor: CyberTheme.card(context),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.primary(dialogContext),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStakeDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberTheme.card(context),
        title: Row(
          children: [
            Icon(Icons.lock, color: CyberTheme.success(context)),
            const SizedBox(width: 8),
            Text(
              'Stake CFLY',
              style: TextStyle(color: CyberTheme.textPrimary(context)),
            ),
          ],
        ),
        content: Text(
          'Stake 50,000 CFLY to become a node operator and earn rewards.\n\n'
          'Your stake will be locked until you unstake.',
          style: TextStyle(color: CyberTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.success(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Stake 50,000 CFLY'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StakeScreen()),
      );
    }
  }
}
