// ZAFTO Receipt Service — Supabase Backend
// Providers, notifier, and service for receipt operations.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/receipt.dart';
import '../repositories/receipt_repository.dart';
import '../services/storage_service.dart';
import 'auth_service.dart';

// --- Providers ---

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ReceiptRepository(storage);
});

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  final repo = ref.watch(receiptRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return ReceiptService(repo, authState);
});

// Receipts for a specific job — auto-dispose when screen closes.
final jobReceiptsProvider = StateNotifierProvider.autoDispose
    .family<JobReceiptsNotifier, AsyncValue<List<Receipt>>, String>(
  (ref, jobId) {
    final service = ref.watch(receiptServiceProvider);
    return JobReceiptsNotifier(service, jobId);
  },
);

// Recent receipts across all jobs.
final recentReceiptsProvider =
    FutureProvider.autoDispose<List<Receipt>>(
  (ref) async {
    final repo = ref.watch(receiptRepositoryProvider);
    return repo.getReceiptsByCompany(limit: 50);
  },
);

// --- Job Receipts Notifier ---

class JobReceiptsNotifier
    extends StateNotifier<AsyncValue<List<Receipt>>> {
  final ReceiptService _service;
  final String _jobId;

  JobReceiptsNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadReceipts();
  }

  Future<void> loadReceipts() async {
    state = const AsyncValue.loading();
    try {
      final receipts = await _service.getReceiptsByJob(_jobId);
      state = AsyncValue.data(receipts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Receipt?> addReceipt({
    required String vendorName,
    required double amount,
    required ReceiptCategory category,
    required DateTime receiptDate,
    String description = '',
    String? paymentMethod,
    Uint8List? imageBytes,
  }) async {
    try {
      final receipt = await _service.createReceipt(
        jobId: _jobId,
        vendorName: vendorName,
        amount: amount,
        category: category,
        receiptDate: receiptDate,
        description: description,
        paymentMethod: paymentMethod,
        imageBytes: imageBytes,
      );
      await loadReceipts();
      return receipt;
    } catch (e) {
      return null;
    }
  }
}

// --- Service ---

class ReceiptService {
  final ReceiptRepository _repo;
  final AuthState _authState;

  ReceiptService(this._repo, this._authState);

  Future<Receipt> createReceipt({
    String? jobId,
    required String vendorName,
    required double amount,
    required ReceiptCategory category,
    required DateTime receiptDate,
    String description = '',
    String? paymentMethod,
    Uint8List? imageBytes,
    Map<String, dynamic> ocrData = const {},
    OcrStatus ocrStatus = OcrStatus.pending,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to save receipts.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final receipt = Receipt(
      companyId: companyId,
      jobId: jobId,
      uploadedByUserId: userId,
      vendorName: vendorName,
      amount: amount,
      category: category,
      description: description,
      receiptDate: receiptDate,
      ocrData: ocrData,
      ocrStatus: ocrStatus,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    return _repo.createReceipt(
      receipt: receipt,
      imageBytes: imageBytes,
      companyId: companyId,
    );
  }

  Future<List<Receipt>> getReceiptsByJob(String jobId) {
    return _repo.getReceiptsByJob(jobId);
  }

  Future<List<Receipt>> getRecentReceipts({int limit = 50}) {
    return _repo.getReceiptsByCompany(limit: limit);
  }

  Future<Receipt> updateReceipt(String id, Map<String, dynamic> updates) {
    return _repo.updateReceipt(id, updates);
  }

  Future<void> deleteReceipt(String id) {
    return _repo.deleteReceipt(id);
  }

  Future<String> getReceiptImageUrl(String storagePath) {
    return _repo.getReceiptImageUrl(storagePath);
  }
}
