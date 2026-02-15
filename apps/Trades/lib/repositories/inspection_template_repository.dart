// ZAFTO Inspection Template Repository
// Created: INS1 — Inspector Deep Buildout
//
// Supabase CRUD for inspection_templates table.
// RLS handles company scoping automatically.
// System templates (is_system=true) are readable by all companies.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/inspection.dart';

class InspectionTemplateRepository {
  static const _table = 'inspection_templates';

  // READ

  Future<List<InspectionTemplate>> getTemplates({
    String? trade,
    InspectionType? inspectionType,
    bool? systemOnly,
  }) async {
    try {
      var query = supabase.from(_table).select();
      if (trade != null) {
        query = query.eq('trade', trade);
      }
      if (inspectionType != null) {
        query = query.eq(
            'inspection_type', PmInspection.enumToDb(inspectionType));
      }
      if (systemOnly == true) {
        query = query.eq('is_system', true);
      }
      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((row) => InspectionTemplate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch templates: $e',
        userMessage: 'Could not load templates. Please try again.',
        cause: e,
      );
    }
  }

  Future<InspectionTemplate?> getTemplate(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return InspectionTemplate.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch template: $e',
        userMessage: 'Could not load template. Please try again.',
        cause: e,
      );
    }
  }

  // WRITE

  Future<InspectionTemplate> createTemplate(
    InspectionTemplate t,
  ) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(t.toInsertJson())
          .select()
          .single();
      return InspectionTemplate.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create template: $e',
        userMessage: 'Could not create template. Please try again.',
        cause: e,
      );
    }
  }

  Future<InspectionTemplate> updateTemplate(
    String id,
    InspectionTemplate t,
  ) async {
    try {
      final response = await supabase
          .from(_table)
          .update(t.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return InspectionTemplate.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update template: $e',
        userMessage: 'Could not update template. Please try again.',
        cause: e,
      );
    }
  }

  Future<InspectionTemplate> cloneTemplate(String id) async {
    try {
      final original = await getTemplate(id);
      if (original == null) {
        throw DatabaseError(
          'Template not found: $id',
          userMessage: 'Template not found.',
        );
      }
      final clone = original.copyWith(
        id: '',
        name: '${original.name} (Copy)',
        isSystem: false,
        version: 1,
      );
      return createTemplate(clone);
    } catch (e) {
      if (e is DatabaseError) rethrow;
      throw DatabaseError(
        'Failed to clone template: $e',
        userMessage: 'Could not clone template. Please try again.',
        cause: e,
      );
    }
  }
}
