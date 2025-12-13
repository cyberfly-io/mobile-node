import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:kadena_dart_sdk/kadena_dart_sdk.dart';
import 'wallet_service.dart';
import '../src/rust/api.dart' as rust_api;

/// Node status from smart contract
class NodeRegistrationStatus {
  final String? peerId;
  final String status;
  final String multiaddr;
  final String account;
  final String? registerDate;
  final String? lastActiveDate;

  NodeRegistrationStatus({
    this.peerId,
    required this.status,
    required this.multiaddr,
    required this.account,
    this.registerDate,
    this.lastActiveDate,
  });

  factory NodeRegistrationStatus.fromJson(Map<String, dynamic> json) {
    // API returns snake_case keys: peer_id, registered_at, last_updated
    return NodeRegistrationStatus(
      peerId: json['peer_id'] as String? ?? json['peerId'] as String?,
      status: json['status'] as String? ?? 'unknown',
      multiaddr: json['multiaddr'] as String? ?? '',
      account: json['account'] as String? ?? '',
      registerDate: _parseTimestamp(json['registered_at'] ?? json['registerDate']),
      lastActiveDate: _parseTimestamp(json['last_updated'] ?? json['lastActiveDate']),
    );
  }

  /// Parse Kadena timestamp format like {timep: "2025-12-08T12:02:33.267133Z"}
  static String? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value['timep'] != null) {
      return value['timep'] as String?;
    }
    return null;
  }

  bool get isActive => status == 'active';
}

/// Reward information
class RewardInfo {
  final double days;
  final double reward;

  RewardInfo({required this.days, required this.reward});

  factory RewardInfo.fromJson(Map<String, dynamic> json) {
    return RewardInfo(
      days: (json['days'] as num?)?.toDouble() ?? 0.0,
      reward: (json['reward'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get hasClaimableRewards => reward > 0;
}

/// Kadena configuration
class KadenaConfig {
  final String networkId;
  final String chainId;
  final String apiHost;
  final String contractModule;
  final String gasStation;

  const KadenaConfig({
    this.networkId = 'mainnet01',
    this.chainId = '1',
    this.apiHost = 'https://api.chainweb-community.org/chainweb/0.0',
    this.contractModule = 'free.cyberfly_node',
    this.gasStation = 'free.cyberfly-account-gas-station',
  });

  String get pactApiUrl => '$apiHost/$networkId/chain/$chainId/pact';
}

/// Kadena service for node registration on blockchain
class KadenaService extends ChangeNotifier {
  final WalletService _walletService;
  final KadenaConfig config;
  final ISigningApi _signingApi = SigningApi();

  NodeRegistrationStatus? _nodeStatus;
  RewardInfo? _rewardInfo;
  bool _isLoading = false;
  String? _error;
  String? _lastTxHash;

  KadenaService({
    required WalletService walletService,
    this.config = const KadenaConfig(),
  }) : _walletService = walletService;

  NodeRegistrationStatus? get nodeStatus => _nodeStatus;
  RewardInfo? get rewardInfo => _rewardInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastTxHash => _lastTxHash;
  bool get isRegistered => _nodeStatus != null;

  /// Get public key from wallet
  String? get _publicKey => _walletService.publicKey;
  String? get _secretKey => _walletService.walletInfo?.secretKey;
  String? get _account => _walletService.account;

  /// Generate libp2p PeerId from wallet secret key for Kadena registration
  /// This matches the desktop cyberfly-rust-node implementation for backward compatibility
  String? generateLibp2pPeerId() {
    final secretKey = _secretKey;
    if (secretKey == null) return null;
    
    try {
      return rust_api.generatePeerIdFromSecretKey(secretKeyHex: secretKey);
    } catch (e) {
      debugPrint('Failed to generate libp2p PeerId: $e');
      return null;
    }
  }

  /// Execute a local (read-only) Pact command
  /// Uses the proper Kadena command format with cmd, hash, sigs
  Future<Map<String, dynamic>?> _localCommand(String pactCode, {int gasLimit = 150000}) async {
    try {
      final creationTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Build the payload structure matching PactCommandPayload format
      final payload = {
        'networkId': config.networkId,
        'payload': {
          'exec': {
            'data': {},
            'code': pactCode,
          },
        },
        'signers': <Map<String, dynamic>>[],
        'meta': {
          'chainId': config.chainId,
          'sender': '',
          'gasLimit': gasLimit,
          'gasPrice': 0.0000001,
          'ttl': 600,
          'creationTime': creationTime,
        },
        'nonce': DateTime.now().toIso8601String(),
      };

      // JSON encode the payload for the cmd field
      final cmdStr = jsonEncode(payload);
      
      // Compute blake2b hash of the cmd string
      final hash = CryptoLib.blakeHash(cmdStr);

      // Build the proper command structure
      final command = {
        'cmd': cmdStr,
        'hash': hash,
        'sigs': <Map<String, dynamic>>[],
      };

      // Use query parameters to skip preflight and signature verification
      final url = '${config.pactApiUrl}/api/v1/local?preflight=false&signatureVerification=false';
      
      debugPrint('_localCommand: sending to $url');
      debugPrint('_localCommand: code = $pactCode');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(command),
      );

      debugPrint('_localCommand: status=${response.statusCode}');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('_localCommand: full response = $result');
        return result['result'] as Map<String, dynamic>?;
      } else {
        debugPrint('_localCommand: error response = ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('Local command error: $e');
      return null;
    }
  }

  /// Sign and send a transaction
  Future<String?> _sendCommand({
    required String pactCode,
    Map<String, dynamic>? envData,
    required List<DappCapp> capabilities,
  }) async {
    if (_publicKey == null || _secretKey == null) {
      _error = 'Wallet not initialized';
      return null;
    }

    try {
      // Create sign request
      final signRequest = SignRequest(
        code: pactCode,
        data: envData ?? {},
        sender: 'cyberfly-account-gas',
        networkId: config.networkId,
        chainId: config.chainId,
        gasLimit: 2000,
        gasPrice: 0.0000001,
        signingPubKey: _publicKey!,
        ttl: 600,
        caps: capabilities,
      );

      // Construct the Pact command payload
      final pactPayload = _signingApi.constructPactCommandPayload(
        request: signRequest,
        signingPubKey: _publicKey!,
      );

      // Create keypair for signing
      final keyPair = KadenaSignKeyPair(
        publicKey: _publicKey!,
        privateKey: _secretKey!,
      );

      // Sign the request
      final signResult = _signingApi.sign(
        payload: pactPayload,
        keyPair: keyPair,
      );

      if (signResult.error != null) {
        _error = signResult.error!.msg;
        return null;
      }

      if (signResult.body == null) {
        _error = 'Sign result body is null';
        return null;
      }

      // Send to blockchain
      final sendPayload = {
        'cmds': [signResult.body!.toJson()],
      };

      final sendResponse = await http.post(
        Uri.parse('${config.pactApiUrl}/api/v1/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sendPayload),
      );

      if (sendResponse.statusCode == 200) {
        final result = jsonDecode(sendResponse.body) as Map<String, dynamic>;
        final requestKeys = result['requestKeys'] as List?;
        if (requestKeys != null && requestKeys.isNotEmpty) {
          return requestKeys.first as String;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Send command error: $e');
      _error = 'Transaction failed: $e';
      return null;
    }
  }

  /// Poll for transaction result
  Future<bool> _pollTransaction(String requestKey) async {
    for (int attempt = 0; attempt < 30; attempt++) {
      await Future.delayed(const Duration(seconds: 2));

      try {
        final response = await http.post(
          Uri.parse('${config.pactApiUrl}/api/v1/poll'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'requestKeys': [requestKey],
          }),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body) as Map<String, dynamic>;
          final txResult = result[requestKey] as Map<String, dynamic>?;

          if (txResult != null) {
            final status = txResult['result']?['status'] as String?;
            if (status == 'success') {
              return true;
            } else if (status == 'failure') {
              final error = txResult['result']?['error']?['message'] as String?;
              _error = error ?? 'Transaction failed';
              return false;
            }
          }
        }
      } catch (e) {
        debugPrint('Poll error: $e');
      }
    }
    _error = 'Transaction polling timeout';
    return false;
  }

  /// Get node info from smart contract
  Future<NodeRegistrationStatus?> getNodeInfo(String peerId) async {
    // Only notify if not already loading to avoid setState during build
    if (!_isLoading) {
      _isLoading = true;
      _error = null;
      // Use addPostFrameCallback to safely notify listeners
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final code = '(${config.contractModule}.get-node "$peerId")';
      debugPrint('getNodeInfo: executing $code');
      final result = await _localCommand(code);
      debugPrint('getNodeInfo: result = $result');

      if (result != null && result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        debugPrint('getNodeInfo: data = $data');
        if (data != null) {
          _nodeStatus = NodeRegistrationStatus.fromJson(data);
          _isLoading = false;
          notifyListeners();
          return _nodeStatus;
        }
      } else if (result != null && result['status'] == 'failure') {
        // Check if it's a "row not found" error (node doesn't exist)
        final errorMsg = result['error']?['message']?.toString() ?? '';
        debugPrint('getNodeInfo: error message = $errorMsg');
        if (errorMsg.contains('row not found') || errorMsg.contains('with-read')) {
          // Node doesn't exist - this is expected for new nodes
          debugPrint('getNodeInfo: node does not exist');
        } else {
          debugPrint('getNodeInfo: unexpected error: $errorMsg');
        }
      }

      _nodeStatus = null;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to get node info: $e';
      debugPrint('getNodeInfo: exception: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Register a new node
  Future<bool> createNode(String peerId, String multiaddr) async {
    if (_account == null || _publicKey == null) {
      _error = 'Wallet not initialized';
      debugPrint('createNode failed: wallet not initialized');
      debugPrint('  account: $_account');
      debugPrint('  publicKey: $_publicKey');
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Creating node registration transaction...');
      final code =
          '(${config.contractModule}.new-node "$peerId" "active" "$multiaddr" "$_account" (read-keyset "ks"))';
      debugPrint('Pact code: $code');

      final envData = {
        'ks': {
          'pred': 'keys-all',
          'keys': [_publicKey],
        },
      };

      final capabilities = [
        DappCapp(
          role: 'Gas',
          description: 'Pay gas fees',
          cap: Capability(
            name: '${config.gasStation}.GAS_PAYER',
            args: [
              'cyberfly-account-gas',
              {'int': 1},
              1.0,
            ],
          ),
        ),
        DappCapp(
          role: 'NewNode',
          description: 'Register new node',
          cap: Capability(name: '${config.contractModule}.NEW_NODE', args: []),
        ),
      ];

      final requestKey = await _sendCommand(
        pactCode: code,
        envData: envData,
        capabilities: capabilities,
      );

      debugPrint('Transaction requestKey: $requestKey');

      if (requestKey == null) {
        debugPrint('Failed to send transaction: ${_error ?? "unknown error"}');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _lastTxHash = requestKey;
      debugPrint('Polling for transaction result...');
      final success = await _pollTransaction(requestKey);
      debugPrint('Transaction result: ${success ? "success" : "failed"}');

      if (success) {
        await getNodeInfo(peerId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to register node: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Activate/update node status
  Future<bool> activateNode(String peerId, String multiaddr) async {
    if (_publicKey == null) {
      _error = 'Wallet not initialized';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code =
          '(${config.contractModule}.update-node "$peerId" "$multiaddr" "active")';

      final capabilities = [
        DappCapp(
          role: 'Gas',
          description: 'Pay gas fees',
          cap: Capability(
            name: '${config.gasStation}.GAS_PAYER',
            args: [
              'cyberfly-account-gas',
              {'int': 1},
              1.0,
            ],
          ),
        ),
        DappCapp(
          role: 'NodeGuard',
          description: 'Node ownership',
          cap: Capability(
            name: '${config.contractModule}.NODE_GUARD',
            args: [peerId],
          ),
        ),
      ];

      final requestKey = await _sendCommand(
        pactCode: code,
        capabilities: capabilities,
      );

      if (requestKey == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _lastTxHash = requestKey;
      final success = await _pollTransaction(requestKey);

      if (success) {
        await getNodeInfo(peerId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to activate node: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Calculate claimable rewards
  Future<RewardInfo?> calculateRewards(String peerId) async {
    try {
      final code =
          '(${config.contractModule}.calculate-days-and-reward "$peerId")';
      final result = await _localCommand(code);

      if (result != null && result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) {
          _rewardInfo = RewardInfo.fromJson(data);
          notifyListeners();
          return _rewardInfo;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to calculate rewards: $e');
      return null;
    }
  }

  /// Claim rewards
  Future<bool> claimReward(String peerId) async {
    if (_account == null || _publicKey == null) {
      _error = 'Wallet not initialized';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code =
          '(${config.contractModule}.claim-reward "$_account" "$peerId")';

      final capabilities = [
        DappCapp(
          role: 'Gas',
          description: 'Pay gas fees',
          cap: Capability(
            name: '${config.gasStation}.GAS_PAYER',
            args: [
              'cyberfly-account-gas',
              {'int': 1},
              1.0,
            ],
          ),
        ),
        DappCapp(
          role: 'NodeGuard',
          description: 'Node ownership',
          cap: Capability(
            name: '${config.contractModule}.NODE_GUARD',
            args: [peerId],
          ),
        ),
      ];

      final requestKey = await _sendCommand(
        pactCode: code,
        capabilities: capabilities,
      );

      if (requestKey == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _lastTxHash = requestKey;
      final success = await _pollTransaction(requestKey);

      if (success) {
        await calculateRewards(peerId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to claim reward: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check status and auto-claim rewards if available (for periodic task)
  /// This is a silent operation - does not show loading state or errors in UI
  Future<bool> checkAndClaimRewards(String peerId) async {
    try {
      debugPrint('Checking rewards for node: $peerId');
      
      // Check if rewards are claimable
      final rewardInfo = await calculateRewards(peerId);
      if (rewardInfo != null && rewardInfo.hasClaimableRewards) {
        debugPrint('Rewards available: ${rewardInfo.days} days, ${rewardInfo.reward} tokens - claiming now');
        final success = await claimReward(peerId);
        if (success) {
          debugPrint('✅ Auto-claimed ${rewardInfo.reward} CFLY tokens');
        }
        return success;
      } else {
        debugPrint('No claimable rewards yet (days: ${rewardInfo?.days ?? 0}, reward: ${rewardInfo?.reward ?? 0})');
        return false;
      }
    } catch (e) {
      debugPrint('Auto-claim check failed: $e');
      return false;
    }
  }

  /// Ensure node is registered and active (main entry point)
  /// Returns: 'created' if new node created, 'active' if already active, 'activated' if was inactive, null if failed
  Future<String?> ensureRegistered(String peerId, String multiaddr) async {
    debugPrint('ensureRegistered called:');
    debugPrint('  peerId: $peerId');
    debugPrint('  multiaddr: $multiaddr');
    
    final nodeInfo = await getNodeInfo(peerId);
    debugPrint('  existing nodeInfo: ${nodeInfo?.peerId}, status: ${nodeInfo?.status}');

    if (nodeInfo == null) {
      // Node not found, register it
      debugPrint('  -> Node not found, creating new node...');
      final success = await createNode(peerId, multiaddr);
      
      // If creation failed with "already exists", the node exists with different format
      // Just return 'active' as the node is already registered
      if (!success && _error != null && _error!.toLowerCase().contains('already exists')) {
        debugPrint('  -> Node already exists (different key format), treating as active');
        _error = null;
        return 'active';
      }
      return success ? 'created' : null;
    } else if (!nodeInfo.isActive) {
      // Node inactive, activate it
      debugPrint('  -> Node found but inactive, activating...');
      final success = await activateNode(peerId, multiaddr);
      return success ? 'activated' : null;
    }

    // Already active
    debugPrint('  -> Node already active');
    return 'active';
  }

  // ============= BALANCE METHODS =============

  /// Get CFLY token balance for an account
  Future<double?> getCFLYBalance(String? account) async {
    if (account == null) return null;
    
    try {
      final code = '(free.cyberfly_token.get-balance "$account")';
      final result = await _localCommand(code);

      if (result != null && result['status'] == 'success') {
        final data = result['data'];
        if (data != null) {
          if (data is num) return data.toDouble();
          if (data is Map) {
            if (data.containsKey('decimal')) return double.tryParse(data['decimal'].toString());
            if (data.containsKey('int')) return (data['int'] as num).toDouble();
          }
          return double.tryParse(data.toString());
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get CFLY balance: $e');
      return null;
    }
  }

  // ============= STAKING METHODS =============

  /// Get stake info for a specific node
  Future<NodeStakeInfo?> getNodeStake(String peerId) async {
    try {
      final code = '(${config.contractModule}.get-node-stake "$peerId")';
      final result = await _localCommand(code);

      if (result != null && result['status'] == 'success') {
        final data = result['data'];
        if (data != null && data is Map<String, dynamic>) {
          return NodeStakeInfo.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get node stake: $e');
      return null;
    }
  }

  /// Get all nodes owned by the connected account
  Future<List<NodeRegistrationStatus>> getMyNodes() async {
    if (_account == null) return [];
    
    try {
      final code = '(${config.contractModule}.get-account-nodes "$_account")';
      final result = await _localCommand(code);

      if (result != null && result['status'] == 'success') {
        final data = result['data'] as List?;
        if (data != null) {
          return data
              .map((item) => NodeRegistrationStatus.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get my nodes: $e');
      return [];
    }
  }

  /// Get all active nodes in the network
  Future<List<NodeRegistrationStatus>> getAllActiveNodes() async {
    try {
      final code = '(${config.contractModule}.get-all-active-nodes)';
      final result = await _localCommand(code);

      if (result != null && result['status'] == 'success') {
        final data = result['data'] as List?;
        if (data != null) {
          return data
              .map((item) => NodeRegistrationStatus.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get all active nodes: $e');
      return [];
    }
  }

  /// Get current APY
  Future<double?> getAPY() async {
    try {
      final code = '(${config.contractModule}.calculate-apy)';
      final result = await _localCommand(code);

      if (result != null && result['status'] == 'success') {
        final data = result['data'];
        return _parseKadenaNumber(data);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get APY: $e');
      return null;
    }
  }

  /// Get staking statistics
  Future<StakeStats?> getStakeStats() async {
    try {
      final code = '(${config.contractModule}.get-stakes-stats)';
      final result = await _localCommand(code);

      if (result != null && result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) {
          return StakeStats.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get stake stats: $e');
      return null;
    }
  }

  /// Stake CFLY on a node (50,000 CFLY required)
  Future<bool> stakeOnNode(String peerId) async {
    if (_account == null || _publicKey == null) {
      _error = 'Wallet not initialized';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code = '(${config.contractModule}.stake "$_account" "$peerId")';

      final capabilities = [
        DappCapp(
          role: 'Gas',
          description: 'Pay gas fees',
          cap: Capability(
            name: '${config.gasStation}.GAS_PAYER',
            args: [
              'cyberfly-account-gas',
              {'int': 1},
              1.0,
            ],
          ),
        ),
        DappCapp(
          role: 'AccountAuth',
          description: 'Account authorization',
          cap: Capability(
            name: '${config.contractModule}.ACCOUNT_AUTH',
            args: [_account],
          ),
        ),
        DappCapp(
          role: 'NodeGuard',
          description: 'Node ownership',
          cap: Capability(
            name: '${config.contractModule}.NODE_GUARD',
            args: [peerId],
          ),
        ),
        DappCapp(
          role: 'Transfer',
          description: 'Transfer CFLY for staking',
          cap: Capability(
            name: 'free.cyberfly_token.TRANSFER',
            args: [_account, 'cyberfly-staking-bank', 50000.0],
          ),
        ),
      ];

      final requestKey = await _sendCommand(
        pactCode: code,
        capabilities: capabilities,
      );

      if (requestKey == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _lastTxHash = requestKey;
      final success = await _pollTransaction(requestKey);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to stake: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Unstake from a node
  Future<bool> unstakeFromNode(String peerId) async {
    if (_account == null || _publicKey == null) {
      _error = 'Wallet not initialized';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code = '(${config.contractModule}.unstake "$_account" "$peerId")';

      final capabilities = [
        DappCapp(
          role: 'Gas',
          description: 'Pay gas fees',
          cap: Capability(
            name: '${config.gasStation}.GAS_PAYER',
            args: [
              'cyberfly-account-gas',
              {'int': 1},
              1.0,
            ],
          ),
        ),
        DappCapp(
          role: 'AccountAuth',
          description: 'Account authorization',
          cap: Capability(
            name: '${config.contractModule}.ACCOUNT_AUTH',
            args: [_account],
          ),
        ),
      ];

      final requestKey = await _sendCommand(
        pactCode: code,
        capabilities: capabilities,
      );

      if (requestKey == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _lastTxHash = requestKey;
      final success = await _pollTransaction(requestKey);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to unstake: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Transfer CFLY tokens to another account
  Future<bool> transferCFLY({
    required String toAccount,
    required double amount,
  }) async {
    if (_account == null || _publicKey == null) {
      _error = 'Wallet not initialized';
      return false;
    }

    if (amount <= 0) {
      _error = 'Amount must be greater than 0';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use coin.transfer for fungible token transfer
      final code = '(free.cyberfly_token.transfer "$_account" "$toAccount" $amount)';

      final capabilities = [
        DappCapp(
          role: 'Gas',
          description: 'Pay gas fees',
          cap: Capability(
            name: '${config.gasStation}.GAS_PAYER',
            args: [
              'cyberfly-account-gas',
              {'int': 1},
              1.0,
            ],
          ),
        ),
        DappCapp(
          role: 'Transfer',
          description: 'Transfer CFLY tokens',
          cap: Capability(
            name: 'free.cyberfly_token.TRANSFER',
            args: [_account, toAccount, amount],
          ),
        ),
      ];

      final requestKey = await _sendCommand(
        pactCode: code,
        capabilities: capabilities,
      );

      if (requestKey == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _lastTxHash = requestKey;
      final success = await _pollTransaction(requestKey);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to transfer: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Helper to parse Kadena number formats
  double? _parseKadenaNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is Map) {
      if (value.containsKey('int')) return (value['int'] as num).toDouble();
      if (value.containsKey('decimal')) return double.tryParse(value['decimal'].toString());
    }
    return double.tryParse(value.toString());
  }
}

/// Node stake information
class NodeStakeInfo {
  final bool active;
  final double? amount;
  final String? staker;
  final String? stakeDate;

  NodeStakeInfo({
    required this.active,
    this.amount,
    this.staker,
    this.stakeDate,
  });

  factory NodeStakeInfo.fromJson(Map<String, dynamic> json) {
    double? parseAmount(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is Map) {
        if (value.containsKey('decimal')) return double.tryParse(value['decimal'].toString());
        if (value.containsKey('int')) return (value['int'] as num).toDouble();
      }
      return double.tryParse(value.toString());
    }

    return NodeStakeInfo(
      active: json['active'] == true,
      amount: parseAmount(json['amount']),
      staker: json['staker'] as String?,
      stakeDate: json['stake-date'] as String?,
    );
  }
}

/// Staking statistics
class StakeStats {
  final int totalStakes;
  final double totalStakedAmount;

  StakeStats({
    required this.totalStakes,
    required this.totalStakedAmount,
  });

  factory StakeStats.fromJson(Map<String, dynamic> json) {
    int parseIntValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is Map && value.containsKey('int')) return value['int'] as int;
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDoubleValue(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is Map) {
        if (value.containsKey('decimal')) return double.tryParse(value['decimal'].toString()) ?? 0.0;
        if (value.containsKey('int')) return (value['int'] as num).toDouble();
      }
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return StakeStats(
      totalStakes: parseIntValue(json['total-stakes']),
      totalStakedAmount: parseDoubleValue(json['total-staked-amount']),
    );
  }
}
