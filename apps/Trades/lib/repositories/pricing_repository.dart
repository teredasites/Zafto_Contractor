// ZAFTO Pricing Repository — Supabase Backend
// CRUD for pricing_rules and pricing_suggestions tables.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/pricing_rule.dart';
import '../models/pricing_suggestion.dart';

class PricingRepository {
  // ── Pricing Rules ──────────────────────────────────────

  static const _rulesTable = 'pricing_rules';

  Future<List<PricingRule>> getRules({bool? activeOnly}) async {
    try {
      var query = supabase.from(_rulesTable).select().isFilter('deleted_at', null);
      if (activeOnly == true) query = query.eq('active', true);
      final response = await query.order('priority', ascending: false);
      return (response as List).map((row) => PricingRule.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load pricing rules', userMessage: 'Could not load pricing rules.', cause: e);
    }
  }

  Future<PricingRule> createRule(PricingRule rule) async {
    try {
      final response = await supabase.from(_rulesTable).insert(rule.toJson()).select().single();
      return PricingRule.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create pricing rule', userMessage: 'Could not save pricing rule.', cause: e);
    }
  }

  Future<void> updateRule(String id, Map<String, dynamic> updates) async {
    try {
      await supabase.from(_rulesTable).update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update pricing rule', userMessage: 'Could not update pricing rule.', cause: e);
    }
  }

  Future<void> toggleRule(String id, bool active) async {
    try {
      await supabase.from(_rulesTable).update({'active': active}).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to toggle pricing rule', userMessage: 'Could not toggle pricing rule.', cause: e);
    }
  }

  Future<void> deleteRule(String id) async {
    try {
      await supabase.from(_rulesTable).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete pricing rule', userMessage: 'Could not delete pricing rule.', cause: e);
    }
  }

  // ── Pricing Suggestions ────────────────────────────────

  static const _suggestionsTable = 'pricing_suggestions';

  Future<List<PricingSuggestion>> getSuggestions({String? estimateId}) async {
    try {
      var query = supabase.from(_suggestionsTable).select().isFilter('deleted_at', null);
      if (estimateId != null) query = query.eq('estimate_id', estimateId);
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((row) => PricingSuggestion.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load suggestions', userMessage: 'Could not load pricing suggestions.', cause: e);
    }
  }

  Future<PricingSuggestion?> getLatestForEstimate(String estimateId) async {
    try {
      final response = await supabase
          .from(_suggestionsTable)
          .select()
          .eq('estimate_id', estimateId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return PricingSuggestion.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to load suggestion', userMessage: 'Could not load pricing suggestion.', cause: e);
    }
  }

  Future<void> updateSuggestionAcceptance(String id, {required bool accepted, double? finalPrice}) async {
    try {
      final updates = <String, dynamic>{
        'accepted': accepted,
        if (finalPrice != null) 'final_price': finalPrice,
      };
      await supabase.from(_suggestionsTable).update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update suggestion', userMessage: 'Could not update suggestion.', cause: e);
    }
  }

  Future<void> markSuggestionJobWon(String id, bool won) async {
    try {
      await supabase.from(_suggestionsTable).update({'job_won': won}).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update suggestion', userMessage: 'Could not update suggestion.', cause: e);
    }
  }
}
