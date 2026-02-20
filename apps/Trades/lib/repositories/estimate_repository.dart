// ZAFTO Estimate Repository — Supabase Backend
// CRUD for xactimate_estimate_lines + code search from xactimate_codes.
// Pricing lookups from pricing_entries. Template reads from estimate_templates.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/estimate_line.dart';
import '../models/xactimate_code.dart';

class EstimateRepository {
  static const _linesTable = 'xactimate_estimate_lines';
  static const _codesTable = 'xactimate_codes';
  static const _pricingTable = 'pricing_entries';
  static const _templatesTable = 'estimate_templates';

  // ==================== ESTIMATE LINES ====================

  Future<List<EstimateLine>> getLines(String claimId) async {
    try {
      final response = await supabase
          .from(_linesTable)
          .select()
          .eq('claim_id', claimId)
          .order('line_number', ascending: true);

      return (response as List)
          .map((row) => EstimateLine.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load estimate lines for claim $claimId',
        userMessage: 'Could not load estimate lines.',
        cause: e,
      );
    }
  }

  Future<EstimateLine> addLine(EstimateLine line) async {
    try {
      final response = await supabase
          .from(_linesTable)
          .insert(line.toInsertJson())
          .select()
          .single();

      return EstimateLine.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add estimate line',
        userMessage: 'Could not add line item. Please try again.',
        cause: e,
      );
    }
  }

  Future<EstimateLine> updateLine(String id, EstimateLine line) async {
    try {
      final response = await supabase
          .from(_linesTable)
          .update(line.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return EstimateLine.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update estimate line',
        userMessage: 'Could not update line item. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteLine(String id) async {
    try {
      await supabase.from(_linesTable).update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete estimate line',
        userMessage: 'Could not delete line item.',
        cause: e,
      );
    }
  }

  Future<void> deleteAllLines(String claimId) async {
    try {
      await supabase.from(_linesTable).update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('claim_id', claimId);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete all estimate lines',
        userMessage: 'Could not clear estimate.',
        cause: e,
      );
    }
  }

  // Get next line number for a claim
  Future<int> getNextLineNumber(String claimId) async {
    try {
      final response = await supabase
          .from(_linesTable)
          .select('line_number')
          .eq('claim_id', claimId)
          .order('line_number', ascending: false)
          .limit(1);

      if ((response as List).isEmpty) return 1;
      final lastNumber = response[0]['line_number'] as int? ?? 0;
      return lastNumber + 1;
    } catch (_) {
      return 1;
    }
  }

  // ==================== CODE SEARCH ====================

  Future<List<XactimateCode>> searchCodes(
    String query, {
    String? categoryCode,
    int limit = 25,
  }) async {
    try {
      var q = supabase
          .from(_codesTable)
          .select()
          .eq('deprecated', false);

      if (categoryCode != null && categoryCode.isNotEmpty) {
        q = q.eq('category_code', categoryCode);
      }

      // Search across full_code and description using ilike
      if (query.isNotEmpty) {
        q = q.or('full_code.ilike.%$query%,description.ilike.%$query%');
      }

      final response = await q
          .order('full_code', ascending: true)
          .limit(limit);

      return (response as List)
          .map((row) => XactimateCode.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to search codes',
        userMessage: 'Code search failed.',
        cause: e,
      );
    }
  }

  Future<List<Map<String, String>>> getCategories() async {
    try {
      // Get distinct category codes and names
      final response = await supabase
          .from(_codesTable)
          .select('category_code, category_name')
          .eq('deprecated', false)
          .order('category_code', ascending: true);

      // Deduplicate in Dart since Supabase doesn't support DISTINCT easily
      final seen = <String>{};
      final categories = <Map<String, String>>[];
      for (final row in (response as List)) {
        final code = row['category_code'] as String? ?? '';
        if (code.isNotEmpty && seen.add(code)) {
          categories.add({
            'code': code,
            'name': row['category_name'] as String? ?? code,
          });
        }
      }
      return categories;
    } catch (e) {
      throw DatabaseError(
        'Failed to load categories',
        userMessage: 'Could not load code categories.',
        cause: e,
      );
    }
  }

  Future<XactimateCode?> getCode(String codeId) async {
    try {
      final response = await supabase
          .from(_codesTable)
          .select()
          .eq('id', codeId)
          .maybeSingle();

      if (response == null) return null;
      return XactimateCode.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load code $codeId',
        userMessage: 'Could not load code.',
        cause: e,
      );
    }
  }

  // ==================== PRICING ====================

  Future<PricingEntry?> getPricing(String codeId, {String? regionCode}) async {
    try {
      var q = supabase
          .from(_pricingTable)
          .select()
          .eq('code_id', codeId);

      if (regionCode != null) {
        q = q.eq('region_code', regionCode);
      }

      final response = await q
          .order('confidence', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return PricingEntry.fromJson(response);
    } catch (_) {
      // Pricing is optional — fail silently
      return null;
    }
  }

  // ==================== TEMPLATES ====================

  Future<List<EstimateTemplate>> getTemplates({String? companyId}) async {
    try {
      var q = supabase.from(_templatesTable).select();

      if (companyId != null) {
        // Get company-specific + system templates
        q = q.or('company_id.eq.$companyId,is_system.eq.true');
      } else {
        q = q.eq('is_system', true);
      }

      final response = await q.order('usage_count', ascending: false);

      return (response as List)
          .map((row) => EstimateTemplate.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load estimate templates',
        userMessage: 'Could not load templates.',
        cause: e,
      );
    }
  }

  Future<void> incrementTemplateUsage(String templateId) async {
    try {
      // Read current count, increment. Simple approach for mobile.
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
}
