// ZAFTO Job Intelligence Repository — Supabase Backend
// CRUD for job_cost_autopsies, autopsy_insights, estimate_adjustments tables.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/job_cost_autopsy.dart';
import '../models/autopsy_insight.dart';
import '../models/estimate_adjustment.dart';

class JobIntelligenceRepository {
  // ── Job Cost Autopsies ────────────────────────────────
  static const _autopsyTable = 'job_cost_autopsies';

  Future<List<JobCostAutopsy>> getAutopsies({String? jobType, String? tradeType}) async {
    try {
      var query = supabase.from(_autopsyTable).select();
      if (jobType != null) query = query.eq('job_type', jobType);
      if (tradeType != null) query = query.eq('trade_type', tradeType);
      final response = await query.order('completed_at', ascending: false);
      return (response as List).map((row) => JobCostAutopsy.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load autopsies', userMessage: 'Could not load job cost data.', cause: e);
    }
  }

  Future<JobCostAutopsy?> getAutopsyByJobId(String jobId) async {
    try {
      final response = await supabase.from(_autopsyTable).select().eq('job_id', jobId).maybeSingle();
      if (response == null) return null;
      return JobCostAutopsy.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to load autopsy', userMessage: 'Could not load job cost analysis.', cause: e);
    }
  }

  Future<JobCostAutopsy> createAutopsy(JobCostAutopsy autopsy) async {
    try {
      final response = await supabase.from(_autopsyTable).insert(autopsy.toJson()).select().single();
      return JobCostAutopsy.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create autopsy', userMessage: 'Could not save job cost analysis.', cause: e);
    }
  }

  // ── Autopsy Insights ──────────────────────────────────
  static const _insightsTable = 'autopsy_insights';

  Future<List<AutopsyInsight>> getInsights({InsightType? type}) async {
    try {
      var query = supabase.from(_insightsTable).select();
      if (type != null) query = query.eq('insight_type', type.dbValue);
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((row) => AutopsyInsight.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load insights', userMessage: 'Could not load intelligence data.', cause: e);
    }
  }

  Future<AutopsyInsight> createInsight(AutopsyInsight insight) async {
    try {
      final response = await supabase.from(_insightsTable).insert(insight.toJson()).select().single();
      return AutopsyInsight.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create insight', userMessage: 'Could not save insight.', cause: e);
    }
  }

  // ── Estimate Adjustments ──────────────────────────────
  static const _adjustmentsTable = 'estimate_adjustments';

  Future<List<EstimateAdjustment>> getAdjustments({AdjustmentStatus? status}) async {
    try {
      var query = supabase.from(_adjustmentsTable).select();
      if (status != null) query = query.eq('status', status.dbValue);
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((row) => EstimateAdjustment.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load adjustments', userMessage: 'Could not load estimate adjustments.', cause: e);
    }
  }

  Future<void> updateAdjustmentStatus(String id, AdjustmentStatus status) async {
    try {
      final updates = <String, dynamic>{'status': status.dbValue};
      if (status == AdjustmentStatus.applied) {
        updates['applied_at'] = DateTime.now().toIso8601String();
      }
      await supabase.from(_adjustmentsTable).update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update adjustment', userMessage: 'Could not update adjustment status.', cause: e);
    }
  }

  // ── Profitability Summary ─────────────────────────────

  Future<Map<String, dynamic>> getProfitabilitySummary() async {
    try {
      final response = await supabase.from(_autopsyTable).select(
        'job_type, gross_margin_pct, revenue, gross_profit, variance_pct'
      );

      final autopsies = List<Map<String, dynamic>>.from(response as List);
      if (autopsies.isEmpty) {
        return {'totalJobs': 0, 'avgMargin': 0.0, 'totalRevenue': 0.0, 'totalProfit': 0.0};
      }

      final totalJobs = autopsies.length;
      final totalRevenue = autopsies.fold<double>(0, (sum, a) => sum + ((a['revenue'] as num?)?.toDouble() ?? 0));
      final totalProfit = autopsies.fold<double>(0, (sum, a) => sum + ((a['gross_profit'] as num?)?.toDouble() ?? 0));
      final avgMargin = autopsies.fold<double>(0, (sum, a) => sum + ((a['gross_margin_pct'] as num?)?.toDouble() ?? 0)) / totalJobs;

      return {
        'totalJobs': totalJobs,
        'avgMargin': avgMargin,
        'totalRevenue': totalRevenue,
        'totalProfit': totalProfit,
      };
    } catch (e) {
      throw DatabaseError('Failed to calculate profitability', userMessage: 'Could not load profitability data.', cause: e);
    }
  }
}
