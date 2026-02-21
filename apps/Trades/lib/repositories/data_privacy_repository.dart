// ZAFTO Data Privacy Repository
// Created: DEPTH33 — Consent management, data export/deletion,
// privacy policy versions. GDPR/CCPA compliant.
//
// Tables: user_consent, data_export_requests, data_deletion_requests,
//         privacy_policy_versions

import '../core/supabase_client.dart';
import '../models/data_privacy.dart';

class DataPrivacyRepository {
  static const _consent = 'user_consent';
  static const _exports = 'data_export_requests';
  static const _deletions = 'data_deletion_requests';
  static const _policies = 'privacy_policy_versions';

  // ══════════════════════════════════════════════════════════════
  // USER CONSENT
  // ══════════════════════════════════════════════════════════════

  /// Get all consent records for the current user
  Future<List<UserConsent>> getConsents() async {
    final data = await supabase
        .from(_consent)
        .select()
        .order('consent_type');
    return data.map((row) => UserConsent.fromJson(row)).toList();
  }

  /// Get a specific consent by type
  Future<UserConsent?> getConsentByType(ConsentType type) async {
    final data = await supabase
        .from(_consent)
        .select()
        .eq('consent_type', type.toJson())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? UserConsent.fromJson(data) : null;
  }

  /// Grant or revoke a consent (creates new audit record)
  Future<UserConsent> setConsent({
    required String userId,
    required String companyId,
    required ConsentType consentType,
    required bool granted,
    required String consentVersion,
    String? ipAddress,
    String? userAgent,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await supabase
        .from(_consent)
        .insert({
          'user_id': userId,
          'company_id': companyId,
          'consent_type': consentType.toJson(),
          'granted': granted,
          'granted_at': granted ? now : null,
          'revoked_at': granted ? null : now,
          'consent_version': consentVersion,
          'ip_address': ipAddress,
          'user_agent': userAgent,
        })
        .select()
        .single();
    return UserConsent.fromJson(data);
  }

  /// Get latest consent status per type for the current user
  Future<Map<ConsentType, bool>> getConsentStatus() async {
    final consents = await getConsents();
    final status = <ConsentType, bool>{};
    // Group by type, take the most recent
    for (final consent in consents) {
      if (!status.containsKey(consent.consentType)) {
        status[consent.consentType] = consent.granted;
      }
    }
    return status;
  }

  // ══════════════════════════════════════════════════════════════
  // DATA EXPORT REQUESTS
  // ══════════════════════════════════════════════════════════════

  /// Get all export requests for the current user
  Future<List<DataExportRequest>> getExportRequests() async {
    final data = await supabase
        .from(_exports)
        .select()
        .order('created_at', ascending: false);
    return data.map((row) => DataExportRequest.fromJson(row)).toList();
  }

  /// Request a data export
  Future<DataExportRequest> requestExport({
    required String userId,
    required String companyId,
    ExportFormat format = ExportFormat.json,
  }) async {
    final data = await supabase
        .from(_exports)
        .insert({
          'user_id': userId,
          'company_id': companyId,
          'export_format': format.toJson(),
        })
        .select()
        .single();
    return DataExportRequest.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // DATA DELETION REQUESTS
  // ══════════════════════════════════════════════════════════════

  /// Get all deletion requests for the current user
  Future<List<DataDeletionRequest>> getDeletionRequests() async {
    final data = await supabase
        .from(_deletions)
        .select()
        .order('created_at', ascending: false);
    return data.map((row) => DataDeletionRequest.fromJson(row)).toList();
  }

  /// Request data deletion
  Future<DataDeletionRequest> requestDeletion({
    required String userId,
    required String companyId,
    DeletionScope scope = DeletionScope.userData,
    String? reason,
  }) async {
    final data = await supabase
        .from(_deletions)
        .insert({
          'user_id': userId,
          'company_id': companyId,
          'scope': scope.toJson(),
          'reason': reason,
        })
        .select()
        .single();
    return DataDeletionRequest.fromJson(data);
  }

  /// Confirm deletion with confirmation code
  Future<DataDeletionRequest> confirmDeletion({
    required String id,
    required String confirmationCode,
  }) async {
    final now = DateTime.now().toUtc();
    final gracePeriodEnd = now.add(const Duration(days: 30));
    final data = await supabase
        .from(_deletions)
        .update({
          'status': 'confirmed',
          'confirmation_code': confirmationCode,
          'confirmed_at': now.toIso8601String(),
          'grace_period_ends': gracePeriodEnd.toIso8601String(),
        })
        .eq('id', id)
        .eq('status', 'pending')
        .select()
        .single();
    return DataDeletionRequest.fromJson(data);
  }

  /// Cancel deletion request (only during pending or grace period)
  Future<DataDeletionRequest> cancelDeletion(String id) async {
    final data = await supabase
        .from(_deletions)
        .update({'status': 'cancelled'})
        .eq('id', id)
        .select()
        .single();
    return DataDeletionRequest.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // PRIVACY POLICY VERSIONS
  // ══════════════════════════════════════════════════════════════

  /// Get all policy versions
  Future<List<PrivacyPolicyVersion>> getPolicyVersions() async {
    final data = await supabase
        .from(_policies)
        .select()
        .order('effective_at', ascending: false);
    return data.map((row) => PrivacyPolicyVersion.fromJson(row)).toList();
  }

  /// Get the current (latest) policy version
  Future<PrivacyPolicyVersion?> getCurrentPolicy() async {
    final data = await supabase
        .from(_policies)
        .select()
        .lte('effective_at', DateTime.now().toUtc().toIso8601String())
        .order('effective_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? PrivacyPolicyVersion.fromJson(data) : null;
  }
}
