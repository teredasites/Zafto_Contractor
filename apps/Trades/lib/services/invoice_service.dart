/// ZAFTO Invoice Service - Offline-First with Cloud Sync
/// Sprint 7.0 - January 2026

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/business/invoice.dart';
import 'business_firestore_service.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  final businessFirestore = ref.watch(businessFirestoreProvider);
  final authState = ref.watch(authStateProvider);
  return InvoiceService(businessFirestore, authState);
});

final invoicesProvider = StateNotifierProvider<InvoicesNotifier, AsyncValue<List<Invoice>>>((ref) {
  final service = ref.watch(invoiceServiceProvider);
  return InvoicesNotifier(service, ref);
});

final invoiceStatsProvider = Provider<InvoiceStats>((ref) {
  final invoices = ref.watch(invoicesProvider);
  return invoices.maybeWhen(
    data: (list) {
      final unpaid = list.where((i) => 
        i.status == InvoiceStatus.sent || 
        i.status == InvoiceStatus.viewed ||
        i.status == InvoiceStatus.overdue
      );
      final paid = list.where((i) => i.status == InvoiceStatus.paid);
      final overdueList = list.where((i) => i.status == InvoiceStatus.overdue);
      
      return InvoiceStats(
        totalInvoices: list.length,
        unpaidCount: unpaid.length,
        paidCount: paid.length,
        overdue: overdueList.length,
        totalOutstanding: unpaid.fold(0.0, (sum, i) => sum + i.total),
        totalCollected: paid.fold(0.0, (sum, i) => sum + i.total),
      );
    },
    orElse: () => InvoiceStats.empty(),
  );
});

/// Overdue invoices for RIGHT NOW section on home screen
final overdueInvoicesProvider = Provider<List<Invoice>>((ref) {
  final invoices = ref.watch(invoicesProvider);
  return invoices.maybeWhen(
    data: (list) => list.where((i) => i.isOverdue).toList(),
    orElse: () => [],
  );
});

/// Unpaid invoices
final unpaidInvoicesProvider = Provider<List<Invoice>>((ref) {
  final invoices = ref.watch(invoicesProvider);
  return invoices.maybeWhen(
    data: (list) => list.where((i) =>
      i.status == InvoiceStatus.sent ||
      i.status == InvoiceStatus.viewed ||
      i.status == InvoiceStatus.overdue
    ).toList(),
    orElse: () => [],
  );
});

final invoiceSyncStatusProvider = StateProvider<InvoiceSyncStatus>((ref) => InvoiceSyncStatus.idle);

enum InvoiceSyncStatus { idle, syncing, synced, error, offline }

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

class InvoicesNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  final InvoiceService _service;
  final Ref _ref;

  InvoicesNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _service.getAllInvoices();
      state = AsyncValue.data(invoices);
      _syncInBackground();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncInBackground() async {
    try {
      _ref.read(invoiceSyncStatusProvider.notifier).state = InvoiceSyncStatus.syncing;
      await _service.syncWithCloud();
      final invoices = await _service.getAllInvoices();
      state = AsyncValue.data(invoices);
      _ref.read(invoiceSyncStatusProvider.notifier).state = InvoiceSyncStatus.synced;
    } catch (e) {
      _ref.read(invoiceSyncStatusProvider.notifier).state = InvoiceSyncStatus.error;
    }
  }

  Future<void> addInvoice(Invoice invoice) async {
    await _service.saveInvoice(invoice);
    await loadInvoices();
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await _service.saveInvoice(invoice);
    await loadInvoices();
  }

  Future<void> deleteInvoice(String id) async {
    await _service.deleteInvoice(id);
    await loadInvoices();
  }

  Future<void> forceSync() async {
    await _syncInBackground();
  }
}

// ============================================================
// INVOICE SERVICE
// ============================================================

class InvoiceService {
  static const _boxName = 'invoices';
  static const _syncMetaBox = 'invoices_sync_meta';
  static const _counterBox = 'invoice_counter';
  
  final BusinessFirestoreService _cloudService;
  final AuthState _authState;

  InvoiceService(this._cloudService, this._authState);

  bool get _isLoggedIn => _authState.isAuthenticated && _authState.hasCompany;

  // ==================== LOCAL STORAGE ====================

  Future<Box<String>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<String>(_boxName);
    }
    return Hive.box<String>(_boxName);
  }

  Future<Box<String>> _getSyncMetaBox() async {
    if (!Hive.isBoxOpen(_syncMetaBox)) {
      return await Hive.openBox<String>(_syncMetaBox);
    }
    return Hive.box<String>(_syncMetaBox);
  }

  Future<Box<int>> _getCounterBox() async {
    if (!Hive.isBoxOpen(_counterBox)) {
      return await Hive.openBox<int>(_counterBox);
    }
    return Hive.box<int>(_counterBox);
  }

  Future<List<Invoice>> getAllInvoices() async {
    final box = await _getBox();
    final invoices = <Invoice>[];
    
    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        try {
          invoices.add(Invoice.fromJson(jsonDecode(json)));
        } catch (_) {}
      }
    }
    
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Future<Invoice?> getInvoice(String id) async {
    final box = await _getBox();
    final json = box.get(id);
    if (json == null) return null;
    return Invoice.fromJson(jsonDecode(json));
  }

  Future<void> saveInvoice(Invoice invoice) async {
    final box = await _getBox();
    
    final invoiceWithSync = invoice.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await box.put(invoice.id, jsonEncode(invoiceWithSync.toJson()));
    await _markForSync(invoice.id);
    
    if (_isLoggedIn) {
      _trySyncInvoice(invoiceWithSync);
    }
  }

  Future<void> deleteInvoice(String id) async {
    final box = await _getBox();
    await box.delete(id);
    await _markDeletionForSync(id);
    
    if (_isLoggedIn) {
      try {
        await _cloudService.deleteInvoice(id);
      } catch (_) {}
    }
  }

  String generateId() => 'inv_${DateTime.now().millisecondsSinceEpoch}';

  /// Generate next invoice number (INV-2026-0001 format)
  Future<String> generateInvoiceNumber() async {
    final counterBox = await _getCounterBox();
    final year = DateTime.now().year;
    final key = 'invoice_$year';
    
    final current = counterBox.get(key) ?? 0;
    final next = current + 1;
    await counterBox.put(key, next);
    
    return 'INV-$year-${next.toString().padLeft(4, '0')}';
  }

  // ==================== SYNC OPERATIONS ====================

  Future<void> _markForSync(String invoiceId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('pending_$invoiceId', DateTime.now().toIso8601String());
  }

  Future<void> _markDeletionForSync(String invoiceId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('delete_$invoiceId', DateTime.now().toIso8601String());
    await metaBox.delete('pending_$invoiceId');
  }

  Future<void> _trySyncInvoice(Invoice invoice) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      final existing = await _cloudService.getInvoice(invoice.id);
      if (existing == null) {
        await _cloudService.createInvoice(invoice);
      } else {
        await _cloudService.updateInvoice(invoice);
      }
      
      final metaBox = await _getSyncMetaBox();
      await metaBox.delete('pending_${invoice.id}');
    } catch (_) {}
  }

  Future<void> syncWithCloud() async {
    if (!_isLoggedIn) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection');
    }

    final metaBox = await _getSyncMetaBox();
    final localBox = await _getBox();

    // Process deletions
    final deleteKeys = metaBox.keys.where((k) => k.toString().startsWith('delete_'));
    for (final key in deleteKeys) {
      final invoiceId = key.toString().replaceFirst('delete_', '');
      try {
        await _cloudService.deleteInvoice(invoiceId);
        await metaBox.delete(key);
      } catch (_) {}
    }

    // Push pending changes
    final pendingKeys = metaBox.keys.where((k) => k.toString().startsWith('pending_'));
    for (final key in pendingKeys) {
      final invoiceId = key.toString().replaceFirst('pending_', '');
      final localJson = localBox.get(invoiceId);
      if (localJson != null) {
        try {
          final invoice = Invoice.fromJson(jsonDecode(localJson));
          final existing = await _cloudService.getInvoice(invoiceId);
          if (existing == null) {
            await _cloudService.createInvoice(invoice);
          } else {
            await _cloudService.updateInvoice(invoice);
          }
          await metaBox.delete(key);
        } catch (_) {}
      }
    }

    // Pull cloud changes
    final lastSyncStr = metaBox.get('lastSync');
    final lastSync = lastSyncStr != null 
        ? DateTime.parse(lastSyncStr) 
        : DateTime.fromMillisecondsSinceEpoch(0);

    final cloudInvoices = await _cloudService.getInvoicesUpdatedSince(lastSync);
    
    for (final cloudInvoice in cloudInvoices) {
      final localJson = localBox.get(cloudInvoice.id);
      if (localJson != null) {
        final localInvoice = Invoice.fromJson(jsonDecode(localJson));
        if (cloudInvoice.updatedAt.isAfter(localInvoice.updatedAt)) {
          await localBox.put(cloudInvoice.id, jsonEncode(cloudInvoice.toJson()));
        }
      } else {
        await localBox.put(cloudInvoice.id, jsonEncode(cloudInvoice.toJson()));
      }
    }

    await metaBox.put('lastSync', DateTime.now().toIso8601String());
  }

  Future<int> getPendingSyncCount() async {
    final metaBox = await _getSyncMetaBox();
    return metaBox.keys
        .where((k) => k.toString().startsWith('pending_') || k.toString().startsWith('delete_'))
        .length;
  }
}
