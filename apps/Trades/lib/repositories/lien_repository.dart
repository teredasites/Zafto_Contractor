// ZAFTO Lien Repository — Supabase Backend
// CRUD for lien_rules_by_state, lien_tracking, lien_document_templates.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/lien_rule.dart';
import '../models/lien_tracking.dart';

class LienRepository {
  // ── Lien Rules ───────────────────────────────────────

  static const _rulesTable = 'lien_rules_by_state';

  Future<List<LienRule>> getAllRules() async {
    try {
      final response = await supabase.from(_rulesTable).select().order('state_code');
      return (response as List).map((row) => LienRule.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load lien rules', userMessage: 'Could not load lien rules.', cause: e);
    }
  }

  Future<LienRule?> getRuleByState(String stateCode) async {
    try {
      final response = await supabase
          .from(_rulesTable)
          .select()
          .eq('state_code', stateCode)
          .maybeSingle();
      if (response == null) return null;
      return LienRule.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to load lien rule', userMessage: 'Could not load state lien rule.', cause: e);
    }
  }

  // ── Lien Tracking ────────────────────────────────────

  static const _trackingTable = 'lien_tracking';

  Future<List<LienTracking>> getActiveLiens() async {
    try {
      final response = await supabase
          .from(_trackingTable)
          .select()
          .inFilter('status', ['monitoring', 'notice_due', 'notice_sent', 'lien_eligible', 'lien_filed', 'enforcement'])
          .order('created_at', ascending: false);
      return (response as List).map((row) => LienTracking.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load liens', userMessage: 'Could not load active liens.', cause: e);
    }
  }

  Future<LienTracking?> getLienByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_trackingTable)
          .select()
          .eq('job_id', jobId)
          .maybeSingle();
      if (response == null) return null;
      return LienTracking.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to load lien', userMessage: 'Could not load lien record.', cause: e);
    }
  }

  Future<LienTracking> createLien(LienTracking lien) async {
    try {
      final response = await supabase
          .from(_trackingTable)
          .insert(lien.toJson())
          .select()
          .single();
      return LienTracking.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create lien', userMessage: 'Could not save lien record.', cause: e);
    }
  }

  Future<void> updateLienStatus(String id, String status) async {
    try {
      await supabase.from(_trackingTable).update({'status': status}).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update lien', userMessage: 'Could not update lien status.', cause: e);
    }
  }

  Future<void> markNoticeSent(String id, {required String documentPath}) async {
    try {
      await supabase.from(_trackingTable).update({
        'preliminary_notice_sent': true,
        'preliminary_notice_date': DateTime.now().toIso8601String().split('T').first,
        'preliminary_notice_document_path': documentPath,
        'status': 'notice_sent',
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to mark notice sent', userMessage: 'Could not update notice.', cause: e);
    }
  }

  Future<void> markLienFiled(String id, {required String documentPath}) async {
    try {
      await supabase.from(_trackingTable).update({
        'lien_filed': true,
        'lien_filing_date': DateTime.now().toIso8601String().split('T').first,
        'lien_filing_document_path': documentPath,
        'status': 'lien_filed',
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to mark lien filed', userMessage: 'Could not update lien filing.', cause: e);
    }
  }

  Future<void> markLienReleased(String id, {required String documentPath}) async {
    try {
      await supabase.from(_trackingTable).update({
        'lien_released': true,
        'lien_release_date': DateTime.now().toIso8601String().split('T').first,
        'lien_release_document_path': documentPath,
        'status': 'lien_released',
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to release lien', userMessage: 'Could not update lien release.', cause: e);
    }
  }

  // ── Document Templates ───────────────────────────────

  static const _templatesTable = 'lien_document_templates';

  Future<List<Map<String, dynamic>>> getTemplates(String stateCode, {String? documentType}) async {
    try {
      var query = supabase.from(_templatesTable).select().eq('state_code', stateCode);
      if (documentType != null) query = query.eq('document_type', documentType);
      final response = await query.order('document_type');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw DatabaseError('Failed to load templates', userMessage: 'Could not load document templates.', cause: e);
    }
  }

  /// Render a template by replacing {{PLACEHOLDER}} with actual values.
  String renderTemplate(String templateContent, Map<String, String> values) {
    var rendered = templateContent;
    for (final entry in values.entries) {
      rendered = rendered.replaceAll('{{${entry.key}}}', entry.value);
    }
    return rendered;
  }
}
