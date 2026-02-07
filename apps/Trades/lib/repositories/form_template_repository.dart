// ZAFTO Form Template Repository — Supabase Backend
// CRUD for the form_templates table.
// System templates (company_id=NULL) are read-only.
// Company templates are CRUD.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/form_template.dart';

class FormTemplateRepository {
  static const _table = 'form_templates';

  // Get all templates visible to the company (own + system).
  // RLS handles filtering: company sees own + WHERE company_id IS NULL.
  Future<List<FormTemplate>> getTemplates() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('sort_order')
          .order('name');
      return (response as List)
          .map((row) => FormTemplate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load form templates',
        userMessage: 'Could not load form templates.',
        cause: e,
      );
    }
  }

  // Get templates filtered by trade (includes trade=NULL system templates).
  Future<List<FormTemplate>> getTemplatesByTrade(String trade) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('is_active', true)
          .or('trade.eq.$trade,trade.is.null')
          .order('sort_order')
          .order('name');
      return (response as List)
          .map((row) => FormTemplate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load templates for trade $trade',
        userMessage: 'Could not load form templates.',
        cause: e,
      );
    }
  }

  // Get templates for multiple trades (union of trade-specific + general).
  Future<List<FormTemplate>> getTemplatesForTrades(
      List<String> trades) async {
    try {
      final tradeFilter =
          trades.map((t) => 'trade.eq.$t').join(',');
      final response = await supabase
          .from(_table)
          .select()
          .eq('is_active', true)
          .or('$tradeFilter,trade.is.null')
          .order('sort_order')
          .order('name');
      return (response as List)
          .map((row) => FormTemplate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load templates for trades',
        userMessage: 'Could not load form templates.',
        cause: e,
      );
    }
  }

  // Get system templates only.
  Future<List<FormTemplate>> getSystemTemplates() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('is_system', true)
          .order('trade')
          .order('sort_order');
      return (response as List)
          .map((row) => FormTemplate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load system templates',
        userMessage: 'Could not load form templates.',
        cause: e,
      );
    }
  }

  Future<FormTemplate?> getTemplate(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return FormTemplate.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load template $id',
        userMessage: 'Could not load form template.',
        cause: e,
      );
    }
  }

  // Create company-specific template (clone from system or new).
  Future<FormTemplate> createTemplate(FormTemplate template) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(template.toInsertJson())
          .select()
          .single();
      return FormTemplate.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create form template',
        userMessage: 'Could not create form template. Please try again.',
        cause: e,
      );
    }
  }

  Future<FormTemplate> updateTemplate(
      String id, FormTemplate template) async {
    try {
      final response = await supabase
          .from(_table)
          .update(template.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return FormTemplate.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update form template',
        userMessage: 'Could not update form template. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete template $id',
        userMessage: 'Could not delete form template.',
        cause: e,
      );
    }
  }
}
