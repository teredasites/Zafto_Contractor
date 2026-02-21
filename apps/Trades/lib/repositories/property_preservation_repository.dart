// ZAFTO Property Preservation Repository
// Created: DEPTH34 — PP work orders, national companies, winterization,
// debris estimation, chargebacks, utility tracking, vendor apps,
// boiler/furnace DB, pricing matrices, stripped property estimates.
//
// Tables: pp_work_orders, pp_chargebacks, pp_winterization_records,
//         pp_debris_estimates, pp_utility_tracking, pp_vendor_applications,
//         pp_national_companies, pp_work_order_types, boiler_furnace_models,
//         pp_pricing_matrices, pp_stripped_estimates

import '../core/supabase_client.dart';
import '../models/property_preservation.dart';

class PropertyPreservationRepository {
  static const _workOrders = 'pp_work_orders';
  static const _chargebacks = 'pp_chargebacks';
  static const _winterization = 'pp_winterization_records';
  static const _debris = 'pp_debris_estimates';
  static const _utilities = 'pp_utility_tracking';
  static const _vendorApps = 'pp_vendor_applications';
  static const _nationals = 'pp_national_companies';
  static const _woTypes = 'pp_work_order_types';
  static const _boilerModels = 'boiler_furnace_models';
  static const _pricing = 'pp_pricing_matrices';
  static const _stripped = 'pp_stripped_estimates';

  // ══════════════════════════════════════════════════════════════
  // NATIONAL COMPANIES (system reference — read-only from app)
  // ══════════════════════════════════════════════════════════════

  /// Get all active national PP companies
  Future<List<PpNationalCompany>> getNationalCompanies() async {
    final data = await supabase
        .from(_nationals)
        .select()
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .order('name');
    return data.map((row) => PpNationalCompany.fromJson(row)).toList();
  }

  /// Get national company by ID
  Future<PpNationalCompany> getNationalCompany(String id) async {
    final data = await supabase
        .from(_nationals)
        .select()
        .eq('id', id)
        .single();
    return PpNationalCompany.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // WORK ORDER TYPES (system reference — read-only from app)
  // ══════════════════════════════════════════════════════════════

  /// Get all work order types
  Future<List<PpWorkOrderType>> getWorkOrderTypes() async {
    final data = await supabase
        .from(_woTypes)
        .select()
        .order('category')
        .order('name');
    return data.map((row) => PpWorkOrderType.fromJson(row)).toList();
  }

  /// Get work order types by category
  Future<List<PpWorkOrderType>> getWorkOrderTypesByCategory(
    String category,
  ) async {
    final data = await supabase
        .from(_woTypes)
        .select()
        .eq('category', category)
        .order('name');
    return data.map((row) => PpWorkOrderType.fromJson(row)).toList();
  }

  /// Get work order type by code
  Future<PpWorkOrderType?> getWorkOrderTypeByCode(String code) async {
    final data = await supabase
        .from(_woTypes)
        .select()
        .eq('code', code)
        .maybeSingle();
    return data != null ? PpWorkOrderType.fromJson(data) : null;
  }

  // ══════════════════════════════════════════════════════════════
  // WORK ORDERS (company-scoped CRUD)
  // ══════════════════════════════════════════════════════════════

  /// Get work orders with optional filters
  Future<List<PpWorkOrder>> getWorkOrders({
    String? status,
    String? nationalCompanyId,
    String? propertyId,
    String? assignedTo,
    int limit = 50,
    int offset = 0,
  }) async {
    var q = supabase
        .from(_workOrders)
        .select()
        .isFilter('deleted_at', null);

    if (status != null) q = q.eq('status', status);
    if (nationalCompanyId != null) {
      q = q.eq('national_company_id', nationalCompanyId);
    }
    if (propertyId != null) q = q.eq('property_id', propertyId);
    if (assignedTo != null) q = q.eq('assigned_to', assignedTo);

    final data = await q
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return data.map((row) => PpWorkOrder.fromJson(row)).toList();
  }

  /// Get overdue work orders
  Future<List<PpWorkOrder>> getOverdueWorkOrders() async {
    final data = await supabase
        .from(_workOrders)
        .select()
        .isFilter('deleted_at', null)
        .lte('due_date', DateTime.now().toIso8601String())
        .not('status', 'in', '(completed,approved)')
        .order('due_date', ascending: true);
    return data.map((row) => PpWorkOrder.fromJson(row)).toList();
  }

  /// Get a single work order
  Future<PpWorkOrder> getWorkOrder(String id) async {
    final data = await supabase
        .from(_workOrders)
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .single();
    return PpWorkOrder.fromJson(data);
  }

  /// Create a work order
  Future<PpWorkOrder> createWorkOrder(PpWorkOrder wo) async {
    final data = await supabase
        .from(_workOrders)
        .insert(wo.toJson())
        .select()
        .single();
    return PpWorkOrder.fromJson(data);
  }

  /// Update a work order (optimistic locking via updated_at)
  Future<PpWorkOrder> updateWorkOrder(PpWorkOrder wo) async {
    final data = await supabase
        .from(_workOrders)
        .update(wo.toJson())
        .eq('id', wo.id)
        .eq('updated_at', wo.updatedAt)
        .select()
        .single();
    return PpWorkOrder.fromJson(data);
  }

  /// Update work order status
  Future<PpWorkOrder> updateWorkOrderStatus(
    String id,
    String updatedAt,
    PpWorkOrderStatus newStatus,
  ) async {
    final now = DateTime.now().toIso8601String();
    final patch = <String, dynamic>{'status': newStatus.toJson()};

    if (newStatus == PpWorkOrderStatus.inProgress) {
      patch['started_at'] = now;
    } else if (newStatus == PpWorkOrderStatus.completed) {
      patch['completed_at'] = now;
    } else if (newStatus == PpWorkOrderStatus.submitted) {
      patch['submitted_at'] = now;
    }

    final data = await supabase
        .from(_workOrders)
        .update(patch)
        .eq('id', id)
        .eq('updated_at', updatedAt)
        .select()
        .single();
    return PpWorkOrder.fromJson(data);
  }

  /// Soft-delete a work order
  Future<void> deleteWorkOrder(String id, String updatedAt) async {
    await supabase
        .from(_workOrders)
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('updated_at', updatedAt);
  }

  // ══════════════════════════════════════════════════════════════
  // CHARGEBACKS (company-scoped CRUD)
  // ══════════════════════════════════════════════════════════════

  /// Get chargebacks with optional filters
  Future<List<PpChargeback>> getChargebacks({
    String? nationalCompanyId,
    String? disputeStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    var q = supabase
        .from(_chargebacks)
        .select()
        .isFilter('deleted_at', null);

    if (nationalCompanyId != null) {
      q = q.eq('national_company_id', nationalCompanyId);
    }
    if (disputeStatus != null) q = q.eq('dispute_status', disputeStatus);

    final data = await q
        .order('chargeback_date', ascending: false)
        .range(offset, offset + limit - 1);
    return data.map((row) => PpChargeback.fromJson(row)).toList();
  }

  /// Create a chargeback
  Future<PpChargeback> createChargeback(PpChargeback cb) async {
    final data = await supabase
        .from(_chargebacks)
        .insert(cb.toJson())
        .select()
        .single();
    return PpChargeback.fromJson(data);
  }

  /// Update chargeback (optimistic locking)
  Future<PpChargeback> updateChargeback(PpChargeback cb) async {
    final data = await supabase
        .from(_chargebacks)
        .update(cb.toJson())
        .eq('id', cb.id)
        .eq('updated_at', cb.updatedAt)
        .select()
        .single();
    return PpChargeback.fromJson(data);
  }

  /// Submit a chargeback dispute
  Future<PpChargeback> submitDispute(
    String id,
    String updatedAt,
    String evidenceNotes,
  ) async {
    final data = await supabase
        .from(_chargebacks)
        .update({
          'dispute_status': 'submitted',
          'dispute_submitted_at': DateTime.now().toIso8601String(),
          'evidence_notes': evidenceNotes,
        })
        .eq('id', id)
        .eq('updated_at', updatedAt)
        .select()
        .single();
    return PpChargeback.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // WINTERIZATION RECORDS (company-scoped CRUD)
  // ══════════════════════════════════════════════════════════════

  /// Get winterization records for a property
  Future<List<PpWinterizationRecord>> getWinterizationRecords({
    String? propertyId,
    String? workOrderId,
    int limit = 50,
  }) async {
    var q = supabase
        .from(_winterization)
        .select()
        .isFilter('deleted_at', null);

    if (propertyId != null) q = q.eq('property_id', propertyId);
    if (workOrderId != null) q = q.eq('work_order_id', workOrderId);

    final data = await q
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((row) => PpWinterizationRecord.fromJson(row)).toList();
  }

  /// Create a winterization record
  Future<PpWinterizationRecord> createWinterizationRecord(
    PpWinterizationRecord rec,
  ) async {
    final data = await supabase
        .from(_winterization)
        .insert(rec.toJson())
        .select()
        .single();
    return PpWinterizationRecord.fromJson(data);
  }

  /// Update a winterization record (optimistic locking)
  Future<PpWinterizationRecord> updateWinterizationRecord(
    PpWinterizationRecord rec,
  ) async {
    final data = await supabase
        .from(_winterization)
        .update(rec.toJson())
        .eq('id', rec.id)
        .eq('updated_at', rec.updatedAt)
        .select()
        .single();
    return PpWinterizationRecord.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // DEBRIS ESTIMATES (company-scoped CRUD)
  // ══════════════════════════════════════════════════════════════

  /// Get debris estimates
  Future<List<PpDebrisEstimate>> getDebrisEstimates({
    String? propertyId,
    String? workOrderId,
    int limit = 50,
  }) async {
    var q = supabase
        .from(_debris)
        .select()
        .isFilter('deleted_at', null);

    if (propertyId != null) q = q.eq('property_id', propertyId);
    if (workOrderId != null) q = q.eq('work_order_id', workOrderId);

    final data = await q
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((row) => PpDebrisEstimate.fromJson(row)).toList();
  }

  /// Create a debris estimate
  Future<PpDebrisEstimate> createDebrisEstimate(PpDebrisEstimate est) async {
    final data = await supabase
        .from(_debris)
        .insert(est.toJson())
        .select()
        .single();
    return PpDebrisEstimate.fromJson(data);
  }

  /// Update a debris estimate (optimistic locking)
  Future<PpDebrisEstimate> updateDebrisEstimate(PpDebrisEstimate est) async {
    final data = await supabase
        .from(_debris)
        .update(est.toJson())
        .eq('id', est.id)
        .eq('updated_at', est.updatedAt)
        .select()
        .single();
    return PpDebrisEstimate.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // UTILITY TRACKING (company-scoped CRUD)
  // ══════════════════════════════════════════════════════════════

  /// Get utilities for a property
  Future<List<PpUtilityTracking>> getUtilities({
    String? propertyId,
    int limit = 50,
  }) async {
    var q = supabase
        .from(_utilities)
        .select()
        .isFilter('deleted_at', null);

    if (propertyId != null) q = q.eq('property_id', propertyId);

    final data = await q.order('utility_type').limit(limit);
    return data.map((row) => PpUtilityTracking.fromJson(row)).toList();
  }

  /// Create a utility tracking record
  Future<PpUtilityTracking> createUtility(PpUtilityTracking util) async {
    final data = await supabase
        .from(_utilities)
        .insert(util.toJson())
        .select()
        .single();
    return PpUtilityTracking.fromJson(data);
  }

  /// Update a utility tracking record (optimistic locking)
  Future<PpUtilityTracking> updateUtility(PpUtilityTracking util) async {
    final data = await supabase
        .from(_utilities)
        .update(util.toJson())
        .eq('id', util.id)
        .eq('updated_at', util.updatedAt)
        .select()
        .single();
    return PpUtilityTracking.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // VENDOR APPLICATIONS (company-scoped CRUD)
  // ══════════════════════════════════════════════════════════════

  /// Get all vendor applications for this company
  Future<List<PpVendorApplication>> getVendorApplications() async {
    final data = await supabase
        .from(_vendorApps)
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return data.map((row) => PpVendorApplication.fromJson(row)).toList();
  }

  /// Get vendor application for a specific national
  Future<PpVendorApplication?> getVendorApplicationForNational(
    String nationalCompanyId,
  ) async {
    final data = await supabase
        .from(_vendorApps)
        .select()
        .eq('national_company_id', nationalCompanyId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return data != null ? PpVendorApplication.fromJson(data) : null;
  }

  /// Create or update a vendor application (upsert on company+national)
  Future<PpVendorApplication> upsertVendorApplication(
    PpVendorApplication app,
  ) async {
    final data = await supabase
        .from(_vendorApps)
        .upsert(app.toJson(), onConflict: 'company_id,national_company_id')
        .select()
        .single();
    return PpVendorApplication.fromJson(data);
  }

  /// Update vendor application status
  Future<PpVendorApplication> updateVendorAppStatus(
    String id,
    String updatedAt,
    String newStatus,
  ) async {
    final now = DateTime.now().toIso8601String();
    final patch = <String, dynamic>{'status': newStatus};

    if (newStatus == 'submitted') {
      patch['applied_at'] = now;
    } else if (newStatus == 'approved') {
      patch['approved_at'] = now;
    } else if (newStatus == 'rejected') {
      patch['rejected_at'] = now;
    }

    final data = await supabase
        .from(_vendorApps)
        .update(patch)
        .eq('id', id)
        .eq('updated_at', updatedAt)
        .select()
        .single();
    return PpVendorApplication.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // BOILER/FURNACE MODELS (system reference — read-only)
  // ══════════════════════════════════════════════════════════════

  /// Get all boiler/furnace models
  Future<List<BoilerFurnaceModel>> getBoilerFurnaceModels({
    String? equipmentType,
    String? fuelType,
    String? manufacturer,
  }) async {
    var q = supabase.from(_boilerModels).select();

    if (equipmentType != null) q = q.eq('equipment_type', equipmentType);
    if (fuelType != null) q = q.eq('fuel_type', fuelType);
    if (manufacturer != null) q = q.eq('manufacturer', manufacturer);

    final data = await q.order('manufacturer').order('model_name');
    return data.map((row) => BoilerFurnaceModel.fromJson(row)).toList();
  }

  /// Search boiler/furnace models by name
  Future<List<BoilerFurnaceModel>> searchBoilerModels(String query) async {
    final data = await supabase
        .from(_boilerModels)
        .select()
        .or('manufacturer.ilike.%$query%,model_name.ilike.%$query%')
        .order('manufacturer')
        .limit(30);
    return data.map((row) => BoilerFurnaceModel.fromJson(row)).toList();
  }

  // ══════════════════════════════════════════════════════════════
  // PRICING MATRICES (system reference — read-only)
  // ══════════════════════════════════════════════════════════════

  /// Get pricing for a state and work order type
  Future<List<PpPricingMatrix>> getPricing({
    required String stateCode,
    String? workOrderType,
    String? pricingSource,
  }) async {
    var q = supabase
        .from(_pricing)
        .select()
        .eq('state_code', stateCode);

    if (workOrderType != null) q = q.eq('work_order_type', workOrderType);
    if (pricingSource != null) q = q.eq('pricing_source', pricingSource);

    final data = await q.order('work_order_type');
    return data.map((row) => PpPricingMatrix.fromJson(row)).toList();
  }

  // ══════════════════════════════════════════════════════════════
  // STRIPPED PROPERTY ESTIMATES (company-scoped CRUD)
  // ══════════════════════════════════════════════════════════════

  /// Get stripped estimates
  Future<List<PpStrippedEstimate>> getStrippedEstimates({
    String? propertyId,
    String? workOrderId,
    int limit = 50,
  }) async {
    var q = supabase
        .from(_stripped)
        .select()
        .isFilter('deleted_at', null);

    if (propertyId != null) q = q.eq('property_id', propertyId);
    if (workOrderId != null) q = q.eq('work_order_id', workOrderId);

    final data = await q
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((row) => PpStrippedEstimate.fromJson(row)).toList();
  }

  /// Create a stripped estimate
  Future<PpStrippedEstimate> createStrippedEstimate(
    PpStrippedEstimate est,
  ) async {
    final data = await supabase
        .from(_stripped)
        .insert(est.toJson())
        .select()
        .single();
    return PpStrippedEstimate.fromJson(data);
  }

  /// Update a stripped estimate (optimistic locking)
  Future<PpStrippedEstimate> updateStrippedEstimate(
    PpStrippedEstimate est,
  ) async {
    final data = await supabase
        .from(_stripped)
        .update(est.toJson())
        .eq('id', est.id)
        .eq('updated_at', est.updatedAt)
        .select()
        .single();
    return PpStrippedEstimate.fromJson(data);
  }
}
