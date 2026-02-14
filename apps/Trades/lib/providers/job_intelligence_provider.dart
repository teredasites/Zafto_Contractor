// ZAFTO Job Intelligence Provider — Riverpod
// Exposes autopsy list, single autopsy, insights, adjustments, profitability summary.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/job_intelligence_repository.dart';
import '../models/job_cost_autopsy.dart';
import '../models/autopsy_insight.dart';
import '../models/estimate_adjustment.dart';

final jobIntelligenceRepositoryProvider = Provider<JobIntelligenceRepository>((ref) {
  return JobIntelligenceRepository();
});

// ── All autopsies (optionally filtered) ──────────────────────

final autopsyListProvider = FutureProvider.autoDispose
    .family<List<JobCostAutopsy>, ({String? jobType, String? tradeType})>((ref, params) {
  final repo = ref.watch(jobIntelligenceRepositoryProvider);
  return repo.getAutopsies(jobType: params.jobType, tradeType: params.tradeType);
});

// ── Single autopsy by job ID ─────────────────────────────────

final autopsyByJobProvider = FutureProvider.autoDispose
    .family<JobCostAutopsy?, String>((ref, jobId) {
  final repo = ref.watch(jobIntelligenceRepositoryProvider);
  return repo.getAutopsyByJobId(jobId);
});

// ── Insights ─────────────────────────────────────────────────

final insightsProvider = FutureProvider.autoDispose
    .family<List<AutopsyInsight>, InsightType?>((ref, type) {
  final repo = ref.watch(jobIntelligenceRepositoryProvider);
  return repo.getInsights(type: type);
});

// ── Adjustments ──────────────────────────────────────────────

final adjustmentsProvider = FutureProvider.autoDispose
    .family<List<EstimateAdjustment>, AdjustmentStatus?>((ref, status) {
  final repo = ref.watch(jobIntelligenceRepositoryProvider);
  return repo.getAdjustments(status: status);
});

// ── Profitability summary ────────────────────────────────────

final profitabilitySummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final repo = ref.watch(jobIntelligenceRepositoryProvider);
  return repo.getProfitabilitySummary();
});
