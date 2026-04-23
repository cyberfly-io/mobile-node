import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CyberFly Color Palette
///
/// NOTE: Token names (`neonCyan`, etc.) are kept for API compatibility with
/// existing widgets, but the *values* have been toned down from pure neons to
/// muted Tailwind-400-style hues for a cleaner, more modern look. If you
/// actually need a vivid neon somewhere (e.g. a brand accent), use
/// [CyberColors.accentCyan] etc. below.
class CyberColors {
  CyberColors._();

  // Primary accent colors — toned-down, modern palette
  static const Color neonCyan = Color(0xFF22D3EE);    // cyan-400
  static const Color neonMagenta = Color(0xFFC084FC); // purple-400
  static const Color neonGreen = Color(0xFF34D399);   // emerald-400
  static const Color neonYellow = Color(0xFFFBBF24);  // amber-400
  static const Color neonRed = Color(0xFFF87171);     // red-400
  static const Color neonOrange = Color(0xFFFB923C);  // orange-400
  static const Color neonPurple = Color(0xFFA78BFA);  // violet-400
  static const Color neonBlue = Color(0xFF60A5FA);    // blue-400

  // High-saturation accents — reserved for special emphasis only.
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Background Colors (slate-tinged dark surfaces, not black-purple)
  static const Color backgroundDark = Color(0xFF0B0F1A);     // slate-950 tinted
  static const Color backgroundMedium = Color(0xFF111827);   // gray-900
  static const Color backgroundLight = Color(0xFF1E293B);    // slate-800
  static const Color backgroundCard = Color(0xFF111827);     // gray-900
  static const Color backgroundElevated = Color(0xFF1F2937); // gray-800

  // Deep gradient colors (kept for existing widgets, now more neutral)
  static const Color deepBlue = Color(0xFF0F172A);     // slate-900
  static const Color deepPurple = Color(0xFF1E1B3A);
  static const Color midnightBlue = Color(0xFF0B1220);
  static const Color cosmicPurple = Color(0xFF1E1B3A);

  // Alias for convenience
  static const Color cardDark = backgroundCard;

  // Text Colors
  static const Color textPrimary = Color(0xFFE5E7EB);   // gray-200
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textDim = Color(0xFF64748B);       // slate-500
  static const Color textMuted = Color(0xFF475569);     // slate-600

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

  // Card gradient: near-flat for a modern, quiet look.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [backgroundCard, backgroundElevated],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  // New futuristic gradients
  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [deepBlue, cosmicPurple, midnightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient cyberGradient = LinearGradient(
    colors: [
      Color(0xFF0A0A1A),
      Color(0xFF0D1B2A),
      Color(0xFF1B0A28),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient neonAccentGradient = LinearGradient(
    colors: [neonBlue, neonPurple, neonMagenta],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const RadialGradient glowGradient = RadialGradient(
    colors: [
      Color(0x30A855F7),
      Color(0x1500A3FF),
      Color(0x00000000),
    ],
    center: Alignment.center,
    radius: 1.0,
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

  // Modernized: dimmer, tighter glow for a cleaner look.
  // (Kept same public signature so callers can still pass `intensity`.)
  static List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.14 * intensity),
        blurRadius: 10,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: color.withOpacity(0.08 * intensity),
        blurRadius: 24,
        spreadRadius: 1,
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
        backgroundColor: CyberColors.backgroundDark.withOpacity(0.92),
        foregroundColor: CyberColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CyberColors.textPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(
          color: CyberColors.textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: CyberColors.backgroundCard,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        shadowColor: Colors.black.withOpacity(0.4),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CyberColors.neonCyan,
          foregroundColor: CyberColors.backgroundDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CyberColors.neonCyan,
          side: BorderSide(color: CyberColors.neonCyan.withOpacity(0.55), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CyberColors.neonCyan,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CyberColors.neonCyan,
        foregroundColor: CyberColors.backgroundDark,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberColors.backgroundLight.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.8),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: CyberColors.neonRed.withOpacity(0.8),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: CyberColors.neonRed,
            width: 1.4,
          ),
        ),
        labelStyle: const TextStyle(
          color: CyberColors.textSecondary,
        ),
        hintStyle: TextStyle(
          color: CyberColors.textDim.withOpacity(0.75),
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
          fontWeight: FontWeight.w600,
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
        selectedColor: CyberColors.neonCyan.withOpacity(0.18),
        labelStyle: const TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: Colors.white.withOpacity(0.08),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: CyberColors.backgroundCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        titleTextStyle: const TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 14,
          height: 1.4,
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
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
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
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CyberColors.backgroundCard,
        indicatorColor: CyberColors.neonCyan.withOpacity(0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: CyberColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: CyberColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
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

      // Text Theme — sans for display/body; monospace kept only for stat labels / IDs.
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        headlineLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        titleMedium: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: CyberColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 15,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: CyberColors.textSecondary,
          fontSize: 12,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: CyberColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        // labelMedium/Small stay monospace: they're used for IDs, stats,
        // and numeric readouts where a fixed-width face helps scanning.
        labelMedium: TextStyle(
          color: CyberColors.textSecondary,
          fontFamily: 'monospace',
          fontSize: 12,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          color: CyberColors.textDim,
          fontFamily: 'monospace',
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Light theme - Clean cyber-inspired light mode
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CyberColorsLight.backgroundLight,
      primaryColor: CyberColorsLight.primaryCyan,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: CyberColorsLight.primaryCyan,
        secondary: CyberColorsLight.primaryMagenta,
        tertiary: CyberColorsLight.primaryGreen,
        surface: CyberColorsLight.cardBackground,
        error: CyberColorsLight.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: CyberColorsLight.textPrimary,
        onError: Colors.white,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: CyberColorsLight.backgroundLight.withOpacity(0.92),
        foregroundColor: CyberColorsLight.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CyberColorsLight.textPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(
          color: CyberColorsLight.textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: CyberColorsLight.cardBackground,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: CyberColorsLight.borderColor,
            width: 1,
          ),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CyberColorsLight.primaryCyan,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CyberColorsLight.primaryCyan,
          side: BorderSide(color: CyberColorsLight.primaryCyan.withOpacity(0.55), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CyberColorsLight.primaryCyan,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CyberColorsLight.primaryCyan,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberColorsLight.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: CyberColorsLight.borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: CyberColorsLight.borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: CyberColorsLight.primaryCyan.withOpacity(0.8),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: CyberColorsLight.error,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: CyberColorsLight.error,
            width: 1.4,
          ),
        ),
        labelStyle: const TextStyle(
          color: CyberColorsLight.textSecondary,
        ),
        hintStyle: TextStyle(
          color: CyberColorsLight.textSecondary.withOpacity(0.7),
        ),
        prefixIconColor: CyberColorsLight.textSecondary,
        suffixIconColor: CyberColorsLight.textSecondary,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: CyberColorsLight.primaryCyan,
        linearTrackColor: CyberColorsLight.borderColor,
        circularTrackColor: CyberColorsLight.borderColor,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: CyberColorsLight.primaryCyan,
        inactiveTrackColor: CyberColorsLight.borderColor,
        thumbColor: CyberColorsLight.primaryCyan,
        overlayColor: CyberColorsLight.primaryCyan.withOpacity(0.2),
        valueIndicatorColor: CyberColorsLight.primaryCyan,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberColorsLight.primaryCyan;
          }
          return CyberColorsLight.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberColorsLight.primaryCyan.withOpacity(0.3);
          }
          return CyberColorsLight.borderColor;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberColorsLight.primaryCyan.withOpacity(0.5);
          }
          return CyberColorsLight.borderColor;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberColorsLight.primaryCyan;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(
          color: CyberColorsLight.primaryCyan.withOpacity(0.5),
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: CyberColorsLight.inputBackground,
        selectedColor: CyberColorsLight.primaryCyan.withOpacity(0.18),
        labelStyle: const TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: CyberColorsLight.borderColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: CyberColorsLight.cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: CyberColorsLight.borderColor,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: CyberColorsLight.cardBackground,
        modalBackgroundColor: CyberColorsLight.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CyberColorsLight.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: CyberColorsLight.primaryCyan,
        unselectedLabelColor: CyberColorsLight.textSecondary,
        indicatorColor: CyberColorsLight.primaryCyan,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CyberColorsLight.cardBackground,
        indicatorColor: CyberColorsLight.primaryCyan.withOpacity(0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: CyberColorsLight.primaryCyan,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: CyberColorsLight.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CyberColorsLight.primaryCyan);
          }
          return const IconThemeData(color: CyberColorsLight.textSecondary);
        }),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: CyberColorsLight.borderColor,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: CyberColorsLight.textPrimary,
        size: 24,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: CyberColorsLight.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 15,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: CyberColorsLight.textSecondary,
          fontSize: 12,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: CyberColorsLight.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        // labelMedium / labelSmall keep monospace — used for IDs, stats, numeric readouts.
        labelMedium: TextStyle(
          color: CyberColorsLight.textSecondary,
          fontFamily: 'monospace',
          fontSize: 12,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          color: CyberColorsLight.textSecondary,
          fontFamily: 'monospace',
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Light theme color palette
class CyberColorsLight {
  CyberColorsLight._();

  // Primary Colors (darker for light background)
  static const Color primaryCyan = Color(0xFF0097A7);
  static const Color primaryMagenta = Color(0xFFAD1457);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryYellow = Color(0xFFF9A825);
  static const Color primaryOrange = Color(0xFFE65100);
  static const Color primaryPurple = Color(0xFF6A1B9A);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundMedium = Color(0xFFECEFF3);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF); // Alias for consistency
  static const Color inputBackground = Color(0xFFF0F2F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDim = Color(0xFF9CA3AF);

  // Border & Divider Colors
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFE5E7EB); // Alias for consistency
  static const Color divider = Color(0xFFE5E7EB);

  // Status Colors
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color syncing = primaryCyan;
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color connecting = primaryOrange;

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, primaryMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundLight, backgroundMedium],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Theme-aware color helper - use this in widgets to get correct colors based on theme
class CyberTheme {
  CyberTheme._();

  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Primary accent color (cyan)
  static Color primary(BuildContext context) {
    return isDark(context) ? CyberColors.neonCyan : CyberColorsLight.primaryCyan;
  }

  /// Background color
  static Color background(BuildContext context) {
    return isDark(context) ? CyberColors.backgroundDark : CyberColorsLight.backgroundLight;
  }

  /// Card/surface background color
  static Color card(BuildContext context) {
    return isDark(context) ? CyberColors.backgroundCard : CyberColorsLight.cardBackground;
  }

  /// Elevated card background
  static Color cardElevated(BuildContext context) {
    return isDark(context) ? CyberColors.backgroundElevated : CyberColorsLight.cardBackground;
  }

  /// Primary text color
  static Color textPrimary(BuildContext context) {
    return isDark(context) ? CyberColors.textPrimary : CyberColorsLight.textPrimary;
  }

  /// Secondary text color
  static Color textSecondary(BuildContext context) {
    return isDark(context) ? CyberColors.textSecondary : CyberColorsLight.textSecondary;
  }

  /// Dim/muted text color
  static Color textDim(BuildContext context) {
    return isDark(context) ? CyberColors.textDim : CyberColorsLight.textDim;
  }

  /// Border color
  static Color border(BuildContext context) {
    return isDark(context) 
        ? CyberColors.textDim.withOpacity(0.2) 
        : CyberColorsLight.borderColor;
  }

  /// Divider color
  static Color divider(BuildContext context) {
    return isDark(context) 
        ? Colors.white.withOpacity(0.1) 
        : CyberColorsLight.borderColor;
  }

  /// Success/online color
  static Color success(BuildContext context) {
    return isDark(context) ? CyberColors.neonGreen : CyberColorsLight.online;
  }

  /// Warning color
  static Color warning(BuildContext context) {
    return isDark(context) ? CyberColors.neonYellow : CyberColorsLight.warning;
  }

  /// Error color
  static Color error(BuildContext context) {
    return isDark(context) ? CyberColors.neonRed : CyberColorsLight.error;
  }

  /// Navigation bar background
  static Color navBar(BuildContext context) {
    return isDark(context) ? const Color(0xFF1D1E33) : CyberColorsLight.cardBackground;
  }

  /// Navigation bar shadow
  static List<BoxShadow> navBarShadow(BuildContext context) {
    return isDark(context)
        ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))]
        : [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))];
  }

  /// App bar background with opacity
  static Color appBarBackground(BuildContext context, {double opacity = 0.9}) {
    return isDark(context) 
        ? CyberColors.backgroundDark.withOpacity(opacity)
        : CyberColorsLight.backgroundLight.withOpacity(opacity);
  }

  /// Settings card decoration
  static BoxDecoration settingsCard(BuildContext context, {Color? borderColor}) {
    return BoxDecoration(
      color: card(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? border(context),
      ),
    );
  }

  /// Icon container decoration
  static BoxDecoration iconContainer(BuildContext context, Color color) {
    return BoxDecoration(
      color: color.withOpacity(isDark(context) ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(8),
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
