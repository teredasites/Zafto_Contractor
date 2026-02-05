import 'package:flutter/material.dart';
import 'zafto_colors.dart';

/// ZAFTO Design System v2.6 - Theme Definitions
/// 
/// LOCKED - January 28, 2026 - DO NOT DEVIATE
/// 
/// 10 Themes: 4 Light + 5 Dark + 1 Accessibility
/// All hex values are EXACT per spec

enum ZaftoTheme {
  // Light themes
  light,
  warm,
  rose,
  mint,
  // Dark themes
  dark,
  midnight,
  nord,
  forest,
  oledBlack,
  // Accessibility
  highContrast,
}

class ZaftoThemes {
  ZaftoThemes._();

  /// Get ZaftoColors for a theme
  static ZaftoColors getColors(ZaftoTheme theme) {
    switch (theme) {
      case ZaftoTheme.light:
        return light;
      case ZaftoTheme.warm:
        return warm;
      case ZaftoTheme.rose:
        return rose;
      case ZaftoTheme.mint:
        return mint;
      case ZaftoTheme.dark:
        return dark;
      case ZaftoTheme.midnight:
        return midnight;
      case ZaftoTheme.nord:
        return nord;
      case ZaftoTheme.forest:
        return forest;
      case ZaftoTheme.oledBlack:
        return oledBlack;
      case ZaftoTheme.highContrast:
        return highContrast;
    }
  }

  /// Get display name for theme
  static String getThemeName(ZaftoTheme theme) {
    switch (theme) {
      case ZaftoTheme.light:
        return 'Light';
      case ZaftoTheme.warm:
        return 'Warm';
      case ZaftoTheme.rose:
        return 'Rosé';
      case ZaftoTheme.mint:
        return 'Mint';
      case ZaftoTheme.dark:
        return 'Dark';
      case ZaftoTheme.midnight:
        return 'Midnight';
      case ZaftoTheme.nord:
        return 'Nord';
      case ZaftoTheme.forest:
        return 'Forest';
      case ZaftoTheme.oledBlack:
        return 'OLED Black';
      case ZaftoTheme.highContrast:
        return 'High Contrast';
    }
  }

  /// Check if theme is dark
  static bool isDarkTheme(ZaftoTheme theme) {
    return theme == ZaftoTheme.dark ||
        theme == ZaftoTheme.midnight ||
        theme == ZaftoTheme.nord ||
        theme == ZaftoTheme.forest ||
        theme == ZaftoTheme.oledBlack ||
        theme == ZaftoTheme.highContrast;
  }

  /// Light themes list
  static const List<ZaftoTheme> lightThemes = [
    ZaftoTheme.light,
    ZaftoTheme.warm,
    ZaftoTheme.rose,
    ZaftoTheme.mint,
  ];

  /// Dark themes list
  static const List<ZaftoTheme> darkThemes = [
    ZaftoTheme.dark,
    ZaftoTheme.midnight,
    ZaftoTheme.nord,
    ZaftoTheme.forest,
    ZaftoTheme.oledBlack,
  ];


  // ===========================================================================
  // LIGHT THEMES
  // ===========================================================================

  /// 1. Light - Clean and bright
  static const ZaftoColors light = ZaftoColors(
    themeName: 'Light',
    isDark: false,
    bgBase: Color(0xFFF8F8FA),
    bgElevated: Color(0xFFFFFFFF),
    bgInset: Color(0xFFEFEFF4),
    textPrimary: Color(0xE0000000),
    textSecondary: Color(0x99000000),
    textTertiary: Color(0x6B000000),
    textQuaternary: Color(0x47000000),
    accentPrimary: Color(0xFF1A1A1A),
    accentSuccess: Color(0xFF34C759),
    accentWarning: Color(0xFFFF9500),
    accentError: Color(0xFFFF3B30),
    accentInfo: Color(0xFF007AFF),
    borderDefault: Color(0x1F000000),
    borderSubtle: Color(0x0F000000),
    borderStrong: Color(0x33000000),
    fillDefault: Color(0x0A000000),
    fillHover: Color(0x14000000),
    fillPressed: Color(0x1F000000),
    navBg: Color(0xFFF8F8FA),
    navBorder: Color(0x1F000000),
  );

  /// 2. Warm - Easy on eyes (sepia)
  static const ZaftoColors warm = ZaftoColors(
    themeName: 'Warm',
    isDark: false,
    bgBase: Color(0xFFF5F2EB),
    bgElevated: Color(0xFFFDFCF9),
    bgInset: Color(0xFFEBE7DE),
    textPrimary: Color(0xEB1C1917),
    textSecondary: Color(0xA61C1917),
    textTertiary: Color(0x731C1917),
    textQuaternary: Color(0x4D1C1917),
    accentPrimary: Color(0xFF292524),
    accentSuccess: Color(0xFF65A30D),
    accentWarning: Color(0xFFD97706),
    accentError: Color(0xFFDC2626),
    accentInfo: Color(0xFF0284C7),
    borderDefault: Color(0x1F1C1917),
    borderSubtle: Color(0x0F1C1917),
    borderStrong: Color(0x331C1917),
    fillDefault: Color(0x0A1C1917),
    fillHover: Color(0x141C1917),
    fillPressed: Color(0x1F1C1917),
    navBg: Color(0xFFF5F2EB),
    navBorder: Color(0x1F1C1917),
  );

  /// 3. Rosé - Soft pink tones
  static const ZaftoColors rose = ZaftoColors(
    themeName: 'Rosé',
    isDark: false,
    bgBase: Color(0xFFFDF4F5),
    bgElevated: Color(0xFFFFFAFA),
    bgInset: Color(0xFFF9E8EA),
    textPrimary: Color(0xE6501428),
    textSecondary: Color(0x9E501428),
    textTertiary: Color(0x73501428),
    textQuaternary: Color(0x4D501428),
    accentPrimary: Color(0xFF9F1239),
    accentSuccess: Color(0xFF059669),
    accentWarning: Color(0xFFD97706),
    accentError: Color(0xFFE11D48),
    accentInfo: Color(0xFF0891B2),
    borderDefault: Color(0x1F501428),
    borderSubtle: Color(0x0F501428),
    borderStrong: Color(0x33501428),
    fillDefault: Color(0x0A501428),
    fillHover: Color(0x14501428),
    fillPressed: Color(0x1F501428),
    navBg: Color(0xFFFDF4F5),
    navBorder: Color(0x1F501428),
  );

  /// 4. Mint - Fresh and calm
  static const ZaftoColors mint = ZaftoColors(
    themeName: 'Mint',
    isDark: false,
    bgBase: Color(0xFFF0FAF6),
    bgElevated: Color(0xFFFAFFFC),
    bgInset: Color(0xFFE0F2EB),
    textPrimary: Color(0xE6064E3B),
    textSecondary: Color(0x9E064E3B),
    textTertiary: Color(0x73064E3B),
    textQuaternary: Color(0x4D064E3B),
    accentPrimary: Color(0xFF047857),
    accentSuccess: Color(0xFF059669),
    accentWarning: Color(0xFFD97706),
    accentError: Color(0xFFDC2626),
    accentInfo: Color(0xFF0891B2),
    borderDefault: Color(0x1F064E3B),
    borderSubtle: Color(0x0F064E3B),
    borderStrong: Color(0x33064E3B),
    fillDefault: Color(0x0A064E3B),
    fillHover: Color(0x14064E3B),
    fillPressed: Color(0x1F064E3B),
    navBg: Color(0xFFF0FAF6),
    navBorder: Color(0x1F064E3B),
  );


  // ===========================================================================
  // DARK THEMES
  // ===========================================================================

  /// 5. Dark - Classic dark mode (DEFAULT FOR LCD)
  static const ZaftoColors dark = ZaftoColors(
    themeName: 'Dark',
    isDark: true,
    bgBase: Color(0xFF0A0A0B),
    bgElevated: Color(0xFF151516),
    bgInset: Color(0xFF050506),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0xADFFFFFF),
    textTertiary: Color(0x7AFFFFFF),
    textQuaternary: Color(0x52FFFFFF),
    accentPrimary: Color(0xFFFFFFFF),
    accentSuccess: Color(0xFF32D74B),
    accentWarning: Color(0xFFFF9F0A),
    accentError: Color(0xFFFF453A),
    accentInfo: Color(0xFF0A84FF),
    borderDefault: Color(0x33FFFFFF),
    borderSubtle: Color(0x1AFFFFFF),
    borderStrong: Color(0x4DFFFFFF),
    fillDefault: Color(0x14FFFFFF),
    fillHover: Color(0x1FFFFFFF),
    fillPressed: Color(0x29FFFFFF),
    navBg: Color(0xFF151516),
    navBorder: Color(0x33FFFFFF),
  );

  /// 6. Midnight - Deep blue (VS Code vibes)
  static const ZaftoColors midnight = ZaftoColors(
    themeName: 'Midnight',
    isDark: true,
    bgBase: Color(0xFF0B0D14),
    bgElevated: Color(0xFF12151F),
    bgInset: Color(0xFF060810),
    textPrimary: Color(0xF0E6EBFF),
    textSecondary: Color(0xB3C8D2EB),
    textTertiary: Color(0x7AC8D2EB),
    textQuaternary: Color(0x52C8D2EB),
    accentPrimary: Color(0xFFE8EDFF),
    accentSuccess: Color(0xFF4ADE80),
    accentWarning: Color(0xFFFBBF24),
    accentError: Color(0xFFF87171),
    accentInfo: Color(0xFF60A5FA),
    borderDefault: Color(0x33E6EBFF),
    borderSubtle: Color(0x1AE6EBFF),
    borderStrong: Color(0x4DE6EBFF),
    fillDefault: Color(0x14E6EBFF),
    fillHover: Color(0x1FE6EBFF),
    fillPressed: Color(0x29E6EBFF),
    navBg: Color(0xFF12151F),
    navBorder: Color(0x33E6EBFF),
  );

  /// 7. Nord - Arctic inspired
  static const ZaftoColors nord = ZaftoColors(
    themeName: 'Nord',
    isDark: true,
    bgBase: Color(0xFF2E3440),
    bgElevated: Color(0xFF3B4252),
    bgInset: Color(0xFF272C36),
    textPrimary: Color(0xF2ECEFF4),
    textSecondary: Color(0xBFD8DEE9),
    textTertiary: Color(0x80D8DEE9),
    textQuaternary: Color(0x52D8DEE9),
    accentPrimary: Color(0xFF88C0D0),
    accentSuccess: Color(0xFFA3BE8C),
    accentWarning: Color(0xFFEBCB8B),
    accentError: Color(0xFFBF616A),
    accentInfo: Color(0xFF81A1C1),
    borderDefault: Color(0x33ECEFF4),
    borderSubtle: Color(0x1AECEFF4),
    borderStrong: Color(0x4DECEFF4),
    fillDefault: Color(0x14ECEFF4),
    fillHover: Color(0x1FECEFF4),
    fillPressed: Color(0x29ECEFF4),
    navBg: Color(0xFF3B4252),
    navBorder: Color(0x33ECEFF4),
  );


  /// 8. Forest - Deep green tones
  static const ZaftoColors forest = ZaftoColors(
    themeName: 'Forest',
    isDark: true,
    bgBase: Color(0xFF0A100D),
    bgElevated: Color(0xFF131A15),
    bgInset: Color(0xFF060A08),
    textPrimary: Color(0xF0DCFCE7),
    textSecondary: Color(0xB3BBF7D0),
    textTertiary: Color(0x7ABBF7D0),
    textQuaternary: Color(0x52BBF7D0),
    accentPrimary: Color(0xFF6EE7B7),
    accentSuccess: Color(0xFF4ADE80),
    accentWarning: Color(0xFFFBBF24),
    accentError: Color(0xFFF87171),
    accentInfo: Color(0xFF22D3EE),
    borderDefault: Color(0x33DCFCE7),
    borderSubtle: Color(0x1ADCFCE7),
    borderStrong: Color(0x4DDCFCE7),
    fillDefault: Color(0x14DCFCE7),
    fillHover: Color(0x1FDCFCE7),
    fillPressed: Color(0x29DCFCE7),
    navBg: Color(0xFF131A15),
    navBorder: Color(0x33DCFCE7),
  );

  /// 9. OLED Black - True black (DEFAULT FOR OLED)
  static const ZaftoColors oledBlack = ZaftoColors(
    themeName: 'OLED Black',
    isDark: true,
    bgBase: Color(0xFF000000),
    bgElevated: Color(0xFF0C0C0C),
    bgInset: Color(0xFF000000),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0xADFFFFFF),
    textTertiary: Color(0x7AFFFFFF),
    textQuaternary: Color(0x52FFFFFF),
    accentPrimary: Color(0xFFFFFFFF),
    accentSuccess: Color(0xFF30D158),
    accentWarning: Color(0xFFFF9F0A),
    accentError: Color(0xFFFF453A),
    accentInfo: Color(0xFF0A84FF),
    borderDefault: Color(0x33FFFFFF),
    borderSubtle: Color(0x1AFFFFFF),
    borderStrong: Color(0x4DFFFFFF),
    fillDefault: Color(0x14FFFFFF),
    fillHover: Color(0x1FFFFFFF),
    fillPressed: Color(0x29FFFFFF),
    navBg: Color(0xFF0C0C0C),
    navBorder: Color(0x33FFFFFF),
  );

  /// 10. High Contrast - Maximum accessibility
  static const ZaftoColors highContrast = ZaftoColors(
    themeName: 'High Contrast',
    isDark: true,
    bgBase: Color(0xFF000000),
    bgElevated: Color(0xFF000000),
    bgInset: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFFFFF),
    textTertiary: Color(0xFFFFFFFF),
    textQuaternary: Color(0xCCFFFFFF),
    accentPrimary: Color(0xFFFFFF00),
    accentSuccess: Color(0xFF00FF00),
    accentWarning: Color(0xFFFFFF00),
    accentError: Color(0xFFFF0000),
    accentInfo: Color(0xFF00FFFF),
    borderDefault: Color(0x80FFFFFF),
    borderSubtle: Color(0x4DFFFFFF),
    borderStrong: Color(0xFFFFFFFF),
    fillDefault: Color(0x33FFFFFF),
    fillHover: Color(0x4DFFFFFF),
    fillPressed: Color(0x66FFFFFF),
    navBg: Color(0xFF000000),
    navBorder: Color(0x80FFFFFF),
  );
}
