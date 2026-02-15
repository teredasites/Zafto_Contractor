// ZAFTO Floor Plan Repository
// Created: Sprint SK7 (Session 106)
//
// Supabase CRUD for property_floor_plans + floor_plan_layers +
// floor_plan_rooms + floor_plan_snapshots + floor_plan_photo_pins.
// RLS handles company scoping — no manual filtering needed.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/floor_plan_elements.dart';

// =============================================================================
// MODELS (lightweight row wrappers — not the JSONB plan_data itself)
// =============================================================================

class FloorPlanRecord {
  final String id;
  final String companyId;
  final String? propertyId;
  final String? jobId;
  final String? estimateId;
  final String name;
  final int floorLevel;
  final int floorNumber;
  final String status;
  final FloorPlanData planData;
  final int syncVersion;
  final String? thumbnailPath;
  final String? lastSyncedAt;
  final String createdAt;
  final String updatedAt;

  const FloorPlanRecord({
    required this.id,
    required this.companyId,
    this.propertyId,
    this.jobId,
    this.estimateId,
    required this.name,
    this.floorLevel = 1,
    this.floorNumber = 1,
    this.status = 'draft',
    required this.planData,
    this.syncVersion = 1,
    this.thumbnailPath,
    this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FloorPlanRecord.fromJson(Map<String, dynamic> json) {
    final rawData = json['plan_data'] as Map<String, dynamic>?;
    FloorPlanData planData;
    try {
      planData =
          rawData != null ? FloorPlanData.fromJson(rawData) : const FloorPlanData();
    } catch (_) {
      planData = const FloorPlanData();
    }

    return FloorPlanRecord(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      propertyId: json['property_id'] as String?,
      jobId: json['job_id'] as String?,
      estimateId: json['estimate_id'] as String?,
      name: (json['name'] as String?) ?? 'Untitled',
      floorLevel: (json['floor_level'] as int?) ?? 1,
      floorNumber: (json['floor_number'] as int?) ?? 1,
      status: (json['status'] as String?) ?? 'draft',
      planData: planData,
      syncVersion: (json['sync_version'] as int?) ?? 1,
      thumbnailPath: json['thumbnail_path'] as String?,
      lastSyncedAt: json['last_synced_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class FloorPlanSnapshot {
  final String id;
  final String floorPlanId;
  final String companyId;
  final FloorPlanData planData;
  final String snapshotReason;
  final String? snapshotLabel;
  final String? createdBy;
  final String createdAt;

  const FloorPlanSnapshot({
    required this.id,
    required this.floorPlanId,
    required this.companyId,
    required this.planData,
    required this.snapshotReason,
    this.snapshotLabel,
    this.createdBy,
    required this.createdAt,
  });

  factory FloorPlanSnapshot.fromJson(Map<String, dynamic> json) {
    final rawData = json['plan_data'] as Map<String, dynamic>?;
    FloorPlanData planData;
    try {
      planData =
          rawData != null ? FloorPlanData.fromJson(rawData) : const FloorPlanData();
    } catch (_) {
      planData = const FloorPlanData();
    }
    return FloorPlanSnapshot(
      id: json['id'] as String,
      floorPlanId: json['floor_plan_id'] as String,
      companyId: json['company_id'] as String,
      planData: planData,
      snapshotReason: (json['snapshot_reason'] as String?) ?? 'manual',
      snapshotLabel: json['snapshot_label'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class FloorPlanPhotoPin {
  final String id;
  final String floorPlanId;
  final String companyId;
  final String? photoId;
  final String? photoPath;
  final double positionX;
  final double positionY;
  final String? roomId;
  final String? label;
  final String pinType;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;

  const FloorPlanPhotoPin({
    required this.id,
    required this.floorPlanId,
    required this.companyId,
    this.photoId,
    this.photoPath,
    required this.positionX,
    required this.positionY,
    this.roomId,
    this.label,
    this.pinType = 'photo',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FloorPlanPhotoPin.fromJson(Map<String, dynamic> json) {
    return FloorPlanPhotoPin(
      id: json['id'] as String,
      floorPlanId: json['floor_plan_id'] as String,
      companyId: json['company_id'] as String,
      photoId: json['photo_id'] as String?,
      photoPath: json['photo_path'] as String?,
      positionX: (json['position_x'] as num).toDouble(),
      positionY: (json['position_y'] as num).toDouble(),
      roomId: json['room_id'] as String?,
      label: json['label'] as String?,
      pinType: (json['pin_type'] as String?) ?? 'photo',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

// =============================================================================
// REPOSITORY
// =============================================================================

class FloorPlanRepository {
  // ===========================================================================
  // PLANS — CRUD
  // ===========================================================================

  Future<List<FloorPlanRecord>> getPlans({String? propertyId}) async {
    try {
      var query = supabase
          .from('property_floor_plans')
          .select()
          .isFilter('deleted_at', null);

      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }

      final response = await query.order('floor_number', ascending: true);
      return (response as List)
          .map((row) => FloorPlanRecord.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch floor plans: $e', cause: e);
    }
  }

  Future<FloorPlanRecord?> getPlan(String id) async {
    try {
      final response = await supabase
          .from('property_floor_plans')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return FloorPlanRecord.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch floor plan: $e', cause: e);
    }
  }

  Future<FloorPlanRecord> createPlan({
    required String companyId,
    required String name,
    String? propertyId,
    String? jobId,
    int floorLevel = 1,
    int floorNumber = 1,
  }) async {
    try {
      final response = await supabase
          .from('property_floor_plans')
          .insert({
            'company_id': companyId,
            'name': name,
            'property_id': propertyId,
            'job_id': jobId,
            'floor_level': floorLevel,
            'floor_number': floorNumber,
            'plan_data': const FloorPlanData().toJson(),
            'status': 'draft',
          })
          .select()
          .single();
      return FloorPlanRecord.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create floor plan: $e', cause: e);
    }
  }

  Future<void> updatePlanData({
    required String planId,
    required FloorPlanData data,
    required int syncVersion,
  }) async {
    try {
      await supabase.from('property_floor_plans').update({
        'plan_data': data.toJson(),
        'sync_version': syncVersion,
        'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', planId);
    } catch (e) {
      throw DatabaseError('Failed to save floor plan: $e', cause: e);
    }
  }

  Future<void> updatePlanName(String planId, String name) async {
    try {
      await supabase
          .from('property_floor_plans')
          .update({'name': name}).eq('id', planId);
    } catch (e) {
      throw DatabaseError('Failed to rename floor plan: $e', cause: e);
    }
  }

  Future<void> updateThumbnailPath(String planId, String path) async {
    try {
      await supabase
          .from('property_floor_plans')
          .update({'thumbnail_path': path}).eq('id', planId);
    } catch (e) {
      throw DatabaseError('Failed to update thumbnail: $e', cause: e);
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      // Soft delete
      await supabase.from('property_floor_plans').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', planId);
    } catch (e) {
      throw DatabaseError('Failed to delete floor plan: $e', cause: e);
    }
  }

  // ===========================================================================
  // SNAPSHOTS
  // ===========================================================================

  Future<List<FloorPlanSnapshot>> getSnapshots(String floorPlanId) async {
    try {
      final response = await supabase
          .from('floor_plan_snapshots')
          .select()
          .eq('floor_plan_id', floorPlanId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) =>
              FloorPlanSnapshot.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch snapshots: $e', cause: e);
    }
  }

  Future<FloorPlanSnapshot> createSnapshot({
    required String floorPlanId,
    required String companyId,
    required FloorPlanData planData,
    required String reason,
    String? label,
  }) async {
    try {
      // Enforce max 50 snapshots per plan — prune oldest if needed
      final existing = await getSnapshots(floorPlanId);
      if (existing.length >= 50) {
        final toDelete = existing.sublist(49);
        for (final snap in toDelete) {
          await supabase
              .from('floor_plan_snapshots')
              .delete()
              .eq('id', snap.id);
        }
      }

      final response = await supabase
          .from('floor_plan_snapshots')
          .insert({
            'floor_plan_id': floorPlanId,
            'company_id': companyId,
            'plan_data': planData.toJson(),
            'snapshot_reason': reason,
            'snapshot_label': label,
          })
          .select()
          .single();
      return FloorPlanSnapshot.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create snapshot: $e', cause: e);
    }
  }

  Future<void> deleteSnapshot(String snapshotId) async {
    try {
      await supabase
          .from('floor_plan_snapshots')
          .delete()
          .eq('id', snapshotId);
    } catch (e) {
      throw DatabaseError('Failed to delete snapshot: $e', cause: e);
    }
  }

  // ===========================================================================
  // PHOTO PINS
  // ===========================================================================

  Future<List<FloorPlanPhotoPin>> getPhotoPins(String floorPlanId) async {
    try {
      final response = await supabase
          .from('floor_plan_photo_pins')
          .select()
          .eq('floor_plan_id', floorPlanId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) =>
              FloorPlanPhotoPin.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch photo pins: $e', cause: e);
    }
  }

  Future<FloorPlanPhotoPin> createPhotoPin({
    required String floorPlanId,
    required String companyId,
    required double positionX,
    required double positionY,
    String? photoPath,
    String? roomId,
    String? label,
    String pinType = 'photo',
  }) async {
    try {
      final response = await supabase
          .from('floor_plan_photo_pins')
          .insert({
            'floor_plan_id': floorPlanId,
            'company_id': companyId,
            'position_x': positionX,
            'position_y': positionY,
            'photo_path': photoPath,
            'room_id': roomId,
            'label': label,
            'pin_type': pinType,
          })
          .select()
          .single();
      return FloorPlanPhotoPin.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create photo pin: $e', cause: e);
    }
  }

  Future<void> updatePhotoPin({
    required String pinId,
    String? label,
    String? photoPath,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (label != null) updates['label'] = label;
      if (photoPath != null) updates['photo_path'] = photoPath;
      if (updates.isEmpty) return;

      await supabase
          .from('floor_plan_photo_pins')
          .update(updates)
          .eq('id', pinId);
    } catch (e) {
      throw DatabaseError('Failed to update photo pin: $e', cause: e);
    }
  }

  Future<void> deletePhotoPin(String pinId) async {
    try {
      await supabase
          .from('floor_plan_photo_pins')
          .delete()
          .eq('id', pinId);
    } catch (e) {
      throw DatabaseError('Failed to delete photo pin: $e', cause: e);
    }
  }

  // ===========================================================================
  // MULTI-FLOOR HELPERS
  // ===========================================================================

  /// Get all floor plans for a property, ordered by floor number.
  Future<List<FloorPlanRecord>> getFloorsForProperty(
      String propertyId) async {
    return getPlans(propertyId: propertyId);
  }

  /// Add a new floor to an existing property.
  Future<FloorPlanRecord> addFloor({
    required String companyId,
    required String propertyId,
    required String name,
    required int floorNumber,
  }) async {
    return createPlan(
      companyId: companyId,
      name: name,
      propertyId: propertyId,
      floorLevel: floorNumber,
      floorNumber: floorNumber,
    );
  }
}
