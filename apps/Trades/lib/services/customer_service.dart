// ZAFTO Customer Service — Supabase Backend
// Rewritten: Sprint B1b (Session 41)
//
// Replaces Hive + Firestore sync with direct Supabase queries.
// Same provider names so all consuming screens keep working.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final customerServiceProvider = Provider<CustomerService>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return CustomerService(repo, authState);
});

final customersProvider =
    StateNotifierProvider<CustomersNotifier, AsyncValue<List<Customer>>>((ref) {
  final service = ref.watch(customerServiceProvider);
  return CustomersNotifier(service);
});

final customerStatsProvider = Provider<CustomerStats>((ref) {
  final customers = ref.watch(customersProvider);
  return customers.maybeWhen(
    data: (list) {
      final residential =
          list.where((c) => c.type == CustomerType.residential);
      final commercial =
          list.where((c) => c.type == CustomerType.commercial);

      return CustomerStats(
        totalCustomers: list.length,
        residentialCount: residential.length,
        commercialCount: commercial.length,
        totalRevenue: list.fold(0.0, (sum, c) => sum + c.totalRevenue),
        outstandingBalance:
            list.fold(0.0, (sum, c) => sum + c.outstandingBalance),
      );
    },
    orElse: () => CustomerStats.empty(),
  );
});

final customerCountProvider = Provider<int>((ref) {
  final stats = ref.watch(customerStatsProvider);
  return stats.total;
});

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

  CustomersNotifier(this._service) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _service.getAllCustomers();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      await _service.createCustomer(customer);
      await loadCustomers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _service.updateCustomer(customer);
      await loadCustomers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _service.deleteCustomer(id);
      await loadCustomers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Customer> search(String query) {
    return state.maybeWhen(
      data: (list) {
        final q = query.toLowerCase();
        return list
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                (c.email?.toLowerCase().contains(q) ?? false) ||
                (c.phone?.contains(q) ?? false) ||
                (c.companyName?.toLowerCase().contains(q) ?? false))
            .toList();
      },
      orElse: () => [],
    );
  }
}

// ============================================================
// CUSTOMER SERVICE (business logic)
// ============================================================

class CustomerService {
  final CustomerRepository _repo;
  final AuthState _authState;

  CustomerService(this._repo, this._authState);

  Future<List<Customer>> getAllCustomers() => _repo.getCustomers();

  Future<Customer?> getCustomer(String id) => _repo.getCustomer(id);

  Future<Customer> createCustomer(Customer customer) {
    final enriched = customer.copyWith(
      companyId: _authState.companyId ?? '',
      createdByUserId: _authState.user?.uid ?? '',
    );
    return _repo.createCustomer(enriched);
  }

  Future<Customer> updateCustomer(Customer customer) =>
      _repo.updateCustomer(customer.id, customer);

  Future<void> deleteCustomer(String id) => _repo.deleteCustomer(id);

  Future<List<Customer>> searchCustomers(String query) =>
      _repo.searchCustomers(query);

  // Kept for backward compat — screens that generate IDs locally.
  // Supabase generates UUIDs server-side, but screens may still call this.
  String generateId() => 'cust_${DateTime.now().millisecondsSinceEpoch}';
}
