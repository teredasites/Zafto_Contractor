// ZAFTO Estimate Service — Supabase Backend
// Auth-enriched wrapper around EstimateRepository.
// Providers, notifier, and service for estimate lines + code search.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/estimate_line.dart';
import '../models/xactimate_code.dart';
import '../repositories/estimate_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final estimateRepositoryProvider = Provider<EstimateRepository>((ref) {
  return EstimateRepository();
});

final estimateServiceProvider = Provider<EstimateService>((ref) {
  final repo = ref.watch(estimateRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return EstimateService(repo, authState);
});

// Estimate lines for a specific claim.
final estimateLinesProvider = StateNotifierProvider.autoDispose
    .family<EstimateLinesNotifier, AsyncValue<List<EstimateLine>>, String>(
  (ref, claimId) {
    final service = ref.watch(estimateServiceProvider);
    return EstimateLinesNotifier(service, claimId);
  },
);

// Templates for current company.
final estimateTemplatesProvider =
    FutureProvider.autoDispose<List<EstimateTemplate>>((ref) async {
  final service = ref.watch(estimateServiceProvider);
  return service.getTemplates();
});

// Code categories (for filter chips).
final codeCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  final repo = ref.watch(estimateRepositoryProvider);
  return repo.getCategories();
});

// --- Notifier ---

class EstimateLinesNotifier
    extends StateNotifier<AsyncValue<List<EstimateLine>>> {
  final EstimateService _service;
  final String _claimId;

  EstimateLinesNotifier(this._service, this._claimId)
      : super(const AsyncValue.loading()) {
    loadLines();
  }

  Future<void> loadLines() async {
    state = const AsyncValue.loading();
    try {
      final lines = await _service.getLines(_claimId);
      state = AsyncValue.data(lines);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Group lines by room for display
  Map<String, List<EstimateLine>> get linesByRoom {
    final lines = state.valueOrNull ?? [];
    final grouped = <String, List<EstimateLine>>{};
    for (final line in lines) {
      final room = line.roomName ?? 'Unassigned';
      grouped.putIfAbsent(room, () => []).add(line);
    }
    return grouped;
  }

  // Totals
  double get subtotal =>
      (state.valueOrNull ?? []).fold<double>(0, (sum, l) => sum + l.total);

  int get lineCount => state.valueOrNull?.length ?? 0;
}

// --- Service ---

class EstimateService {
  final EstimateRepository _repo;
  final AuthState _authState;

  EstimateService(this._repo, this._authState);

  String get _companyId {
    final id = _authState.companyId;
    if (id == null || id.isEmpty) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to manage estimates.',
        code: AuthErrorCode.sessionExpired,
      );
    }
    return id;
  }

  // ==================== LINES ====================

  Future<List<EstimateLine>> getLines(String claimId) {
    return _repo.getLines(claimId);
  }

  Future<EstimateLine> addLine({
    required String claimId,
    String? codeId,
    required String category,
    required String itemCode,
    required String description,
    double quantity = 1,
    required String unit,
    required double unitPrice,
    double materialCost = 0,
    double laborCost = 0,
    double equipmentCost = 0,
    String? roomName,
    String? coverageGroup,
    bool isSupplement = false,
    String? supplementId,
    double depreciationRate = 0,
    String? notes,
  }) async {
    final nextLineNumber = await _repo.getNextLineNumber(claimId);

    final line = EstimateLine(
      companyId: _companyId,
      claimId: claimId,
      codeId: codeId,
      category: category,
      itemCode: itemCode,
      description: description,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      materialCost: materialCost,
      laborCost: laborCost,
      equipmentCost: equipmentCost,
      roomName: roomName,
      lineNumber: nextLineNumber,
      coverageGroup: coverageGroup,
      isSupplement: isSupplement,
      supplementId: supplementId,
      depreciationRate: depreciationRate,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.addLine(line);
  }

  Future<EstimateLine> addLineFromCode({
    required String claimId,
    required XactimateCode code,
    double quantity = 1,
    String? roomName,
    PricingEntry? pricing,
  }) async {
    final unitPrice = pricing?.totalCost ?? 0;
    return addLine(
      claimId: claimId,
      codeId: code.id,
      category: code.categoryName,
      itemCode: code.fullCode,
      description: code.description,
      quantity: quantity,
      unit: code.unit,
      unitPrice: unitPrice,
      materialCost: pricing?.materialCost ?? 0,
      laborCost: pricing?.laborCost ?? 0,
      equipmentCost: pricing?.equipmentCost ?? 0,
      roomName: roomName,
      coverageGroup: code.coverageGroup,
    );
  }

  Future<EstimateLine> updateLine(String id, EstimateLine line) {
    return _repo.updateLine(id, line);
  }

  Future<void> deleteLine(String id) {
    return _repo.deleteLine(id);
  }

  // Add all lines from a template
  Future<List<EstimateLine>> addFromTemplate({
    required String claimId,
    required EstimateTemplate template,
    String? roomName,
  }) async {
    final lines = <EstimateLine>[];
    for (final item in template.lineItems) {
      final line = await addLine(
        claimId: claimId,
        category: item['category'] as String? ?? '',
        itemCode: item['item_code'] as String? ?? '',
        description: item['description'] as String? ?? '',
        quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
        unit: item['unit'] as String? ?? 'EA',
        unitPrice: (item['unit_price'] as num?)?.toDouble() ?? 0,
        materialCost: (item['material_cost'] as num?)?.toDouble() ?? 0,
        laborCost: (item['labor_cost'] as num?)?.toDouble() ?? 0,
        equipmentCost: (item['equipment_cost'] as num?)?.toDouble() ?? 0,
        roomName: roomName,
        coverageGroup: item['coverage_group'] as String?,
      );
      lines.add(line);
    }
    // Increment template usage counter
    await _repo.incrementTemplateUsage(template.id);
    return lines;
  }

  // ==================== CODES ====================

  Future<List<XactimateCode>> searchCodes(
    String query, {
    String? categoryCode,
  }) {
    return _repo.searchCodes(query, categoryCode: categoryCode);
  }

  Future<PricingEntry?> getPricing(String codeId, {String? regionCode}) {
    return _repo.getPricing(codeId, regionCode: regionCode);
  }

  // ==================== TEMPLATES ====================

  Future<List<EstimateTemplate>> getTemplates() {
    return _repo.getTemplates(companyId: _authState.companyId);
  }
}
