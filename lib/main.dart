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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00D9FF),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0E21),
          cardTheme: CardThemeData(
            color: const Color(0xFF1D1E33),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0A0E21),
            elevation: 0,
            centerTitle: true,
          ),
        ),
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
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hub_outlined,
                size: 80,
                color: Color(0xFF00D9FF),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                color: Color(0xFF00D9FF),
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
