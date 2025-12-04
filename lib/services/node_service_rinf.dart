import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../src/bindings/bindings.dart';
import 'background_service.dart';

/// Peer info model for UI
class PeerInfo {
  final String nodeId;
  final DateTime lastSeen;
  final String? address;
  final bool isConnected;
  final int? latencyMs;

  PeerInfo({
    required this.nodeId,
    required this.lastSeen,
    this.address,
    this.isConnected = false,
    this.latencyMs,
  });

  factory PeerInfo.fromSignal(PeerInfoPiece piece) {
    return PeerInfo(
      nodeId: piece.nodeId,
      lastSeen: DateTime.tryParse(piece.lastSeen) ?? DateTime.now(),
      address: piece.address,
      isConnected: true,
    );
  }
}

/// Node info model for UI
class NodeInfo {
  final String nodeId;
  final String publicKey;
  final String? relayUrl;
  final List<String> localAddrs;
  final String version;

  NodeInfo({
    required this.nodeId,
    required this.publicKey,
    this.relayUrl,
    required this.localAddrs,
    this.version = '0.1.0',
  });

  factory NodeInfo.fromSignal(NodeStartedResponse signal) {
    return NodeInfo(
      nodeId: signal.nodeId,
      publicKey: signal.publicKey,
      relayUrl: signal.relayUrl,
      localAddrs: signal.localAddrs,
    );
  }

  factory NodeInfo.fromInfoSignal(NodeInfoResponse signal) {
    return NodeInfo(
      nodeId: signal.nodeId,
      publicKey: signal.publicKey,
      relayUrl: signal.relayUrl,
      localAddrs: signal.localAddrs,
    );
  }
}

/// Node status model for UI
class NodeStatus {
  final bool isRunning;
  final int connectedPeers;
  final int discoveredPeers;
  final int uptimeSeconds;
  final String health;
  final int gossipMessagesReceived;
  final int storageSizeBytes;
  final int totalKeys;
  final int totalOperations;

  NodeStatus({
    required this.isRunning,
    required this.connectedPeers,
    required this.discoveredPeers,
    required this.uptimeSeconds,
    required this.health,
    required this.gossipMessagesReceived,
    required this.storageSizeBytes,
    required this.totalKeys,
    required this.totalOperations,
  });

  factory NodeStatus.empty() => NodeStatus(
    isRunning: false,
    connectedPeers: 0,
    discoveredPeers: 0,
    uptimeSeconds: 0,
    health: 'stopped',
    gossipMessagesReceived: 0,
    storageSizeBytes: 0,
    totalKeys: 0,
    totalOperations: 0,
  );

  factory NodeStatus.fromSignal(NodeStatusResponse signal) {
    return NodeStatus(
      isRunning: signal.isRunning,
      connectedPeers: signal.connectedPeers,
      discoveredPeers: signal.discoveredPeers,
      uptimeSeconds: signal.uptimeSeconds.toInt(),
      health: signal.health,
      gossipMessagesReceived: signal.gossipMessagesReceived.toInt(),
      storageSizeBytes: signal.storageSizeBytes.toInt(),
      totalKeys: signal.totalKeys.toInt(),
      totalOperations: signal.totalOperations.toInt(),
    );
  }
}

/// Operation info model for UI
class OperationInfo {
  final String opId;
  final String dbName;
  final String key;
  final String value;
  final int timestamp;
  final String signer;

  OperationInfo({
    required this.opId,
    required this.dbName,
    required this.key,
    required this.value,
    required this.timestamp,
    required this.signer,
  });

  factory OperationInfo.fromSignal(OperationPiece piece) {
    return OperationInfo(
      opId: piece.opId,
      dbName: piece.dbName,
      key: piece.key,
      value: String.fromCharCodes(piece.value),
      timestamp: piece.timestamp.toInt(),
      signer: piece.signer,
    );
  }
}

/// Service for interacting with the Rust node via rinf signals
class NodeService extends ChangeNotifier {
  NodeInfo? _nodeInfo;
  NodeStatus _status = NodeStatus.empty();
  List<PeerInfo> _peers = [];
  bool _isStarting = false;
  Timer? _statusTimer;
  String? _walletSecretKey;
  String? _walletPublicKey;
  String? _error;
  bool _useBackgroundService = false;

  // Background service
  final BackgroundService _backgroundService = BackgroundService();
  StreamSubscription? _backgroundDataSub;

  // Stream subscriptions
  StreamSubscription? _nodeStartedSub;
  StreamSubscription? _nodeStartErrorSub;
  StreamSubscription? _nodeStoppedSub;
  StreamSubscription? _nodeStatusSub;
  StreamSubscription? _nodeInfoSub;
  StreamSubscription? _peersSub;
  StreamSubscription? _logSub;

  NodeInfo? get nodeInfo => _nodeInfo;
  NodeStatus get status => _status;
  List<PeerInfo> get peers => _peers;
  bool get isStarting => _isStarting;
  bool get isRunning => _status.isRunning;
  String? get error => _error;
  bool get useBackgroundService => _useBackgroundService;

  /// Initialize the service and set up signal listeners
  Future<void> initialize({bool useBackground = false}) async {
    _useBackgroundService = useBackground;
    
    // Set up signal listeners (for direct mode or to receive updates)
    _setupSignalListeners();
    
    if (_useBackgroundService) {
      await _backgroundService.initialize();
      _setupBackgroundServiceListener();
    }
    
    debugPrint('NodeService initialized with rinf (background: $useBackground)');
  }

  void _setupBackgroundServiceListener() {
    _backgroundDataSub = _backgroundService.onDataReceived.listen((data) {
      if (data == null) return;
      
      final type = data['type'] as String?;
      switch (type) {
        case 'node_started':
          if (data['success'] == true) {
            final nodeId = data['nodeId'] as String? ?? '';
            _nodeInfo = NodeInfo(
              nodeId: nodeId,
              publicKey: '',
              localAddrs: [],
            );
            _isStarting = false;
            _status = NodeStatus(
              isRunning: true,
              connectedPeers: 0,
              discoveredPeers: 0,
              uptimeSeconds: 0,
              health: 'healthy',
              gossipMessagesReceived: 0,
              storageSizeBytes: 0,
              totalKeys: 0,
              totalOperations: 0,
            );
            notifyListeners();
          } else {
            _error = data['error'] as String?;
            _isStarting = false;
            notifyListeners();
          }
          break;
        case 'node_stopped':
          _status = NodeStatus.empty();
          _nodeInfo = null;
          _peers = [];
          notifyListeners();
          break;
        case 'node_status':
          _status = NodeStatus(
            isRunning: data['isRunning'] as bool? ?? false,
            connectedPeers: data['connectedPeers'] as int? ?? 0,
            discoveredPeers: 0,
            uptimeSeconds: 0,
            health: 'healthy',
            gossipMessagesReceived: 0,
            storageSizeBytes: 0,
            totalKeys: 0,
            totalOperations: 0,
          );
          notifyListeners();
          break;
        case 'error':
          _error = data['message'] as String?;
          notifyListeners();
          break;
      }
    });
  }

  void _setupSignalListeners() {
    // Listen for node started
    _nodeStartedSub = NodeStartedResponse.rustSignalStream.listen((signal) {
      debugPrint('Node started: ${signal.message.nodeId}');
      _nodeInfo = NodeInfo.fromSignal(signal.message);
      _isStarting = false;
      _status = NodeStatus(
        isRunning: true,
        connectedPeers: 0,
        discoveredPeers: 0,
        uptimeSeconds: 0,
        health: 'healthy',
        gossipMessagesReceived: 0,
        storageSizeBytes: 0,
        totalKeys: 0,
        totalOperations: 0,
      );
      notifyListeners();
      
      // Start status polling
      _startStatusPolling();
    });

    // Listen for node start error
    _nodeStartErrorSub = NodeStartErrorResponse.rustSignalStream.listen((signal) {
      debugPrint('Node start error: ${signal.message.error}');
      _error = signal.message.error;
      _isStarting = false;
      notifyListeners();
    });

    // Listen for node stopped
    _nodeStoppedSub = NodeStoppedResponse.rustSignalStream.listen((signal) {
      debugPrint('Node stopped');
      _status = NodeStatus.empty();
      _nodeInfo = null;
      _peers = [];
      _statusTimer?.cancel();
      notifyListeners();
    });

    // Listen for status updates
    _nodeStatusSub = NodeStatusResponse.rustSignalStream.listen((signal) {
      _status = NodeStatus.fromSignal(signal.message);
      notifyListeners();
    });

    // Listen for node info updates
    _nodeInfoSub = NodeInfoResponse.rustSignalStream.listen((signal) {
      _nodeInfo = NodeInfo.fromInfoSignal(signal.message);
      notifyListeners();
    });

    // Listen for peers list
    _peersSub = PeersListResponse.rustSignalStream.listen((signal) {
      _peers = signal.message.peers.map((p) => PeerInfo.fromSignal(p)).toList();
      notifyListeners();
    });

    // Listen for log messages
    _logSub = LogMessageEvent.rustSignalStream.listen((signal) {
      debugPrint('[Rust ${signal.message.level}] ${signal.message.message}');
    });
  }

  /// Set wallet keys for node identity
  Future<void> setWalletKeys({required String secretKey, required String publicKey}) async {
    _walletSecretKey = secretKey;
    _walletPublicKey = publicKey;
    
    // Store secret key in secure storage
    const storage = FlutterSecureStorage();
    await storage.write(key: 'wallet_private_key', value: secretKey);
  }

  /// Start the node with wallet identity
  Future<void> startNode() async {
    if (_isStarting || _status.isRunning) return;

    _isStarting = true;
    _error = null;
    notifyListeners();

    try {
      // Get data directory
      final appDir = await getApplicationDocumentsDirectory();
      final dataDir = '${appDir.path}/cyberfly_node';

      // Create directory if it doesn't exist
      final dir = Directory(dataDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      debugPrint('Starting node with data dir: $dataDir');
      debugPrint('Wallet secret key provided: ${_walletSecretKey != null}');
      debugPrint('Using background service: $_useBackgroundService');

      if (_useBackgroundService) {
        // Start background service first
        await _backgroundService.startService();
        
        // Then tell it to start the node
        _backgroundService.sendToService('start_node', {
          'storagePath': dataDir,
          'bootstrapPeers': <String>[],
        });
      } else {
        // Direct mode - send signal directly
        StartNodeRequest(
          dataDir: dataDir,
          bootstrapPeers: const [],
          walletSecretKey: _walletSecretKey,
        ).sendSignalToRust();
      }
      
      // The response will come via NodeStartedResponse or NodeStartErrorResponse
    } catch (e) {
      _error = 'Failed to start node: $e';
      debugPrint(_error);
      _isStarting = false;
      notifyListeners();
    }
  }

  /// Stop the node
  Future<void> stopNode() async {
    _statusTimer?.cancel();
    _statusTimer = null;

    try {
      if (_useBackgroundService) {
        _backgroundService.sendToService('stop_node');
      } else {
        const StopNodeRequest().sendSignalToRust();
      }
      debugPrint('Stop node request sent');
      // The response will come via NodeStoppedResponse
    } catch (e) {
      debugPrint('Error stopping node: $e');
      // Force status update anyway
      _status = NodeStatus.empty();
      _nodeInfo = null;
      _peers = [];
      notifyListeners();
    }
  }

  /// Stop the background service completely
  Future<void> stopBackgroundService() async {
    await _backgroundService.stopService();
  }

  /// Check if background service is running
  Future<bool> isBackgroundServiceRunning() async {
    return await _backgroundService.isRunning();
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _requestStatus();
      _requestPeers();
    });
  }

  void _requestStatus() {
    if (!_status.isRunning && !_isStarting) return;
    const GetNodeStatusRequest().sendSignalToRust();
  }

  void _requestPeers() {
    if (!_status.isRunning) return;
    const GetPeersRequest().sendSignalToRust();
  }

  /// Request node info
  void requestNodeInfo() {
    const GetNodeInfoRequest().sendSignalToRust();
  }

  /// Get database names
  void requestDatabaseNames() {
    const GetDatabaseNamesRequest().sendSignalToRust();
  }

  /// Get operations for a database
  void requestOperations(String dbName) {
    GetOperationsRequest(dbName: dbName).sendSignalToRust();
  }

  /// Get storage stats
  void requestStorageStats() {
    const GetStorageStatsRequest().sendSignalToRust();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _backgroundDataSub?.cancel();
    _nodeStartedSub?.cancel();
    _nodeStartErrorSub?.cancel();
    _nodeStoppedSub?.cancel();
    _nodeStatusSub?.cancel();
    _nodeInfoSub?.cancel();
    _peersSub?.cancel();
    _logSub?.cancel();
    super.dispose();
  }
}
