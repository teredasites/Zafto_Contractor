// ZAFTO Permit Intelligence Repository — Supabase Backend
// CRUD for permit_jurisdictions, permit_requirements, job_permits, permit_inspections.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/permit_jurisdiction.dart';
import '../models/permit_requirement.dart';
import '../models/job_permit.dart';
import '../models/permit_inspection.dart';

class PermitIntelligenceRepository {
  // ── Jurisdictions ──────────────────────────────────────

  static const _jurisdictionsTable = 'permit_jurisdictions';

  Future<List<PermitJurisdiction>> getJurisdictions({String? stateCode}) async {
    try {
      var query = supabase.from(_jurisdictionsTable).select();
      if (stateCode != null) query = query.eq('state_code', stateCode);
      final response = await query.order('jurisdiction_name');
      return (response as List).map((row) => PermitJurisdiction.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load jurisdictions', userMessage: 'Could not load jurisdiction data.', cause: e);
    }
  }

  Future<PermitJurisdiction?> getJurisdictionByCity(String cityName, String stateCode) async {
    try {
      final response = await supabase
          .from(_jurisdictionsTable)
          .select()
          .eq('city_name', cityName)
          .eq('state_code', stateCode)
          .maybeSingle();
      if (response == null) return null;
      return PermitJurisdiction.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to find jurisdiction', userMessage: 'Could not find jurisdiction.', cause: e);
    }
  }

  Future<PermitJurisdiction> createJurisdiction(PermitJurisdiction jurisdiction) async {
    try {
      final response = await supabase
          .from(_jurisdictionsTable)
          .insert(jurisdiction.toJson())
          .select()
          .single();
      return PermitJurisdiction.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create jurisdiction', userMessage: 'Could not save jurisdiction.', cause: e);
    }
  }

  // ── Requirements ───────────────────────────────────────

  static const _requirementsTable = 'permit_requirements';

  Future<List<PermitRequirement>> getRequirements(String jurisdictionId, {String? tradeType}) async {
    try {
      var query = supabase.from(_requirementsTable).select().eq('jurisdiction_id', jurisdictionId);
      if (tradeType != null) query = query.eq('trade_type', tradeType);
      final response = await query.order('work_type');
      return (response as List).map((row) => PermitRequirement.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load requirements', userMessage: 'Could not load permit requirements.', cause: e);
    }
  }

  Future<PermitRequirement> createRequirement(PermitRequirement requirement) async {
    try {
      final response = await supabase
          .from(_requirementsTable)
          .insert(requirement.toJson())
          .select()
          .single();
      return PermitRequirement.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create requirement', userMessage: 'Could not save permit requirement.', cause: e);
    }
  }

  // ── Job Permits ────────────────────────────────────────

  static const _jobPermitsTable = 'job_permits';

  Future<List<JobPermit>> getJobPermits(String jobId) async {
    try {
      final response = await supabase
          .from(_jobPermitsTable)
          .select()
          .eq('job_id', jobId)
          .order('created_at');
      return (response as List).map((row) => JobPermit.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load job permits', userMessage: 'Could not load permits.', cause: e);
    }
  }

  Future<List<JobPermit>> getAllActivePermits() async {
    try {
      final response = await supabase
          .from(_jobPermitsTable)
          .select()
          .not('status', 'in', '("closed","denied")')
          .order('expiration_date');
      return (response as List).map((row) => JobPermit.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load permits', userMessage: 'Could not load active permits.', cause: e);
    }
  }

  Future<JobPermit> createJobPermit(JobPermit permit) async {
    try {
      final response = await supabase
          .from(_jobPermitsTable)
          .insert(permit.toJson())
          .select()
          .single();
      return JobPermit.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create permit', userMessage: 'Could not save permit.', cause: e);
    }
  }

  Future<void> updatePermitStatus(String id, PermitStatus status) async {
    try {
      final updates = <String, dynamic>{'status': status.dbValue};
      if (status == PermitStatus.approved) {
        updates['approval_date'] = DateTime.now().toIso8601String().split('T').first;
      }
      await supabase.from(_jobPermitsTable).update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update permit', userMessage: 'Could not update permit status.', cause: e);
    }
  }

  // ── Inspections ────────────────────────────────────────

  static const _inspectionsTable = 'permit_inspections';

  Future<List<PermitInspection>> getInspections(String jobPermitId) async {
    try {
      final response = await supabase
          .from(_inspectionsTable)
          .select()
          .eq('job_permit_id', jobPermitId)
          .order('scheduled_date');
      return (response as List).map((row) => PermitInspection.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load inspections', userMessage: 'Could not load inspections.', cause: e);
    }
  }

  Future<PermitInspection> createInspection(PermitInspection inspection) async {
    try {
      final response = await supabase
          .from(_inspectionsTable)
          .insert(inspection.toJson())
          .select()
          .single();
      return PermitInspection.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create inspection', userMessage: 'Could not save inspection.', cause: e);
    }
  }

  Future<void> updateInspectionResult(String id, {
    required InspectionResult result,
    String? failureReason,
    String? correctionNotes,
    DateTime? correctionDeadline,
  }) async {
    try {
      final updates = <String, dynamic>{
        'result': result.dbValue,
        'completed_date': DateTime.now().toIso8601String().split('T').first,
        if (failureReason != null) 'failure_reason': failureReason,
        if (correctionNotes != null) 'correction_notes': correctionNotes,
        if (correctionDeadline != null) 'correction_deadline': correctionDeadline.toIso8601String().split('T').first,
        'reinspection_needed': result == InspectionResult.fail,
      };
      await supabase.from(_inspectionsTable).update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update inspection', userMessage: 'Could not update inspection result.', cause: e);
    }
  }
}
