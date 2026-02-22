// ZAFTO Realtor Portal Settings Provider — Riverpod
// Connects realtor_portal_settings_repository to Flutter UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/realtor_portal_settings_repository.dart';
import '../models/realtor_portal_settings.dart';

final realtorPortalSettingsRepoProvider =
    Provider((ref) => RealtorPortalSettingsRepository());

final realtorPortalSettingsProvider = FutureProvider.autoDispose
    .family<RealtorPortalSettings?, String>(
  (ref, companyId) async {
    final repo = ref.watch(realtorPortalSettingsRepoProvider);
    return repo.getSettings(companyId);
  },
);
