import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Service for PIN and biometric authentication
class AuthService extends ChangeNotifier {
  static const _pinKey = 'app_pin';
  static const _biometricEnabledKey = 'biometric_enabled';
  
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _hasPinSet = false;
  
  AuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        ),
        _localAuth = localAuth ?? LocalAuthentication();
  
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get hasPinSet => _hasPinSet;
  
  /// Initialize the auth service and check capabilities
  Future<void> initialize() async {
    await _checkBiometricAvailability();
    await _loadSettings();
    notifyListeners();
  }
  
  /// Check if device supports biometric authentication
  Future<void> _checkBiometricAvailability() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      _isBiometricAvailable = canAuthenticate && isDeviceSupported;
      
      if (_isBiometricAvailable) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        _isBiometricAvailable = availableBiometrics.isNotEmpty;
      }
    } on PlatformException {
      _isBiometricAvailable = false;
    }
  }
  
  /// Load saved settings
  Future<void> _loadSettings() async {
    final pin = await _secureStorage.read(key: _pinKey);
    _hasPinSet = pin != null && pin.isNotEmpty;
    debugPrint('AuthService: PIN set = $_hasPinSet');
    
    final biometricEnabled = await _secureStorage.read(key: _biometricEnabledKey);
    _isBiometricEnabled = biometricEnabled == 'true' && _isBiometricAvailable;
    debugPrint('AuthService: Biometric enabled = $_isBiometricEnabled, available = $_isBiometricAvailable');
  }
  
  /// Set a new PIN
  Future<bool> setPin(String pin) async {
    if (pin.length < 4 || pin.length > 6) {
      return false;
    }
    
    try {
      await _secureStorage.write(key: _pinKey, value: pin);
      _hasPinSet = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      return storedPin == pin;
    } catch (e) {
      return false;
    }
  }
  
  /// Remove PIN
  Future<void> removePin() async {
    await _secureStorage.delete(key: _pinKey);
    _hasPinSet = false;
    await setBiometricEnabled(false);
    notifyListeners();
  }
  
  /// Enable or disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    debugPrint('AuthService: setBiometricEnabled($enabled) called');
    if (enabled && !_isBiometricAvailable) {
      debugPrint('AuthService: Cannot enable - biometric not available');
      return false;
    }
    
    try {
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
      _isBiometricEnabled = enabled;
      debugPrint('AuthService: Biometric enabled set to $enabled');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthService: Failed to save biometric setting: $e');
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    if (!_isBiometricAvailable) {
      debugPrint('AuthService: Biometric not available');
      return false;
    }
    
    try {
      debugPrint('AuthService: Attempting biometric authentication...');
      final result = await _localAuth.authenticate(
        localizedReason: reason ?? 'Authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device credentials as fallback
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      debugPrint('AuthService: Biometric result = $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('AuthService: Biometric error - ${e.code}: ${e.message}');
      return false;
    }
  }
  
  /// Authenticate using either biometrics (if enabled) or PIN
  /// Returns true if authentication successful, false otherwise
  Future<AuthResult> authenticate({String? reason}) async {
    debugPrint('AuthService: authenticate() called');
    debugPrint('AuthService: biometricEnabled=$_isBiometricEnabled, biometricAvailable=$_isBiometricAvailable, hasPinSet=$_hasPinSet');
    
    // If biometric is enabled and available, try biometric first
    if (_isBiometricEnabled && _isBiometricAvailable) {
      debugPrint('AuthService: Trying biometric authentication...');
      final biometricSuccess = await authenticateWithBiometrics(reason: reason);
      if (biometricSuccess) {
        debugPrint('AuthService: Biometric succeeded');
        return AuthResult.success;
      }
      debugPrint('AuthService: Biometric failed, falling back to PIN');
      // If biometric fails, fall back to PIN if set
      if (_hasPinSet) {
        return AuthResult.requirePin;
      }
      return AuthResult.failed;
    }
    
    // If only PIN is set
    if (_hasPinSet) {
      debugPrint('AuthService: Only PIN is set, requiring PIN');
      return AuthResult.requirePin;
    }
    
    // No authentication method set up
    debugPrint('AuthService: No auth setup');
    return AuthResult.notSetup;
  }
  
  /// Check if any authentication method is set up
  bool get isAuthSetup => _hasPinSet || _isBiometricEnabled;
}

/// Result of authentication attempt
enum AuthResult {
  success,      // Authentication successful (biometric passed)
  requirePin,   // Need to show PIN input
  failed,       // Authentication failed
  notSetup,     // No authentication method set up
}
