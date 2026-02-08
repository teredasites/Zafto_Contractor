// ZAFTO Estimate Engine Repository
// Created: Sprint D8c (Session 86)
//
// Supabase CRUD for D8 estimate engine tables:
// estimates, estimate_areas, estimate_line_items, estimate_photos.
// Also handles code database queries (estimate_items, categories, units).
// Separate from E5 EstimateRepository (xactimate_estimate_lines).
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/estimate.dart';
import '../models/estimate_item.dart';

class EstimateEngineRepository {
  // ============================================================
  // ESTIMATES — READ
  // ============================================================

  Future<List<Estimate>> getEstimates() async {
    try {
      final response = await supabase
          .from('estimates')
          .select('*, estimate_areas(*), estimate_line_items(*), estimate_photos(*)')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List)
          .map((row) => Estimate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch estimates: $e', cause: e);
    }
  }

  Future<Estimate?> getEstimate(String id) async {
    try {
      final response = await supabase
          .from('estimates')
          .select('*, estimate_areas(*), estimate_line_items(*), estimate_photos(*)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Estimate.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch estimate: $e', cause: e);
    }
  }

  Future<List<Estimate>> getEstimatesByStatus(EstimateStatus status) async {
    try {
      final response = await supabase
          .from('estimates')
          .select()
          .eq('status', status.dbValue)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Estimate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch estimates by status: $e', cause: e);
    }
  }

  Future<List<Estimate>> getEstimatesByType(EstimateType type) async {
    try {
      final response = await supabase
          .from('estimates')
          .select()
          .eq('estimate_type', type.dbValue)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Estimate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch estimates by type: $e', cause: e);
    }
  }

  Future<List<Estimate>> getEstimatesByJob(String jobId) async {
    try {
      final response = await supabase
          .from('estimates')
          .select('*, estimate_line_items(*)')
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Estimate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch estimates for job: $e', cause: e);
    }
  }

  Future<List<Estimate>> getEstimatesByCustomer(String customerId) async {
    try {
      final response = await supabase
          .from('estimates')
          .select()
          .eq('customer_id', customerId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Estimate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch estimates for customer: $e', cause: e);
    }
  }

  Future<List<Estimate>> searchEstimates(String query) async {
    try {
      final q = '%$query%';
      final response = await supabase
          .from('estimates')
          .select()
          .or('estimate_number.ilike.$q,title.ilike.$q,property_address.ilike.$q,claim_number.ilike.$q')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List)
          .map((row) => Estimate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to search estimates: $e', cause: e);
    }
  }

  // ============================================================
  // ESTIMATES — WRITE
  // ============================================================

  Future<Estimate> createEstimate(Estimate estimate) async {
    try {
      final response = await supabase
          .from('estimates')
          .insert(estimate.toInsertJson())
          .select()
          .single();
      return Estimate.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create estimate: $e',
        userMessage: 'Could not create estimate. Please try again.',
        cause: e,
      );
    }
  }

  Future<Estimate> updateEstimate(String id, Estimate estimate) async {
    try {
      final response = await supabase
          .from('estimates')
          .update(estimate.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Estimate.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update estimate: $e',
        userMessage: 'Could not update estimate. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteEstimate(String id) async {
    try {
      await supabase
          .from('estimates')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete estimate: $e',
        userMessage: 'Could not delete estimate. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // ESTIMATE AREAS — CRUD
  // ============================================================

  Future<List<EstimateArea>> getAreas(String estimateId) async {
    try {
      final response = await supabase
          .from('estimate_areas')
          .select()
          .eq('estimate_id', estimateId)
          .order('sort_order');
      return (response as List)
          .map((row) => EstimateArea.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch areas: $e', cause: e);
    }
  }

  Future<EstimateArea> createArea(EstimateArea area) async {
    try {
      final response = await supabase
          .from('estimate_areas')
          .insert(area.toInsertJson())
          .select()
          .single();
      return EstimateArea.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create area: $e', cause: e);
    }
  }

  Future<EstimateArea> updateArea(String id, EstimateArea area) async {
    try {
      final response = await supabase
          .from('estimate_areas')
          .update(area.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return EstimateArea.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to update area: $e', cause: e);
    }
  }

  Future<void> deleteArea(String id) async {
    try {
      await supabase.from('estimate_areas').delete().eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete area: $e', cause: e);
    }
  }

  // ============================================================
  // ESTIMATE LINE ITEMS — CRUD
  // ============================================================

  Future<List<EstimateLineItem>> getLineItems(String estimateId) async {
    try {
      final response = await supabase
          .from('estimate_line_items')
          .select()
          .eq('estimate_id', estimateId)
          .order('sort_order');
      return (response as List)
          .map((row) => EstimateLineItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch line items: $e', cause: e);
    }
  }

  Future<List<EstimateLineItem>> getLineItemsByArea(String areaId) async {
    try {
      final response = await supabase
          .from('estimate_line_items')
          .select()
          .eq('area_id', areaId)
          .order('sort_order');
      return (response as List)
          .map((row) => EstimateLineItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch line items for area: $e', cause: e);
    }
  }

  Future<EstimateLineItem> createLineItem(EstimateLineItem item) async {
    try {
      final response = await supabase
          .from('estimate_line_items')
          .insert(item.toInsertJson())
          .select()
          .single();
      return EstimateLineItem.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create line item: $e', cause: e);
    }
  }

  Future<List<EstimateLineItem>> createLineItems(
      List<EstimateLineItem> items) async {
    try {
      final response = await supabase
          .from('estimate_line_items')
          .insert(items.map((i) => i.toInsertJson()).toList())
          .select();
      return (response as List)
          .map((row) => EstimateLineItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to create line items: $e', cause: e);
    }
  }

  Future<EstimateLineItem> updateLineItem(
      String id, EstimateLineItem item) async {
    try {
      final response = await supabase
          .from('estimate_line_items')
          .update(item.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return EstimateLineItem.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to update line item: $e', cause: e);
    }
  }

  Future<void> deleteLineItem(String id) async {
    try {
      await supabase.from('estimate_line_items').delete().eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete line item: $e', cause: e);
    }
  }

  Future<void> deleteLineItemsByArea(String areaId) async {
    try {
      await supabase
          .from('estimate_line_items')
          .delete()
          .eq('area_id', areaId);
    } catch (e) {
      throw DatabaseError(
          'Failed to delete line items for area: $e', cause: e);
    }
  }

  // ============================================================
  // ESTIMATE PHOTOS — CRUD
  // ============================================================

  Future<List<EstimatePhoto>> getPhotos(String estimateId) async {
    try {
      final response = await supabase
          .from('estimate_photos')
          .select()
          .eq('estimate_id', estimateId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => EstimatePhoto.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch photos: $e', cause: e);
    }
  }

  Future<EstimatePhoto> createPhoto(EstimatePhoto photo) async {
    try {
      final response = await supabase
          .from('estimate_photos')
          .insert(photo.toInsertJson())
          .select()
          .single();
      return EstimatePhoto.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create photo: $e', cause: e);
    }
  }

  Future<void> deletePhoto(String id) async {
    try {
      await supabase.from('estimate_photos').delete().eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete photo: $e', cause: e);
    }
  }

  // ============================================================
  // CODE DATABASE — READ (estimate_items, categories, units)
  // ============================================================

  Future<List<EstimateItem>> getCodeItems({
    String? trade,
    String? categoryId,
    bool commonOnly = false,
  }) async {
    try {
      var query = supabase.from('estimate_items').select();
      if (trade != null) query = query.eq('trade', trade);
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (commonOnly) query = query.eq('is_common', true);
      final response = await query.order('zafto_code');
      return (response as List)
          .map((row) => EstimateItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch code items: $e', cause: e);
    }
  }

  Future<List<EstimateItem>> searchCodeItems(String query) async {
    try {
      final response = await supabase
          .from('estimate_items')
          .select()
          .textSearch('description', query)
          .limit(50);
      return (response as List)
          .map((row) => EstimateItem.fromJson(row))
          .toList();
    } catch (e) {
      // Fallback to ilike search if full-text fails
      try {
        final q = '%$query%';
        final response = await supabase
            .from('estimate_items')
            .select()
            .or('description.ilike.$q,zafto_code.ilike.$q')
            .limit(50);
        return (response as List)
            .map((row) => EstimateItem.fromJson(row))
            .toList();
      } catch (e2) {
        throw DatabaseError('Failed to search code items: $e2', cause: e2);
      }
    }
  }

  Future<List<EstimateCategory>> getCategories() async {
    try {
      final response = await supabase
          .from('estimate_categories')
          .select()
          .order('sort_order');
      return (response as List)
          .map((row) => EstimateCategory.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch categories: $e', cause: e);
    }
  }

  Future<List<EstimateUnit>> getUnits() async {
    try {
      final response = await supabase
          .from('estimate_units')
          .select()
          .order('code');
      return (response as List)
          .map((row) => EstimateUnit.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch units: $e', cause: e);
    }
  }

  // ============================================================
  // SEQUENCE
  // ============================================================

  Future<String> nextEstimateNumber() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final prefix = 'EST-$dateStr-';
      final response = await supabase
          .from('estimates')
          .select('estimate_number')
          .like('estimate_number', '$prefix%')
          .order('estimate_number', ascending: false)
          .limit(1)
          .maybeSingle();

      int next = 1;
      if (response != null) {
        final lastNumber = response['estimate_number'] as String;
        final seq = int.tryParse(lastNumber.split('-').last) ?? 0;
        next = seq + 1;
      }
      return '$prefix${next.toString().padLeft(3, '0')}';
    } catch (e) {
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final ms = DateTime.now().millisecondsSinceEpoch % 1000;
      return 'EST-$dateStr-${ms.toString().padLeft(3, '0')}';
    }
  }
}
