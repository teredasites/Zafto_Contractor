/// ZAFTO Customer Service - Offline-First with Cloud Sync
/// Sprint 7.0 - January 2026

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/business/customer.dart';
import 'business_firestore_service.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final customerServiceProvider = Provider<CustomerService>((ref) {
  final businessFirestore = ref.watch(businessFirestoreProvider);
  final authState = ref.watch(authStateProvider);
  return CustomerService(businessFirestore, authState);
});

final customersProvider = StateNotifierProvider<CustomersNotifier, AsyncValue<List<Customer>>>((ref) {
  final service = ref.watch(customerServiceProvider);
  return CustomersNotifier(service, ref);
});

final customerStatsProvider = Provider<CustomerStats>((ref) {
  final customers = ref.watch(customersProvider);
  return customers.maybeWhen(
    data: (list) {
      final residential = list.where((c) => c.type == CustomerType.residential);
      final commercial = list.where((c) => c.type == CustomerType.commercial);
      
      return CustomerStats(
        totalCustomers: list.length,
        residentialCount: residential.length,
        commercialCount: commercial.length,
        totalRevenue: list.fold(0.0, (sum, c) => sum + c.totalRevenue),
        outstandingBalance: list.fold(0.0, (sum, c) => sum + c.outstandingBalance),
      );
    },
    orElse: () => CustomerStats.empty(),
  );
});

/// Simple customer count for home screen tiles
final customerCountProvider = Provider<int>((ref) {
  final stats = ref.watch(customerStatsProvider);
  return stats.total;
});

final customerSyncStatusProvider = StateProvider<CustomerSyncStatus>((ref) => CustomerSyncStatus.idle);

enum CustomerSyncStatus { idle, syncing, synced, error, offline }

// ============================================================
// STATS MODEL
// ============================================================

class CustomerStats {
  final int totalCustomers;
  final int residentialCount;
  final int commercialCount;
  final double totalRevenue;
  final double outstandingBalance;

  const CustomerStats({
    required this.totalCustomers,
    required this.residentialCount,
    required this.commercialCount,
    required this.totalRevenue,
    required this.outstandingBalance,
  });

  /// Alias for totalCustomers
  int get total => totalCustomers;

  factory CustomerStats.empty() => const CustomerStats(
    totalCustomers: 0,
    residentialCount: 0,
    commercialCount: 0,
    totalRevenue: 0,
    outstandingBalance: 0,
  );
}

// ============================================================
// CUSTOMERS NOTIFIER
// ============================================================

class CustomersNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerService _service;
  final Ref _ref;

  CustomersNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _service.getAllCustomers();
      state = AsyncValue.data(customers);
      _syncInBackground();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncInBackground() async {
    try {
      _ref.read(customerSyncStatusProvider.notifier).state = CustomerSyncStatus.syncing;
      await _service.syncWithCloud();
      final customers = await _service.getAllCustomers();
      state = AsyncValue.data(customers);
      _ref.read(customerSyncStatusProvider.notifier).state = CustomerSyncStatus.synced;
    } catch (e) {
      _ref.read(customerSyncStatusProvider.notifier).state = CustomerSyncStatus.error;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await _service.saveCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _service.saveCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _service.deleteCustomer(id);
    await loadCustomers();
  }

  Future<void> forceSync() async {
    await _syncInBackground();
  }

  /// Search customers locally
  List<Customer> search(String query) {
    return state.maybeWhen(
      data: (list) {
        final q = query.toLowerCase();
        return list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          (c.email?.toLowerCase().contains(q) ?? false) ||
          (c.phone?.contains(q) ?? false) ||
          (c.companyName?.toLowerCase().contains(q) ?? false)
        ).toList();
      },
      orElse: () => [],
    );
  }
}

// ============================================================
// CUSTOMER SERVICE
// ============================================================

class CustomerService {
  static const _boxName = 'customers';
  static const _syncMetaBox = 'customers_sync_meta';
  
  final BusinessFirestoreService _cloudService;
  final AuthState _authState;

  CustomerService(this._cloudService, this._authState);

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

  Future<List<Customer>> getAllCustomers() async {
    final box = await _getBox();
    final customers = <Customer>[];
    
    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        try {
          customers.add(Customer.fromJson(jsonDecode(json)));
        } catch (_) {}
      }
    }
    
    customers.sort((a, b) => a.name.compareTo(b.name));
    return customers;
  }

  Future<Customer?> getCustomer(String id) async {
    final box = await _getBox();
    final json = box.get(id);
    if (json == null) return null;
    return Customer.fromJson(jsonDecode(json));
  }

  Future<void> saveCustomer(Customer customer) async {
    final box = await _getBox();
    
    final customerWithSync = customer.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await box.put(customer.id, jsonEncode(customerWithSync.toJson()));
    await _markForSync(customer.id);
    
    if (_isLoggedIn) {
      _trySyncCustomer(customerWithSync);
    }
  }

  Future<void> deleteCustomer(String id) async {
    final box = await _getBox();
    await box.delete(id);
    await _markDeletionForSync(id);
    
    if (_isLoggedIn) {
      try {
        await _cloudService.deleteCustomer(id);
      } catch (_) {}
    }
  }

  String generateId() => 'cust_${DateTime.now().millisecondsSinceEpoch}';

  // ==================== SYNC OPERATIONS ====================

  Future<void> _markForSync(String customerId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('pending_$customerId', DateTime.now().toIso8601String());
  }

  Future<void> _markDeletionForSync(String customerId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('delete_$customerId', DateTime.now().toIso8601String());
    await metaBox.delete('pending_$customerId');
  }

  Future<void> _trySyncCustomer(Customer customer) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      final existing = await _cloudService.getCustomer(customer.id);
      if (existing == null) {
        await _cloudService.createCustomer(customer);
      } else {
        await _cloudService.updateCustomer(customer);
      }
      
      final metaBox = await _getSyncMetaBox();
      await metaBox.delete('pending_${customer.id}');
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
      final customerId = key.toString().replaceFirst('delete_', '');
      try {
        await _cloudService.deleteCustomer(customerId);
        await metaBox.delete(key);
      } catch (_) {}
    }

    // Push pending changes
    final pendingKeys = metaBox.keys.where((k) => k.toString().startsWith('pending_'));
    for (final key in pendingKeys) {
      final customerId = key.toString().replaceFirst('pending_', '');
      final localJson = localBox.get(customerId);
      if (localJson != null) {
        try {
          final customer = Customer.fromJson(jsonDecode(localJson));
          final existing = await _cloudService.getCustomer(customerId);
          if (existing == null) {
            await _cloudService.createCustomer(customer);
          } else {
            await _cloudService.updateCustomer(customer);
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

    final cloudCustomers = await _cloudService.getCustomersUpdatedSince(lastSync);
    
    for (final cloudCustomer in cloudCustomers) {
      final localJson = localBox.get(cloudCustomer.id);
      if (localJson != null) {
        final localCustomer = Customer.fromJson(jsonDecode(localJson));
        if (cloudCustomer.updatedAt.isAfter(localCustomer.updatedAt)) {
          await localBox.put(cloudCustomer.id, jsonEncode(cloudCustomer.toJson()));
        }
      } else {
        await localBox.put(cloudCustomer.id, jsonEncode(cloudCustomer.toJson()));
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
