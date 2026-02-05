import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'zafto_colors.dart';
import 'zafto_themes.dart';

/// ZAFTO Design System v2.6 - Theme Builder
/// 
/// LOCKED - January 28, 2026 - DO NOT DEVIATE
/// 
/// Builds Flutter ThemeData from ZaftoColors tokens.
/// All UI components should use Theme.of(context).extension<ZaftoColors>()

class ZaftoThemeBuilder {
  ZaftoThemeBuilder._();

  // ===========================================================================
  // SPACING - 4px base grid
  // ===========================================================================
  
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double space2XL = 24.0;

  // ===========================================================================
  // CORNERS
  // ===========================================================================
  
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusFull = 9999.0;

  // ===========================================================================
  // ANIMATIONS
  // ===========================================================================
  
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);

  // ===========================================================================
  // HAPTICS
  // ===========================================================================
  
  static void hapticLight() => HapticFeedback.lightImpact();
  static void hapticMedium() => HapticFeedback.mediumImpact();
  static void hapticSelection() => HapticFeedback.selectionClick();

  // ===========================================================================
  // THEME BUILDER
  // ===========================================================================

  /// Build ThemeData from a ZaftoTheme
  static ThemeData buildTheme(ZaftoTheme theme) {
    final colors = ZaftoThemes.getColors(theme);
    return _buildThemeData(colors);
  }

  /// Build ThemeData from ZaftoColors
  static ThemeData _buildThemeData(ZaftoColors colors) {
    final isDark = colors.isDark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.bgBase,
      
      // Disable InkSparkle shader (causes web compilation crashes)
      splashFactory: InkSplash.splashFactory,
      
      // Color scheme
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.accentPrimary,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: colors.accentInfo,
        onSecondary: Colors.white,
        error: colors.accentError,
        onError: Colors.white,
        surface: colors.bgElevated,
        onSurface: colors.textPrimary,
      ),

      // Extensions - THIS IS HOW UI ACCESSES TOKENS
      extensions: [colors],

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: colors.bgElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),

      // Typography
      textTheme: _buildTextTheme(colors),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgInset,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: colors.accentPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colors.textQuaternary),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.borderDefault),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
        ),
      ),

      // Bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.navBg,
        selectedItemColor: colors.accentPrimary,
        unselectedItemColor: colors.textQuaternary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        elevation: 0,
      ),
    );
  }

  /// Build text theme with proper hierarchy
  static TextTheme _buildTextTheme(ZaftoColors colors) {
    return TextTheme(
      // Display - 20px bold (stats, large numbers)
      displayLarge: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      // Title - 17px semi (card titles, section heads)
      titleLarge: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      // Body - 15px medium (primary text, buttons)
      bodyLarge: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
      ),
      // Body2 - 14px regular (descriptions)
      bodyMedium: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      // Caption - 13px regular (secondary info)
      bodySmall: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colors.textTertiary,
      ),
      // Label - 11px semi uppercase (section headers)
      labelLarge: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colors.textTertiary,
      ),
      // Micro - 10px medium (nav labels, badges)
      labelMedium: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: colors.textQuaternary,
      ),
      // Tiny - 9px semi uppercase (stat labels)
      labelSmall: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colors.textTertiary,
      ),
    );
  }
}
