import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CyberFly Color Palette
class CyberColors {
  CyberColors._();

  // Primary Neon Colors
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonMagenta = Color(0xFFFF00FF);
  static const Color neonGreen = Color(0xFF00FF41);
  static const Color neonYellow = Color(0xFFFFFF00);
  static const Color neonRed = Color(0xFFFF0055);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color neonPurple = Color(0xFF9D00FF);

  // Background Colors (Dark Space Blue)
  static const Color backgroundDark = Color(0xFF0A0E27);
  static const Color backgroundMedium = Color(0xFF1A1F3A);
  static const Color backgroundLight = Color(0xFF252B4A);
  static const Color backgroundCard = Color(0xFF151933);
  static const Color backgroundElevated = Color(0xFF1E2444);
  
  // Alias for convenience
  static const Color cardDark = backgroundCard;

  // Text Colors
  static const Color textPrimary = Color(0xFFE0E6FF);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textDim = Color(0xFF5A6380);
  static const Color textMuted = Color(0xFF3D4460);

  // Status Colors
  static const Color online = neonGreen;
  static const Color offline = Color(0xFF6B7280);
  static const Color syncing = neonCyan;
  static const Color warning = neonYellow;
  static const Color error = neonRed;
  static const Color connecting = neonOrange;

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [neonGreen, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [neonYellow, neonOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [neonRed, neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundDark, backgroundMedium],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [backgroundCard, backgroundElevated],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow Colors (with opacity for shadows)
  static Color cyanGlow = neonCyan.withOpacity(0.6);
  static Color magentaGlow = neonMagenta.withOpacity(0.6);
  static Color greenGlow = neonGreen.withOpacity(0.6);
  static Color yellowGlow = neonYellow.withOpacity(0.5);
  static Color redGlow = neonRed.withOpacity(0.6);
}

/// CyberFly Shadows and Glows
class CyberShadows {
  CyberShadows._();

  static List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.3 * intensity),
        blurRadius: 8,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: color.withOpacity(0.2 * intensity),
        blurRadius: 16,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withOpacity(0.1 * intensity),
        blurRadius: 32,
        spreadRadius: 4,
      ),
    ];
  }

  static List<BoxShadow> get cyanGlow => neonGlow(CyberColors.neonCyan);
  static List<BoxShadow> get magentaGlow => neonGlow(CyberColors.neonMagenta);
  static List<BoxShadow> get greenGlow => neonGlow(CyberColors.neonGreen);
  static List<BoxShadow> get yellowGlow => neonGlow(CyberColors.neonYellow);
  static List<BoxShadow> get redGlow => neonGlow(CyberColors.neonRed);

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: CyberColors.neonCyan.withOpacity(0.05),
      blurRadius: 20,
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

/// CyberFly Border Styles
class CyberBorders {
  CyberBorders._();

  static Border glowBorder(Color color, {double width = 1.0}) {
    return Border.all(color: color.withOpacity(0.5), width: width);
  }

  static BoxDecoration glowingCard({
    Color glowColor = CyberColors.neonCyan,
    double borderRadius = 16,
    double glowIntensity = 1.0,
  }) {
    return BoxDecoration(
      gradient: CyberColors.cardGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: glowColor.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: CyberShadows.neonGlow(glowColor, intensity: glowIntensity),
    );
  }

  static BoxDecoration angularCard({
    Color glowColor = CyberColors.neonCyan,
  }) {
    return BoxDecoration(
      color: CyberColors.backgroundCard,
      border: Border.all(
        color: glowColor.withOpacity(0.4),
        width: 1,
      ),
      boxShadow: CyberShadows.neonGlow(glowColor, intensity: 0.5),
    );
  }
}

/// CyberFly Theme Data
class CyberFlyTheme {
  CyberFlyTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CyberColors.backgroundDark,
      primaryColor: CyberColors.neonCyan,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: CyberColors.neonCyan,
        secondary: CyberColors.neonMagenta,
        tertiary: CyberColors.neonGreen,
        surface: CyberColors.backgroundCard,
        error: CyberColors.neonRed,
        onPrimary: CyberColors.backgroundDark,
        onSecondary: CyberColors.backgroundDark,
        onSurface: CyberColors.textPrimary,
        onError: CyberColors.textPrimary,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: CyberColors.backgroundDark.withOpacity(0.9),
        foregroundColor: CyberColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: CyberColors.neonCyan,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(
          color: CyberColors.neonCyan,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: CyberColors.backgroundCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.2),
            width: 1,
          ),
        ),
        shadowColor: CyberColors.neonCyan.withOpacity(0.3),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CyberColors.neonCyan,
          foregroundColor: CyberColors.backgroundDark,
          elevation: 8,
          shadowColor: CyberColors.cyanGlow,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CyberColors.neonCyan,
          side: const BorderSide(color: CyberColors.neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CyberColors.neonCyan,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CyberColors.neonCyan,
        foregroundColor: CyberColors.backgroundDark,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberColors.backgroundLight.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CyberColors.textDim.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CyberColors.textDim.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: CyberColors.neonCyan,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: CyberColors.neonRed,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: CyberColors.neonRed,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          color: CyberColors.textSecondary,
          fontFamily: 'monospace',
        ),
        hintStyle: TextStyle(
          color: CyberColors.textDim.withOpacity(0.7),
          fontFamily: 'monospace',
        ),
        prefixIconColor: CyberColors.textSecondary,
        suffixIconColor: CyberColors.textSecondary,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CyberColors.neonCyan,
        linearTrackColor: CyberColors.backgroundLight,
        circularTrackColor: CyberColors.backgroundLight,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: CyberColors.neonCyan,
        inactiveTrackColor: CyberColors.backgroundLight,
        thumbColor: CyberColors.neonCyan,
        overlayColor: CyberColors.neonCyan.withOpacity(0.2),
        valueIndicatorColor: CyberColors.neonCyan,
        valueIndicatorTextStyle: const TextStyle(
          color: CyberColors.backgroundDark,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberColors.neonCyan;
          }
          return CyberColors.textDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberColors.neonCyan.withOpacity(0.3);
          }
          return CyberColors.backgroundLight;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberColors.neonCyan.withOpacity(0.5);
          }
          return CyberColors.textDim.withOpacity(0.3);
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberColors.neonCyan;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(CyberColors.backgroundDark),
        side: BorderSide(
          color: CyberColors.neonCyan.withOpacity(0.5),
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: CyberColors.backgroundLight,
        selectedColor: CyberColors.neonCyan.withOpacity(0.2),
        labelStyle: const TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
        side: BorderSide(
          color: CyberColors.neonCyan.withOpacity(0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: CyberColors.backgroundCard,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.3),
          ),
        ),
        titleTextStyle: const TextStyle(
          color: CyberColors.neonCyan,
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 14,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CyberColors.backgroundCard,
        modalBackgroundColor: CyberColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CyberColors.backgroundElevated,
        contentTextStyle: const TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.3),
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: CyberColors.neonCyan,
        unselectedLabelColor: CyberColors.textSecondary,
        indicatorColor: CyberColors.neonCyan,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CyberColors.backgroundCard,
        indicatorColor: CyberColors.neonCyan.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: CyberColors.neonCyan,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(
            color: CyberColors.textSecondary,
            fontFamily: 'monospace',
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CyberColors.neonCyan);
          }
          return const IconThemeData(color: CyberColors.textSecondary);
        }),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: CyberColors.textDim.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: CyberColors.textPrimary,
        size: 24,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        displayMedium: TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        displaySmall: TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        headlineLarge: TextStyle(
          color: CyberColors.neonCyan,
          fontFamily: 'monospace',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        headlineMedium: TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: CyberColors.textSecondary,
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: CyberColors.textSecondary,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        labelMedium: TextStyle(
          color: CyberColors.textSecondary,
          fontFamily: 'monospace',
          fontSize: 12,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: CyberColors.textDim,
          fontFamily: 'monospace',
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Text Styles for special use cases
class CyberTextStyles {
  CyberTextStyles._();

  static const TextStyle neonTitle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: CyberColors.neonCyan,
    letterSpacing: 3,
    shadows: [
      Shadow(color: CyberColors.neonCyan, blurRadius: 10),
      Shadow(color: CyberColors.neonCyan, blurRadius: 20),
    ],
  );

  static const TextStyle glowingText = TextStyle(
    fontFamily: 'monospace',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: CyberColors.neonCyan,
    shadows: [
      Shadow(color: CyberColors.neonCyan, blurRadius: 8),
    ],
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: CyberColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: CyberColors.textPrimary,
    letterSpacing: 1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: CyberColors.textSecondary,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    color: CyberColors.textPrimary,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: 'monospace',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: CyberColors.textPrimary,
    letterSpacing: 1,
  );

  static const TextStyle statLabel = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: CyberColors.textSecondary,
    letterSpacing: 1,
  );

  static const TextStyle nodeId = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    color: CyberColors.neonCyan,
    letterSpacing: 0.5,
  );

  static const TextStyle latency = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static TextStyle latencyColored(int ms) {
    Color color;
    if (ms < 50) {
      color = CyberColors.neonGreen;
    } else if (ms < 100) {
      color = CyberColors.neonCyan;
    } else if (ms < 200) {
      color = CyberColors.neonYellow;
    } else if (ms < 500) {
      color = CyberColors.neonOrange;
    } else {
      color = CyberColors.neonRed;
    }
    return latency.copyWith(color: color);
  }
}
