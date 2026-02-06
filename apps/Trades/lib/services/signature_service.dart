// ZAFTO Signature Service — Supabase Backend
// Providers, notifier, and service for digital signature operations.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/signature.dart';
import '../repositories/signature_repository.dart';
import '../services/storage_service.dart';
import 'auth_service.dart';

// --- Providers ---

final signatureRepositoryProvider = Provider<SignatureRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SignatureRepository(storage);
});

final signatureServiceProvider = Provider<SignatureService>((ref) {
  final repo = ref.watch(signatureRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return SignatureService(repo, authState);
});

// Signatures for a specific job — auto-dispose when screen closes.
final jobSignaturesProvider = StateNotifierProvider.autoDispose
    .family<JobSignaturesNotifier, AsyncValue<List<Signature>>, String>(
  (ref, jobId) {
    final service = ref.watch(signatureServiceProvider);
    return JobSignaturesNotifier(service, jobId);
  },
);

// --- Job Signatures Notifier ---

class JobSignaturesNotifier
    extends StateNotifier<AsyncValue<List<Signature>>> {
  final SignatureService _service;
  final String _jobId;

  JobSignaturesNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadSignatures();
  }

  Future<void> loadSignatures() async {
    state = const AsyncValue.loading();
    try {
      final sigs = await _service.getSignaturesByJob(_jobId);
      state = AsyncValue.data(sigs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// --- Service ---

class SignatureService {
  final SignatureRepository _repo;
  final AuthState _authState;

  SignatureService(this._repo, this._authState);

  Future<Signature> createSignature({
    String? jobId,
    String? invoiceId,
    required String signerName,
    String? signerRole,
    required SignaturePurpose purpose,
    required Uint8List imageBytes,
    String? notes,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to save signatures.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final signature = Signature(
      companyId: companyId,
      jobId: jobId,
      invoiceId: invoiceId,
      signerName: signerName,
      signerRole: signerRole,
      purpose: purpose,
      notes: notes,
      locationLatitude: latitude,
      locationLongitude: longitude,
      locationAddress: locationAddress,
      createdAt: DateTime.now(),
    );

    return _repo.createSignature(
      signature: signature,
      imageBytes: imageBytes,
      companyId: companyId,
    );
  }

  Future<List<Signature>> getSignaturesByJob(String jobId) {
    return _repo.getSignaturesByJob(jobId);
  }

  Future<List<Signature>> getSignaturesByPurpose(
      String jobId, SignaturePurpose purpose) {
    return _repo.getSignaturesByPurpose(jobId, purpose);
  }

  Future<String> getSignatureImageUrl(String storagePath) {
    return _repo.getSignatureImageUrl(storagePath);
  }
}
