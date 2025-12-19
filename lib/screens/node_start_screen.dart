import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/node_service.dart';
import '../services/kadena_service.dart';
import '../services/wallet_service.dart';
import '../theme/theme.dart';
import '../main.dart';
import 'main_screen.dart';

/// Welcome screen shown on first launch after wallet setup
/// Prompts user to explicitly start the node
class NodeStartScreen extends StatefulWidget {
  const NodeStartScreen({super.key});

  @override
  State<NodeStartScreen> createState() => _NodeStartScreenState();
}

class _NodeStartScreenState extends State<NodeStartScreen>
    with TickerProviderStateMixin {
  bool _isStarting = false;
  bool _isStarted = false;
  String _statusText = '';
  late AnimationController _pulseController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<bool> _showTermsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAccepted = prefs.getBool('termsAccepted') ?? false;
    if (alreadyAccepted) return true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _TermsBottomSheet(),
    );

    if (result == true) {
      await prefs.setBool('termsAccepted', true);
      return true;
    }
    return false;
  }

  Future<void> _startNode() async {
    if (_isStarting) return;

    // Show terms dialog first
    final accepted = await _showTermsDialog();
    if (!accepted) {
      return;
    }

    setState(() {
      _isStarting = true;
      _statusText = 'Initializing node...';
    });

    final nodeService = context.read<NodeService>();
    final kadenaService = context.read<KadenaService>();
    final walletService = context.read<WalletService>();

    try {
      // Start the node (use direct mode for initial start)
      setState(() => _statusText = 'Starting Cyberfly node...');
      await nodeService.startNode(forceDirectMode: true);

      // Wait for node to be fully running
      await Future.delayed(const Duration(seconds: 2));

      if (nodeService.isRunning && nodeService.nodeInfo != null) {
        setState(() => _statusText = 'Connecting to network...');
        await Future.delayed(const Duration(seconds: 2));

        // Register node to smart contract
        final publicKey = walletService.publicKey;
        if (publicKey != null) {
          setState(() => _statusText = 'Registering to network...');

          // Fetch public IP and construct multiaddr
          final publicIp = await getPublicIp();
          final multiaddr = publicIp != null
              ? '$publicKey@$publicIp:31001'
              : nodeService.nodeInfo!.relayUrl ?? '/p2p/$publicKey';

          try {
            final result = await kadenaService.ensureRegistered(publicKey, multiaddr);
            debugPrint('Node registration result: $result');

            // Start auto-claim timer
            nodeService.startAutoClaimTimer(kadenaService, publicKey);
          } catch (e) {
            debugPrint('Registration error (non-fatal): $e');
          }
        }

        // Mark first start complete
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasStartedNodeBefore', true);

        setState(() {
          _statusText = 'Node started successfully!';
          _isStarted = true;
        });

        // Navigate to main screen after brief delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        throw Exception('Node failed to start');
      }
    } catch (e) {
      debugPrint('Failed to start node: $e');
      if (mounted) {
        setState(() {
          _isStarting = false;
          _statusText = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start node: ${e.toString()}'),
            backgroundColor: CyberColors.neonRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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

          // Animated background effects (dark mode only)
          if (isDark) ...[
            // Purple glow
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
                      const Color(0xFF9D00FF).withOpacity(0.2),
                      const Color(0xFF9D00FF).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Cyan glow
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
                      const Color(0xFF00A3FF).withOpacity(0.15),
                      const Color(0xFF00A3FF).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with animated glow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                CyberTheme.primary(context).withOpacity(
                                  0.1 + (_pulseController.value * 0.2),
                                ),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CyberTheme.primary(context).withOpacity(
                                  0.3 * _pulseController.value,
                                ),
                                blurRadius: 40 + (_pulseController.value * 20),
                                spreadRadius: 5 * _pulseController.value,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CyberTheme.card(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CyberTheme.primary(context).withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 100,
                              height: 100,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      'CYBERFLY',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.primary(context),
                        letterSpacing: 8,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'DECENTRALIZED P2P NETWORK',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: CyberTheme.textDim(context),
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Welcome message
                    NeonGlowCard(
                      glowColor: CyberTheme.primary(context),
                      animate: !_isStarting,
                      child: Column(
                        children: [
                          Icon(
                            Icons.rocket_launch,
                            color: CyberTheme.primary(context),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to Cyberfly',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CyberTheme.textPrimary(context),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join the decentralized network by running a node and get utility token CFLY.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: CyberTheme.textSecondary(context),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Features list
                          _buildFeatureItem(
                            context,
                            icon: Icons.security,
                            text: 'Secure P2P connections',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            context,
                            icon: Icons.sync,
                            text: 'Real-time data synchronization',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            context,
                            icon: Icons.token,
                            text: 'Get utility token CFLY',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Status text (shown during startup)
                    if (_statusText.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CyberTheme.primary(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _statusText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: CyberTheme.primary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Start button
                    if (!_isStarting && !_isStarted)
                      ScaleTransition(
                        scale: _scaleController,
                        child: SizedBox(
                          width: double.infinity,
                          child: NeonButton(
                            text: 'START NODE',
                            icon: Icons.play_arrow,
                            color: CyberTheme.primary(context),
                            onPressed: () {
                              _scaleController.forward().then((_) {
                                _scaleController.reverse();
                              });
                              _startNode();
                            },
                          ),
                        ),
                      ),

                    // Success indicator
                    if (_isStarted) ...[
                      Icon(
                        Icons.check_circle,
                        color: CyberColors.neonGreen,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Node Running',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CyberColors.neonGreen,
                          letterSpacing: 1,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Info text
                    if (!_isStarting)
                      Text(
                        'A persistent notification will appear when your node is running',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: CyberTheme.textDim(context),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context,
      {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          color: CyberTheme.primary(context),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: CyberTheme.textSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// Terms and Conditions / Privacy Policy Bottom Sheet
class _TermsBottomSheet extends StatefulWidget {
  @override
  State<_TermsBottomSheet> createState() => _TermsBottomSheetState();
}

class _TermsBottomSheetState extends State<_TermsBottomSheet> {
  bool _hasScrolledToEnd = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToEnd) {
        setState(() => _hasScrolledToEnd = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: CyberColors.neonPurple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CyberTheme.textSecondary(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.policy_outlined,
                  color: CyberTheme.primary(context),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Terms & Privacy Policy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Terms of Service'),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'By using Cyberfly Node, you agree to the following terms:',
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'You are solely responsible for your wallet and private keys.',
                  ),
                  _buildBulletPoint(
                    'The node participates in a decentralized network and may relay data from other peers.',
                  ),
                  _buildBulletPoint(
                    'You agree not to use this software for any illegal activities.',
                  ),
                  _buildBulletPoint(
                    'The software is provided "as is" without warranty of any kind.',
                  ),
                  _buildBulletPoint(
                    'We are not liable for any damages arising from the use of this software.',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Privacy Policy'),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'Your privacy is important to us. Here\'s how we handle your data:',
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'Your wallet keys are stored locally on your device and never transmitted to our servers.',
                  ),
                  _buildBulletPoint(
                    'The node connects to the Cyberfly P2P network to sync data.',
                  ),
                  _buildBulletPoint(
                    'Your public key may be visible to other peers on the network.',
                  ),
                  _buildBulletPoint(
                    'We do not collect personal information beyond what is necessary for the network to operate.',
                  ),
                  _buildBulletPoint(
                    'Network activity logs may be stored locally for debugging purposes.',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Network Participation'),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'By running a Cyberfly Node, you:',
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'Contribute computing resources to the decentralized network.',
                  ),
                  _buildBulletPoint(
                    'May earn rewards for validating and relaying data.',
                  ),
                  _buildBulletPoint(
                    'Agree to maintain a stable internet connection for optimal performance.',
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      _hasScrolledToEnd
                          ? '✓ You\'ve read the terms'
                          : '↓ Scroll to read all terms',
                      style: TextStyle(
                        fontSize: 12,
                        color: _hasScrolledToEnd
                            ? CyberColors.neonGreen
                            : CyberTheme.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0A1420)
                  : Colors.grey.shade100,
              border: Border(
                top: BorderSide(
                  color: CyberTheme.textSecondary(context).withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CyberTheme.textSecondary(context),
                      side: BorderSide(
                        color: CyberTheme.textSecondary(context).withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _hasScrolledToEnd
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberColors.neonPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          CyberColors.neonPurple.withOpacity(0.3),
                      disabledForegroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accept & Continue',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: CyberTheme.primary(context),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: CyberTheme.textSecondary(context),
        height: 1.5,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: CyberTheme.primary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: CyberTheme.textSecondary(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
