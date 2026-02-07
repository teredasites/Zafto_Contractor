// ZAFTO Property Asset Repository
// Created: Property Management feature
//
// Supabase CRUD for property_assets and asset_service_records tables.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/property_asset.dart';

class AssetRepository {
  static const _assetsTable = 'property_assets';
  static const _serviceTable = 'asset_service_records';

  // ============================================================
  // PROPERTY ASSETS — READ
  // ============================================================

  Future<List<PropertyAsset>> getAssets({
    String? propertyId,
    String? unitId,
  }) async {
    try {
      var query = supabase.from(_assetsTable).select();
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((row) => PropertyAsset.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch assets: $e',
        userMessage: 'Could not load assets. Please try again.',
        cause: e,
      );
    }
  }

  Future<PropertyAsset?> getAsset(String id) async {
    try {
      final response = await supabase
          .from(_assetsTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return PropertyAsset.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch asset: $e',
        userMessage: 'Could not load asset. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<PropertyAsset>> getAssetsNeedingService() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await supabase
          .from(_assetsTable)
          .select()
          .lte('next_service_date', now)
          .order('next_service_date', ascending: true);
      return (response as List)
          .map((row) => PropertyAsset.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch assets needing service: $e',
        userMessage: 'Could not load service-due assets. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // PROPERTY ASSETS — WRITE
  // ============================================================

  Future<PropertyAsset> createAsset(PropertyAsset a) async {
    try {
      final response = await supabase
          .from(_assetsTable)
          .insert(a.toInsertJson())
          .select()
          .single();
      return PropertyAsset.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create asset: $e',
        userMessage: 'Could not create asset. Please try again.',
        cause: e,
      );
    }
  }

  Future<PropertyAsset> updateAsset(String id, PropertyAsset a) async {
    try {
      final response = await supabase
          .from(_assetsTable)
          .update(a.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return PropertyAsset.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update asset: $e',
        userMessage: 'Could not update asset. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // SERVICE RECORDS — READ
  // ============================================================

  Future<List<AssetServiceRecord>> getServiceRecords(String assetId) async {
    try {
      final response = await supabase
          .from(_serviceTable)
          .select()
          .eq('asset_id', assetId)
          .order('service_date', ascending: false);
      return (response as List)
          .map((row) => AssetServiceRecord.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch service records: $e',
        userMessage: 'Could not load service records. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // SERVICE RECORDS — WRITE
  // ============================================================

  Future<AssetServiceRecord> addServiceRecord(AssetServiceRecord r) async {
    try {
      // Insert the service record.
      final response = await supabase
          .from(_serviceTable)
          .insert(r.toInsertJson())
          .select()
          .single();
      final record = AssetServiceRecord.fromJson(response);

      // Update the asset's last_service_date and next_service_date.
      final updates = <String, dynamic>{};
      if (r.serviceDate != null) {
        updates['last_service_date'] = r.serviceDate!.toIso8601String();
      }
      if (r.nextServiceDate != null) {
        updates['next_service_date'] = r.nextServiceDate!.toIso8601String();
      }
      await supabase
          .from(_assetsTable)
          .update(updates)
          .eq('id', r.assetId);

      return record;
    } catch (e) {
      throw DatabaseError(
        'Failed to add service record: $e',
        userMessage: 'Could not save service record. Please try again.',
        cause: e,
      );
    }
  }
}
