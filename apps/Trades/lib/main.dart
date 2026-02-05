import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'theme/theme_provider.dart';
import 'theme/zafto_theme_builder.dart';
import 'screens/home_screen_v2.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'services/exam_prep/progress_tracker.dart';

/// ZAFTO - Multi-Trade Professional Platform
/// 
/// Design System v2.6 - LOCKED January 28, 2026
/// Philosophy: "Apple-crisp Silicon Valley Toolbox"

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('favorites');
  await Hive.openBox('exam_progress');
  await Hive.openBox('ai_credits');
  await Hive.openBox('app_state');
  // Sprint 5 Business boxes
  await Hive.openBox<String>('jobs');
  await Hive.openBox<String>('invoices');
  await Hive.openBox<String>('customers');
  // Sprint 16 Bid System boxes
  await Hive.openBox<String>('bids');
  await Hive.openBox<String>('bids_sync_meta');
  await Hive.openBox<String>('bid_templates');
  // Session 23 Time Clock boxes
  await Hive.openBox<String>('time_entries');
  await Hive.openBox<String>('time_entries_sync_meta');
  
  // Initialize exam progress tracker (CRITICAL - must be after Hive init)
  await ProgressTracker().initialize();
  
  // Lock to portrait mode (mobile only)
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  runApp(const ProviderScope(child: ZaftoApp()));
}

class ZaftoApp extends ConsumerWidget {
  const ZaftoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeData = ZaftoThemeBuilder.buildTheme(themeState.currentTheme);
    
    // Set system UI based on theme
    final isDark = themeState.isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: themeState.colors.navBg,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
    
    return MaterialApp(
      title: 'ZAFTO',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: themeData,
      themeMode: ThemeMode.system,
      home: const _AppEntry(),
    );
  }
}

/// Entry point - onboarding screens disabled for rebuild
class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    // WEB: Go directly to home
    if (kIsWeb) {
      return const HomeScreenV2();
    }

    // MOBILE: Check auth only
    final authState = ref.watch(authStateProvider);

    if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        body: Center(
          child: CircularProgressIndicator(color: colors.accentPrimary),
        ),
      );
    }

    if (authState.status == AuthStatus.unauthenticated || authState.user == null) {
      return const LoginScreen();
    }

    return const HomeScreenV2();
  }
}
