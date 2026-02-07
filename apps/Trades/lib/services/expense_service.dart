// ZAFTO Expense & Vendor Service — Supabase Backend
// Providers, notifiers, and auth-enriched services for expenses and vendors.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../models/expense_record.dart';
import '../models/vendor.dart';
import '../repositories/expense_repository.dart';
import '../repositories/vendor_repository.dart';
import 'auth_service.dart';

// --- Repository Providers ---

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository();
});

// --- Service Providers ---

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return ExpenseService(repo, authState);
});

final vendorServiceProvider = Provider<VendorService>((ref) {
  final repo = ref.watch(vendorRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return VendorService(repo, authState);
});

// --- Data Providers ---

// All expenses for the company — auto-dispose when screen closes.
final expenseListProvider =
    FutureProvider.autoDispose<List<ExpenseRecord>>((ref) async {
  final service = ref.watch(expenseServiceProvider);
  return service.getExpenses();
});

// Active vendors — auto-dispose when screen closes.
final vendorListProvider =
    FutureProvider.autoDispose<List<Vendor>>((ref) async {
  final service = ref.watch(vendorServiceProvider);
  return service.getVendors(isActive: true);
});

// --- Expense Service ---

class ExpenseService {
  final ExpenseRepository _repo;
  final AuthState _authState;

  ExpenseService(this._repo, this._authState);

  // Create an expense, enriching with auth context.
  Future<ExpenseRecord> createExpense({
    String? jobId,
    String? vendorId,
    required DateTime expenseDate,
    required String description,
    required double amount,
    double taxAmount = 0,
    double? total,
    ExpenseCategory category = ExpenseCategory.uncategorized,
    ExpensePaymentMethod paymentMethod = ExpensePaymentMethod.cash,
    String? receiptStoragePath,
    String? receiptUrl,
    ExpenseOcrStatus ocrStatus = ExpenseOcrStatus.none,
    String? notes,
  }) async {
    final companyId = _authState.companyId;
    final userId = _authState.user?.uid;
    if (companyId == null || userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to create expenses.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final expense = ExpenseRecord(
      companyId: companyId,
      jobId: jobId,
      vendorId: vendorId,
      createdByUserId: userId,
      expenseDate: expenseDate,
      description: description,
      amount: amount,
      taxAmount: taxAmount,
      total: total ?? (amount + taxAmount),
      category: category,
      paymentMethod: paymentMethod,
      receiptStoragePath: receiptStoragePath,
      receiptUrl: receiptUrl,
      ocrStatus: ocrStatus,
      notes: notes,
      createdAt: DateTime.now(),
    );

    return _repo.createExpense(expense);
  }

  Future<List<ExpenseRecord>> getExpenses({
    int limit = 100,
    ExpenseStatus? status,
  }) {
    return _repo.getExpensesByCompany(limit: limit, status: status);
  }

  Future<List<ExpenseRecord>> getExpensesByJob(String jobId) {
    return _repo.getExpensesByJob(jobId);
  }

  Future<ExpenseRecord?> getExpense(String id) {
    return _repo.getExpense(id);
  }

  Future<ExpenseRecord> updateExpense(
      String id, Map<String, dynamic> updates) {
    return _repo.updateExpense(id, updates);
  }

  Future<void> deleteExpense(String id) {
    return _repo.deleteExpense(id);
  }
}

// --- Vendor Service ---

class VendorService {
  final VendorRepository _repo;
  final AuthState _authState;

  VendorService(this._repo, this._authState);

  // Create a vendor, enriching with auth context.
  Future<Vendor> createVendor({
    required String vendorName,
    String? contactName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? taxId,
    bool is1099Eligible = false,
    String? paymentTerms,
    String? notes,
  }) async {
    final companyId = _authState.companyId;
    if (companyId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to create vendors.',
        code: AuthErrorCode.sessionExpired,
      );
    }

    final vendor = Vendor(
      companyId: companyId,
      vendorName: vendorName,
      contactName: contactName,
      email: email,
      phone: phone,
      address: address,
      city: city,
      state: state,
      zip: zip,
      taxId: taxId,
      is1099Eligible: is1099Eligible,
      paymentTerms: paymentTerms,
      notes: notes,
      createdAt: DateTime.now(),
    );

    return _repo.createVendor(vendor);
  }

  Future<List<Vendor>> getVendors({
    int limit = 100,
    bool? isActive,
  }) {
    return _repo.getVendors(limit: limit, isActive: isActive);
  }

  Future<Vendor?> getVendor(String id) {
    return _repo.getVendor(id);
  }

  Future<List<Vendor>> searchVendors(String query) {
    return _repo.searchVendors(query);
  }

  Future<Vendor> updateVendor(String id, Map<String, dynamic> updates) {
    return _repo.updateVendor(id, updates);
  }

  Future<void> deleteVendor(String id) {
    return _repo.deleteVendor(id);
  }
}
