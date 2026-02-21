// ZAFTO Recon-to-Estimate Pipeline Provider
// Created: DEPTH30 — One Address → Complete Bid
//
// Riverpod providers for recon-estimate mappings, recommendations,
// bundles, and cross-trade dependencies.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recon_estimate_pipeline.dart';
import '../repositories/recon_estimate_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final reconEstimateRepoProvider = Provider<ReconEstimateRepository>((ref) {
  return ReconEstimateRepository();
});

// ════════════════════════════════════════════════════════════════
// MEASUREMENT MAPPINGS (by trade)
// ════════════════════════════════════════════════════════════════

final reconMappingsProvider = FutureProvider.autoDispose
    .family<List<ReconEstimateMapping>, String>((ref, trade) async {
  final repo = ref.read(reconEstimateRepoProvider);
  return repo.getMappings(trade);
});

/// All mappings (for admin/settings)
final allReconMappingsProvider =
    FutureProvider.autoDispose<List<ReconEstimateMapping>>((ref) async {
  final repo = ref.read(reconEstimateRepoProvider);
  return repo.getAllMappings();
});

// ════════════════════════════════════════════════════════════════
// MATERIAL RECOMMENDATIONS (by trade)
// ════════════════════════════════════════════════════════════════

final reconRecommendationsProvider = FutureProvider.autoDispose
    .family<List<ReconMaterialRecommendation>, String>((ref, trade) async {
  final repo = ref.read(reconEstimateRepoProvider);
  return repo.getRecommendations(trade);
});

// ════════════════════════════════════════════════════════════════
// ESTIMATE BUNDLES
// ════════════════════════════════════════════════════════════════

final estimateBundlesProvider =
    FutureProvider.autoDispose<List<EstimateBundle>>((ref) async {
  final repo = ref.read(reconEstimateRepoProvider);
  return repo.getBundles();
});

final estimateBundleProvider = FutureProvider.autoDispose
    .family<EstimateBundle, String>((ref, bundleId) async {
  final repo = ref.read(reconEstimateRepoProvider);
  return repo.getBundle(bundleId);
});

// ════════════════════════════════════════════════════════════════
// CROSS-TRADE DEPENDENCIES
// ════════════════════════════════════════════════════════════════

final crossTradeDependenciesProvider =
    FutureProvider.autoDispose<List<CrossTradeDependency2>>((ref) async {
  final repo = ref.read(reconEstimateRepoProvider);
  return repo.getDependencies();
});
