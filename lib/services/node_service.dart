import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../src/rust/api.dart' as rust_api;
import '../src/rust/frb_generated.dart';
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

  factory PeerInfo.fromDto(rust_api.PeerInfoDto dto) {
    return PeerInfo(
      nodeId: dto.nodeId,
      lastSeen: DateTime.now(), // Connected now
      address: dto.address,
      isConnected: true,
      latencyMs: dto.latencyMs?.toInt(),
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

  factory NodeInfo.fromRust(rust_api.NodeInfo info) {
    return NodeInfo(
      nodeId: info.nodeId,
      publicKey: info.publicKey,
      localAddrs: [],
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
  final int latencyRequestsSent;
  final int latencyResponsesReceived;

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
    required this.latencyRequestsSent,
    required this.latencyResponsesReceived,
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
    latencyRequestsSent: 0,
    latencyResponsesReceived: 0,
  );

  factory NodeStatus.fromDto(rust_api.NodeStatusDto dto) {
    return NodeStatus(
      isRunning: dto.isRunning,
      connectedPeers: dto.connectedPeers,
      discoveredPeers: dto.discoveredPeers,
      uptimeSeconds: dto.uptimeSeconds.toInt(),
      health: dto.isRunning ? 'healthy' : 'stopped',
      gossipMessagesReceived: dto.gossipMessagesReceived.toInt(),
      storageSizeBytes: dto.storageSizeBytes.toInt(),
      totalKeys: dto.totalKeys.toInt(),
      totalOperations: 0,
      latencyRequestsSent: dto.latencyRequestsSent.toInt(),
      latencyResponsesReceived: dto.latencyResponsesReceived.toInt(),
    );
  }
}

/// Service for interacting with the Rust node via flutter_rust_bridge FFI
class NodeService extends ChangeNotifier {
  NodeInfo? _nodeInfo;
  NodeStatus _status = NodeStatus.empty();
  List<PeerInfo> _peers = [];
  bool _isStarting = false;
  Timer? _statusTimer;
  Timer? _fastPollTimer;
  String? _walletSecretKey;
  String? _error;
  bool _initialized = false;
  int _lastStatusHash = 0;
  int _lastPeersHash = 0;
  
  // Background service support
  bool _useBackgroundService = false;
  final BackgroundService _backgroundService = BackgroundService();
  StreamSubscription? _backgroundDataSub;

  NodeInfo? get nodeInfo => _nodeInfo;
  NodeStatus get status => _status;
  List<PeerInfo> get peers => _peers;
  bool get isStarting => _isStarting;
  bool get isRunning => _status.isRunning;
  String? get error => _error;
  bool get useBackgroundService => _useBackgroundService;

  /// Initialize the Rust library
  Future<void> initialize({bool useBackground = false}) async {
    if (_initialized) return;
    
    _useBackgroundService = useBackground;
    
    try {
      debugPrint('Initializing RustLib...');
      await RustLib.init();
      debugPrint('RustLib.init() completed');
      rust_api.initLogging();
      _initialized = true;
      
      // Initialize background service if enabled
      if (_useBackgroundService) {
        await _backgroundService.initialize();
        _setupBackgroundServiceListener();
        debugPrint('Background service initialized');
      }
      
      debugPrint('NodeService initialized (background: $useBackground)');
    } catch (e) {
      debugPrint('Failed to initialize Rust library: $e');
      _error = 'Failed to initialize: $e';
      rethrow; // Rethrow so caller knows initialization failed
    }
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
              latencyRequestsSent: 0,
              latencyResponsesReceived: 0,
            );
            _startStatusPolling();
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
          final isRunning = data['isRunning'] as bool? ?? false;
          final connectedPeers = data['connectedPeers'] as int? ?? 0;
          if (isRunning != _status.isRunning || connectedPeers != _status.connectedPeers) {
            _status = NodeStatus(
              isRunning: isRunning,
              connectedPeers: connectedPeers,
              discoveredPeers: _status.discoveredPeers,
              uptimeSeconds: _status.uptimeSeconds,
              health: isRunning ? 'healthy' : 'stopped',
              gossipMessagesReceived: _status.gossipMessagesReceived,
              storageSizeBytes: _status.storageSizeBytes,
              totalKeys: _status.totalKeys,
              totalOperations: _status.totalOperations,
              latencyRequestsSent: _status.latencyRequestsSent,
              latencyResponsesReceived: _status.latencyResponsesReceived,
            );
            notifyListeners();
          }
          break;
      }
    });
  }

  /// Set wallet keys for node identity
  Future<void> setWalletKeys({required String secretKey, required String publicKey}) async {
    _walletSecretKey = secretKey;
    
    // Store secret key in secure storage (for background service auto-start)
    const storage = FlutterSecureStorage();
    await storage.write(key: 'wallet_secret_key', value: secretKey);
  }

  /// Start the node with wallet identity
  Future<void> startNode() async {
    if (_isStarting || _status.isRunning) return;
    
    // Ensure Rust library is initialized
    if (!_initialized) {
      debugPrint('RustLib not initialized, initializing now...');
      await initialize(useBackground: _useBackgroundService);
    }

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
        debugPrint('Background service started');
        
        // Then tell it to start the node
        _backgroundService.sendToService('start_node', {
          'dataDir': dataDir,
          'walletSecretKey': _walletSecretKey,
          'bootstrapPeers': <String>[],
        });
        // Response will come via _setupBackgroundServiceListener
      } else {
        // Direct mode - start the node via FFI
        final nodeInfo = await rust_api.startNode(
          dataDir: dataDir,
          walletSecretKey: _walletSecretKey,
          bootstrapPeers: const [],
        );
        
        _nodeInfo = NodeInfo.fromRust(nodeInfo);
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
          latencyRequestsSent: 0,
          latencyResponsesReceived: 0,
        );
        _isStarting = false;
        notifyListeners();
        
        debugPrint('Node started: ${_nodeInfo?.nodeId}');
        
        // Start fast polling initially, then slow down (non-blocking)
        _startFastPolling();
      }
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
    _fastPollTimer?.cancel();
    _fastPollTimer = null;

    try {
      if (_useBackgroundService) {
        _backgroundService.sendToService('stop_node');
        debugPrint('Stop node command sent to background service');
      } else {
        await rust_api.stopNode();
        debugPrint('Node stopped');
      }
      
      _status = NodeStatus.empty();
      _nodeInfo = null;
      _peers = [];
      _lastStatusHash = 0;
      _lastPeersHash = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping node: $e');
      // Force status update anyway
      _status = NodeStatus.empty();
      _nodeInfo = null;
      _peers = [];
      _lastStatusHash = 0;
      _lastPeersHash = 0;
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

  /// Start fast polling (500ms) for first 10 seconds, then slow down
  void _startFastPolling() {
    debugPrint('>>> _startFastPolling() called');
    _statusTimer?.cancel();
    _fastPollTimer?.cancel();
    
    // Fast polling for first 10 seconds (500ms interval)
    debugPrint('>>> Starting fast poll timer (500ms)');
    _fastPollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      debugPrint('>>> Timer tick - calling _fetchStatusAndPeers');
      _fetchStatusAndPeers();
    });
    
    // After 10 seconds, switch to slower polling
    Future.delayed(const Duration(seconds: 10), () {
      _fastPollTimer?.cancel();
      _fastPollTimer = null;
      _startStatusPolling();
    });
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    // Normal polling at 1 second interval
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchStatusAndPeers();
    });
  }

  /// Fetch status and peers, only notify if changed
  Future<void> _fetchStatusAndPeers() async {
    debugPrint('>>> _fetchStatusAndPeers entered: isRunning=${_status.isRunning}, isStarting=$_isStarting');
    if (!_status.isRunning && !_isStarting) {
      debugPrint('_fetchStatusAndPeers: skipping - isRunning=${_status.isRunning}, isStarting=$_isStarting');
      return;
    }
    
    debugPrint('>>> About to call rust_api.getNodeStatus()');
    try {
      // Fetch status - NOW SYNC!
      final statusDto = rust_api.getNodeStatus();
      debugPrint('>>> Got status: connected=${statusDto.connectedPeers}, discovered=${statusDto.discoveredPeers}, gossip=${statusDto.gossipMessagesReceived}');
      
      // Fetch peers if running - NOW SYNC!
      List<rust_api.PeerInfoDto> peersDto = [];
      if (statusDto.isRunning) {
        peersDto = rust_api.getPeers();
        debugPrint('Peers fetched: ${peersDto.length}');
      }
      
      // Check if status changed
      final newStatusHash = _computeStatusHash(statusDto);
      final statusChanged = newStatusHash != _lastStatusHash;
      if (statusChanged) {
        _status = NodeStatus.fromDto(statusDto);
        _lastStatusHash = newStatusHash;
        debugPrint('Status changed, updating UI');
      }
      
      // Check if peers changed
      final newPeersHash = _computePeersHash(peersDto);
      final peersChanged = newPeersHash != _lastPeersHash;
      if (peersChanged) {
        _peers = peersDto.map((p) => PeerInfo.fromDto(p)).toList();
        _lastPeersHash = newPeersHash;
        debugPrint('Peers changed, updating UI');
      }
      
      // Only notify if something changed
      if (statusChanged || peersChanged) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching status/peers: $e');
    }
  }

  int _computeStatusHash(rust_api.NodeStatusDto dto) {
    return Object.hash(
      dto.isRunning,
      dto.connectedPeers,
      dto.discoveredPeers,
      dto.gossipMessagesReceived,
      dto.storageSizeBytes,
      dto.totalKeys,
      dto.latencyRequestsSent,
      dto.latencyResponsesReceived,
    );
  }

  int _computePeersHash(List<rust_api.PeerInfoDto> peers) {
    if (peers.isEmpty) return 0;
    return Object.hash(
      peers.length,
      peers.map((p) => '${p.nodeId}:${p.latencyMs}').join(','),
    );
  }

  /// Request node info
  void requestNodeInfo() {
    final info = rust_api.getNodeInfo();
    if (info != null) {
      _nodeInfo = NodeInfo.fromRust(info);
      notifyListeners();
    }
  }

  /// Send gossip message
  Future<void> sendGossip(String topic, String message) async {
    try {
      await rust_api.sendGossip(topic: topic, message: message);
    } catch (e) {
      debugPrint('Error sending gossip: $e');
    }
  }

  /// Store data with signature for sync across network
  Future<void> storeData(String dbName, String key, List<int> value, {
    required String publicKey,
    required String signature,
  }) async {
    try {
      await rust_api.storeData(
        dbName: dbName, 
        key: key, 
        value: value,
        publicKey: publicKey,
        signature: signature,
      );
    } catch (e) {
      debugPrint('Error storing data: $e');
    }
  }

  /// Store data locally without sync (no signature required)
  Future<void> storeDataLocal(String dbName, String key, List<int> value) async {
    try {
      await rust_api.storeDataLocal(dbName: dbName, key: key, value: value);
    } catch (e) {
      debugPrint('Error storing local data: $e');
    }
  }

  /// Get data
  Future<List<int>?> getData(String dbName, String key) async {
    try {
      return await rust_api.getData(dbName: dbName, key: key);
    } catch (e) {
      debugPrint('Error getting data: $e');
      return null;
    }
  }

  /// Force immediate refresh of status
  Future<void> refreshStatus() async {
    await _fetchStatusAndPeers();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _fastPollTimer?.cancel();
    _backgroundDataSub?.cancel();
    super.dispose();
  }
}
