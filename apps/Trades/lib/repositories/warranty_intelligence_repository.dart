// ZAFTO Warranty Intelligence Repository — Supabase Backend
// CRUD for warranty_outreach_log, warranty_claims, product_recalls tables.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/warranty_outreach_log.dart';
import '../models/warranty_claim.dart';
import '../models/product_recall.dart';

class WarrantyIntelligenceRepository {
  // ── Outreach Log ─────────────────────────────────────────────
  static const _outreachTable = 'warranty_outreach_log';

  Future<List<WarrantyOutreachLog>> getOutreachLogs({String? equipmentId, String? customerId}) async {
    try {
      var query = supabase.from(_outreachTable).select();
      if (equipmentId != null) query = query.eq('equipment_id', equipmentId);
      if (customerId != null) query = query.eq('customer_id', customerId);
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((row) => WarrantyOutreachLog.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load outreach logs', userMessage: 'Could not load outreach history.', cause: e);
    }
  }

  Future<WarrantyOutreachLog> createOutreach(WarrantyOutreachLog log) async {
    try {
      final response = await supabase.from(_outreachTable).insert(log.toJson()).select().single();
      return WarrantyOutreachLog.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create outreach', userMessage: 'Could not save outreach record.', cause: e);
    }
  }

  Future<void> updateOutreachResponse(String id, ResponseStatus status, {String? resultingJobId}) async {
    try {
      final updates = <String, dynamic>{'response_status': status.dbValue};
      if (resultingJobId != null) updates['resulting_job_id'] = resultingJobId;
      await supabase.from(_outreachTable).update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update outreach response', userMessage: 'Could not update response status.', cause: e);
    }
  }

  // ── Warranty Claims ──────────────────────────────────────────
  static const _claimsTable = 'warranty_claims';

  Future<List<WarrantyClaim>> getClaims({String? equipmentId, String? status}) async {
    try {
      var query = supabase.from(_claimsTable).select();
      if (equipmentId != null) query = query.eq('equipment_id', equipmentId);
      if (status != null) query = query.eq('claim_status', status);
      final response = await query.order('claim_date', ascending: false);
      return (response as List).map((row) => WarrantyClaim.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load warranty claims', userMessage: 'Could not load claims.', cause: e);
    }
  }

  Future<WarrantyClaim> createClaim(WarrantyClaim claim) async {
    try {
      final response = await supabase.from(_claimsTable).insert(claim.toJson()).select().single();
      return WarrantyClaim.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create claim', userMessage: 'Could not save warranty claim.', cause: e);
    }
  }

  Future<void> updateClaimStatus(String id, ClaimStatus status, {String? resolutionNotes, double? amountApproved}) async {
    try {
      final updates = <String, dynamic>{'claim_status': status.dbValue};
      if (resolutionNotes != null) updates['resolution_notes'] = resolutionNotes;
      if (amountApproved != null) updates['amount_approved'] = amountApproved;
      await supabase.from(_claimsTable).update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update claim', userMessage: 'Could not update claim status.', cause: e);
    }
  }

  // ── Product Recalls ──────────────────────────────────────────
  static const _recallsTable = 'product_recalls';

  Future<List<ProductRecall>> getRecalls({bool activeOnly = true}) async {
    try {
      var query = supabase.from(_recallsTable).select();
      if (activeOnly) query = query.eq('is_active', true);
      final response = await query.order('recall_date', ascending: false);
      return (response as List).map((row) => ProductRecall.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load recalls', userMessage: 'Could not load product recalls.', cause: e);
    }
  }

  Future<List<ProductRecall>> checkRecallsForEquipment(String manufacturer, String? modelNumber) async {
    try {
      final query = supabase.from(_recallsTable).select().eq('manufacturer', manufacturer).eq('is_active', true);
      final response = await query;
      final recalls = (response as List).map((row) => ProductRecall.fromJson(row)).toList();

      // Filter by model pattern if provided
      if (modelNumber != null) {
        return recalls.where((r) {
          if (r.modelPattern == null) return true;
          return modelNumber.contains(r.modelPattern!) || r.modelPattern!.contains(modelNumber);
        }).toList();
      }
      return recalls;
    } catch (e) {
      throw DatabaseError('Failed to check recalls', userMessage: 'Could not check for product recalls.', cause: e);
    }
  }

  // ── Warranty Expiry Alerts ───────────────────────────────────

  /// Get equipment with warranties expiring in the next N days
  Future<List<Map<String, dynamic>>> getExpiringWarranties({int daysAhead = 90}) async {
    try {
      final cutoff = DateTime.now().add(Duration(days: daysAhead)).toIso8601String().split('T').first;
      final today = DateTime.now().toIso8601String().split('T').first;

      final response = await supabase
          .from('home_equipment')
          .select('id, name, manufacturer, model_number, serial_number, warranty_end_date, customer_id')
          .gte('warranty_end_date', today)
          .lte('warranty_end_date', cutoff)
          .order('warranty_end_date');

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw DatabaseError('Failed to load expiring warranties', userMessage: 'Could not check warranty expirations.', cause: e);
    }
  }
}
