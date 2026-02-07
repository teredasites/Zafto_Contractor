// ZAFTO Certification Repository — Supabase Backend
// CRUD for the certifications table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/certification.dart';

class CertificationRepository {
  static const _table = 'certifications';

  Future<Certification> createCertification(
      Certification certification) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(certification.toInsertJson())
          .select()
          .single();
      return Certification.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create certification',
        userMessage: 'Could not save certification. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<Certification>> getCertifications() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .order('expiration_date');
      return (response as List)
          .map((row) => Certification.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load certifications',
        userMessage: 'Could not load certifications.',
        cause: e,
      );
    }
  }

  Future<List<Certification>> getCertificationsByUser(String userId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('expiration_date');
      return (response as List)
          .map((row) => Certification.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load certifications for user $userId',
        userMessage: 'Could not load certifications.',
        cause: e,
      );
    }
  }

  // Get certifications expiring within N days.
  Future<List<Certification>> getExpiring({int days = 30}) async {
    try {
      final cutoff =
          DateTime.now().add(Duration(days: days)).toIso8601String();
      final response = await supabase
          .from(_table)
          .select()
          .lte('expiration_date', cutoff)
          .neq('status', 'revoked')
          .order('expiration_date');
      return (response as List)
          .map((row) => Certification.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load expiring certifications',
        userMessage: 'Could not load certifications.',
        cause: e,
      );
    }
  }

  Future<Certification?> getCertification(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Certification.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load certification $id',
        userMessage: 'Could not load certification.',
        cause: e,
      );
    }
  }

  Future<Certification> updateCertification(
      String id, Certification certification) async {
    try {
      final response = await supabase
          .from(_table)
          .update(certification.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Certification.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update certification',
        userMessage: 'Could not update certification. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteCertification(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete certification $id',
        userMessage: 'Could not delete certification.',
        cause: e,
      );
    }
  }
}
