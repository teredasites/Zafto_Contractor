// ZAFTO Insurance Claim Repository — Supabase Backend
// CRUD for the insurance_claims table. Soft delete with deleted_at.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/insurance_claim.dart';

class InsuranceClaimRepository {
  static const _table = 'insurance_claims';

  Future<InsuranceClaim> createClaim(InsuranceClaim claim) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(claim.toInsertJson())
          .select()
          .single();

      return InsuranceClaim.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create insurance claim',
        userMessage: 'Could not save claim. Please try again.',
        cause: e,
      );
    }
  }

  Future<InsuranceClaim> updateClaim(String id, InsuranceClaim claim) async {
    try {
      final response = await supabase
          .from(_table)
          .update(claim.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return InsuranceClaim.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update insurance claim',
        userMessage: 'Could not update claim. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> updateClaimStatus(String id, ClaimStatus status) async {
    try {
      final updateData = <String, dynamic>{
        'claim_status': status.dbValue,
      };
      // Set milestone timestamps based on status
      final now = DateTime.now().toUtc().toIso8601String();
      switch (status) {
        case ClaimStatus.scopeSubmitted:
          updateData['scope_submitted_at'] = now;
          break;
        case ClaimStatus.estimateApproved:
          updateData['estimate_approved_at'] = now;
          break;
        case ClaimStatus.workInProgress:
          updateData['work_started_at'] = now;
          break;
        case ClaimStatus.workComplete:
          updateData['work_completed_at'] = now;
          break;
        case ClaimStatus.settled:
          updateData['settled_at'] = now;
          break;
        default:
          break;
      }

      await supabase.from(_table).update(updateData).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to update claim status',
        userMessage: 'Could not update status. Please try again.',
        cause: e,
      );
    }
  }

  Future<InsuranceClaim?> getClaimByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return InsuranceClaim.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load claim for job $jobId',
        userMessage: 'Could not load claim.',
        cause: e,
      );
    }
  }

  Future<InsuranceClaim?> getClaim(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return InsuranceClaim.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load insurance claim $id',
        userMessage: 'Could not load claim.',
        cause: e,
      );
    }
  }

  Future<List<InsuranceClaim>> getClaims({ClaimStatus? status}) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null);

      if (status != null) {
        query = query.eq('claim_status', status.dbValue);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((row) => InsuranceClaim.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load insurance claims',
        userMessage: 'Could not load claims.',
        cause: e,
      );
    }
  }

  Future<List<InsuranceClaim>> getActiveClaims() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null)
          .not('claim_status', 'in', '("closed","denied","settled")')
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => InsuranceClaim.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load active claims',
        userMessage: 'Could not load claims.',
        cause: e,
      );
    }
  }

  Future<void> deleteClaim(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete insurance claim',
        userMessage: 'Could not delete claim.',
        cause: e,
      );
    }
  }
}
