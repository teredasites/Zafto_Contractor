// ZAFTO Warranty Intelligence Provider
// W2: Riverpod providers for warranty portfolio, claims, recalls.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/warranty_outreach_log.dart';
import '../models/warranty_claim.dart';
import '../models/product_recall.dart';
import '../repositories/warranty_intelligence_repository.dart';

// ══════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER (singleton)
// ══════════════════════════════════════════════════════════════════

final warrantyIntelligenceRepoProvider =
    Provider<WarrantyIntelligenceRepository>((ref) {
  return WarrantyIntelligenceRepository();
});

// ══════════════════════════════════════════════════════════════════
// EXPIRING WARRANTIES — equipment with warranties ending in 90 days
// ══════════════════════════════════════════════════════════════════

final expiringWarrantiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(warrantyIntelligenceRepoProvider);
  return repo.getExpiringWarranties(daysAhead: 90);
});

// ══════════════════════════════════════════════════════════════════
// WARRANTY CLAIMS (all, company-scoped via RLS)
// ══════════════════════════════════════════════════════════════════

final warrantyClaimsProvider =
    FutureProvider.autoDispose<List<WarrantyClaim>>((ref) async {
  final repo = ref.read(warrantyIntelligenceRepoProvider);
  return repo.getClaims();
});

// ══════════════════════════════════════════════════════════════════
// WARRANTY CLAIMS BY EQUIPMENT (.family by equipment ID)
// ══════════════════════════════════════════════════════════════════

final warrantyClaimsByEquipmentProvider =
    FutureProvider.autoDispose
        .family<List<WarrantyClaim>, String>((ref, equipmentId) async {
  final repo = ref.read(warrantyIntelligenceRepoProvider);
  return repo.getClaims(equipmentId: equipmentId);
});

// ══════════════════════════════════════════════════════════════════
// OUTREACH LOG BY EQUIPMENT (.family by equipment ID)
// ══════════════════════════════════════════════════════════════════

final outreachByEquipmentProvider =
    FutureProvider.autoDispose
        .family<List<WarrantyOutreachLog>, String>((ref, equipmentId) async {
  final repo = ref.read(warrantyIntelligenceRepoProvider);
  return repo.getOutreachLogs(equipmentId: equipmentId);
});

// ══════════════════════════════════════════════════════════════════
// OUTREACH LOG BY CUSTOMER (.family by customer ID)
// ══════════════════════════════════════════════════════════════════

final outreachByCustomerProvider =
    FutureProvider.autoDispose
        .family<List<WarrantyOutreachLog>, String>((ref, customerId) async {
  final repo = ref.read(warrantyIntelligenceRepoProvider);
  return repo.getOutreachLogs(customerId: customerId);
});

// ══════════════════════════════════════════════════════════════════
// PRODUCT RECALLS (active only)
// ══════════════════════════════════════════════════════════════════

final productRecallsProvider =
    FutureProvider.autoDispose<List<ProductRecall>>((ref) async {
  final repo = ref.read(warrantyIntelligenceRepoProvider);
  return repo.getRecalls();
});

// ══════════════════════════════════════════════════════════════════
// CHECK RECALLS FOR SPECIFIC EQUIPMENT
// ══════════════════════════════════════════════════════════════════

final equipmentRecallsProvider = FutureProvider.autoDispose
    .family<List<ProductRecall>, ({String manufacturer, String? model})>(
        (ref, params) async {
  final repo = ref.read(warrantyIntelligenceRepoProvider);
  return repo.checkRecallsForEquipment(params.manufacturer, params.model);
});
