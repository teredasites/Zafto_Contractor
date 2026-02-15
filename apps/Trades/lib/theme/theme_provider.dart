import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'zafto_colors.dart';
import 'zafto_themes.dart';

/// Theme state provider for ZAFTO
/// 
/// Supports:
/// - Manual theme selection (all 10 themes)
/// - System theme matching (auto-detect light/dark)
/// - OLED detection for true black on OLED screens
/// - Persistent storage via Hive

// =============================================================================
// THEME STATE
// =============================================================================

class ThemeState {
  final ZaftoTheme currentTheme;
  final bool useSystemTheme;
  final bool isOledScreen;

  const ThemeState({
    required this.currentTheme,
    this.useSystemTheme = true,
    this.isOledScreen = false,
  });

  ZaftoColors get colors => ZaftoThemes.getColors(currentTheme);
  bool get isDark => ZaftoThemes.isDarkTheme(currentTheme);
  String get themeName => ZaftoThemes.getThemeName(currentTheme);

  ThemeState copyWith({
    ZaftoTheme? currentTheme,
    bool? useSystemTheme,
    bool? isOledScreen,
  }) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      isOledScreen: isOledScreen ?? this.isOledScreen,
    );
  }
}

// =============================================================================
// THEME NOTIFIER
// =============================================================================

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState(currentTheme: ZaftoTheme.dark)) {
    _loadSavedTheme();
  }

  static const String _themeKey = 'selected_theme';
  static const String _useSystemKey = 'use_system_theme';
  static const String _isOledKey = 'is_oled_screen';

  /// Load saved theme from Hive storage
  Future<void> _loadSavedTheme() async {
    try {
      final box = Hive.box('settings');
      final savedTheme = box.get(_themeKey, defaultValue: 'dark');
      final useSystem = box.get(_useSystemKey, defaultValue: true);
      final isOled = box.get(_isOledKey, defaultValue: false);

      final theme = ZaftoTheme.values.firstWhere(
        (t) => t.name == savedTheme,
        orElse: () => ZaftoTheme.dark,
      );

      state = ThemeState(
        currentTheme: useSystem ? _getSystemTheme(isOled) : theme,
        useSystemTheme: useSystem,
        isOledScreen: isOled,
      );
    } catch (e) {
      state = const ThemeState(currentTheme: ZaftoTheme.dark);
    }
  }

  /// Get appropriate theme based on system preference
  ZaftoTheme _getSystemTheme(bool isOled) {
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    if (brightness == Brightness.dark) {
      return isOled ? ZaftoTheme.oledBlack : ZaftoTheme.dark;
    }
    return ZaftoTheme.light;
  }

  /// Set a specific theme manually
  Future<void> setTheme(ZaftoTheme theme) async {
    state = state.copyWith(
      currentTheme: theme,
      useSystemTheme: false,
    );
    await _saveTheme();
  }

  /// Toggle system theme matching
  Future<void> setUseSystemTheme(bool value) async {
    state = state.copyWith(
      useSystemTheme: value,
      currentTheme: value ? _getSystemTheme(state.isOledScreen) : state.currentTheme,
    );
    await _saveTheme();
  }

  /// Set OLED screen preference
  Future<void> setOledScreen(bool value) async {
    state = state.copyWith(
      isOledScreen: value,
      currentTheme: state.useSystemTheme ? _getSystemTheme(value) : state.currentTheme,
    );
    await _saveTheme();
  }

  /// Handle system theme change
  void onSystemThemeChanged(Brightness brightness) {
    if (state.useSystemTheme) {
      final newTheme = brightness == Brightness.dark
          ? (state.isOledScreen ? ZaftoTheme.oledBlack : ZaftoTheme.dark)
          : ZaftoTheme.light;
      state = state.copyWith(currentTheme: newTheme);
    }
  }

  /// Save current theme to Hive
  Future<void> _saveTheme() async {
    try {
      final box = Hive.box('settings');
      await box.put(_themeKey, state.currentTheme.name);
      await box.put(_useSystemKey, state.useSystemTheme);
      await box.put(_isOledKey, state.isOledScreen);
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Main theme state provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Quick access to current colors
final zaftoColorsProvider = Provider<ZaftoColors>((ref) {
  return ref.watch(themeProvider).colors;
});

/// Quick access to isDark
final isDarkProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDark;
});
