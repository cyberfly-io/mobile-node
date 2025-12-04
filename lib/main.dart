import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'screens/wallet_setup_screen.dart';
import 'services/wallet_service.dart';
import 'services/kadena_service.dart';
import 'services/node_service.dart';
import 'services/auth_service.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CyberflyNodeApp());
}

class CyberflyNodeApp extends StatelessWidget {
  const CyberflyNodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService()),
        ChangeNotifierProvider(create: (_) => NodeService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<WalletService, KadenaService>(
          create: (context) => KadenaService(
            walletService: context.read<WalletService>(),
          ),
          update: (context, walletService, previous) =>
              previous ?? KadenaService(walletService: walletService),
        ),
      ],
      child: MaterialApp(
        title: 'Cyberfly Node',
        debugShowCheckedModeBanner: false,
        theme: CyberFlyTheme.darkTheme,
        home: const AppEntryPoint(),
      ),
    );
  }
}

/// Entry point that checks wallet status and shows appropriate screen
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _isInitialized = false;
  bool _hasWallet = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization to after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final walletService = context.read<WalletService>();
    final nodeService = context.read<NodeService>();
    final authService = context.read<AuthService>();
    
    // Initialize auth service
    await authService.initialize();
    
    // Load background service preference
    final prefs = await SharedPreferences.getInstance();
    final useBackground = prefs.getBool('runInBackground') ?? true;
    
    // Initialize node service with flutter_rust_bridge
    try {
      await nodeService.initialize(useBackground: useBackground);
      debugPrint('Node service initialized successfully (background: $useBackground)');
    } catch (e) {
      debugPrint('Failed to initialize node service: $e');
      // Continue anyway to show wallet setup screen
    }
    
    final hasWallet = await walletService.initialize();

    // Pass wallet keys to node service if wallet exists
    if (hasWallet && walletService.walletInfo != null) {
      await nodeService.setWalletKeys(
        secretKey: walletService.walletInfo!.secretKey,
        publicKey: walletService.walletInfo!.publicKey,
      );
      
      // Auto-start node (check autoStart preference)
      final autoStart = prefs.getBool('autoStart') ?? true;
      if (autoStart) {
        // Don't block app startup - start node in background
        nodeService.startNode().then((_) {
          debugPrint('Node auto-started successfully');
        }).catchError((e) {
          debugPrint('Failed to auto-start node: $e');
        });
      }
    }

    if (mounted) {
      setState(() {
        _hasWallet = hasWallet;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: CyberColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo with glow
              AnimatedGradientBorder(
                borderRadius: 50,
                gradientColors: const [
                  CyberColors.neonCyan,
                  CyberColors.neonMagenta,
                  CyberColors.neonCyan,
                ],
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CyberColors.cardDark,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'CYBERFLY',
                style: CyberTextStyles.neonTitle.copyWith(
                  fontSize: 28,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Initializing Node...',
                style: CyberTextStyles.body.copyWith(
                  color: CyberColors.textDim,
                ),
              ),
              const SizedBox(height: 24),
              const GlowingProgressIndicator(
                color: CyberColors.neonCyan,
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasWallet) {
      return WalletSetupScreen(
        onWalletCreated: () async {
          // Set wallet keys for node identity
          final walletService = context.read<WalletService>();
          final nodeService = context.read<NodeService>();
          if (walletService.walletInfo != null) {
            await nodeService.setWalletKeys(
              secretKey: walletService.walletInfo!.secretKey,
              publicKey: walletService.walletInfo!.publicKey,
            );
            
            // Start node in background (don't block UI)
            nodeService.startNode().catchError((e) {
              debugPrint('Failed to start node: $e');
            });
          }
          setState(() {
            _hasWallet = true;
          });
        },
      );
    }

    return const MainScreen();
  }
}
