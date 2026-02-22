import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/signing_workflow.dart';

class SigningWorkflowRepository {
  final SupabaseClient _client;

  SigningWorkflowRepository(this._client);

  /// Get all active workflows for a company.
  Future<List<SigningWorkflow>> getByCompany(
    String companyId, {
    String? status,
    int limit = 50,
  }) async {
    var query = _client
        .from('signing_workflows')
        .select()
        .eq('company_id', companyId)
        .isFilter('deleted_at', null);

    if (status != null) {
      query = query.eq('status', status);
    }

    final res = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List)
        .map((e) => SigningWorkflow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single workflow by ID.
  Future<SigningWorkflow?> getById(String id) async {
    final res = await _client
        .from('signing_workflows')
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (res == null) return null;
    return SigningWorkflow.fromJson(res);
  }

  /// Get workflows for a specific rendered document.
  Future<List<SigningWorkflow>> getByRender(String renderId) async {
    final res = await _client
        .from('signing_workflows')
        .select()
        .eq('render_id', renderId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => SigningWorkflow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new signing workflow.
  Future<SigningWorkflow> create(Map<String, dynamic> data) async {
    final res = await _client
        .from('signing_workflows')
        .insert(data)
        .select()
        .single();
    return SigningWorkflow.fromJson(res);
  }

  /// Update workflow status.
  Future<void> updateStatus(String id, String status) async {
    final updateData = <String, dynamic>{'status': status};
    if (status == 'completed') {
      updateData['completed_at'] = DateTime.now().toIso8601String();
    }
    await _client
        .from('signing_workflows')
        .update(updateData)
        .eq('id', id);
  }

  /// Void a workflow.
  Future<void> voidWorkflow(
    String id,
    String voidedBy,
    String reason,
  ) async {
    await _client.from('signing_workflows').update({
      'status': 'voided',
      'voided_at': DateTime.now().toIso8601String(),
      'voided_by': voidedBy,
      'voided_reason': reason,
    }).eq('id', id);
  }

  /// Soft delete.
  Future<void> softDelete(String id) async {
    await _client.from('signing_workflows').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ── Audit Events ──

  /// Get audit events for a signature request.
  Future<List<SignatureAuditEvent>> getAuditEvents({
    String? signatureRequestId,
    String? renderId,
    int limit = 100,
  }) async {
    var query = _client.from('signature_audit_events').select();

    if (signatureRequestId != null) {
      query = query.eq('signature_request_id', signatureRequestId);
    }
    if (renderId != null) {
      query = query.eq('render_id', renderId);
    }

    final res = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List)
        .map((e) => SignatureAuditEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Log an audit event.
  Future<void> logAuditEvent(Map<String, dynamic> event) async {
    await _client.from('signature_audit_events').insert(event);
  }
}
