// ZAFTO Environment Configuration
// Created: Sprint A2 (Session 39)
//
// Usage:
//   import 'package:zafto/core/env.dart';
//   import 'package:zafto/core/env_dev.dart'; // or env_staging/env_prod
//
//   final config = devConfig; // from the imported env file

enum Environment { dev, staging, prod }

class EnvConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String powerSyncUrl;
  final String sentryDsn;
  final String livekitUrl;
  final String livekitApiKey;
  final String signalwireSpaceUrl;
  final String signalwireProjectId;
  final Environment environment;

  const EnvConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.powerSyncUrl,
    this.sentryDsn = '',
    this.livekitUrl = '',
    this.livekitApiKey = '',
    this.signalwireSpaceUrl = '',
    this.signalwireProjectId = '',
    required this.environment,
  });

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;

  /// Whether to enable verbose logging and debug tools
  bool get enableDebug => environment != Environment.prod;
}
