// ZAFTO Change Order Service — Supabase Backend
// Providers, notifier, and auth-enriched service for change orders.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/change_order.dart';
import '../repositories/change_order_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final changeOrderRepositoryProvider = Provider<ChangeOrderRepository>((ref) {
  return ChangeOrderRepository();
});

final changeOrderServiceProvider = Provider<ChangeOrderService>((ref) {
  final repo = ref.watch(changeOrderRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return ChangeOrderService(repo, authState);
});

// Change orders for a job — auto-dispose when screen closes.
final jobChangeOrdersProvider = StateNotifierProvider.autoDispose
    .family<ChangeOrdersNotifier, AsyncValue<List<ChangeOrder>>, String>(
  (ref, jobId) {
    final service = ref.watch(changeOrderServiceProvider);
    return ChangeOrdersNotifier(service, jobId);
  },
);

// --- Change Orders Notifier ---

class ChangeOrdersNotifier
    extends StateNotifier<AsyncValue<List<ChangeOrder>>> {
  final ChangeOrderService _service;
  final String _jobId;

  ChangeOrdersNotifier(this._service, this._jobId)
      : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = const AsyncValue.loading();
    try {
      final orders = await _service.getChangeOrdersByJob(_jobId);
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  double get approvedTotal =>
      state.valueOrNull
          ?.where((o) => o.isApproved)
          .fold<double>(0.0, (sum, o) => sum + o.computedAmount) ??
      0.0;

  int get unresolvedCount =>
      state.valueOrNull?.where((o) => !o.isResolved).length ?? 0;

  int get totalCount => state.valueOrNull?.length ?? 0;
}

// --- Service ---

class ChangeOrderService {
  final ChangeOrderRepository _repo;
  final AuthState _authState;

  ChangeOrderService(this._repo, this._authState);

  // Create a change order, enriching with auth context + auto-number.
  Future<ChangeOrder> createChangeOrder({
    required String jobId,
    required String title,
    required String description,
    String? reason,
    List<ChangeOrderLineItem> lineItems = const [],
    double amount = 0,
    String? notes,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to create change orders.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final number = await _repo.getNextNumber(jobId);

    final order = ChangeOrder(
      companyId: companyId,
      jobId: jobId,
      createdByUserId: userId,
      changeOrderNumber: number,
      title: title,
      description: description,
      reason: reason,
      lineItems: lineItems,
      amount: amount,
      notes: notes,
    );

    return _repo.createChangeOrder(order);
  }

  Future<List<ChangeOrder>> getChangeOrdersByJob(String jobId) {
    return _repo.getChangeOrdersByJob(jobId);
  }

  Future<ChangeOrder> updateChangeOrder(
      String id, Map<String, dynamic> updates) {
    return _repo.updateChangeOrder(id, updates);
  }

  Future<ChangeOrder> submitForApproval(String id) {
    return _repo.submitForApproval(id);
  }

  Future<ChangeOrder> approve(
      String id, String approvedByName, String? signatureId) {
    return _repo.approve(id, approvedByName, signatureId);
  }

  Future<ChangeOrder> reject(String id) {
    return _repo.reject(id);
  }

  Future<ChangeOrder> voidOrder(String id) {
    return _repo.voidOrder(id);
  }

  Future<void> deleteChangeOrder(String id) {
    return _repo.deleteChangeOrder(id);
  }

  Future<int> getUnresolvedCount(String jobId) {
    return _repo.getUnresolvedCount(jobId);
  }

  Future<double> getApprovedTotal(String jobId) {
    return _repo.getApprovedTotal(jobId);
  }
}
