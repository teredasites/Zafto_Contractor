// ZAFTO Invoice Service — Supabase Backend
// Rewritten: Sprint B1d (Session 42)
//
// Replaces Hive + Firestore sync with direct Supabase queries.
// Same provider names so all consuming screens keep working.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return InvoiceService(repo, authState);
});

final invoicesProvider =
    StateNotifierProvider<InvoicesNotifier, AsyncValue<List<Invoice>>>(
        (ref) {
  final service = ref.watch(invoiceServiceProvider);
  return InvoicesNotifier(service);
});

final invoiceStatsProvider = Provider<InvoiceStats>((ref) {
  final invoices = ref.watch(invoicesProvider);
  return invoices.maybeWhen(
    data: (list) {
      final unpaid = list.where((i) =>
          i.status == InvoiceStatus.sent ||
          i.status == InvoiceStatus.viewed ||
          i.status == InvoiceStatus.overdue);
      final paid = list.where((i) => i.status == InvoiceStatus.paid);
      final overdueList =
          list.where((i) => i.status == InvoiceStatus.overdue);

      return InvoiceStats(
        totalInvoices: list.length,
        unpaidCount: unpaid.length,
        paidCount: paid.length,
        overdue: overdueList.length,
        totalOutstanding:
            unpaid.fold(0.0, (sum, i) => sum + i.total),
        totalCollected:
            paid.fold(0.0, (sum, i) => sum + i.total),
      );
    },
    orElse: () => InvoiceStats.empty(),
  );
});

final overdueInvoicesProvider = Provider<List<Invoice>>((ref) {
  final invoices = ref.watch(invoicesProvider);
  return invoices.maybeWhen(
    data: (list) => list.where((i) => i.isOverdue).toList(),
    orElse: () => [],
  );
});

final unpaidInvoicesProvider = Provider<List<Invoice>>((ref) {
  final invoices = ref.watch(invoicesProvider);
  return invoices.maybeWhen(
    data: (list) => list
        .where((i) =>
            i.status == InvoiceStatus.sent ||
            i.status == InvoiceStatus.viewed ||
            i.status == InvoiceStatus.overdue)
        .toList(),
    orElse: () => [],
  );
});

final invoiceCountProvider = Provider<int>((ref) {
  final stats = ref.watch(invoiceStatsProvider);
  return stats.totalInvoices;
});

// ============================================================
// STATS MODEL
// ============================================================

class InvoiceStats {
  final int totalInvoices;
  final int unpaidCount;
  final int paidCount;
  final int overdue;
  final double totalOutstanding;
  final double totalCollected;

  const InvoiceStats({
    required this.totalInvoices,
    required this.unpaidCount,
    required this.paidCount,
    required this.overdue,
    required this.totalOutstanding,
    required this.totalCollected,
  });

  factory InvoiceStats.empty() => const InvoiceStats(
        totalInvoices: 0,
        unpaidCount: 0,
        paidCount: 0,
        overdue: 0,
        totalOutstanding: 0,
        totalCollected: 0,
      );
}

// ============================================================
// INVOICES NOTIFIER
// ============================================================

class InvoicesNotifier
    extends StateNotifier<AsyncValue<List<Invoice>>> {
  final InvoiceService _service;

  InvoicesNotifier(this._service)
      : super(const AsyncValue.loading()) {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _service.getAllInvoices();
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addInvoice(Invoice invoice) async {
    try {
      await _service.createInvoice(invoice);
      await loadInvoices();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateInvoice(Invoice invoice) async {
    try {
      await _service.updateInvoice(invoice);
      await loadInvoices();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateInvoiceStatus(
      String id, InvoiceStatus status) async {
    try {
      await _service.updateInvoiceStatus(id, status);
      await loadInvoices();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _service.deleteInvoice(id);
      await loadInvoices();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Invoice> search(String query) {
    return state.maybeWhen(
      data: (list) {
        final q = query.toLowerCase();
        return list
            .where((i) =>
                i.invoiceNumber.toLowerCase().contains(q) ||
                i.customerName.toLowerCase().contains(q) ||
                (i.notes?.toLowerCase().contains(q) ?? false))
            .toList();
      },
      orElse: () => [],
    );
  }
}

// ============================================================
// INVOICE SERVICE (business logic)
// ============================================================

class InvoiceService {
  final InvoiceRepository _repo;
  final AuthState _authState;

  InvoiceService(this._repo, this._authState);

  Future<List<Invoice>> getAllInvoices() => _repo.getInvoices();

  Future<Invoice?> getInvoice(String id) => _repo.getInvoice(id);

  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) =>
      _repo.getInvoicesByStatus(status);

  Future<List<Invoice>> getInvoicesByCustomer(String customerId) =>
      _repo.getInvoicesByCustomer(customerId);

  Future<List<Invoice>> getInvoicesByJob(String jobId) =>
      _repo.getInvoicesByJob(jobId);

  Future<Invoice> createInvoice(Invoice invoice) {
    final enriched = invoice.copyWith(
      companyId: _authState.companyId ?? '',
      createdByUserId: _authState.user?.uid ?? '',
    );
    return _repo.createInvoice(enriched);
  }

  Future<Invoice> updateInvoice(Invoice invoice) =>
      _repo.updateInvoice(invoice.id, invoice);

  Future<Invoice> updateInvoiceStatus(
          String id, InvoiceStatus status) =>
      _repo.updateInvoiceStatus(id, status);

  Future<Invoice> recordPayment(
    String id, {
    required double amount,
    required String method,
    String? reference,
  }) =>
      _repo.recordPayment(id,
          amount: amount, method: method, reference: reference);

  Future<void> deleteInvoice(String id) => _repo.deleteInvoice(id);

  Future<List<Invoice>> searchInvoices(String query) =>
      _repo.searchInvoices(query);

  Future<String> generateInvoiceNumber() =>
      _repo.nextInvoiceNumber();

  // Backward compat
  String generateId() =>
      'inv_${DateTime.now().millisecondsSinceEpoch}';

  // Kept for screens that call saveInvoice
  Future<Invoice> saveInvoice(Invoice invoice) async {
    if (invoice.id.isEmpty) {
      return createInvoice(invoice);
    } else {
      return updateInvoice(invoice);
    }
  }
}
