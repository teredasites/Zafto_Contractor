// ZAFTO Estimate Engine Service — Supabase Backend
// Created: Sprint D8c (Session 86)
//
// Auth-enriched wrapper around EstimateEngineRepository.
// Providers, notifier, and business logic for the D8 estimate engine.
// Separate from E5 EstimateService (xactimate-specific).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/estimate.dart';
import '../models/estimate_item.dart';
import '../repositories/estimate_engine_repository.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final estimateEngineRepositoryProvider =
    Provider<EstimateEngineRepository>((ref) {
  return EstimateEngineRepository();
});

final estimateEngineServiceProvider = Provider<EstimateEngineService>((ref) {
  final repo = ref.watch(estimateEngineRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return EstimateEngineService(repo, authState);
});

final estimatesProvider =
    StateNotifierProvider<EstimatesNotifier, AsyncValue<List<Estimate>>>(
        (ref) {
  final service = ref.watch(estimateEngineServiceProvider);
  return EstimatesNotifier(service);
});

final draftEstimatesProvider = Provider<List<Estimate>>((ref) {
  final estimates = ref.watch(estimatesProvider);
  return estimates.maybeWhen(
    data: (list) =>
        list.where((e) => e.status == EstimateStatus.draft).toList(),
    orElse: () => [],
  );
});

final sentEstimatesProvider = Provider<List<Estimate>>((ref) {
  final estimates = ref.watch(estimatesProvider);
  return estimates.maybeWhen(
    data: (list) => list
        .where((e) =>
            e.status == EstimateStatus.sent ||
            e.status == EstimateStatus.viewed)
        .toList(),
    orElse: () => [],
  );
});

final approvedEstimatesProvider = Provider<List<Estimate>>((ref) {
  final estimates = ref.watch(estimatesProvider);
  return estimates.maybeWhen(
    data: (list) => list
        .where((e) =>
            e.status == EstimateStatus.approved ||
            e.status == EstimateStatus.converted)
        .toList(),
    orElse: () => [],
  );
});

final insuranceEstimatesProvider = Provider<List<Estimate>>((ref) {
  final estimates = ref.watch(estimatesProvider);
  return estimates.maybeWhen(
    data: (list) =>
        list.where((e) => e.estimateType == EstimateType.insurance).toList(),
    orElse: () => [],
  );
});

final estimateStatsProvider = Provider<EstimateStats>((ref) {
  final estimates = ref.watch(estimatesProvider);
  return estimates.maybeWhen(
    data: (list) {
      final drafts =
          list.where((e) => e.status == EstimateStatus.draft).length;
      final sent = list
          .where((e) =>
              e.status == EstimateStatus.sent ||
              e.status == EstimateStatus.viewed)
          .length;
      final approved = list
          .where((e) =>
              e.status == EstimateStatus.approved ||
              e.status == EstimateStatus.converted)
          .length;
      final rejected =
          list.where((e) => e.status == EstimateStatus.rejected).length;

      final approvedEstimates = list.where((e) =>
          e.status == EstimateStatus.approved ||
          e.status == EstimateStatus.converted);
      final totalValue = approvedEstimates.fold<double>(
          0.0, (sum, e) => sum + e.grandTotal);

      final pendingEstimates = list.where((e) =>
          e.status == EstimateStatus.sent ||
          e.status == EstimateStatus.viewed);
      final pendingValue = pendingEstimates.fold<double>(
          0.0, (sum, e) => sum + e.grandTotal);

      final decisions = approved + rejected;
      final approvalRate =
          decisions > 0 ? (approved / decisions * 100) : 0.0;

      final insurance =
          list.where((e) => e.estimateType == EstimateType.insurance).length;

      return EstimateStats(
        totalEstimates: list.length,
        draftEstimates: drafts,
        sentEstimates: sent,
        approvedEstimates: approved,
        rejectedEstimates: rejected,
        insuranceEstimates: insurance,
        totalValue: totalValue,
        pendingValue: pendingValue,
        approvalRate: approvalRate,
      );
    },
    orElse: () => EstimateStats.empty(),
  );
});

// Code database providers (reference data, cached)
final estimateCategoriesProvider =
    FutureProvider<List<EstimateCategory>>((ref) async {
  final repo = ref.watch(estimateEngineRepositoryProvider);
  return repo.getCategories();
});

final estimateUnitsProvider =
    FutureProvider<List<EstimateUnit>>((ref) async {
  final repo = ref.watch(estimateEngineRepositoryProvider);
  return repo.getUnits();
});

// ============================================================
// STATS MODEL
// ============================================================

class EstimateStats {
  final int totalEstimates;
  final int draftEstimates;
  final int sentEstimates;
  final int approvedEstimates;
  final int rejectedEstimates;
  final int insuranceEstimates;
  final double totalValue;
  final double pendingValue;
  final double approvalRate;

  const EstimateStats({
    required this.totalEstimates,
    required this.draftEstimates,
    required this.sentEstimates,
    required this.approvedEstimates,
    required this.rejectedEstimates,
    required this.insuranceEstimates,
    required this.totalValue,
    required this.pendingValue,
    required this.approvalRate,
  });

  factory EstimateStats.empty() => const EstimateStats(
        totalEstimates: 0,
        draftEstimates: 0,
        sentEstimates: 0,
        approvedEstimates: 0,
        rejectedEstimates: 0,
        insuranceEstimates: 0,
        totalValue: 0,
        pendingValue: 0,
        approvalRate: 0,
      );

  String get totalValueDisplay =>
      '\$${totalValue.toStringAsFixed(2)}';
  String get pendingValueDisplay =>
      '\$${pendingValue.toStringAsFixed(2)}';
  String get approvalRateDisplay =>
      '${approvalRate.toStringAsFixed(1)}%';
}

// ============================================================
// ESTIMATES NOTIFIER
// ============================================================

class EstimatesNotifier extends StateNotifier<AsyncValue<List<Estimate>>> {
  final EstimateEngineService _service;

  EstimatesNotifier(this._service)
      : super(const AsyncValue.loading()) {
    loadEstimates();
  }

  Future<void> loadEstimates() async {
    state = const AsyncValue.loading();
    try {
      final estimates = await _service.getAllEstimates();
      state = AsyncValue.data(estimates);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEstimate(Estimate estimate) async {
    try {
      await _service.createEstimate(estimate);
      await loadEstimates();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEstimate(Estimate estimate) async {
    try {
      await _service.updateEstimate(estimate);
      await loadEstimates();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEstimate(String id) async {
    try {
      await _service.deleteEstimate(id);
      await loadEstimates();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Estimate> search(String query) {
    return state.maybeWhen(
      data: (list) {
        final q = query.toLowerCase();
        return list
            .where((e) =>
                e.estimateNumber.toLowerCase().contains(q) ||
                (e.title?.toLowerCase().contains(q) ?? false) ||
                (e.propertyAddress?.toLowerCase().contains(q) ?? false) ||
                (e.claimNumber?.toLowerCase().contains(q) ?? false))
            .toList();
      },
      orElse: () => [],
    );
  }
}

// ============================================================
// ESTIMATE ENGINE SERVICE (business logic)
// ============================================================

class EstimateEngineService {
  final EstimateEngineRepository _repo;
  final AuthState _authState;

  EstimateEngineService(this._repo, this._authState);

  // --- Estimates ---

  Future<List<Estimate>> getAllEstimates() => _repo.getEstimates();

  Future<Estimate?> getEstimate(String id) => _repo.getEstimate(id);

  Future<List<Estimate>> getEstimatesByStatus(EstimateStatus status) =>
      _repo.getEstimatesByStatus(status);

  Future<List<Estimate>> getEstimatesByType(EstimateType type) =>
      _repo.getEstimatesByType(type);

  Future<List<Estimate>> getEstimatesForJob(String jobId) =>
      _repo.getEstimatesByJob(jobId);

  Future<List<Estimate>> getEstimatesForCustomer(String customerId) =>
      _repo.getEstimatesByCustomer(customerId);

  Future<Estimate> createEstimate(Estimate estimate) {
    final enriched = estimate.copyWith(
      companyId: _authState.companyId ?? '',
      createdBy: _authState.user?.uid ?? '',
    );
    return _repo.createEstimate(enriched);
  }

  Future<Estimate> updateEstimate(Estimate estimate) =>
      _repo.updateEstimate(estimate.id, estimate);

  Future<void> deleteEstimate(String id) => _repo.deleteEstimate(id);

  Future<List<Estimate>> searchEstimates(String query) =>
      _repo.searchEstimates(query);

  Future<String> generateEstimateNumber() => _repo.nextEstimateNumber();

  Future<Estimate> saveEstimate(Estimate estimate) async {
    if (estimate.id.isEmpty) {
      return createEstimate(estimate);
    } else {
      return updateEstimate(estimate);
    }
  }

  // --- Areas ---

  Future<List<EstimateArea>> getAreas(String estimateId) =>
      _repo.getAreas(estimateId);

  Future<EstimateArea> createArea(EstimateArea area) =>
      _repo.createArea(area);

  Future<EstimateArea> updateArea(EstimateArea area) =>
      _repo.updateArea(area.id, area);

  Future<void> deleteArea(String id) => _repo.deleteArea(id);

  // --- Line Items ---

  Future<List<EstimateLineItem>> getLineItems(String estimateId) =>
      _repo.getLineItems(estimateId);

  Future<EstimateLineItem> createLineItem(EstimateLineItem item) =>
      _repo.createLineItem(item);

  Future<List<EstimateLineItem>> createLineItems(
          List<EstimateLineItem> items) =>
      _repo.createLineItems(items);

  Future<EstimateLineItem> updateLineItem(EstimateLineItem item) =>
      _repo.updateLineItem(item.id, item);

  Future<void> deleteLineItem(String id) => _repo.deleteLineItem(id);

  // --- Photos ---

  Future<List<EstimatePhoto>> getPhotos(String estimateId) =>
      _repo.getPhotos(estimateId);

  Future<EstimatePhoto> createPhoto(EstimatePhoto photo) =>
      _repo.createPhoto(photo);

  Future<void> deletePhoto(String id) => _repo.deletePhoto(id);

  // --- Code Database ---

  Future<List<EstimateItem>> getCodeItems({
    String? trade,
    String? categoryId,
    bool commonOnly = false,
  }) =>
      _repo.getCodeItems(
          trade: trade, categoryId: categoryId, commonOnly: commonOnly);

  Future<List<EstimateItem>> searchCodeItems(String query) =>
      _repo.searchCodeItems(query);

  Future<List<EstimateCategory>> getCategories() => _repo.getCategories();

  Future<List<EstimateUnit>> getUnits() => _repo.getUnits();

  // --- Estimate Operations ---

  Future<Estimate> sendEstimate(Estimate estimate) async {
    if (estimate.status != EstimateStatus.draft) {
      throw Exception('Can only send draft estimates');
    }
    final sent = estimate.copyWith(
      status: EstimateStatus.sent,
      sentAt: DateTime.now(),
    );
    return saveEstimate(sent);
  }

  Future<Estimate> approveEstimate(String id) async {
    final estimate = await getEstimate(id);
    if (estimate == null) throw Exception('Estimate not found');
    if (!estimate.isPending) throw Exception('Estimate is not pending');
    final approved = estimate.copyWith(
      status: EstimateStatus.approved,
      approvedAt: DateTime.now(),
    );
    return saveEstimate(approved);
  }

  Future<Estimate> rejectEstimate(String id) async {
    final estimate = await getEstimate(id);
    if (estimate == null) throw Exception('Estimate not found');
    if (!estimate.isPending) throw Exception('Estimate is not pending');
    final rejected = estimate.copyWith(
      status: EstimateStatus.rejected,
      rejectedAt: DateTime.now(),
    );
    return saveEstimate(rejected);
  }

  Future<Estimate> duplicateEstimate(String id) async {
    final original = await getEstimate(id);
    if (original == null) throw Exception('Estimate not found');

    final newNumber = await generateEstimateNumber();
    final now = DateTime.now();

    // Create new estimate header
    final duplicate = Estimate(
      companyId: _authState.companyId ?? original.companyId,
      createdBy: _authState.user?.uid ?? original.createdBy,
      estimateNumber: newNumber,
      title: '${original.title ?? original.estimateNumber} (Copy)',
      propertyAddress: original.propertyAddress,
      propertyCity: original.propertyCity,
      propertyState: original.propertyState,
      propertyZip: original.propertyZip,
      estimateType: original.estimateType,
      overheadPct: original.overheadPct,
      profitPct: original.profitPct,
      taxPct: original.taxPct,
      notes: original.notes,
      createdAt: now,
      updatedAt: now,
    );
    final created = await _repo.createEstimate(duplicate);

    // Copy areas
    for (final area in original.areas) {
      final newArea = area.copyWith(
        id: '',
        estimateId: created.id,
        createdAt: now,
      );
      await _repo.createArea(newArea);
    }

    // Copy line items
    for (final item in original.lineItems) {
      final newItem = item.copyWith(
        id: '',
        estimateId: created.id,
        createdAt: now,
      );
      await _repo.createLineItem(newItem);
    }

    // Re-fetch with children
    return (await _repo.getEstimate(created.id))!;
  }

  // Recalculate estimate totals from line items and save
  Future<Estimate> recalculateAndSave(String estimateId) async {
    final estimate = await getEstimate(estimateId);
    if (estimate == null) throw Exception('Estimate not found');
    final recalculated = estimate.recalculate();
    return updateEstimate(recalculated);
  }
}
