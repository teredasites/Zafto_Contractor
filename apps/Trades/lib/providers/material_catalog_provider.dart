// ZAFTO Material Catalog Provider
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Riverpod providers for material catalog with tier-based filtering.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_catalog.dart';
import '../repositories/material_catalog_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final materialCatalogRepoProvider = Provider<MaterialCatalogRepository>((ref) {
  return MaterialCatalogRepository();
});

// ════════════════════════════════════════════════════════════════
// ALL MATERIALS (optionally by trade)
// ════════════════════════════════════════════════════════════════

final materialCatalogProvider = FutureProvider.autoDispose
    .family<List<MaterialCatalogItem>, String?>((ref, trade) async {
  final repo = ref.read(materialCatalogRepoProvider);
  return repo.getMaterials(trade: trade);
});

// ════════════════════════════════════════════════════════════════
// SINGLE MATERIAL
// ════════════════════════════════════════════════════════════════

final materialItemProvider = FutureProvider.autoDispose
    .family<MaterialCatalogItem, String>((ref, materialId) async {
  final repo = ref.read(materialCatalogRepoProvider);
  return repo.getMaterial(materialId);
});

// ════════════════════════════════════════════════════════════════
// MATERIALS BY TIER
// ════════════════════════════════════════════════════════════════

final materialsByTierProvider = FutureProvider.autoDispose
    .family<List<MaterialCatalogItem>, MaterialTier>((ref, tier) async {
  final repo = ref.read(materialCatalogRepoProvider);
  return repo.getMaterialsByTier(tier);
});

// ════════════════════════════════════════════════════════════════
// TIER EQUIVALENTS FOR A MATERIAL
// ════════════════════════════════════════════════════════════════

final tierEquivalentsProvider = FutureProvider.autoDispose
    .family<List<MaterialCatalogItem>, String>((ref, materialId) async {
  final repo = ref.read(materialCatalogRepoProvider);
  return repo.getTierEquivalents(materialId);
});
