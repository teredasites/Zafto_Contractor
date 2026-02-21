// ZAFTO Property Preservation Providers
// Created: DEPTH34 — PP work orders, national companies, winterization,
// debris estimation, chargebacks, utility tracking, vendor apps,
// boiler/furnace DB, pricing matrices, stripped property estimates.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property_preservation.dart';
import '../repositories/property_preservation_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final ppRepoProvider =
    Provider<PropertyPreservationRepository>((ref) {
  return PropertyPreservationRepository();
});

// ════════════════════════════════════════════════════════════════
// NATIONAL COMPANIES (system reference)
// ════════════════════════════════════════════════════════════════

/// All active national PP companies
final ppNationalCompaniesProvider =
    FutureProvider.autoDispose<List<PpNationalCompany>>((ref) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getNationalCompanies();
});

/// Single national company by ID
final ppNationalCompanyProvider = FutureProvider.autoDispose
    .family<PpNationalCompany, String>((ref, id) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getNationalCompany(id);
});

// ════════════════════════════════════════════════════════════════
// WORK ORDER TYPES (system reference)
// ════════════════════════════════════════════════════════════════

/// All work order types
final ppWorkOrderTypesProvider =
    FutureProvider.autoDispose<List<PpWorkOrderType>>((ref) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getWorkOrderTypes();
});

/// Work order types filtered by category
final ppWorkOrderTypesByCategoryProvider = FutureProvider.autoDispose
    .family<List<PpWorkOrderType>, String>((ref, category) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getWorkOrderTypesByCategory(category);
});

// ════════════════════════════════════════════════════════════════
// WORK ORDERS (company-scoped)
// ════════════════════════════════════════════════════════════════

/// All work orders (default: most recent first)
final ppWorkOrdersProvider =
    FutureProvider.autoDispose<List<PpWorkOrder>>((ref) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getWorkOrders();
});

/// Work orders by status
final ppWorkOrdersByStatusProvider = FutureProvider.autoDispose
    .family<List<PpWorkOrder>, String>((ref, status) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getWorkOrders(status: status);
});

/// Overdue work orders
final ppOverdueWorkOrdersProvider =
    FutureProvider.autoDispose<List<PpWorkOrder>>((ref) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getOverdueWorkOrders();
});

/// Single work order by ID
final ppWorkOrderProvider = FutureProvider.autoDispose
    .family<PpWorkOrder, String>((ref, id) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getWorkOrder(id);
});

// ════════════════════════════════════════════════════════════════
// CHARGEBACKS (company-scoped)
// ════════════════════════════════════════════════════════════════

/// All chargebacks
final ppChargebacksProvider =
    FutureProvider.autoDispose<List<PpChargeback>>((ref) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getChargebacks();
});

// ════════════════════════════════════════════════════════════════
// WINTERIZATION RECORDS
// ════════════════════════════════════════════════════════════════

/// Winterization records by property
final ppWinterizationByPropertyProvider = FutureProvider.autoDispose
    .family<List<PpWinterizationRecord>, String>((ref, propertyId) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getWinterizationRecords(propertyId: propertyId);
});

// ════════════════════════════════════════════════════════════════
// DEBRIS ESTIMATES
// ════════════════════════════════════════════════════════════════

/// Debris estimates by property
final ppDebrisByPropertyProvider = FutureProvider.autoDispose
    .family<List<PpDebrisEstimate>, String>((ref, propertyId) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getDebrisEstimates(propertyId: propertyId);
});

// ════════════════════════════════════════════════════════════════
// UTILITY TRACKING
// ════════════════════════════════════════════════════════════════

/// Utilities by property
final ppUtilitiesByPropertyProvider = FutureProvider.autoDispose
    .family<List<PpUtilityTracking>, String>((ref, propertyId) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getUtilities(propertyId: propertyId);
});

// ════════════════════════════════════════════════════════════════
// VENDOR APPLICATIONS
// ════════════════════════════════════════════════════════════════

/// All vendor applications for this company
final ppVendorAppsProvider =
    FutureProvider.autoDispose<List<PpVendorApplication>>((ref) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getVendorApplications();
});

// ════════════════════════════════════════════════════════════════
// BOILER/FURNACE MODELS (system reference)
// ════════════════════════════════════════════════════════════════

/// All boiler/furnace models
final boilerFurnaceModelsProvider =
    FutureProvider.autoDispose<List<BoilerFurnaceModel>>((ref) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getBoilerFurnaceModels();
});

/// Boiler/furnace models by equipment type
final boilerModelsByTypeProvider = FutureProvider.autoDispose
    .family<List<BoilerFurnaceModel>, String>((ref, type) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getBoilerFurnaceModels(equipmentType: type);
});

// ════════════════════════════════════════════════════════════════
// PRICING MATRICES (system reference)
// ════════════════════════════════════════════════════════════════

/// Pricing for a given state
final ppPricingByStateProvider = FutureProvider.autoDispose
    .family<List<PpPricingMatrix>, String>((ref, stateCode) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getPricing(stateCode: stateCode);
});

// ════════════════════════════════════════════════════════════════
// STRIPPED ESTIMATES
// ════════════════════════════════════════════════════════════════

/// Stripped estimates by property
final ppStrippedByPropertyProvider = FutureProvider.autoDispose
    .family<List<PpStrippedEstimate>, String>((ref, propertyId) async {
  final repo = ref.read(ppRepoProvider);
  return repo.getStrippedEstimates(propertyId: propertyId);
});
