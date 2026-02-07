// ZAFTO Insurance Claim Service — Supabase Backend
// Providers, notifier, and service for insurance claims.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/insurance_claim.dart';
import '../repositories/insurance_claim_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final insuranceClaimRepositoryProvider =
    Provider<InsuranceClaimRepository>((ref) {
  return InsuranceClaimRepository();
});

final insuranceClaimServiceProvider = Provider<InsuranceClaimService>((ref) {
  final repo = ref.watch(insuranceClaimRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return InsuranceClaimService(repo, authState);
});

// All claims for current company.
final insuranceClaimsProvider = StateNotifierProvider.autoDispose<
    InsuranceClaimsNotifier, AsyncValue<List<InsuranceClaim>>>(
  (ref) {
    final service = ref.watch(insuranceClaimServiceProvider);
    return InsuranceClaimsNotifier(service);
  },
);

// Active claims only.
final activeClaimsProvider =
    FutureProvider.autoDispose<List<InsuranceClaim>>((ref) async {
  final repo = ref.watch(insuranceClaimRepositoryProvider);
  return repo.getActiveClaims();
});

// Claim for a specific job.
final jobClaimProvider =
    FutureProvider.autoDispose.family<InsuranceClaim?, String>(
  (ref, jobId) async {
    final repo = ref.watch(insuranceClaimRepositoryProvider);
    return repo.getClaimByJob(jobId);
  },
);

// Single claim by ID.
final claimDetailProvider =
    FutureProvider.autoDispose.family<InsuranceClaim?, String>(
  (ref, claimId) async {
    final repo = ref.watch(insuranceClaimRepositoryProvider);
    return repo.getClaim(claimId);
  },
);

// --- Notifier ---

class InsuranceClaimsNotifier
    extends StateNotifier<AsyncValue<List<InsuranceClaim>>> {
  final InsuranceClaimService _service;

  InsuranceClaimsNotifier(this._service)
      : super(const AsyncValue.loading()) {
    loadClaims();
  }

  Future<void> loadClaims() async {
    state = const AsyncValue.loading();
    try {
      final claims = await _service.getClaims();
      state = AsyncValue.data(claims);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<InsuranceClaim> filterByStatus(ClaimStatus status) {
    return state.valueOrNull
            ?.where((c) => c.claimStatus == status)
            .toList() ??
        [];
  }
}

// --- Service ---

class InsuranceClaimService {
  final InsuranceClaimRepository _repo;
  final AuthState _authState;

  InsuranceClaimService(this._repo, this._authState);

  Future<InsuranceClaim> createClaim({
    required String jobId,
    required String insuranceCompany,
    required String claimNumber,
    String? policyNumber,
    required DateTime dateOfLoss,
    LossType lossType = LossType.unknown,
    ClaimCategory claimCategory = ClaimCategory.restoration,
    String? lossDescription,
    String? adjusterName,
    String? adjusterPhone,
    String? adjusterEmail,
    String? adjusterCompany,
    double deductible = 0,
    double? coverageLimit,
    String? notes,
    Map<String, dynamic>? data,
  }) async {
    final companyId = _authState.companyId;
    if (companyId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to create claims.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final claim = InsuranceClaim(
      companyId: companyId,
      jobId: jobId,
      insuranceCompany: insuranceCompany,
      claimNumber: claimNumber,
      policyNumber: policyNumber,
      dateOfLoss: dateOfLoss,
      lossType: lossType,
      claimCategory: claimCategory,
      lossDescription: lossDescription,
      adjusterName: adjusterName,
      adjusterPhone: adjusterPhone,
      adjusterEmail: adjusterEmail,
      adjusterCompany: adjusterCompany,
      deductible: deductible,
      coverageLimit: coverageLimit,
      notes: notes,
      data: data ?? const {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repo.createClaim(claim);
  }

  Future<InsuranceClaim> updateClaim(
      String id, InsuranceClaim claim) {
    return _repo.updateClaim(id, claim);
  }

  Future<void> updateClaimStatus(String id, ClaimStatus status) {
    return _repo.updateClaimStatus(id, status);
  }

  Future<List<InsuranceClaim>> getClaims({ClaimStatus? status}) {
    return _repo.getClaims(status: status);
  }

  Future<InsuranceClaim?> getClaimByJob(String jobId) {
    return _repo.getClaimByJob(jobId);
  }

  Future<InsuranceClaim?> getClaim(String id) {
    return _repo.getClaim(id);
  }

  Future<void> deleteClaim(String id) {
    return _repo.deleteClaim(id);
  }
}
