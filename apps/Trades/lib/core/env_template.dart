// ZAFTO Environment Template
// Copy this file to env_dev.dart, env_staging.dart, or env_prod.dart
// and fill in real values from your Supabase dashboard.
//
// NEVER commit files with real keys. Only this template is committed.

import 'env.dart';

const templateConfig = EnvConfig(
  supabaseUrl: 'https://YOUR_PROJECT_REF.supabase.co',
  supabaseAnonKey: 'YOUR_ANON_KEY',
  powerSyncUrl: 'https://YOUR_POWERSYNC_INSTANCE.powersync.journeyapps.com',
  sentryDsn: 'https://YOUR_SENTRY_DSN@sentry.io/YOUR_PROJECT_ID',
  livekitUrl: 'wss://YOUR_LIVEKIT_PROJECT.livekit.cloud',
  livekitApiKey: 'YOUR_LIVEKIT_API_KEY',
  signalwireSpaceUrl: 'YOUR_SPACE.signalwire.com',
  signalwireProjectId: 'YOUR_SIGNALWIRE_PROJECT_ID',
  environment: Environment.dev, // Change to staging or prod as appropriate
);
