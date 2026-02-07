import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/supabase_client.dart';
import 'core/env_dev.dart';
import 'theme/theme_provider.dart';
import 'theme/zafto_theme_builder.dart';
import 'screens/home_screen_v2.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/company_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/exam_prep/progress_tracker.dart';

/// ZAFTO - Multi-Trade Professional Platform
///
/// Design System v2.6 - LOCKED January 28, 2026

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = devConfig.sentryDsn;
      options.environment = devConfig.environment.name;
      options.tracesSampleRate = 1.0;
      options.attachScreenshot = true;
      options.beforeSend = (event, hint) {
        // Attach user context from current Supabase session if available
        try {
          final user = currentUser;
          if (user != null) {
            event = event.copyWith(
              user: SentryUser(id: user.id),
            );
          }
        } catch (_) {
          // Supabase may not be initialized yet — skip
        }
        return event;
      };
    },
    appRunner: () async {
      // Initialize Supabase (primary backend)
      await initSupabase(devConfig);

      // Initialize Firebase (kept for AI Cloud Functions — remove after Edge Function migration)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (!kIsWeb) {
        FlutterError.onError = (details) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          // Also report to Sentry
          Sentry.captureException(details.exception, stackTrace: details.stack);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          // Also report to Sentry
          Sentry.captureException(error, stackTrace: stack);
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
    },
  );
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

/// App entry point — routes based on auth state.
class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    // WEB: Go directly to home
    if (kIsWeb) {
      return const HomeScreenV2();
    }

    // MOBILE: Route based on auth state
    final authState = ref.watch(authStateProvider);

    if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        body: Center(
          child: CircularProgressIndicator(color: colors.accentPrimary),
        ),
      );
    }

    if (authState.status == AuthStatus.unauthenticated ||
        authState.status == AuthStatus.error) {
      return const LoginScreen();
    }

    if (authState.status == AuthStatus.needsOnboarding) {
      return const CompanySetupScreen();
    }

    return const HomeScreenV2();
  }
}
