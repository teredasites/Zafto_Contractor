import 'package:flutter/material.dart';

/// ZAFTO Design System v2.6 - Color Token System
/// 
/// LOCKED - January 28, 2026 - DO NOT DEVIATE
/// 
/// This file defines the semantic color tokens used throughout the app.
/// All UI must use these tokens via Theme.of(context).extension<ZaftoColors>()
/// 
/// Philosophy: "Apple-crisp Silicon Valley Toolbox"
/// Inspiration: Linear, Arc Browser, Raycast, Stripe iOS

/// Semantic color tokens for ZAFTO themes
class ZaftoColors extends ThemeExtension<ZaftoColors> {
  // Background tokens
  final Color bgBase;
  final Color bgElevated;
  final Color bgInset;
  
  // Text tokens with opacity-based hierarchy
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textQuaternary;
  
  // Accent tokens
  final Color accentPrimary;
  final Color accentSuccess;
  final Color accentWarning;
  final Color accentError;
  final Color accentInfo;
  
  // Border tokens
  final Color borderDefault;
  final Color borderSubtle;
  final Color borderStrong;
  
  // Fill tokens (for interactive elements)
  final Color fillDefault;
  final Color fillHover;
  final Color fillPressed;
  
  // Meta (navigation, system)
  final Color navBg;
  final Color navBorder;
  
  // Theme metadata
  final bool isDark;
  final String themeName;

  // =========================================================================
  // CONVENIENCE GETTERS (Aliases for common usage patterns)
  // These map to existing tokens - not new colors, just aliases.
  // =========================================================================

  /// Alias for bgElevated - used for card backgrounds
  Color get bgCard => bgElevated;

  /// Alias for accentWarning - short form
  Color get warning => accentWarning;

  /// Alias for accentSuccess - positive/success state
  Color get accentPositive => accentSuccess;

  /// Alias for accentError - short form
  Color get error => accentError;

  /// Alias for accentSuccess - short form
  Color get success => accentSuccess;

  /// Alias for borderDefault - short form
  Color get border => borderDefault;

  /// Alias for accentError - negative/error state
  Color get accentNegative => accentError;

  /// Alias for accentError - destructive actions
  Color get accentDestructive => accentError;

  /// Contrasting text for use on accent-colored backgrounds.
  /// Automatically picks dark or light text based on accent luminance.
  Color get textOnAccent =>
      accentPrimary.computeLuminance() > 0.4
          ? const Color(0xFF0D0D0D)
          : const Color(0xFFFFFFFF);

  const ZaftoColors({
    required this.bgBase,
    required this.bgElevated,
    required this.bgInset,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuaternary,
    required this.accentPrimary,
    required this.accentSuccess,
    required this.accentWarning,
    required this.accentError,
    required this.accentInfo,
    required this.borderDefault,
    required this.borderSubtle,
    required this.borderStrong,
    required this.fillDefault,
    required this.fillHover,
    required this.fillPressed,
    required this.navBg,
    required this.navBorder,
    required this.isDark,
    required this.themeName,
  });

  @override
  ZaftoColors copyWith({
    Color? bgBase,
    Color? bgElevated,
    Color? bgInset,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textQuaternary,
    Color? accentPrimary,
    Color? accentSuccess,
    Color? accentWarning,
    Color? accentError,
    Color? accentInfo,
    Color? borderDefault,
    Color? borderSubtle,
    Color? borderStrong,
    Color? fillDefault,
    Color? fillHover,
    Color? fillPressed,
    Color? navBg,
    Color? navBorder,
    bool? isDark,
    String? themeName,
  }) {
    return ZaftoColors(
      bgBase: bgBase ?? this.bgBase,
      bgElevated: bgElevated ?? this.bgElevated,
      bgInset: bgInset ?? this.bgInset,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textQuaternary: textQuaternary ?? this.textQuaternary,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      accentWarning: accentWarning ?? this.accentWarning,
      accentError: accentError ?? this.accentError,
      accentInfo: accentInfo ?? this.accentInfo,
      borderDefault: borderDefault ?? this.borderDefault,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      fillDefault: fillDefault ?? this.fillDefault,
      fillHover: fillHover ?? this.fillHover,
      fillPressed: fillPressed ?? this.fillPressed,
      navBg: navBg ?? this.navBg,
      navBorder: navBorder ?? this.navBorder,
      isDark: isDark ?? this.isDark,
      themeName: themeName ?? this.themeName,
    );
  }

  @override
  ZaftoColors lerp(ThemeExtension<ZaftoColors>? other, double t) {
    if (other is! ZaftoColors) return this;
    return ZaftoColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgInset: Color.lerp(bgInset, other.bgInset, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textQuaternary: Color.lerp(textQuaternary, other.textQuaternary, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSuccess: Color.lerp(accentSuccess, other.accentSuccess, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      accentError: Color.lerp(accentError, other.accentError, t)!,
      accentInfo: Color.lerp(accentInfo, other.accentInfo, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      fillDefault: Color.lerp(fillDefault, other.fillDefault, t)!,
      fillHover: Color.lerp(fillHover, other.fillHover, t)!,
      fillPressed: Color.lerp(fillPressed, other.fillPressed, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
      themeName: t < 0.5 ? themeName : other.themeName,
    );
  }
}
