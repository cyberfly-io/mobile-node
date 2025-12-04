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
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Cyberfly Node Service',
      description: 'This channel is used for Cyberfly node background service',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Cyberfly Node',
        initialNotificationContent: 'Initializing...',
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

// Main background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Rust library in background isolate
  await RustLib.init();
  rust_api.initLogging();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String nodeId = '';
  bool isNodeRunning = false;

  // Update notification helper
  void updateNotification(String content) {
    flutterLocalNotificationsPlugin.show(
      notificationId,
      'Cyberfly Node',
      content,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'Cyberfly Node Service',
          icon: 'ic_bg_service_small',
          ongoing: true,
        ),
      ),
    );
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
      updateNotification('Node running: ${nodeId.substring(0, 8)}...');
      service.invoke('update', {
        'type': 'node_started',
        'success': true,
        'nodeId': nodeId,
      });
    } catch (e) {
      updateNotification('Node failed to start');
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
      final autoStart = prefs.getBool('autoStart') ?? true;
      final runInBackground = prefs.getBool('runInBackground') ?? true;
      
      if (!autoStart || !runInBackground) {
        updateNotification('Waiting for app...');
        return;
      }
      
      // Load wallet keys from secure storage
      const secureStorage = FlutterSecureStorage();
      final walletSecretKey = await secureStorage.read(key: 'wallet_secret_key');
      
      if (walletSecretKey == null) {
        updateNotification('No wallet configured');
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
      updateNotification('Auto-start failed');
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
    updateNotification('Stopping node...');
    try {
      await rust_api.stopNode();
      isNodeRunning = false;
      nodeId = '';
      updateNotification('Node stopped');
      service.invoke('update', {
        'type': 'node_stopped',
        'success': true,
      });
    } catch (e) {
      service.invoke('update', {
        'type': 'error',
        'message': e.toString(),
      });
    }
  });

  service.on('get_status').listen((event) async {
    try {
      final status = await rust_api.getNodeStatus();
      service.invoke('update', {
        'type': 'node_status',
        'isRunning': status.isRunning,
        'nodeId': status.nodeId,
        'connectedPeers': status.connectedPeers,
      });

      if (status.isRunning) {
        updateNotification(
            'Peers: ${status.connectedPeers} | ${status.nodeId?.substring(0, 8) ?? ""}...');
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

  // Start periodic status updates
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (isNodeRunning) {
      try {
        final status = await rust_api.getNodeStatus();
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

  updateNotification('Service ready');
  
  // Auto-start node if service started on boot
  autoStartOnBoot();
}
