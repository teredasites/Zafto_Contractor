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
  final String companyId;
  final String rentChargeId;
  final String tenantId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? stripePaymentIntentId;
  final double processingFee;
  final String feePaidBy;
  final DateTime? paidAt;
  final String? notes;
  final DateTime createdAt;
  // Verification fields
  final String? reportedBy;
  final String verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final String? proofDocumentUrl;
  // Payment source
  final String paymentSource;
  final String? sourceName;
  final String? sourceReference;
  final DateTime? paymentDate;

  const RentPayment({
    required this.id,
    required this.companyId,
    required this.rentChargeId,
    required this.tenantId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.stripePaymentIntentId,
    this.processingFee = 0,
    this.feePaidBy = 'landlord',
    this.paidAt,
    this.notes,
    required this.createdAt,
    this.reportedBy,
    this.verificationStatus = 'auto_verified',
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNotes,
    this.proofDocumentUrl,
    this.paymentSource = 'tenant',
    this.sourceName,
    this.sourceReference,
    this.paymentDate,
  });

  factory RentPayment.fromJson(Map<String, dynamic> json) => RentPayment(
    id: json['id'] as String,
    companyId: json['company_id'] as String,
    rentChargeId: json['rent_charge_id'] as String,
    tenantId: json['tenant_id'] as String,
    amount: (json['amount'] as num).toDouble(),
    paymentMethod: json['payment_method'] as String,
    status: json['status'] as String? ?? 'pending',
    stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
    processingFee: (json['processing_fee'] as num?)?.toDouble() ?? 0,
    feePaidBy: json['fee_paid_by'] as String? ?? 'landlord',
    paidAt: json['paid_at'] != null
        ? DateTime.parse(json['paid_at'] as String)
        : null,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    reportedBy: json['reported_by'] as String?,
    verificationStatus:
        json['verification_status'] as String? ?? 'auto_verified',
    verifiedBy: json['verified_by'] as String?,
    verifiedAt: json['verified_at'] != null
        ? DateTime.parse(json['verified_at'] as String)
        : null,
    verificationNotes: json['verification_notes'] as String?,
    proofDocumentUrl: json['proof_document_url'] as String?,
    paymentSource: json['payment_source'] as String? ?? 'tenant',
    sourceName: json['source_name'] as String?,
    sourceReference: json['source_reference'] as String?,
    paymentDate: json['payment_date'] != null
        ? DateTime.parse(json['payment_date'] as String)
        : null,
  );

  Map<String, dynamic> toInsertJson() => {
    'rent_charge_id': rentChargeId,
    'tenant_id': tenantId,
    'amount': amount,
    'payment_method': paymentMethod,
    'status': status,
    'stripe_payment_intent_id': stripePaymentIntentId,
    'processing_fee': processingFee,
    'fee_paid_by': feePaidBy,
    'paid_at': paidAt?.toUtc().toIso8601String(),
    'notes': notes,
    'verification_status': verificationStatus,
    'payment_source': paymentSource,
    'source_name': sourceName,
    'source_reference': sourceReference,
    'proof_document_url': proofDocumentUrl,
    'payment_date': paymentDate?.toIso8601String().split('T')[0],
  };

  bool get isPendingVerification =>
      verificationStatus == 'pending_verification';
  bool get isVerified =>
      verificationStatus == 'verified' ||
      verificationStatus == 'auto_verified';
  bool get isDisputed => verificationStatus == 'disputed';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isSelfReported => reportedBy != null;
}

// ============================================================
// Government Payment Program Model
// ============================================================

class GovernmentPaymentProgram {
  final String id;
  final String companyId;
  final String tenantId;
  final String programType;
  final String programName;
  final String? authorityName;
  final String? authorityContactName;
  final String? authorityPhone;
  final String? authorityEmail;
  final String? voucherNumber;
  final String? hapContractNumber;
  final double? monthlyHapAmount;
  final double? tenantPortion;
  final double? utilityAllowance;
  final DateTime? effectiveDate;
  final DateTime? expirationDate;
  final DateTime? recertificationDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GovernmentPaymentProgram({
    required this.id,
    required this.companyId,
    required this.tenantId,
    required this.programType,
    required this.programName,
    this.authorityName,
    this.authorityContactName,
    this.authorityPhone,
    this.authorityEmail,
    this.voucherNumber,
    this.hapContractNumber,
    this.monthlyHapAmount,
    this.tenantPortion,
    this.utilityAllowance,
    this.effectiveDate,
    this.expirationDate,
    this.recertificationDate,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GovernmentPaymentProgram.fromJson(Map<String, dynamic> json) =>
      GovernmentPaymentProgram(
        id: json['id'] as String,
        companyId: json['company_id'] as String,
        tenantId: json['tenant_id'] as String,
        programType: json['program_type'] as String,
        programName: json['program_name'] as String,
        authorityName: json['authority_name'] as String?,
        authorityContactName: json['authority_contact_name'] as String?,
        authorityPhone: json['authority_phone'] as String?,
        authorityEmail: json['authority_email'] as String?,
        voucherNumber: json['voucher_number'] as String?,
        hapContractNumber: json['hap_contract_number'] as String?,
        monthlyHapAmount:
            (json['monthly_hap_amount'] as num?)?.toDouble(),
        tenantPortion: (json['tenant_portion'] as num?)?.toDouble(),
        utilityAllowance:
            (json['utility_allowance'] as num?)?.toDouble(),
        effectiveDate: json['effective_date'] != null
            ? DateTime.parse(json['effective_date'] as String)
            : null,
        expirationDate: json['expiration_date'] != null
            ? DateTime.parse(json['expiration_date'] as String)
            : null,
        recertificationDate: json['recertification_date'] != null
            ? DateTime.parse(json['recertification_date'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  static const programTypeLabels = {
    'section_8_hcv': 'Section 8 (HCV)',
    'vash': 'VASH (Veterans)',
    'public_housing': 'Public Housing',
    'project_based_voucher': 'Project-Based Voucher',
    'state_program': 'State Program',
    'local_program': 'Local Program',
    'employer_assistance': 'Employer Assistance',
    'other': 'Other',
  };

  String get programTypeLabel =>
      programTypeLabels[programType] ?? programType;
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

  // ============================================================
  // PAYMENT VERIFICATION
  // ============================================================

  Future<List<RentPayment>> getPendingVerifications() async {
    try {
      final response = await supabase
          .from(_paymentsTable)
          .select()
          .eq('verification_status', 'pending_verification')
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => RentPayment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch pending verifications: $e',
        userMessage: 'Could not load pending verifications.',
        cause: e,
      );
    }
  }

  Future<void> verifyPayment(String paymentId, {String? notes}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      await supabase.from(_paymentsTable).update({
        'verification_status': 'verified',
        'verified_by': userId,
        'verified_at': DateTime.now().toUtc().toIso8601String(),
        'verification_notes': notes,
        'status': 'completed',
        'paid_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', paymentId);
    } catch (e) {
      throw DatabaseError(
        'Failed to verify payment: $e',
        userMessage: 'Could not verify payment. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> disputePayment(String paymentId, String notes) async {
    try {
      await supabase.from(_paymentsTable).update({
        'verification_status': 'disputed',
        'verification_notes': notes,
      }).eq('id', paymentId);
    } catch (e) {
      throw DatabaseError(
        'Failed to dispute payment: $e',
        userMessage: 'Could not dispute payment. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> rejectPayment(String paymentId, String notes) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      await supabase.from(_paymentsTable).update({
        'verification_status': 'rejected',
        'verified_by': userId,
        'verified_at': DateTime.now().toUtc().toIso8601String(),
        'verification_notes': notes,
        'status': 'failed',
      }).eq('id', paymentId);
    } catch (e) {
      throw DatabaseError(
        'Failed to reject payment: $e',
        userMessage: 'Could not reject payment. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // GOVERNMENT PROGRAMS
  // ============================================================

  Future<List<GovernmentPaymentProgram>> getGovernmentPrograms(
    String tenantId,
  ) async {
    try {
      final response = await supabase
          .from('government_payment_programs')
          .select()
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => GovernmentPaymentProgram.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch government programs: $e',
        userMessage: 'Could not load payment programs.',
        cause: e,
      );
    }
  }
}
