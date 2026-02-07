// ZAFTO Walkthrough Repository — Supabase Backend
// Full CRUD for walkthroughs, rooms, photos, templates, and floor plans.
// All methods throw DatabaseError on failure.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/walkthrough.dart';
import '../models/walkthrough_room.dart';
import '../models/walkthrough_photo.dart';
import '../models/walkthrough_template.dart';
import '../models/floor_plan.dart';

class WalkthroughRepository {
  static const _walkthroughsTable = 'walkthroughs';
  static const _roomsTable = 'walkthrough_rooms';
  static const _photosTable = 'walkthrough_photos';
  static const _templatesTable = 'walkthrough_templates';
  static const _floorPlansTable = 'property_floor_plans';

  // ==================== WALKTHROUGHS ====================

  Future<List<Walkthrough>> getWalkthroughs(
    String companyId, {
    String? status,
  }) async {
    try {
      var query = supabase
          .from(_walkthroughsTable)
          .select()
          .eq('company_id', companyId);

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('created_at', ascending: false);

      return (response as List)
          .map((row) => Walkthrough.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load walkthroughs for company $companyId',
        userMessage: 'Could not load walkthroughs.',
        cause: e,
      );
    }
  }

  Future<Walkthrough> getWalkthrough(String id) async {
    try {
      final response = await supabase
          .from(_walkthroughsTable)
          .select()
          .eq('id', id)
          .single();

      return Walkthrough.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load walkthrough $id',
        userMessage: 'Could not load walkthrough.',
        cause: e,
      );
    }
  }

  Future<Walkthrough> createWalkthrough(Walkthrough walkthrough) async {
    try {
      final response = await supabase
          .from(_walkthroughsTable)
          .insert(walkthrough.toInsertJson())
          .select()
          .single();

      return Walkthrough.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create walkthrough',
        userMessage: 'Could not create walkthrough. Please try again.',
        cause: e,
      );
    }
  }

  Future<Walkthrough> updateWalkthrough(
    String id,
    Walkthrough walkthrough,
  ) async {
    try {
      final response = await supabase
          .from(_walkthroughsTable)
          .update(walkthrough.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return Walkthrough.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update walkthrough',
        userMessage: 'Could not update walkthrough. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteWalkthrough(String id) async {
    try {
      await supabase.from(_walkthroughsTable).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete walkthrough',
        userMessage: 'Could not delete walkthrough.',
        cause: e,
      );
    }
  }

  Future<Walkthrough> completeWalkthrough(String id) async {
    try {
      final response = await supabase
          .from(_walkthroughsTable)
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return Walkthrough.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to complete walkthrough',
        userMessage: 'Could not mark walkthrough as complete.',
        cause: e,
      );
    }
  }

  // ==================== ROOMS ====================

  Future<List<WalkthroughRoom>> getRooms(String walkthroughId) async {
    try {
      final response = await supabase
          .from(_roomsTable)
          .select()
          .eq('walkthrough_id', walkthroughId)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((row) => WalkthroughRoom.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load rooms for walkthrough $walkthroughId',
        userMessage: 'Could not load rooms.',
        cause: e,
      );
    }
  }

  Future<WalkthroughRoom> getRoom(String id) async {
    try {
      final response = await supabase
          .from(_roomsTable)
          .select()
          .eq('id', id)
          .single();

      return WalkthroughRoom.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load room $id',
        userMessage: 'Could not load room.',
        cause: e,
      );
    }
  }

  Future<WalkthroughRoom> addRoom(WalkthroughRoom room) async {
    try {
      final response = await supabase
          .from(_roomsTable)
          .insert(room.toInsertJson())
          .select()
          .single();

      return WalkthroughRoom.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add room',
        userMessage: 'Could not add room. Please try again.',
        cause: e,
      );
    }
  }

  Future<WalkthroughRoom> updateRoom(
    String id,
    WalkthroughRoom room,
  ) async {
    try {
      final response = await supabase
          .from(_roomsTable)
          .update(room.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return WalkthroughRoom.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update room',
        userMessage: 'Could not update room. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      await supabase.from(_roomsTable).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete room',
        userMessage: 'Could not delete room.',
        cause: e,
      );
    }
  }

  Future<void> reorderRooms(
    String walkthroughId,
    List<String> roomIds,
  ) async {
    try {
      // Update sort_order for each room based on position in list
      for (int i = 0; i < roomIds.length; i++) {
        await supabase
            .from(_roomsTable)
            .update({
              'sort_order': i,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', roomIds[i])
            .eq('walkthrough_id', walkthroughId);
      }
    } catch (e) {
      throw DatabaseError(
        'Failed to reorder rooms',
        userMessage: 'Could not reorder rooms.',
        cause: e,
      );
    }
  }

  // ==================== PHOTOS ====================

  Future<List<WalkthroughPhoto>> getPhotos(
    String walkthroughId, {
    String? roomId,
  }) async {
    try {
      var query = supabase
          .from(_photosTable)
          .select()
          .eq('walkthrough_id', walkthroughId);

      if (roomId != null && roomId.isNotEmpty) {
        query = query.eq('room_id', roomId);
      }

      final response =
          await query.order('sort_order', ascending: true);

      return (response as List)
          .map((row) => WalkthroughPhoto.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load photos for walkthrough $walkthroughId',
        userMessage: 'Could not load photos.',
        cause: e,
      );
    }
  }

  Future<WalkthroughPhoto> addPhoto(WalkthroughPhoto photo) async {
    try {
      final response = await supabase
          .from(_photosTable)
          .insert(photo.toInsertJson())
          .select()
          .single();

      return WalkthroughPhoto.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add photo',
        userMessage: 'Could not save photo. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deletePhoto(String id) async {
    try {
      await supabase.from(_photosTable).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete photo',
        userMessage: 'Could not delete photo.',
        cause: e,
      );
    }
  }

  // ==================== TEMPLATES ====================

  Future<List<WalkthroughTemplate>> getTemplates({
    String? companyId,
    String? walkthroughType,
  }) async {
    try {
      var query = supabase.from(_templatesTable).select();

      if (companyId != null) {
        // Get company-specific + system templates
        query = query.or('company_id.eq.$companyId,is_system.eq.true');
      } else {
        query = query.eq('is_system', true);
      }

      if (walkthroughType != null && walkthroughType.isNotEmpty) {
        query = query.eq('walkthrough_type', walkthroughType);
      }

      final response =
          await query.order('usage_count', ascending: false);

      return (response as List)
          .map((row) => WalkthroughTemplate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load walkthrough templates',
        userMessage: 'Could not load templates.',
        cause: e,
      );
    }
  }

  Future<void> incrementTemplateUsage(String templateId) async {
    try {
      final response = await supabase
          .from(_templatesTable)
          .select('usage_count')
          .eq('id', templateId)
          .single();

      final current = response['usage_count'] as int? ?? 0;
      await supabase
          .from(_templatesTable)
          .update({'usage_count': current + 1})
          .eq('id', templateId);
    } catch (_) {
      // Non-critical — fail silently
    }
  }

  // ==================== FLOOR PLANS ====================

  Future<List<FloorPlan>> getFloorPlans(String propertyId) async {
    try {
      final response = await supabase
          .from(_floorPlansTable)
          .select()
          .eq('property_id', propertyId)
          .order('floor_level', ascending: true);

      return (response as List)
          .map((row) => FloorPlan.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load floor plans for property $propertyId',
        userMessage: 'Could not load floor plans.',
        cause: e,
      );
    }
  }

  Future<FloorPlan> saveFloorPlan(FloorPlan floorPlan) async {
    try {
      if (floorPlan.id.isNotEmpty) {
        // Update existing
        final response = await supabase
            .from(_floorPlansTable)
            .update(floorPlan.toUpdateJson())
            .eq('id', floorPlan.id)
            .select()
            .single();

        return FloorPlan.fromJson(response);
      } else {
        // Insert new
        final response = await supabase
            .from(_floorPlansTable)
            .insert(floorPlan.toInsertJson())
            .select()
            .single();

        return FloorPlan.fromJson(response);
      }
    } catch (e) {
      throw DatabaseError(
        'Failed to save floor plan',
        userMessage: 'Could not save floor plan. Please try again.',
        cause: e,
      );
    }
  }
}
