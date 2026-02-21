// ZAFTO Disposal & Dump Finder Repository
// Created: DEPTH36 — Facilities, dump receipts, scrap prices, waste types.

import '../core/supabase_client.dart';
import '../models/disposal_facility.dart';

class DisposalFacilityRepository {
  static const _facilities = 'disposal_facilities';
  static const _receipts = 'dump_receipts';
  static const _scrapPrices = 'scrap_price_index';
  static const _wasteTypes = 'waste_type_reference';

  // ══════════════════════════════════════════════════════════════
  // FACILITIES
  // ══════════════════════════════════════════════════════════════

  Future<List<DisposalFacility>> getFacilities({
    String? facilityType,
    String? stateCode,
  }) async {
    var query = supabase
        .from(_facilities)
        .select()
        .isFilter('deleted_at', null)
        .eq('is_active', true)
        .order('name');

    if (facilityType != null) query = query.eq('facility_type', facilityType);
    if (stateCode != null) query = query.eq('state_code', stateCode);

    final data = await query;
    return (data as List).map((r) => DisposalFacility.fromJson(r)).toList();
  }

  Future<DisposalFacility> getFacility(String id) async {
    final data = await supabase
        .from(_facilities)
        .select()
        .eq('id', id)
        .single();
    return DisposalFacility.fromJson(data);
  }

  Future<List<DisposalFacility>> searchFacilities(String query) async {
    final data = await supabase
        .from(_facilities)
        .select()
        .isFilter('deleted_at', null)
        .eq('is_active', true)
        .or('name.ilike.%$query%,city.ilike.%$query%,address.ilike.%$query%')
        .order('name');
    return (data as List).map((r) => DisposalFacility.fromJson(r)).toList();
  }

  Future<DisposalFacility> createFacility(Map<String, dynamic> data) async {
    final result = await supabase
        .from(_facilities)
        .insert(data)
        .select()
        .single();
    return DisposalFacility.fromJson(result);
  }

  Future<DisposalFacility> updateFacility(String id, Map<String, dynamic> data) async {
    final result = await supabase
        .from(_facilities)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return DisposalFacility.fromJson(result);
  }

  Future<void> softDeleteFacility(String id) async {
    await supabase
        .from(_facilities)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════
  // DUMP RECEIPTS
  // ══════════════════════════════════════════════════════════════

  Future<List<DumpReceipt>> getReceipts(String companyId, {String? jobId}) async {
    var query = supabase
        .from(_receipts)
        .select()
        .eq('company_id', companyId)
        .isFilter('deleted_at', null)
        .order('receipt_date', ascending: false);

    if (jobId != null) query = query.eq('job_id', jobId);

    final data = await query;
    return (data as List).map((r) => DumpReceipt.fromJson(r)).toList();
  }

  Future<DumpReceipt> getReceipt(String id) async {
    final data = await supabase
        .from(_receipts)
        .select()
        .eq('id', id)
        .single();
    return DumpReceipt.fromJson(data);
  }

  Future<DumpReceipt> createReceipt(Map<String, dynamic> data) async {
    final result = await supabase
        .from(_receipts)
        .insert(data)
        .select()
        .single();
    return DumpReceipt.fromJson(result);
  }

  Future<DumpReceipt> updateReceipt(String id, Map<String, dynamic> data) async {
    final result = await supabase
        .from(_receipts)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return DumpReceipt.fromJson(result);
  }

  Future<void> softDeleteReceipt(String id) async {
    await supabase
        .from(_receipts)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════
  // SCRAP PRICE INDEX (read-only from app)
  // ══════════════════════════════════════════════════════════════

  Future<List<ScrapPriceIndex>> getScrapPrices({String? material}) async {
    var query = supabase
        .from(_scrapPrices)
        .select()
        .order('material')
        .order('effective_date', ascending: false);

    if (material != null) query = query.eq('material', material);

    final data = await query;
    return (data as List).map((r) => ScrapPriceIndex.fromJson(r)).toList();
  }

  Future<List<ScrapPriceIndex>> getLatestScrapPrices() async {
    // Get the most recent price for each material+grade combo
    final data = await supabase
        .from(_scrapPrices)
        .select()
        .order('effective_date', ascending: false);
    // Deduplicate by material+grade (keep first = most recent)
    final seen = <String>{};
    final unique = <ScrapPriceIndex>[];
    for (final row in (data as List)) {
      final item = ScrapPriceIndex.fromJson(row);
      final key = '${item.material}|${item.grade}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(item);
      }
    }
    return unique;
  }

  // ══════════════════════════════════════════════════════════════
  // WASTE TYPE REFERENCE (read-only from app)
  // ══════════════════════════════════════════════════════════════

  Future<List<WasteTypeReference>> getWasteTypes({String? category}) async {
    var query = supabase
        .from(_wasteTypes)
        .select()
        .order('category')
        .order('label');

    if (category != null) query = query.eq('category', category);

    final data = await query;
    return (data as List).map((r) => WasteTypeReference.fromJson(r)).toList();
  }
}
