// ZAFTO Restoration Equipment Repository — Supabase Backend
// CRUD for the restoration_equipment table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/restoration_equipment.dart';

class RestorationEquipmentRepository {
  static const _table = 'restoration_equipment';

  Future<RestorationEquipment> deployEquipment(
      RestorationEquipment equipment) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(equipment.toInsertJson())
          .select()
          .single();

      return RestorationEquipment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to deploy equipment',
        userMessage: 'Could not save equipment. Please try again.',
        cause: e,
      );
    }
  }

  Future<RestorationEquipment> updateEquipment(
      String id, RestorationEquipment equipment) async {
    try {
      final response = await supabase
          .from(_table)
          .update(equipment.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return RestorationEquipment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update equipment',
        userMessage: 'Could not update equipment. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> removeEquipment(String id) async {
    try {
      await supabase.from(_table).update({
        'removed_at': DateTime.now().toUtc().toIso8601String(),
        'status': EquipmentStatus.removed.dbValue,
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to remove equipment',
        userMessage: 'Could not remove equipment.',
        cause: e,
      );
    }
  }

  Future<List<RestorationEquipment>> getEquipmentByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('deployed_at', ascending: false);

      return (response as List)
          .map((row) => RestorationEquipment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load equipment for job $jobId',
        userMessage: 'Could not load equipment.',
        cause: e,
      );
    }
  }

  Future<List<RestorationEquipment>> getDeployedEquipment(
      String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('status', EquipmentStatus.deployed.dbValue)
          .order('deployed_at', ascending: false);

      return (response as List)
          .map((row) => RestorationEquipment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load deployed equipment',
        userMessage: 'Could not load equipment.',
        cause: e,
      );
    }
  }

  Future<RestorationEquipment?> getEquipment(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return RestorationEquipment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load equipment $id',
        userMessage: 'Could not load equipment.',
        cause: e,
      );
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete equipment',
        userMessage: 'Could not delete equipment.',
        cause: e,
      );
    }
  }
}
