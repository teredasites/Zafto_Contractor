// ZAFTO Claim Supplement Repository — Supabase Backend
// CRUD for the claim_supplements table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/claim_supplement.dart';

class ClaimSupplementRepository {
  static const _table = 'claim_supplements';

  Future<ClaimSupplement> createSupplement(ClaimSupplement supplement) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(supplement.toInsertJson())
          .select()
          .single();

      return ClaimSupplement.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create supplement',
        userMessage: 'Could not save supplement. Please try again.',
        cause: e,
      );
    }
  }

  Future<ClaimSupplement> updateSupplement(
      String id, ClaimSupplement supplement) async {
    try {
      final response = await supabase
          .from(_table)
          .update(supplement.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return ClaimSupplement.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update supplement',
        userMessage: 'Could not update supplement. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<ClaimSupplement>> getSupplementsByClaim(String claimId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('claim_id', claimId)
          .order('supplement_number', ascending: true);

      return (response as List)
          .map((row) => ClaimSupplement.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load supplements for claim $claimId',
        userMessage: 'Could not load supplements.',
        cause: e,
      );
    }
  }

  Future<ClaimSupplement?> getSupplement(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ClaimSupplement.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load supplement $id',
        userMessage: 'Could not load supplement.',
        cause: e,
      );
    }
  }

  Future<int> getNextSupplementNumber(String claimId) async {
    try {
      final response = await supabase
          .from(_table)
          .select('supplement_number')
          .eq('claim_id', claimId)
          .order('supplement_number', ascending: false)
          .limit(1);

      if ((response as List).isEmpty) return 1;
      return (response[0]['supplement_number'] as int? ?? 0) + 1;
    } catch (e) {
      return 1;
    }
  }

  Future<void> updateSupplementFields(String id, Map<String, dynamic> fields) async {
    try {
      await supabase.from(_table).update(fields).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to update supplement fields',
        userMessage: 'Could not update supplement.',
        cause: e,
      );
    }
  }

  Future<void> deleteSupplement(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete supplement',
        userMessage: 'Could not delete supplement.',
        cause: e,
      );
    }
  }
}
