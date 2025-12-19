import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../src/rust/api.dart' as rust_api;
import '../src/rust/frb_generated.dart';

const notificationChannelId = 'cyberfly_node_channel';
const notificationId = 888;

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Create notification channel for Android
    // Note: Importance.low is required for ongoing foreground service notifications
    // to be non-intrusive but still visible. The notification cannot be dismissed
    // because it's tied to a foreground service (isForegroundMode: true).
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Cyberfly Node Running',
      description: 'Syncing decentralized data with the Cyberfly network',
      importance: Importance.low,
      showBadge: false, // Disable badge for ongoing service
      enableLights: true,
      ledColor: Color(0xFF00D9FF),
      playSound: false, // Silent notification
      enableVibration: false, // No vibration
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Don't auto-start, we start manually when needed
        autoStartOnBoot: true, // Still allow boot start for subsequent launches
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Cyberfly Node Running',
        initialNotificationContent: 'Starting up...',
        foregroundServiceNotificationId: notificationId,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    _isInitialized = true;
  }

  Future<bool> startService() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _service.startService();
  }

  Future<void> stopService() async {
    final isRunning = await _service.isRunning();
    if (isRunning) {
      _service.invoke('stop');
    }
  }

  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  Stream<Map<String, dynamic>?> get onDataReceived {
    return _service.on('update');
  }

  void sendToService(String method, [Map<String, dynamic>? data]) {
    _service.invoke(method, data);
  }
}

// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// Notification action handler
@pragma('vm:entry-point')
void onNotificationResponse(NotificationResponse details) async {
  if (details.actionId == 'stop_service') {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }
}

// Main background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // IMPORTANT: Set as foreground service immediately
  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  // Initialize flutter_local_notifications for action handling
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: onNotificationResponse,
  );

  // IMMEDIATELY show our persistent notification
  // This overwrites the default dismissible one from flutter_background_service
  if (service is AndroidServiceInstance) {
    // Initial call to set up the method channel structure
    // We call the method directly because updateNotification is defined inside onStart scope 
    // but we can't easily call it before it's defined. 
    // Wait, updateNotification is a local function definition? 
    // No, it's defined below. We can hoisting call it or move definition up?
    // Dart functions are hoisted? No.
    // Let's just create a separate minimal show call here for speed.
    
    // Actually, let's just use the function defined below, Dart supports calling closure/local functions 
    // if they are in scope. But wait, updateNotification is defined inside onStart?
    // Yes, the file structure shows onStart is a top level function, and updateNotification is defined INSIDE it 
    // (Wait, no, looking at indentation, updateNotification seems to be inside onStart? 
    // Let me check the file structure carefully).
    
    // Checking file structure from previous reads:
    // void onStart(ServiceInstance service) async { ... }
    // Inside onStart, there are helper functions defined? 
    // Line 138:   void updateNotification(String content) { ... }
    // Yes, it's a local function.
    
    // So we can just call it after definition or move definition up.
    // Since we are editing the file, let's ensure we call it AFTER definition or move it.
    // I will add the call at the end of onStart, or after the function definition.
  }
  
  // Initialize Rust library in background isolate
  await RustLib.init();
  rust_api.initLogging();

  // Define vars...
  String nodeId = '';
  // ...

  bool isNodeRunning = false;
  int connectedPeers = 0;
  int uptimeSeconds = 0;

  // Format uptime for display
  String formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }

  // Update foreground service notification
  void updateNotification(String content) async {
    if (service is AndroidServiceInstance) {
      // We ONLY use flutter_local_notifications to manage the notification.
      // We do NOT call service.setForegroundNotificationInfo because that might
      // reset the notification to a dismissible state without our custom flags.
      
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

      // Define the "Stop" action
      // Note: We use a distinctive icon for the action if possible, otherwise none
      const AndroidNotificationAction stopAction = AndroidNotificationAction(
        'stop_service', 
        'Stop Node',
        showsUserInterface: false, // Don't open app, just handle bg action
        cancelNotification: false, // Don't auto cancel, we'll handle it
      );

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        notificationChannelId,
        'Cyberfly Node Running',
        channelDescription: 'Syncing decentralized data with the Cyberfly network',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // DISABLE SWIPE TO CLOSE
        autoCancel: false,
        showWhen: false,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        actions: [stopAction],
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await notifications.show(
          notificationId,
          'Cyberfly Node Running',
          content,
          notificationDetails,
        );
        // Ensure the notification is set as the foreground service notification to prevent swipe dismissal
        await service.setForegroundNotificationInfo(
          title: 'Cyberfly Node Running',
          content: content,
        );
    }
  }

  // Update notification with current status
  void updateStatusNotification() {
    if (isNodeRunning) {
      final peerText = connectedPeers == 1 ? 'peer' : 'peers';
      updateNotification(
        'Syncing form decentralized data • $connectedPeers $peerText connected',
      );
    } else {
      updateNotification('Node stopped • Tap to restart');
    }
  }

  // Helper function to start the node
  Future<void> startNodeWithConfig({
    String? dataDir,
    String? walletSecretKey,
    List<String> bootstrapPeers = const [],
  }) async {
    if (isNodeRunning) return;

    updateNotification('Starting node...');
    try {
      final info = await rust_api.startNode(
        dataDir: dataDir ?? '',
        walletSecretKey: walletSecretKey,
        bootstrapPeers: bootstrapPeers,
      );

      nodeId = info.nodeId;
      isNodeRunning = true;
      uptimeSeconds = 0;
      updateNotification('Syncing decentralized data • 0 peers connected');
      service.invoke('update', {
        'type': 'node_started',
        'success': true,
        'nodeId': nodeId,
      });
    } catch (e) {
      updateNotification('❌ Node failed to start');
      service.invoke('update', {
        'type': 'node_started',
        'success': false,
        'error': e.toString(),
      });
    }
  }

  // Auto-start node on boot if configured
  Future<void> autoStartOnBoot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user has started node before (first-time users go through NodeStartScreen)
      final hasStartedBefore = prefs.getBool('hasStartedNodeBefore') ?? false;
      if (!hasStartedBefore) {
        updateNotification('⏳ Waiting for first start...');
        return;
      }
      
      final autoStart = prefs.getBool('autoStart') ?? true;
      final runInBackground = prefs.getBool('runInBackground') ?? true;

      if (!autoStart || !runInBackground) {
        updateNotification('⏳ Waiting for app...');
        return;
      }

      // Load wallet keys from secure storage
      const secureStorage = FlutterSecureStorage();
      final walletSecretKey = await secureStorage.read(
        key: 'wallet_secret_key',
      );

      if (walletSecretKey == null) {
        updateNotification('⚠️ No wallet configured');
        return;
      }

      // Get data directory
      final appDir = await getApplicationDocumentsDirectory();
      final dataDir = '${appDir.path}/cyberfly_node';

      // Load bootstrap peers from preferences
      final bootstrapPeersJson = prefs.getStringList('bootstrapPeers') ?? [];

      debugPrint('Background service auto-starting node...');
      await startNodeWithConfig(
        dataDir: dataDir,
        walletSecretKey: walletSecretKey,
        bootstrapPeers: bootstrapPeersJson,
      );
    } catch (e) {
      debugPrint('Auto-start failed: $e');
      updateNotification('❌ Auto-start failed');
    }
  }

  // Handle commands from the app
  service.on('start_node').listen((event) async {
    if (event == null) return;
    final dataDir = event['dataDir'] as String?;
    final walletSecretKey = event['walletSecretKey'] as String?;
    final bootstrapPeers =
        (event['bootstrapPeers'] as List<dynamic>?)?.cast<String>() ?? [];

    await startNodeWithConfig(
      dataDir: dataDir,
      walletSecretKey: walletSecretKey,
      bootstrapPeers: bootstrapPeers,
    );
  });

  service.on('stop_node').listen((event) async {
    updateNotification('⏹️ Stopping node...');
    try {
      await rust_api.stopNode();
      isNodeRunning = false;
      nodeId = '';
      connectedPeers = 0;
      uptimeSeconds = 0;
      updateNotification('🔴 Node stopped');
      service.invoke('update', {'type': 'node_stopped', 'success': true});
    } catch (e) {
      service.invoke('update', {'type': 'error', 'message': e.toString()});
    }
  });

  service.on('update_notification').listen((event) async {
    if (event == null) return;
    final title = event['title'] as String?;
    final content = event['content'] as String?;
    if (content != null) {
      updateNotification(content);
    }
  });

  service.on('get_status').listen((event) async {
    try {
      final status = await rust_api.getNodeStatus();
      connectedPeers = status.connectedPeers;
      uptimeSeconds = status.uptimeSeconds.toInt();
      service.invoke('update', {
        'type': 'node_status',
        'isRunning': status.isRunning,
        'nodeId': status.nodeId,
        'connectedPeers': status.connectedPeers,
      });

      if (status.isRunning) {
        updateStatusNotification();
      }
    } catch (e) {
      debugPrint('Error getting status: $e');
    }
  });

  service.on('send_gossip').listen((event) async {
    if (event == null) return;
    final topic = event['topic'] as String;
    final message = event['message'] as String;
    try {
      await rust_api.sendGossip(topic: topic, message: message);
    } catch (e) {
      debugPrint('Error sending gossip: $e');
    }
  });

  service.on('stop').listen((event) async {
    // Stop the node before stopping service
    if (isNodeRunning) {
      try {
        await rust_api.stopNode();
      } catch (e) {
        debugPrint('Error stopping node: $e');
      }
      // Give it a moment to clean up
      await Future.delayed(const Duration(seconds: 2));
    }
    service.stopSelf();
  });

  // Start periodic status updates and notification refresh
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (isNodeRunning) {
      try {
        final status = await rust_api.getNodeStatus();
        connectedPeers = status.connectedPeers;
        uptimeSeconds = status.uptimeSeconds.toInt();

        // Update notification with current status
        updateStatusNotification();

        service.invoke('update', {
          'type': 'node_status',
          'isRunning': status.isRunning,
          'connectedPeers': status.connectedPeers,
        });
      } catch (e) {
        debugPrint('Error getting periodic status: $e');
      }
    }
  });

  updateNotification('🔄 Service ready');

  // Auto-start node if service started on boot
  autoStartOnBoot();
}
