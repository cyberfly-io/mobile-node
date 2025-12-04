import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    return NodeRegistrationStatus(
      peerId: json['peerId'] as String?,
      status: json['status'] as String? ?? 'unknown',
      multiaddr: json['multiaddr'] as String? ?? '',
      account: json['account'] as String? ?? '',
      registerDate: json['registerDate'] as String?,
      lastActiveDate: json['lastActiveDate'] as String?,
    );
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
    this.apiHost = 'https://chainweb.ecko.finance/chainweb/0.0',
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
  Future<Map<String, dynamic>?> _localCommand(String pactCode) async {
    try {
      final creationTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final cmd = {
        'pactCode': pactCode,
        'envData': {},
        'meta': {
          'chainId': config.chainId,
          'sender': '',
          'gasLimit': 1000,
          'gasPrice': 0.0000001,
          'ttl': 600,
          'creationTime': creationTime,
        },
        'networkId': config.networkId,
        'nonce': DateTime.now().toIso8601String(),
      };

      final cmdStr = jsonEncode(cmd);

      final payload = {
        'cmd': cmdStr,
        'hash': '',
        'sigs': <Map<String, dynamic>>[],
      };

      final response = await http.post(
        Uri.parse('${config.pactApiUrl}/api/v1/local'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        return result['result'] as Map<String, dynamic>?;
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code = '(${config.contractModule}.get-node "$peerId")';
      final result = await _localCommand(code);

      if (result != null && result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) {
          _nodeStatus = NodeRegistrationStatus.fromJson(data);
          _isLoading = false;
          notifyListeners();
          return _nodeStatus;
        }
      }

      _nodeStatus = null;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to get node info: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Register a new node
  Future<bool> createNode(String peerId, String multiaddr) async {
    if (_account == null || _publicKey == null) {
      _error = 'Wallet not initialized';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code =
          '(${config.contractModule}.new-node "$peerId" "active" "$multiaddr" "$_account" (read-keyset "ks"))';

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

  /// Ensure node is registered and active (main entry point)
  Future<bool> ensureRegistered(String peerId, String multiaddr) async {
    final nodeInfo = await getNodeInfo(peerId);

    if (nodeInfo == null) {
      // Node not found, register it
      return await createNode(peerId, multiaddr);
    } else if (!nodeInfo.isActive) {
      // Node inactive, activate it
      return await activateNode(peerId, multiaddr);
    }

    // Already active
    return true;
  }
}
