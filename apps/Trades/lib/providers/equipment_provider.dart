// ZAFTO Equipment Provider
// Created: Sprint FIELD2 (Session 131)
//
// Riverpod providers for equipment inventory + checkout tracking.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/equipment_item.dart';
import '../models/equipment_checkout.dart';
import '../repositories/equipment_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final equipmentRepoProvider = Provider<EquipmentRepository>((ref) {
  return EquipmentRepository();
});

// ════════════════════════════════════════════════════════════════
// EQUIPMENT ITEMS LIST
// ════════════════════════════════════════════════════════════════

final equipmentItemsProvider =
    FutureProvider.autoDispose<List<EquipmentItem>>((ref) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getItems();
});

// ════════════════════════════════════════════════════════════════
// SINGLE EQUIPMENT ITEM
// ════════════════════════════════════════════════════════════════

final equipmentItemProvider = FutureProvider.autoDispose
    .family<EquipmentItem, String>((ref, itemId) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getItem(itemId);
});

// ════════════════════════════════════════════════════════════════
// CHECKOUT HISTORY FOR AN ITEM
// ════════════════════════════════════════════════════════════════

final equipmentCheckoutsProvider = FutureProvider.autoDispose
    .family<List<EquipmentCheckout>, String>((ref, itemId) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getCheckoutsForItem(itemId);
});

// ════════════════════════════════════════════════════════════════
// MY ACTIVE CHECKOUTS
// ════════════════════════════════════════════════════════════════

final myActiveCheckoutsProvider =
    FutureProvider.autoDispose<List<EquipmentCheckout>>((ref) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getMyActiveCheckouts();
});

// ════════════════════════════════════════════════════════════════
// ALL ACTIVE CHECKOUTS (admin)
// ════════════════════════════════════════════════════════════════

final allActiveCheckoutsProvider =
    FutureProvider.autoDispose<List<EquipmentCheckout>>((ref) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getAllActiveCheckouts();
});

// ════════════════════════════════════════════════════════════════
// OVERDUE CHECKOUTS
// ════════════════════════════════════════════════════════════════

final overdueCheckoutsProvider =
    FutureProvider.autoDispose<List<EquipmentCheckout>>((ref) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getOverdueCheckouts();
});

// ════════════════════════════════════════════════════════════════
// EQUIPMENT ACTIONS NOTIFIER
// ════════════════════════════════════════════════════════════════

class EquipmentActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<EquipmentItem> createItem({
    required String name,
    required EquipmentCategory category,
    String? serialNumber,
    String? barcode,
    String? manufacturer,
    String? modelNumber,
    DateTime? purchaseDate,
    double? purchaseCost,
    EquipmentCondition condition = EquipmentCondition.good,
    String? storageLocation,
    String? notes,
  }) async {
    final repo = ref.read(equipmentRepoProvider);
    final item = await repo.createItem(
      name: name,
      category: category,
      serialNumber: serialNumber,
      barcode: barcode,
      manufacturer: manufacturer,
      modelNumber: modelNumber,
      purchaseDate: purchaseDate,
      purchaseCost: purchaseCost,
      condition: condition,
      storageLocation: storageLocation,
      notes: notes,
    );
    ref.invalidate(equipmentItemsProvider);
    return item;
  }

  Future<EquipmentItem> updateItem(String itemId, Map<String, dynamic> updates) async {
    final repo = ref.read(equipmentRepoProvider);
    final item = await repo.updateItem(itemId, updates);
    ref.invalidate(equipmentItemsProvider);
    ref.invalidate(equipmentItemProvider(itemId));
    return item;
  }

  Future<void> deleteItem(String itemId) async {
    final repo = ref.read(equipmentRepoProvider);
    await repo.deleteItem(itemId);
    ref.invalidate(equipmentItemsProvider);
  }

  Future<EquipmentCheckout> checkout({
    required String equipmentItemId,
    required EquipmentCondition condition,
    DateTime? expectedReturnDate,
    String? jobId,
    String? notes,
  }) async {
    final repo = ref.read(equipmentRepoProvider);
    final checkout = await repo.checkout(
      equipmentItemId: equipmentItemId,
      condition: condition,
      expectedReturnDate: expectedReturnDate,
      jobId: jobId,
      notes: notes,
    );
    ref.invalidate(equipmentItemsProvider);
    ref.invalidate(myActiveCheckoutsProvider);
    ref.invalidate(allActiveCheckoutsProvider);
    ref.invalidate(equipmentItemProvider(equipmentItemId));
    ref.invalidate(equipmentCheckoutsProvider(equipmentItemId));
    return checkout;
  }

  Future<EquipmentCheckout> checkin({
    required String checkoutId,
    required String equipmentItemId,
    required EquipmentCondition condition,
    String? notes,
  }) async {
    final repo = ref.read(equipmentRepoProvider);
    final result = await repo.checkin(
      checkoutId: checkoutId,
      condition: condition,
      notes: notes,
    );
    ref.invalidate(equipmentItemsProvider);
    ref.invalidate(myActiveCheckoutsProvider);
    ref.invalidate(allActiveCheckoutsProvider);
    ref.invalidate(overdueCheckoutsProvider);
    ref.invalidate(equipmentItemProvider(equipmentItemId));
    ref.invalidate(equipmentCheckoutsProvider(equipmentItemId));
    return result;
  }

  Future<EquipmentItem?> findByBarcode(String barcode) async {
    final repo = ref.read(equipmentRepoProvider);
    return repo.findByBarcode(barcode);
  }
}

final equipmentActionsProvider =
    AsyncNotifierProvider<EquipmentActionsNotifier, void>(
        EquipmentActionsNotifier.new);
