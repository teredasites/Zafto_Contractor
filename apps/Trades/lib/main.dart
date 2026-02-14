import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/supabase_client.dart';
import 'core/env.dart';
import 'l10n/app_localizations.dart';
import 'theme/theme_provider.dart';
import 'theme/zafto_theme_builder.dart';
import 'screens/home_screen_v2.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/company_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/exam_prep/progress_tracker.dart';

// ZAFTO - Multi-Trade Professional Platform
// Design System v2.6 - LOCKED January 28, 2026

// Build env config from dart-define or defaults (dev)
const _envConfig = EnvConfig(
  supabaseUrl: String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://onidzgatvndkhtiubbcw.supabase.co'),
  supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: ''),
  powerSyncUrl: String.fromEnvironment('POWERSYNC_URL',
      defaultValue: ''),
  sentryDsn: String.fromEnvironment('SENTRY_DSN',
      defaultValue: ''),
  livekitUrl: String.fromEnvironment('LIVEKIT_URL',
      defaultValue: ''),
  livekitApiKey: String.fromEnvironment('LIVEKIT_API_KEY',
      defaultValue: ''),
  signalwireSpaceUrl: String.fromEnvironment('SIGNALWIRE_SPACE_URL',
      defaultValue: ''),
  signalwireProjectId: String.fromEnvironment('SIGNALWIRE_PROJECT_ID',
      defaultValue: ''),
  environment: Environment.dev,
);

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = _envConfig.sentryDsn;
      options.environment = _envConfig.environment.name;
      options.tracesSampleRate = 1.0;
      options.attachScreenshot = true;
      options.beforeSend = (event, hint) {
        try {
          final user = currentUser;
          if (user != null) {
            event = event.copyWith(
              user: SentryUser(id: user.id),
            );
          }
        } catch (_) {}
        return event;
      };
    },
    appRunner: () async {
      // Initialize Supabase (primary backend)
      await initSupabase(_envConfig);

      if (!kIsWeb) {
        FlutterError.onError = (details) {
          Sentry.captureException(details.exception, stackTrace: details.stack);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
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
      // SK7 Floor Plan offline cache
      await Hive.openBox<String>('floor_plans_cache');
      await Hive.openBox<String>('floor_plans_sync_meta');

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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
