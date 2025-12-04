import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:slip_0010_ed25519/slip_0010_ed25519.dart';

/// Wallet information
class WalletInfo {
  final String mnemonic;
  final String publicKey;
  final String secretKey;
  final String account;
  final bool isNew;

  WalletInfo({
    required this.mnemonic,
    required this.publicKey,
    required this.secretKey,
    required this.account,
    this.isNew = false,
  });

  Map<String, dynamic> toJson() => {
    'mnemonic': mnemonic,
    'publicKey': publicKey,
    'secretKey': secretKey,
    'account': account,
  };

  factory WalletInfo.fromJson(Map<String, dynamic> json) => WalletInfo(
    mnemonic: json['mnemonic'] as String,
    publicKey: json['publicKey'] as String,
    secretKey: json['secretKey'] as String,
    account: json['account'] as String,
  );
}

/// Wallet service for BIP39 mnemonic and Ed25519 keypair management
class WalletService extends ChangeNotifier {
  static const String _walletKey = 'cyberfly_wallet';
  static const String _derivationPath = "m/44'/626'/0'";

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  WalletInfo? _walletInfo;
  bool _isLoading = false;
  String? _error;

  WalletInfo? get walletInfo => _walletInfo;
  bool get isLoading => _isLoading;
  bool get hasWallet => _walletInfo != null;
  String? get error => _error;
  String? get publicKey => _walletInfo?.publicKey;
  String? get account => _walletInfo?.account;

  /// Initialize wallet service - check if wallet exists
  Future<bool> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final walletData = await _secureStorage.read(key: _walletKey);
      if (walletData != null) {
        final json = jsonDecode(walletData) as Map<String, dynamic>;
        _walletInfo = WalletInfo.fromJson(json);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to load wallet: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate a new 12-word mnemonic (for preview)
  String generateMnemonic() {
    return bip39.generateMnemonic(strength: 128);
  }

  /// Validate a mnemonic phrase
  bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  /// Create a new wallet with a fresh mnemonic
  Future<WalletInfo?> createWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final mnemonic = generateMnemonic();
      return await _createWalletFromMnemonic(mnemonic, isNew: true);
    } catch (e) {
      _error = 'Failed to create wallet: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Restore wallet from existing mnemonic
  Future<WalletInfo?> restoreWallet(String mnemonic) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (!validateMnemonic(mnemonic.trim())) {
      _error = 'Invalid mnemonic phrase';
      _isLoading = false;
      notifyListeners();
      return null;
    }

    try {
      return await _createWalletFromMnemonic(mnemonic.trim(), isNew: false);
    } catch (e) {
      _error = 'Failed to restore wallet: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Internal method to create wallet from mnemonic
  Future<WalletInfo?> _createWalletFromMnemonic(
    String mnemonic, {
    required bool isNew,
  }) async {
    try {
      // Convert mnemonic to seed
      final seed = bip39.mnemonicToSeed(mnemonic);

      // Derive Ed25519 keypair using SLIP-0010 with Kadena derivation path
      // m/44'/626'/0' where 626 is Kadena's coin type
      final keyData = ED25519_HD_KEY.derivePath(_derivationPath, seed);

      final secretKey = hex.encode(keyData.key);
      final publicKeyBytes = ED25519_HD_KEY.getPublicKey(keyData.key);
      // Remove the 0x00 prefix from public key (it's 33 bytes with prefix, 32 without)
      final publicKey = hex.encode(
        publicKeyBytes.length == 33
            ? publicKeyBytes.sublist(1)
            : publicKeyBytes,
      );

      // Kadena account format: k:publicKey
      final account = 'k:$publicKey';

      _walletInfo = WalletInfo(
        mnemonic: mnemonic,
        publicKey: publicKey,
        secretKey: secretKey,
        account: account,
        isNew: isNew,
      );

      // Save to secure storage
      await _secureStorage.write(
        key: _walletKey,
        value: jsonEncode(_walletInfo!.toJson()),
      );

      _isLoading = false;
      notifyListeners();
      return _walletInfo;
    } catch (e) {
      _error = 'Failed to derive keypair: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Delete wallet (dangerous - requires backup confirmation)
  Future<bool> deleteWallet() async {
    try {
      await _secureStorage.delete(key: _walletKey);
      _walletInfo = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete wallet: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get mnemonic for backup display (requires confirmation in UI)
  String? getMnemonic() {
    return _walletInfo?.mnemonic;
  }

  /// Preview public key from mnemonic without creating wallet
  Future<String?> previewPublicKey(String mnemonic) async {
    if (!validateMnemonic(mnemonic.trim())) {
      return null;
    }

    try {
      final seed = bip39.mnemonicToSeed(mnemonic.trim());
      final keyData = ED25519_HD_KEY.derivePath(_derivationPath, seed);
      final publicKeyBytes = ED25519_HD_KEY.getPublicKey(keyData.key);
      return hex.encode(
        publicKeyBytes.length == 33
            ? publicKeyBytes.sublist(1)
            : publicKeyBytes,
      );
    } catch (e) {
      return null;
    }
  }
}
