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
          // Theme-aware gradient background
          Container(
            decoration: BoxDecoration(
              gradient: isDark 
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF0A0A1A),
                        Color(0xFF0D1B2A),
                        Color(0xFF1B0A28),
                        Color(0xFF0A0A1A),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.3, 0.7, 1.0],
                    )
                  : const LinearGradient(
                      colors: [
                        Color(0xFFF8FAFF),
                        Color(0xFFEEF2FF),
                        Color(0xFFF5F0FF),
                        Color(0xFFF8FAFF),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.3, 0.7, 1.0],
                    ),
            ),
          ),
          
          // Subtle glow overlays (different for light/dark)
          if (isDark) ...[
            // Purple glow for dark mode
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9D00FF).withOpacity(0.15),
                      const Color(0xFF9D00FF).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Cyan glow for dark mode
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00A3FF).withOpacity(0.1),
                      const Color(0xFF00A3FF).withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Subtle cyan accent for light mode
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0097A7).withOpacity(0.08),
                      const Color(0xFF0097A7).withOpacity(0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle purple accent for light mode
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6A1B9A).withOpacity(0.05),
                      const Color(0xFF6A1B9A).withOpacity(0.01),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          // Cyberpunk animated background with matrix rain (dark mode only)
          // Wrapped in RepaintBoundary to isolate repaints
          if (isDark) ...[
            const RepaintBoundary(
              child: MatrixRainBackground(
                columns: 15,
                speed: 0.8,
                opacity: 0.08,
              ),
            ),

            // Hex grid overlay
            const RepaintBoundary(
              child: HexGridBackground(
                hexSize: 50,
                opacity: 0.03,
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
                    // Refresh button with rotation animation
                    if (nodeService.isRunning)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(
                              opacity: value,
                              child: IconButton(
                                onPressed: () => nodeService.refreshStatus(),
                                icon: Icon(Icons.refresh, color: CyberTheme.primary(context)),
                                tooltip: 'Refresh',
                              ),
                            ),
                          );
                        },
                      )
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Floating logo animation
                        FloatingAnimation(
                          floatHeight: 4,
                          duration: const Duration(seconds: 3),
                          child: Hero(
                            tag: 'app_logo',
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 28,
                              height: 28,
                            ),
                          ),
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
                        // Wallet card with staggered animation
                        AnimatedListItem(
                          index: 0,
                          child: _buildWalletCard(context, walletService),
                        ),

                        const SizedBox(height: 16),

                        // Node info card with staggered animation
                        if (nodeService.nodeInfo != null)
                          AnimatedListItem(
                            index: 1,
                            child: Hero(
                              tag: 'node_info_card',
                              child: NodeInfoCard(
                                nodeInfo: nodeService.nodeInfo!,
                                uptimeSeconds: nodeService.status.uptimeSeconds,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Status indicator with staggered animation
                        AnimatedListItem(
                          index: 2,
                          child: StatusIndicator(
                            status: nodeService.status,
                            isStarting: nodeService.isStarting,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Stats grid with staggered animation
                        AnimatedListItem(
                          index: 3,
                          child: _buildStatsGrid(context, nodeService),
                        ),

                        const SizedBox(height: 24),

                        // Peers section - always show
                        if (nodeService.isRunning) ...[
                          AnimatedListItem(
                            index: 4,
                            child: Text(
                              'CONNECTED PEERS',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: CyberTheme.primary(context),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Peer summary bar
                          if (nodeService.peers.isNotEmpty)
                            AnimatedListItem(
                              index: 5,
                              child: _buildPeerSummary(context, nodeService.peers),
                            ),
                          const SizedBox(height: 12),
                          AnimatedListItem(
                            index: 6,
                            child: nodeService.peers.isEmpty
                                ? _buildEmptyPeersCard(context)
                                : PeerList(peers: nodeService.peers),
                          ),
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
          
          // Action buttons
          const SizedBox(height: 12),
          
          // Send and Stake buttons
          Row(
            children: [
              // Send/Transfer button
              Expanded(
                child: _buildActionButton(
                  context,
                  label: 'Send',
                  icon: Icons.send,
                  color: magentaColor,
                  onPressed: _isLoadingBalance ? null : () => _showTransferDialog(context),
                ),
              ),
              const SizedBox(width: 8),
              // Stake button (only if not already staked)
              if (_stakeInfo?.active != true)
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Stake',
                    icon: Icons.lock,
                    color: CyberTheme.success(context),
                    onPressed: _isLoadingBalance ? null : () => _showStakeDialog(context),
                  ),
                ),
              if (_stakeInfo?.active != true) const SizedBox(width: 8),
              // Refresh button
              IconButton(
                onPressed: _isLoadingBalance ? null : _loadBalanceAndStaking,
                icon: _isLoadingBalance 
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      )
                    : Icon(Icons.refresh, size: 18, color: primaryColor),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _showStakeDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberTheme.card(context),
        title: Text(
          'Stake 50,000 CFLY',
          style: TextStyle(color: CyberTheme.textPrimary(context)),
        ),
        content: Text(
          'Are you sure you want to stake 50,000 CFLY on your node? '
          'This will lock your tokens until you unstake.',
          style: TextStyle(color: CyberTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: CyberTheme.textDim(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.success(context),
            ),
            child: const Text('Stake'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performStake();
    }
  }

  Future<void> _showTransferDialog(BuildContext context) async {
    final recipientController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = CyberTheme.isDark(context);
    final magentaColor = isDark ? CyberColors.neonMagenta : CyberColorsLight.primaryMagenta;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberTheme.card(context),
        title: Row(
          children: [
            Icon(Icons.send, color: magentaColor, size: 24),
            const SizedBox(width: 12),
            Text(
              'Send CFLY',
              style: TextStyle(color: CyberTheme.textPrimary(context)),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: recipientController,
                style: TextStyle(
                  color: CyberTheme.textPrimary(context),
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  labelText: 'Recipient Address',
                  labelStyle: TextStyle(color: CyberTheme.textDim(context)),
                  hintText: 'k:...',
                  hintStyle: TextStyle(color: CyberTheme.textDim(context).withOpacity(0.5)),
                  prefixIcon: Icon(Icons.person, color: magentaColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: magentaColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: magentaColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: magentaColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter recipient address';
                  }
                  if (!value.startsWith('k:') || value.length < 66) {
                    return 'Invalid Kadena address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  color: CyberTheme.textPrimary(context),
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: CyberTheme.textDim(context)),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: CyberTheme.textDim(context).withOpacity(0.5)),
                  prefixIcon: Icon(Icons.token, color: magentaColor),
                  suffixText: 'CFLY',
                  suffixStyle: TextStyle(
                    color: magentaColor,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: magentaColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: magentaColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: magentaColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Invalid amount';
                  }
                  if (_cflyBalance != null && amount > _cflyBalance!) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Balance hint
              if (_cflyBalance != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available: ${_formatBalance(_cflyBalance!)} CFLY',
                    style: TextStyle(
                      fontSize: 12,
                      color: CyberTheme.textDim(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: CyberTheme.textDim(context))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'recipient': recipientController.text.trim(),
                  'amount': double.parse(amountController.text.trim()),
                });
              }
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: magentaColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await _performTransfer(
        toAccount: result['recipient'] as String,
        amount: result['amount'] as double,
      );
    }
  }

  Future<void> _performTransfer({
    required String toAccount,
    required double amount,
  }) async {
    final kadenaService = context.read<KadenaService>();

    setState(() => _isLoadingBalance = true);

    try {
      final success = await kadenaService.transferCFLY(
        toAccount: toAccount,
        amount: amount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Transfer of ${amount.toStringAsFixed(2)} CFLY submitted!' 
                  : 'Transfer failed: ${kadenaService.error}',
              style: TextStyle(color: CyberTheme.textPrimary(context)),
            ),
            backgroundColor: success ? CyberTheme.success(context) : CyberTheme.error(context),
          ),
        );

        // Reload balance after transfer
        if (success) {
          await _loadBalanceAndStaking();
        } else {
          setState(() => _isLoadingBalance = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: CyberTheme.error(context),
          ),
        );
      }
    }
  }

  Future<void> _performStake() async {
    final walletService = context.read<WalletService>();
    final kadenaService = context.read<KadenaService>();
    final publicKey = walletService.publicKey;
    
    if (publicKey == null) return;

    setState(() => _isLoadingBalance = true);

    try {
      final success = await kadenaService.stakeOnNode(publicKey);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Stake transaction submitted!' : 'Stake failed: ${kadenaService.error}',
              style: TextStyle(color: CyberTheme.textPrimary(context)),
            ),
            backgroundColor: success ? CyberTheme.success(context) : CyberTheme.error(context),
          ),
        );
        
        // Reload balance and staking info
        await _loadBalanceAndStaking();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: CyberTheme.error(context),
          ),
        );
      }
    }
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
          title: 'Latency Checks',
          value: status.latencyRequestsSent.toString(),
          icon: Icons.speed,
          color: CyberTheme.isDark(context) ? CyberColors.neonMagenta : CyberColorsLight.primaryMagenta,
          subtitle: '${status.latencyResponsesReceived} responses',
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildPeerSummary(BuildContext context, List<PeerInfo> peers) {
    final isDark = CyberTheme.isDark(context);
    final primaryColor = CyberTheme.primary(context);
    final successColor = CyberTheme.success(context);
    
    // Calculate stats
    final mobileCount = peers.where((p) => p.isMobile).length;
    final desktopCount = peers.length - mobileCount;
    
    // Get unique regions
    final regions = <String>{};
    for (final peer in peers) {
      if (peer.region != null && peer.region!.isNotEmpty) {
        regions.add(peer.region!);
      }
    }
    
    // Calculate average latency
    final peersWithLatency = peers.where((p) => p.latencyMs != null).toList();
    final avgLatency = peersWithLatency.isEmpty 
        ? 0 
        : (peersWithLatency.map((p) => p.latencyMs!).reduce((a, b) => a + b) / peersWithLatency.length).round();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.05)
            : CyberColorsLight.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : CyberColorsLight.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPeerStat(
            context,
            icon: Icons.phone_android,
            label: 'Mobile',
            value: mobileCount.toString(),
            color: primaryColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.white.withOpacity(0.1) : CyberColorsLight.divider,
          ),
          _buildPeerStat(
            context,
            icon: Icons.computer,
            label: 'Desktop',
            value: desktopCount.toString(),
            color: successColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.white.withOpacity(0.1) : CyberColorsLight.divider,
          ),
          _buildPeerStat(
            context,
            icon: Icons.public,
            label: 'Regions',
            value: regions.length.toString(),
            color: CyberTheme.warning(context),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.white.withOpacity(0.1) : CyberColorsLight.divider,
          ),
          _buildPeerStat(
            context,
            icon: Icons.speed,
            label: 'Avg Latency',
            value: avgLatency > 0 ? '${avgLatency}ms' : 'N/A',
            color: isDark ? CyberColors.neonMagenta : CyberColorsLight.primaryMagenta,
          ),
        ],
      ),
    );
  }

  Widget _buildPeerStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = CyberTheme.isDark(context);
    final textColor = isDark ? Colors.white : CyberColorsLight.textPrimary;
    final secondaryColor = isDark ? Colors.white.withOpacity(0.5) : CyberColorsLight.textSecondary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
