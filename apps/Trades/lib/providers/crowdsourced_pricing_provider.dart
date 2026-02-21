// ZAFTO Crowdsourced Material Pricing Providers
// Created: DEPTH31 — Receipt OCR, Supplier Directory, Pricing Engine
//
// Riverpod providers for material receipts, supplier directory,
// price index, distributor accounts, price alerts, contributor status.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/crowdsourced_pricing.dart';
import '../repositories/crowdsourced_pricing_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final crowdsourcedPricingRepoProvider =
    Provider<CrowdsourcedPricingRepository>((ref) {
  return CrowdsourcedPricingRepository();
});

// ════════════════════════════════════════════════════════════════
// MATERIAL RECEIPTS
// ════════════════════════════════════════════════════════════════

/// All receipts (optionally filtered by status)
final materialReceiptsProvider = FutureProvider.autoDispose
    .family<List<MaterialReceipt>, String?>((ref, status) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getReceipts(status: status);
});

/// Single receipt
final materialReceiptProvider = FutureProvider.autoDispose
    .family<MaterialReceipt, String>((ref, id) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getReceipt(id);
});

/// Receipt items for a specific receipt
final receiptItemsProvider = FutureProvider.autoDispose
    .family<List<MaterialReceiptItem>, String>((ref, receiptId) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getReceiptItems(receiptId);
});

// ════════════════════════════════════════════════════════════════
// SUPPLIER DIRECTORY
// ════════════════════════════════════════════════════════════════

/// All suppliers (optionally filtered by type and trade)
final suppliersProvider =
    FutureProvider.autoDispose<List<SupplierDirectory>>((ref) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getSuppliers();
});

/// Suppliers filtered by trade
final suppliersByTradeProvider = FutureProvider.autoDispose
    .family<List<SupplierDirectory>, String>((ref, trade) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getSuppliers(trade: trade);
});

/// Search suppliers
final supplierSearchProvider = FutureProvider.autoDispose
    .family<List<SupplierDirectory>, String>((ref, query) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.searchSuppliers(query);
});

// ════════════════════════════════════════════════════════════════
// MATERIAL PRICE INDEX
// ════════════════════════════════════════════════════════════════

/// Search price index
final priceIndexSearchProvider = FutureProvider.autoDispose
    .family<List<MaterialPriceIndex>, String>((ref, query) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.searchPriceIndex(query: query);
});

/// Price for a specific product
final productPriceProvider = FutureProvider.autoDispose
    .family<MaterialPriceIndex?, String>((ref, productName) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getPriceForProduct(productName);
});

// ════════════════════════════════════════════════════════════════
// BLS/FRED PRICE INDICES
// ════════════════════════════════════════════════════════════════

/// Price indices for a specific BLS series
final blsPriceIndicesProvider = FutureProvider.autoDispose
    .family<List<MaterialPriceIndexEntry>, String>((ref, seriesId) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getPriceIndices(seriesId);
});

// ════════════════════════════════════════════════════════════════
// REGIONAL COST FACTORS
// ════════════════════════════════════════════════════════════════

/// Regional factors for a state
final regionalFactorsProvider = FutureProvider.autoDispose
    .family<List<RegionalCostFactor>, String>((ref, state) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getRegionalFactorsForState(state);
});

// ════════════════════════════════════════════════════════════════
// DISTRIBUTOR ACCOUNTS
// ════════════════════════════════════════════════════════════════

/// All linked distributor accounts
final distributorAccountsProvider =
    FutureProvider.autoDispose<List<DistributorAccount>>((ref) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getDistributorAccounts();
});

// ════════════════════════════════════════════════════════════════
// PRICE ALERTS
// ════════════════════════════════════════════════════════════════

/// Active price alerts
final priceAlertsProvider =
    FutureProvider.autoDispose<List<PriceAlert>>((ref) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getPriceAlerts();
});

// ════════════════════════════════════════════════════════════════
// CONTRIBUTOR STATUS
// ════════════════════════════════════════════════════════════════

/// Pricing contributor status for the company
final pricingContributorStatusProvider =
    FutureProvider.autoDispose<PricingContributorStatus?>((ref) async {
  final repo = ref.read(crowdsourcedPricingRepoProvider);
  return repo.getContributorStatus();
});
