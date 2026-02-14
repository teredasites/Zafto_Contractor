// ZAFTO Rent Service — Property Management
// Created: Property Management Feature
//
// Manages rent charges and payments for contractor-owned
// properties. Tracks rent collection, overdue balances,
// and payment recording with partial payment support.
//
// Providers: rentRepositoryProvider, rentServiceProvider,
//   rentChargesProvider

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property.dart';
import '../repositories/lease_repository.dart';
import '../repositories/rent_repository.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final rentRepositoryProvider = Provider<RentRepository>((ref) {
  return RentRepository();
});

final rentServiceProvider = Provider<RentService>((ref) {
  final repo = ref.watch(rentRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return RentService(repo, authState);
});

final rentChargesProvider =
    StateNotifierProvider<RentChargesNotifier, AsyncValue<List<RentCharge>>>(
        (ref) {
  final service = ref.watch(rentServiceProvider);
  return RentChargesNotifier(service);
});

// Overdue charges (filtered view)
final overdueChargesProvider =
    StateNotifierProvider<OverdueChargesNotifier, AsyncValue<List<RentCharge>>>(
        (ref) {
  final service = ref.watch(rentServiceProvider);
  return OverdueChargesNotifier(service);
});

// ============================================================
// RENT SERVICE (business logic)
// ============================================================

class RentService {
  final RentRepository _repo;
  final AuthState _authState;

  RentService(this._repo, this._authState);

  // Charges
  Future<List<RentCharge>> getCharges({String? propertyId}) =>
      _repo.getRentCharges(propertyId: propertyId);

  Future<List<RentCharge>> getOverdueCharges() => _repo.getOverdueCharges();

  Future<RentCharge> createCharge(RentCharge charge) =>
      _repo.createRentCharge(charge);

  Future<void> deleteCharge(String id) async {
    // Soft delete not implemented in repo — void the charge status instead
    await _repo.updateChargePayment(id, 0, 'voided');
  }

  // Generate monthly rent charges for all active leases.
  // This would typically be an Edge Function for production,
  // but exposing here for manual trigger from the app.
  // 1. Get all active leases
  // 2. For each, check if a charge already exists for this month
  // 3. If not, create one
  Future<int> generateMonthlyCharges(DateTime forMonth) async {
    final leaseRepo = LeaseRepository();
    final leases = await leaseRepo.getLeases(status: LeaseStatus.active);
    final companyId = _authState.companyId ?? '';
    int created = 0;

    for (final lease in leases) {
      // Check if charge already exists for this month
      final existing = await _repo.getRentCharges(
        propertyId: lease.propertyId,
        status: 'pending',
      );
      final alreadyCharged = existing.any((c) =>
          c.dueDate.year == forMonth.year &&
          c.dueDate.month == forMonth.month &&
          c.leaseId == lease.id);
      if (alreadyCharged) continue;

      final dueDate = DateTime(forMonth.year, forMonth.month, lease.paymentDueDay ?? 1);
      await _repo.createRentCharge(RentCharge(
        id: '',
        companyId: companyId,
        leaseId: lease.id,
        propertyId: lease.propertyId,
        unitId: lease.unitId,
        tenantId: lease.tenantId,
        amount: lease.monthlyRent,
        dueDate: dueDate,
        paidAmount: 0,
        status: 'pending',
        createdAt: DateTime.now(),
      ));
      created++;
    }
    return created;
  }

  // Record a payment against a rent charge
  Future<void> recordPayment({
    required String chargeId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final payment = RentPayment(
      id: '',
      rentChargeId: chargeId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentReference: reference,
      paymentDate: DateTime.now(),
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _repo.recordPayment(payment);

    // Update charge paid amount
    // Get current charge to compute new paid total
    final charges = await _repo.getRentCharges();
    final charge = charges.firstWhere((c) => c.id == chargeId);
    final newPaid = charge.paidAmount + amount;
    final newStatus = newPaid >= charge.amount ? 'paid' : 'partial';
    await _repo.updateChargePayment(chargeId, newPaid, newStatus);
  }

  // Get payments for a specific charge
  Future<List<RentPayment>> getPayments(String chargeId) =>
      _repo.getRentPayments(chargeId);
}

// ============================================================
// RENT CHARGES NOTIFIER
// ============================================================

class RentChargesNotifier extends StateNotifier<AsyncValue<List<RentCharge>>> {
  final RentService _service;

  RentChargesNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final charges = await _service.getCharges();
      state = AsyncValue.data(charges);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(RentCharge charge) async {
    try {
      await _service.createCharge(charge);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordPayment({
    required String chargeId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    try {
      await _service.recordPayment(
        chargeId: chargeId,
        amount: amount,
        paymentMethod: paymentMethod,
        reference: reference,
        notes: notes,
      );
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _service.deleteCharge(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ============================================================
// OVERDUE CHARGES NOTIFIER
// ============================================================

class OverdueChargesNotifier
    extends StateNotifier<AsyncValue<List<RentCharge>>> {
  final RentService _service;

  OverdueChargesNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final charges = await _service.getOverdueCharges();
      state = AsyncValue.data(charges);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
