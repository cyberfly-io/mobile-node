import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'screens/wallet_setup_screen.dart';
import 'screens/node_start_screen.dart';
import 'services/wallet_service.dart';
import 'services/kadena_service.dart';
import 'services/node_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'theme/theme.dart';

/// Fetch public IP address using ip-api.com (same as Rust node)
Future<String?> getPublicIp() async {
  try {
    final response = await http.get(Uri.parse('http://ip-api.com/json/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['query'] as String?;
    }
  } catch (e) {
    debugPrint('Failed to fetch public IP: $e');
  }
  return null;
}

/// Show a snackbar message globally
void showGlobalSnackBar(String message, {bool isError = false, bool isSuccess = false, bool clearPrevious = true}) {
  // Ensure we're on the main thread and the messenger is ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      debugPrint('SnackBar: $message (messenger not ready)');
      return;
    }
    
    if (clearPrevious) {
      messenger.clearSnackBars();
    }
    
    final color = isError 
        ? Colors.red 
        : isSuccess 
            ? const Color(0xFF00FF88) 
            : const Color(0xFF00D9FF);
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : isSuccess ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 3 : 2),
      ),
    );
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CyberflyNodeApp());
}

ThemeMode _getThemeMode(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
}

// Global key for showing snackbars from anywhere
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class CyberflyNodeApp extends StatelessWidget {
  const CyberflyNodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService()),
        ChangeNotifierProvider(create: (_) => NodeService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProxyProvider<WalletService, KadenaService>(
          create: (context) => KadenaService(
            walletService: context.read<WalletService>(),
          ),
          update: (context, walletService, previous) =>
              previous ?? KadenaService(walletService: walletService),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Cyberfly Node',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: CyberFlyTheme.lightTheme,
            darkTheme: CyberFlyTheme.darkTheme,
            themeMode: _getThemeMode(themeService.themeMode),
            home: const AppEntryPoint(),
          );
        },
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

  /// Request notification permission on Android 13+ (API 33+)
  Future<void> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    // Request permission on Android 13+
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('Notification permission granted: $granted');
    }
  }

  Future<void> _initializeApp() async {
    final walletService = context.read<WalletService>();
    final nodeService = context.read<NodeService>();
    final authService = context.read<AuthService>();
    final themeService = context.read<ThemeService>();
    
    // Request notification permission on Android 13+
    await _requestNotificationPermission();
    
    // Initialize auth service and theme service
    await authService.initialize();
    await themeService.initialize();
    
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
      
      // Check if user has started node before
      final hasStartedBefore = prefs.getBool('hasStartedNodeBefore') ?? false;
      
      // Only auto-start if user has started before AND autoStart is enabled
      final autoStart = prefs.getBool('autoStart') ?? true;
      if (hasStartedBefore && autoStart) {
        // Don't block app startup - start node in background
        nodeService.startNode().then((_) async {
          debugPrint('Node auto-started successfully');
          debugPrint('  isRunning: ${nodeService.isRunning}');
          debugPrint('  nodeInfo: ${nodeService.nodeInfo != null}');
          
          // Small delay to ensure state is fully propagated
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Register node to smart contract after successful start
          if (nodeService.isRunning && nodeService.nodeInfo != null) {
            final kadenaService = context.read<KadenaService>();
            
            // Use wallet public key as peerId for registration
            final publicKey = walletService.publicKey;
            if (publicKey == null) {
              debugPrint('Cannot register node: wallet public key not available');
              return;
            }
            
            // Fetch public IP and construct multiaddr as: publickey@publicIp:31001
            final publicIp = await getPublicIp();
            final multiaddr = publicIp != null
                ? '$publicKey@$publicIp:31001'
                : nodeService.nodeInfo!.relayUrl ?? '/p2p/$publicKey';
            
            debugPrint('Registering node to smart contract:');
            debugPrint('  PeerId (publicKey): $publicKey');
            debugPrint('  Multiaddr: $multiaddr');
            
            try {
              final result = await kadenaService.ensureRegistered(publicKey, multiaddr);
              debugPrint('Node registration result: $result');
              
              if (result == 'created') {
                showGlobalSnackBar('✓ Node registered successfully!', isSuccess: true);
              } else if (result == 'activated') {
                showGlobalSnackBar('✓ Node activated successfully!', isSuccess: true);
              } else if (result == 'active') {
                // Node already registered and active - no snackbar needed
                debugPrint('Node already active, skipping snackbar');
              } else {
                final error = kadenaService.error ?? 'Unknown error';
                debugPrint('Registration failed: $error');
                showGlobalSnackBar('Registration failed: $error', isError: true);
              }
              
              // Start auto-claim timer after registration (check rewards every 60 seconds)
              nodeService.startAutoClaimTimer(kadenaService, publicKey);
              debugPrint('Auto-claim timer started for peerId: $publicKey');
            } catch (e) {
              debugPrint('Node registration error: $e');
              showGlobalSnackBar('Registration error: ${e.toString().split('\n').first}', isError: true);
            }
          } else {
            debugPrint('Cannot register: node not running or nodeInfo null');
            debugPrint('  isRunning: ${nodeService.isRunning}');
            debugPrint('  nodeInfo: ${nodeService.nodeInfo}');
          }
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
            
            // Don't auto-start - let NodeStartScreen handle it
          }
          setState(() {
            _hasWallet = true;
          });
        },
      );
    }

    // Check if user has started node before
    return FutureBuilder<bool>(
      future: SharedPreferences.getInstance().then(
        (prefs) => prefs.getBool('hasStartedNodeBefore') ?? false,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final hasStartedBefore = snapshot.data!;
        if (!hasStartedBefore) {
          return const NodeStartScreen();
        }
        
        return const MainScreen();
      },
    );
  }
}
