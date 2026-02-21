// ZAFTO Disposal & Dump Finder Providers
// Created: DEPTH36 — Facilities, dump receipts, scrap prices, waste types.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/disposal_facility_repository.dart';
import '../models/disposal_facility.dart';

// ══════════════════════════════════════════════════════════════
// REPOSITORY
// ══════════════════════════════════════════════════════════════

final disposalRepoProvider = Provider<DisposalFacilityRepository>((ref) {
  return DisposalFacilityRepository();
});

// ══════════════════════════════════════════════════════════════
// FACILITIES
// ══════════════════════════════════════════════════════════════

final disposalFacilitiesProvider =
    FutureProvider.autoDispose.family<List<DisposalFacility>, ({String? facilityType, String? stateCode})>(
  (ref, params) {
    return ref.watch(disposalRepoProvider).getFacilities(
      facilityType: params.facilityType,
      stateCode: params.stateCode,
    );
  },
);

final disposalFacilityProvider =
    FutureProvider.autoDispose.family<DisposalFacility, String>(
  (ref, id) {
    return ref.watch(disposalRepoProvider).getFacility(id);
  },
);

final disposalFacilitySearchProvider =
    FutureProvider.autoDispose.family<List<DisposalFacility>, String>(
  (ref, query) {
    return ref.watch(disposalRepoProvider).searchFacilities(query);
  },
);

// ══════════════════════════════════════════════════════════════
// DUMP RECEIPTS
// ══════════════════════════════════════════════════════════════

final dumpReceiptsProvider =
    FutureProvider.autoDispose.family<List<DumpReceipt>, ({String companyId, String? jobId})>(
  (ref, params) {
    return ref.watch(disposalRepoProvider).getReceipts(params.companyId, jobId: params.jobId);
  },
);

final dumpReceiptProvider =
    FutureProvider.autoDispose.family<DumpReceipt, String>(
  (ref, id) {
    return ref.watch(disposalRepoProvider).getReceipt(id);
  },
);

// ══════════════════════════════════════════════════════════════
// SCRAP PRICES (system reference)
// ══════════════════════════════════════════════════════════════

final scrapPricesProvider = FutureProvider<List<ScrapPriceIndex>>((ref) {
  return ref.watch(disposalRepoProvider).getLatestScrapPrices();
});

final scrapPricesByMaterialProvider =
    FutureProvider.autoDispose.family<List<ScrapPriceIndex>, String>(
  (ref, material) {
    return ref.watch(disposalRepoProvider).getScrapPrices(material: material);
  },
);

// ══════════════════════════════════════════════════════════════
// WASTE TYPE REFERENCE (system reference)
// ══════════════════════════════════════════════════════════════

final wasteTypesProvider = FutureProvider<List<WasteTypeReference>>((ref) {
  return ref.watch(disposalRepoProvider).getWasteTypes();
});

final wasteTypesByCategoryProvider =
    FutureProvider.autoDispose.family<List<WasteTypeReference>, String>(
  (ref, category) {
    return ref.watch(disposalRepoProvider).getWasteTypes(category: category);
  },
);
