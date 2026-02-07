// ZAFTO Job Material Service — Supabase Backend
// Providers, notifier, and auth-enriched service for job materials.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/job_material.dart';
import '../repositories/job_material_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final jobMaterialRepositoryProvider = Provider<JobMaterialRepository>((ref) {
  return JobMaterialRepository();
});

final jobMaterialServiceProvider = Provider<JobMaterialService>((ref) {
  final repo = ref.watch(jobMaterialRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return JobMaterialService(repo, authState);
});

// Materials for a job — auto-dispose when screen closes.
final jobMaterialsProvider = StateNotifierProvider.autoDispose
    .family<JobMaterialsNotifier, AsyncValue<List<JobMaterial>>, String>(
  (ref, jobId) {
    final service = ref.watch(jobMaterialServiceProvider);
    return JobMaterialsNotifier(service, jobId);
  },
);

// --- Job Materials Notifier ---

class JobMaterialsNotifier
    extends StateNotifier<AsyncValue<List<JobMaterial>>> {
  final JobMaterialService _service;
  final String _jobId;

  JobMaterialsNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadMaterials();
  }

  Future<void> loadMaterials() async {
    state = const AsyncValue.loading();
    try {
      final materials = await _service.getMaterialsByJob(_jobId);
      state = AsyncValue.data(materials);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  double get totalCost {
    return state.valueOrNull?.fold<double>(
            0.0, (sum, m) => sum + m.computedTotal) ??
        0.0;
  }

  double get billableCost {
    return state.valueOrNull
            ?.where((m) => m.isBillable)
            .fold<double>(0.0, (sum, m) => sum + m.computedTotal) ??
        0.0;
  }

  int get itemCount => state.valueOrNull?.length ?? 0;
}

// --- Service ---

class JobMaterialService {
  final JobMaterialRepository _repo;
  final AuthState _authState;

  JobMaterialService(this._repo, this._authState);

  // Create a material entry, enriching with auth context.
  Future<JobMaterial> createMaterial({
    required String jobId,
    required String name,
    String? description,
    MaterialCategory category = MaterialCategory.material,
    double quantity = 1,
    String unit = 'each',
    double? unitCost,
    String? vendor,
    bool isBillable = true,
    String? serialNumber,
    String? warrantyInfo,
    String? notes,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to add materials.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final material = JobMaterial(
      companyId: companyId,
      jobId: jobId,
      addedByUserId: userId,
      name: name,
      description: description,
      category: category,
      quantity: quantity,
      unit: unit,
      unitCost: unitCost,
      vendor: vendor,
      isBillable: isBillable,
      serialNumber: serialNumber,
      warrantyInfo: warrantyInfo,
      notes: notes,
    );

    return _repo.createMaterial(material);
  }

  Future<List<JobMaterial>> getMaterialsByJob(String jobId) {
    return _repo.getMaterialsByJob(jobId);
  }

  Future<JobMaterial> updateMaterial(
      String id, Map<String, dynamic> updates) {
    return _repo.updateMaterial(id, updates);
  }

  Future<void> deleteMaterial(String id) {
    return _repo.deleteMaterial(id);
  }
}
