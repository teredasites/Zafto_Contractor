// ZAFTO Realtor Portal Settings Repository — Supabase Backend
// CRUD for realtor_portal_settings table (1:1 with company).

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/realtor_portal_settings.dart';

class RealtorPortalSettingsRepository {
  static const _table = 'realtor_portal_settings';

  Future<RealtorPortalSettings?> getSettings(String companyId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('company_id', companyId)
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (response == null) return null;
      return RealtorPortalSettings.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load portal settings',
        userMessage: 'Could not load portal settings.',
        cause: e,
      );
    }
  }

  Future<RealtorPortalSettings> upsertSettings(
      RealtorPortalSettings settings) async {
    try {
      final response = await supabase
          .from(_table)
          .upsert(settings.toInsertJson(), onConflict: 'company_id')
          .select()
          .single();
      return RealtorPortalSettings.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to save portal settings',
        userMessage: 'Could not save settings. Please try again.',
        cause: e,
      );
    }
  }

  Future<RealtorPortalSettings> updateSettings(
      String id, RealtorPortalSettings settings) async {
    try {
      final response = await supabase
          .from(_table)
          .update(settings.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return RealtorPortalSettings.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update portal settings',
        userMessage: 'Could not update settings. Please try again.',
        cause: e,
      );
    }
  }
}
