// ZAFTO Inspection Service — Inspector Role
// Created: S121 Inspector App Buildout
//
// Providers + business logic for PM inspections, permit inspections,
// and TPI inspections. Wraps repositories with Riverpod providers.
//
// Providers: inspectionRepoProvider, inspectionServiceProvider,
//   inspectionsProvider, inspectionItemsProvider

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inspection.dart';
import '../repositories/inspection_repository.dart';

// ============================================================
// PROVIDERS
// ============================================================

final inspectionRepoProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepository();
});

final inspectionServiceProvider = Provider<InspectionService>((ref) {
  final repo = ref.watch(inspectionRepoProvider);
  return InspectionService(repo);
});

/// All inspections for the company (RLS-scoped).
final inspectionsProvider =
    AsyncNotifierProvider<InspectionsNotifier, List<PmInspection>>(
  InspectionsNotifier.new,
);

/// Items for a specific inspection.
final inspectionItemsProvider =
    FutureProvider.family<List<PmInspectionItem>, String>((ref, inspectionId) {
  final repo = ref.watch(inspectionRepoProvider);
  return repo.getInspectionItems(inspectionId);
});

// ============================================================
// INSPECTION SERVICE (business logic)
// ============================================================

class InspectionService {
  final InspectionRepository _repo;

  InspectionService(this._repo);

  Future<List<PmInspection>> getInspections({
    String? propertyId,
    String? unitId,
  }) =>
      _repo.getInspections(propertyId: propertyId, unitId: unitId);

  Future<PmInspection?> getInspection(String id) => _repo.getInspection(id);

  Future<PmInspection> createInspection(PmInspection inspection) =>
      _repo.createInspection(inspection);

  Future<PmInspection> updateInspection(String id, PmInspection inspection) =>
      _repo.updateInspection(id, inspection);

  Future<PmInspection> completeInspection(
    String id,
    ItemCondition overall,
    int score,
  ) =>
      _repo.completeInspection(id, overall, score);

  Future<List<PmInspectionItem>> getItems(String inspectionId) =>
      _repo.getInspectionItems(inspectionId);

  Future<PmInspectionItem> addItem(PmInspectionItem item) =>
      _repo.addInspectionItem(item);

  Future<PmInspectionItem> updateItem(String id, PmInspectionItem item) =>
      _repo.updateInspectionItem(id, item);

  // Computed helpers
  int passCount(List<PmInspection> inspections) =>
      inspections.where((i) => i.score >= 70 && i.status == InspectionStatus.completed).length;

  int failCount(List<PmInspection> inspections) =>
      inspections.where((i) => i.score < 70 && i.status == InspectionStatus.completed).length;

  double passRate(List<PmInspection> inspections) {
    final completed = inspections.where((i) => i.status == InspectionStatus.completed).toList();
    if (completed.isEmpty) return 0;
    return passCount(inspections) / completed.length * 100;
  }

  List<PmInspection> scheduledToday(List<PmInspection> inspections) {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return inspections.where((i) {
      if (i.scheduledDate == null) return false;
      return i.scheduledDate!.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          i.scheduledDate!.isBefore(dayEnd);
    }).toList()
      ..sort((a, b) => (a.scheduledDate ?? DateTime(2099))
          .compareTo(b.scheduledDate ?? DateTime(2099)));
  }

  List<PmInspection> thisWeek(List<PmInspection> inspections) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    return inspections.where((i) {
      final date = i.completedDate ?? i.scheduledDate;
      if (date == null) return false;
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end);
    }).toList();
  }
}

// ============================================================
// NOTIFIER
// ============================================================

class InspectionsNotifier extends AsyncNotifier<List<PmInspection>> {
  @override
  Future<List<PmInspection>> build() async {
    final service = ref.watch(inspectionServiceProvider);
    return service.getInspections();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncGuard(() => build());
  }

  Future<void> create(PmInspection inspection) async {
    final service = ref.read(inspectionServiceProvider);
    await service.createInspection(inspection);
    await refresh();
  }

  Future<void> complete(String id, ItemCondition overall, int score) async {
    final service = ref.read(inspectionServiceProvider);
    await service.completeInspection(id, overall, score);
    await refresh();
  }
}
