import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme modes supported by the app
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Service to manage app theme state
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  
  AppThemeMode _themeMode = AppThemeMode.dark;
  bool _isInitialized = false;

  AppThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Get the actual brightness based on theme mode and system settings
  Brightness getBrightness(BuildContext context) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
    }
  }

  /// Check if currently using dark mode
  bool isDarkMode(BuildContext context) {
    return getBrightness(context) == Brightness.dark;
  }

  /// Initialize the theme service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey);
    
    if (savedMode != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => AppThemeMode.dark,
      );
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Set the theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
    
    notifyListeners();
  }

  /// Toggle between light and dark mode (skips system)
  Future<void> toggleTheme(BuildContext context) async {
    if (isDarkMode(context)) {
      await setThemeMode(AppThemeMode.light);
    } else {
      await setThemeMode(AppThemeMode.dark);
    }
  }
}
