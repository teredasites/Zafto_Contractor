// ZAFTO Crowdsourced Material Pricing Repository — Supabase Backend
// Created: DEPTH31 — Receipt OCR, Supplier Directory, Pricing Engine
//
// CRUD for material_receipts, material_receipt_items, supplier_directory,
// material_price_index, distributor_accounts, price_alerts, pricing_contributor_status.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/crowdsourced_pricing.dart';

class CrowdsourcedPricingRepository {
  static const _receiptsTable = 'material_receipts';
  static const _receiptItemsTable = 'material_receipt_items';
  static const _suppliersTable = 'supplier_directory';
  static const _priceIndexTable = 'material_price_index';
  static const _priceIndicesTable = 'material_price_indices';
  static const _regionalCostTable = 'regional_cost_factors';
  static const _distributorAccountsTable = 'distributor_accounts';
  static const _priceAlertsTable = 'price_alerts';
  static const _contributorStatusTable = 'pricing_contributor_status';

  // ==================== MATERIAL RECEIPTS ====================

  /// Get all receipts for the company
  Future<List<MaterialReceipt>> getReceipts({String? status}) async {
    try {
      var query = supabase
          .from(_receiptsTable)
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      if (status != null) {
        query = supabase
            .from(_receiptsTable)
            .select()
            .eq('processing_status', status)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);
      }

      final response = await query;
      return (response as List)
          .map((row) => MaterialReceipt.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load receipts',
        userMessage: 'Could not load material receipts.',
        cause: e,
      );
    }
  }

  /// Get a single receipt with its items
  Future<MaterialReceipt> getReceipt(String id) async {
    try {
      final response = await supabase
          .from(_receiptsTable)
          .select()
          .eq('id', id)
          .single();
      return MaterialReceipt.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load receipt',
        userMessage: 'Could not load receipt details.',
        cause: e,
      );
    }
  }

  /// Get items for a receipt
  Future<List<MaterialReceiptItem>> getReceiptItems(String receiptId) async {
    try {
      final response = await supabase
          .from(_receiptItemsTable)
          .select()
          .eq('receipt_id', receiptId)
          .isFilter('deleted_at', null)
          .order('created_at');

      return (response as List)
          .map((row) => MaterialReceiptItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load receipt items',
        userMessage: 'Could not load receipt line items.',
        cause: e,
      );
    }
  }

  /// Create a new receipt
  Future<MaterialReceipt> createReceipt(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_receiptsTable)
          .insert(data)
          .select()
          .single();
      return MaterialReceipt.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create receipt',
        userMessage: 'Could not save receipt. Please try again.',
        cause: e,
      );
    }
  }

  /// Update a receipt
  Future<MaterialReceipt> updateReceipt(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_receiptsTable)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return MaterialReceipt.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update receipt',
        userMessage: 'Could not update receipt.',
        cause: e,
      );
    }
  }

  /// Soft delete a receipt
  Future<void> deleteReceipt(String id) async {
    try {
      await supabase
          .from(_receiptsTable)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete receipt',
        userMessage: 'Could not remove receipt.',
        cause: e,
      );
    }
  }

  /// Add an item to a receipt
  Future<MaterialReceiptItem> addReceiptItem(
      Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_receiptItemsTable)
          .insert(data)
          .select()
          .single();
      return MaterialReceiptItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add receipt item',
        userMessage: 'Could not add line item.',
        cause: e,
      );
    }
  }

  /// Update a receipt item (manual correction)
  Future<MaterialReceiptItem> updateReceiptItem(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_receiptItemsTable)
          .update({...updates, 'manually_corrected': true})
          .eq('id', id)
          .select()
          .single();
      return MaterialReceiptItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update receipt item',
        userMessage: 'Could not update line item.',
        cause: e,
      );
    }
  }

  /// Soft delete a receipt item
  Future<void> deleteReceiptItem(String id) async {
    try {
      await supabase
          .from(_receiptItemsTable)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete receipt item',
        userMessage: 'Could not remove line item.',
        cause: e,
      );
    }
  }

  // ==================== SUPPLIER DIRECTORY ====================

  /// Get all suppliers
  Future<List<SupplierDirectory>> getSuppliers({
    String? supplierType,
    String? trade,
  }) async {
    try {
      var query = supabase.from(_suppliersTable).select();

      if (supplierType != null) {
        query = query.eq('supplier_type', supplierType);
      }
      if (trade != null) {
        query = query.contains('trades_served', [trade]);
      }

      final response = await query.order('name');
      return (response as List)
          .map((row) => SupplierDirectory.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load suppliers',
        userMessage: 'Could not load supplier directory.',
        cause: e,
      );
    }
  }

  /// Search suppliers by name
  Future<List<SupplierDirectory>> searchSuppliers(String query) async {
    try {
      final response = await supabase
          .from(_suppliersTable)
          .select()
          .or('name.ilike.%$query%,name_normalized.ilike.%$query%')
          .order('receipt_count', ascending: false)
          .limit(20);

      return (response as List)
          .map((row) => SupplierDirectory.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to search suppliers',
        userMessage: 'Could not search suppliers.',
        cause: e,
      );
    }
  }

  /// Get a single supplier
  Future<SupplierDirectory> getSupplier(String id) async {
    try {
      final response = await supabase
          .from(_suppliersTable)
          .select()
          .eq('id', id)
          .single();
      return SupplierDirectory.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load supplier',
        userMessage: 'Could not load supplier details.',
        cause: e,
      );
    }
  }

  // ==================== MATERIAL PRICE INDEX ====================

  /// Search price index
  Future<List<MaterialPriceIndex>> searchPriceIndex({
    String? query,
    String? materialCategory,
    String? trade,
  }) async {
    try {
      var q = supabase
          .from(_priceIndexTable)
          .select()
          .eq('is_published', true);

      if (materialCategory != null) {
        q = q.eq('material_category', materialCategory);
      }
      if (trade != null) {
        q = q.eq('trade', trade);
      }
      if (query != null && query.isNotEmpty) {
        q = q.ilike('product_name_normalized', '%$query%');
      }

      final response = await q.order('sample_count', ascending: false).limit(50);
      return (response as List)
          .map((row) => MaterialPriceIndex.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to search price index',
        userMessage: 'Could not search material prices.',
        cause: e,
      );
    }
  }

  /// Get price index entry by product name
  Future<MaterialPriceIndex?> getPriceForProduct(String productName) async {
    try {
      final response = await supabase
          .from(_priceIndexTable)
          .select()
          .eq('product_name_normalized', productName)
          .eq('is_published', true)
          .limit(1);

      final list = response as List;
      if (list.isEmpty) return null;
      return MaterialPriceIndex.fromJson(list.first);
    } catch (e) {
      throw DatabaseError(
        'Failed to get price',
        userMessage: 'Could not look up material price.',
        cause: e,
      );
    }
  }

  // ==================== BLS/FRED PRICE INDICES ====================

  /// Get price index entries for a series
  Future<List<MaterialPriceIndexEntry>> getPriceIndices(
      String seriesId, {int limit = 24}) async {
    try {
      final response = await supabase
          .from(_priceIndicesTable)
          .select()
          .eq('series_id', seriesId)
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((row) => MaterialPriceIndexEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load price indices',
        userMessage: 'Could not load price trend data.',
        cause: e,
      );
    }
  }

  /// Get latest PPI for a category
  Future<List<MaterialPriceIndexEntry>> getLatestByCategory(
      String category) async {
    try {
      final response = await supabase
          .from(_priceIndicesTable)
          .select()
          .eq('category', category)
          .order('date', ascending: false)
          .limit(1);

      return (response as List)
          .map((row) => MaterialPriceIndexEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load category index',
        userMessage: 'Could not load price index.',
        cause: e,
      );
    }
  }

  // ==================== REGIONAL COST FACTORS ====================

  /// Get regional cost factor for state/metro
  Future<RegionalCostFactor?> getRegionalFactor(
      String state, {String? metroArea, String? trade}) async {
    try {
      var query = supabase
          .from(_regionalCostTable)
          .select()
          .eq('state', state);

      if (metroArea != null) {
        query = query.eq('metro_area', metroArea);
      } else {
        query = query.isFilter('metro_area', null);
      }
      if (trade != null) {
        query = query.eq('trade', trade);
      } else {
        query = query.isFilter('trade', null);
      }

      final response = await query.limit(1);
      final list = response as List;
      if (list.isEmpty) return null;
      return RegionalCostFactor.fromJson(list.first);
    } catch (e) {
      throw DatabaseError(
        'Failed to load regional cost factor',
        userMessage: 'Could not load regional pricing data.',
        cause: e,
      );
    }
  }

  /// Get all regional factors for a state
  Future<List<RegionalCostFactor>> getRegionalFactorsForState(
      String state) async {
    try {
      final response = await supabase
          .from(_regionalCostTable)
          .select()
          .eq('state', state)
          .order('trade');

      return (response as List)
          .map((row) => RegionalCostFactor.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load regional factors',
        userMessage: 'Could not load regional pricing data.',
        cause: e,
      );
    }
  }

  // ==================== DISTRIBUTOR ACCOUNTS ====================

  /// Get all linked distributor accounts for the company
  Future<List<DistributorAccount>> getDistributorAccounts() async {
    try {
      final response = await supabase
          .from(_distributorAccountsTable)
          .select()
          .isFilter('deleted_at', null)
          .order('created_at');

      return (response as List)
          .map((row) => DistributorAccount.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load distributor accounts',
        userMessage: 'Could not load linked supplier accounts.',
        cause: e,
      );
    }
  }

  /// Link a new distributor account
  Future<DistributorAccount> linkDistributorAccount(
      Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_distributorAccountsTable)
          .insert(data)
          .select()
          .single();
      return DistributorAccount.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to link distributor account',
        userMessage: 'Could not link supplier account. Please try again.',
        cause: e,
      );
    }
  }

  /// Update a distributor account
  Future<DistributorAccount> updateDistributorAccount(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_distributorAccountsTable)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return DistributorAccount.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update distributor account',
        userMessage: 'Could not update supplier account.',
        cause: e,
      );
    }
  }

  /// Soft delete (unlink) a distributor account
  Future<void> unlinkDistributorAccount(String id) async {
    try {
      await supabase
          .from(_distributorAccountsTable)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to unlink distributor account',
        userMessage: 'Could not remove supplier account.',
        cause: e,
      );
    }
  }

  // ==================== PRICE ALERTS ====================

  /// Get active price alerts for current user
  Future<List<PriceAlert>> getPriceAlerts() async {
    try {
      final response = await supabase
          .from(_priceAlertsTable)
          .select()
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => PriceAlert.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load price alerts',
        userMessage: 'Could not load price alerts.',
        cause: e,
      );
    }
  }

  /// Create a price alert
  Future<PriceAlert> createPriceAlert(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_priceAlertsTable)
          .insert(data)
          .select()
          .single();
      return PriceAlert.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create price alert',
        userMessage: 'Could not create price alert.',
        cause: e,
      );
    }
  }

  /// Update a price alert
  Future<PriceAlert> updatePriceAlert(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_priceAlertsTable)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return PriceAlert.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update price alert',
        userMessage: 'Could not update price alert.',
        cause: e,
      );
    }
  }

  /// Soft delete a price alert
  Future<void> deletePriceAlert(String id) async {
    try {
      await supabase
          .from(_priceAlertsTable)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete price alert',
        userMessage: 'Could not remove price alert.',
        cause: e,
      );
    }
  }

  // ==================== CONTRIBUTOR STATUS ====================

  /// Get contributor status for the company
  Future<PricingContributorStatus?> getContributorStatus() async {
    try {
      final response = await supabase
          .from(_contributorStatusTable)
          .select()
          .limit(1);

      final list = response as List;
      if (list.isEmpty) return null;
      return PricingContributorStatus.fromJson(list.first);
    } catch (e) {
      throw DatabaseError(
        'Failed to load contributor status',
        userMessage: 'Could not load pricing contributor status.',
        cause: e,
      );
    }
  }

  /// Upsert contributor status (opt in/out)
  Future<PricingContributorStatus> updateContributorStatus(
      Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_contributorStatusTable)
          .upsert(data, onConflict: 'company_id')
          .select()
          .single();
      return PricingContributorStatus.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update contributor status',
        userMessage: 'Could not update pricing contribution preference.',
        cause: e,
      );
    }
  }
}
