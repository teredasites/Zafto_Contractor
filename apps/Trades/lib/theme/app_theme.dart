import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ZAFTO Design System
/// 
/// Premium professional tool aesthetic
/// Apple-level polish, Silicon Valley next-level
/// "Would an Apple designer be embarrassed? If yes, redo it."

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════
  // COLORS - Exact spec from BUILD_STATUS.md
  // ═══════════════════════════════════════════════════════════════
  
  // Backgrounds
  static const Color backgroundDark = Color(0xFF0A0A0A);  // True dark
  static const Color surfaceDark = Color(0xFF141414);     // Cards
  static const Color cardDark = Color(0xFF1C1C1E);        // Elevated cards
  static const Color cardElevated = Color(0xFF232326);    // Higher elevation
  
  // Borders & Dividers
  static const Color border = Color(0xFF2C2C2E);
  static const Color divider = Color(0xFF2C2C2E);
  
  // Accent - Electric yellow
  static const Color electrical = Color(0xFFFFD60A);
  static const Color electricalMuted = Color(0x33FFD60A); // 20% opacity
  
  // Text hierarchy - Exact spec
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);
  
  // Semantic colors
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);
  
  // Trade accent colors
  static const Color plumbing = Color(0xFF0A84FF);
  static const Color hvac = Color(0xFF30D158);
  static const Color carpentry = Color(0xFFFF9F0A);
  
  // Legacy aliases
  static const Color background = backgroundDark;
  static const Color surface = surfaceDark;
  static const Color primary = electrical;
  static const Color primaryYellow = electrical;
  static const Color primaryLight = Color(0xFFFFE066);

  // ═══════════════════════════════════════════════════════════════
  // SPACING - 8px grid
  // ═══════════════════════════════════════════════════════════════
  
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  
  // Legacy aliases
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ═══════════════════════════════════════════════════════════════
  // CORNERS - Exact spec
  // ═══════════════════════════════════════════════════════════════
  
  static const double radiusSmall = 8.0;   // Buttons, chips
  static const double radiusMedium = 12.0; // Cards, inputs
  static const double radiusLarge = 16.0;  // Modals, sheets
  static const double radiusFull = 9999.0; // Pills, avatars
  
  // Legacy aliases
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // ═══════════════════════════════════════════════════════════════
  // SHADOWS - Exact spec
  // ═══════════════════════════════════════════════════════════════
  
  static List<BoxShadow> get elevation1 => [
    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(0, 1)),
  ];
  
  static List<BoxShadow> get elevation2 => [
    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  
  static List<BoxShadow> get elevation3 => [
    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8)),
  ];
  
  // Legacy aliases
  static List<BoxShadow> get shadowSM => elevation1;
  static List<BoxShadow> get shadowMD => elevation2;
  static List<BoxShadow> get shadowLG => elevation3;

  // ═══════════════════════════════════════════════════════════════
  // ANIMATIONS
  // ═══════════════════════════════════════════════════════════════
  
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEmphasized = Curves.easeOutCubic;

  // ═══════════════════════════════════════════════════════════════
  // HAPTICS - Premium feel
  // ═══════════════════════════════════════════════════════════════
  
  static void hapticLight() => HapticFeedback.lightImpact();
  static void hapticMedium() => HapticFeedback.mediumImpact();
  static void hapticHeavy() => HapticFeedback.heavyImpact();
  static void hapticSelection() => HapticFeedback.selectionClick();

  // ═══════════════════════════════════════════════════════════════
  // CARD DECORATIONS - Reusable
  // ═══════════════════════════════════════════════════════════════
  
  /// Standard card - surface color, medium radius, elevation1
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardDark,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: elevation1,
  );
  
  /// Elevated card - higher surface, large radius, elevation2
  static BoxDecoration get cardElevatedDecoration => BoxDecoration(
    color: cardElevated,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: elevation2,
  );
  
  /// Interactive card - adds border on surface
  static BoxDecoration get cardInteractiveDecoration => BoxDecoration(
    color: surfaceDark,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: border, width: 1),
  );
  
  /// Accent card - yellow tinted background
  static BoxDecoration get cardAccentDecoration => BoxDecoration(
    color: electricalMuted,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: electrical.withOpacity(0.3), width: 1),
  );

  // ═══════════════════════════════════════════════════════════════
  // INPUT DECORATIONS
  // ═══════════════════════════════════════════════════════════════
  
  static InputDecoration inputDecoration({String? hint, String? label, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: surfaceDark,
      hintStyle: const TextStyle(color: textTertiary, fontSize: 15),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: electrical, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      
      colorScheme: const ColorScheme.dark(
        primary: electrical,
        secondary: info,
        surface: surfaceDark,
        error: error,
        onPrimary: Color(0xFF000000),
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      
      // Typography - SF Pro spec
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'SF Pro Display', fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: textPrimary),
        displayMedium: TextStyle(fontFamily: 'SF Pro Display', fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: textPrimary),
        headlineLarge: TextStyle(fontFamily: 'SF Pro Display', fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.26, color: textPrimary),
        headlineMedium: TextStyle(fontFamily: 'SF Pro Display', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.24, color: textPrimary),
        titleLarge: TextStyle(fontFamily: 'SF Pro Text', fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontFamily: 'SF Pro Text', fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: TextStyle(fontFamily: 'SF Pro Text', fontSize: 17, fontWeight: FontWeight.w400, height: 1.5, color: textPrimary),
        bodyMedium: TextStyle(fontFamily: 'SF Pro Text', fontSize: 15, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: TextStyle(fontFamily: 'SF Pro Text', fontSize: 13, fontWeight: FontWeight.w400, color: textTertiary),
        labelLarge: TextStyle(fontFamily: 'SF Pro Text', fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        labelMedium: TextStyle(fontFamily: 'SF Pro Text', fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall: TextStyle(fontFamily: 'SF Pro Text', fontSize: 11, fontWeight: FontWeight.w500, color: textTertiary),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium), borderSide: const BorderSide(color: electrical, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textTertiary),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electrical,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(0, 48), // 48px touch target
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          textStyle: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          textStyle: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: electrical,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: electrical,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 1),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardElevated,
        contentTextStyle: const TextStyle(fontFamily: 'SF Pro Text', color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        behavior: SnackBarBehavior.floating,
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: electricalMuted,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        labelStyle: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 14, fontWeight: FontWeight.w500),
      ),
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardDark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        elevation: 0,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        elevation: 0,
      ),
    );
  }
}
