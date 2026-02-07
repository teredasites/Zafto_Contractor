// ZAFTO Rent Repository
// Created: Property Management feature
//
// Supabase CRUD for rent_charges and rent_payments tables.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';

// ============================================================
// MODELS — Rent data classes
// ============================================================

class RentCharge {
  final String id;
  final String companyId;
  final String leaseId;
  final String unitId;
  final String tenantId;
  final String propertyId;
  final String chargeType;
  final String? description;
  final double amount;
  final DateTime dueDate;
  final String status;
  final double paidAmount;
  final DateTime? paidAt;
  final String? journalEntryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentCharge({
    required this.id,
    required this.companyId,
    required this.leaseId,
    required this.unitId,
    required this.tenantId,
    required this.propertyId,
    required this.chargeType,
    this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAmount = 0,
    this.paidAt,
    this.journalEntryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RentCharge.fromJson(Map<String, dynamic> json) => RentCharge(
    id: json['id'] as String,
    companyId: json['company_id'] as String,
    leaseId: json['lease_id'] as String,
    unitId: json['unit_id'] as String,
    tenantId: json['tenant_id'] as String,
    propertyId: json['property_id'] as String,
    chargeType: json['charge_type'] as String,
    description: json['description'] as String?,
    amount: (json['amount'] as num).toDouble(),
    dueDate: DateTime.parse(json['due_date'] as String),
    status: json['status'] as String,
    paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
    paidAt: json['paid_at'] != null
        ? DateTime.parse(json['paid_at'] as String)
        : null,
    journalEntryId: json['journal_entry_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toInsertJson() => {
    'company_id': companyId,
    'lease_id': leaseId,
    'unit_id': unitId,
    'tenant_id': tenantId,
    'property_id': propertyId,
    'charge_type': chargeType,
    'description': description,
    'amount': amount,
    'due_date': dueDate.toIso8601String(),
    'status': status,
    'paid_amount': paidAmount,
  };

  RentCharge copyWith({
    String? id,
    String? companyId,
    String? leaseId,
    String? unitId,
    String? tenantId,
    String? propertyId,
    String? chargeType,
    String? description,
    double? amount,
    DateTime? dueDate,
    String? status,
    double? paidAmount,
    DateTime? paidAt,
    String? journalEntryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RentCharge(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    leaseId: leaseId ?? this.leaseId,
    unitId: unitId ?? this.unitId,
    tenantId: tenantId ?? this.tenantId,
    propertyId: propertyId ?? this.propertyId,
    chargeType: chargeType ?? this.chargeType,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    paidAmount: paidAmount ?? this.paidAmount,
    paidAt: paidAt ?? this.paidAt,
    journalEntryId: journalEntryId ?? this.journalEntryId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class RentPayment {
  final String id;
  final String rentChargeId;
  final double amount;
  final String paymentMethod;
  final String? paymentReference;
  final DateTime paymentDate;
  final String? stripePaymentId;
  final String? notes;
  final DateTime createdAt;

  const RentPayment({
    required this.id,
    required this.rentChargeId,
    required this.amount,
    required this.paymentMethod,
    this.paymentReference,
    required this.paymentDate,
    this.stripePaymentId,
    this.notes,
    required this.createdAt,
  });

  factory RentPayment.fromJson(Map<String, dynamic> json) => RentPayment(
    id: json['id'] as String,
    rentChargeId: json['rent_charge_id'] as String,
    amount: (json['amount'] as num).toDouble(),
    paymentMethod: json['payment_method'] as String,
    paymentReference: json['payment_reference'] as String?,
    paymentDate: DateTime.parse(json['payment_date'] as String),
    stripePaymentId: json['stripe_payment_id'] as String?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toInsertJson() => {
    'rent_charge_id': rentChargeId,
    'amount': amount,
    'payment_method': paymentMethod,
    'payment_reference': paymentReference,
    'payment_date': paymentDate.toIso8601String(),
    'stripe_payment_id': stripePaymentId,
    'notes': notes,
  };
}

// ============================================================
// REPOSITORY
// ============================================================

class RentRepository {
  static const _chargesTable = 'rent_charges';
  static const _paymentsTable = 'rent_payments';

  // ============================================================
  // RENT CHARGES — READ
  // ============================================================

  Future<List<RentCharge>> getRentCharges({
    String? propertyId,
    String? tenantId,
    String? status,
  }) async {
    try {
      var query = supabase.from(_chargesTable).select();
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      if (tenantId != null) {
        query = query.eq('tenant_id', tenantId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      final response = await query.order('due_date', ascending: false);
      return (response as List)
          .map((row) => RentCharge.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch rent charges: $e',
        userMessage: 'Could not load rent charges. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<RentCharge>> getOverdueCharges() async {
    try {
      final response = await supabase
          .from(_chargesTable)
          .select()
          .eq('status', 'overdue')
          .order('due_date', ascending: true);
      return (response as List)
          .map((row) => RentCharge.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch overdue charges: $e',
        userMessage: 'Could not load overdue charges. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // RENT CHARGES — WRITE
  // ============================================================

  Future<RentCharge> createRentCharge(RentCharge c) async {
    try {
      final response = await supabase
          .from(_chargesTable)
          .insert(c.toInsertJson())
          .select()
          .single();
      return RentCharge.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create rent charge: $e',
        userMessage: 'Could not create rent charge. Please try again.',
        cause: e,
      );
    }
  }

  Future<RentCharge> updateChargePayment(
    String id,
    double paidAmount,
    String status,
  ) async {
    try {
      final updates = <String, dynamic>{
        'paid_amount': paidAmount,
        'status': status,
      };
      if (status == 'paid') {
        updates['paid_at'] = DateTime.now().toUtc().toIso8601String();
      }
      final response = await supabase
          .from(_chargesTable)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return RentCharge.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update charge payment: $e',
        userMessage: 'Could not update payment. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // RENT PAYMENTS — READ
  // ============================================================

  Future<List<RentPayment>> getRentPayments(String chargeId) async {
    try {
      final response = await supabase
          .from(_paymentsTable)
          .select()
          .eq('rent_charge_id', chargeId)
          .order('payment_date', ascending: false);
      return (response as List)
          .map((row) => RentPayment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch rent payments: $e',
        userMessage: 'Could not load payments. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // RENT PAYMENTS — WRITE
  // ============================================================

  Future<RentPayment> recordPayment(RentPayment p) async {
    try {
      final response = await supabase
          .from(_paymentsTable)
          .insert(p.toInsertJson())
          .select()
          .single();
      return RentPayment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to record payment: $e',
        userMessage: 'Could not record payment. Please try again.',
        cause: e,
      );
    }
  }
}
