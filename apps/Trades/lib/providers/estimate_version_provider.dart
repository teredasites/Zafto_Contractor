// ZAFTO Estimate Version Provider
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Riverpod providers for estimate versions and change orders.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/estimate_version.dart';
import '../repositories/estimate_version_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final estimateVersionRepoProvider = Provider<EstimateVersionRepository>((ref) {
  return EstimateVersionRepository();
});

// ════════════════════════════════════════════════════════════════
// VERSIONS FOR AN ESTIMATE
// ════════════════════════════════════════════════════════════════

final estimateVersionsProvider = FutureProvider.autoDispose
    .family<List<EstimateVersion>, String>((ref, estimateId) async {
  final repo = ref.read(estimateVersionRepoProvider);
  return repo.getVersions(estimateId);
});

// ════════════════════════════════════════════════════════════════
// CHANGE ORDERS FOR AN ESTIMATE
// ════════════════════════════════════════════════════════════════

final estimateChangeOrdersProvider = FutureProvider.autoDispose
    .family<List<EstimateChangeOrder>, String>((ref, estimateId) async {
  final repo = ref.read(estimateVersionRepoProvider);
  return repo.getChangeOrders(estimateId);
});
