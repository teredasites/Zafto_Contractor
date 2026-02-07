// ZAFTO Expense Record Model — Supabase Backend
// Maps to `expense_records` table in Supabase PostgreSQL.
// Tracks company expenses with optional receipt/OCR integration.
// Categories: materials, tools, fuel, equipment, vehicle, office, permits, subcontractor, uncategorized.
// Workflow: draft → approved → posted → voided.

enum ExpenseCategory {
  materials,
  tools,
  fuel,
  equipment,
  vehicle,
  office,
  permits,
  subcontractor,
  uncategorized;

  String get dbValue => name;

  String get label {
    switch (this) {
      case ExpenseCategory.materials:
        return 'Materials';
      case ExpenseCategory.tools:
        return 'Tools';
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.vehicle:
        return 'Vehicle';
      case ExpenseCategory.office:
        return 'Office';
      case ExpenseCategory.permits:
        return 'Permits';
      case ExpenseCategory.subcontractor:
        return 'Subcontractor';
      case ExpenseCategory.uncategorized:
        return 'Uncategorized';
    }
  }

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.uncategorized;
    return ExpenseCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ExpenseCategory.uncategorized,
    );
  }
}

enum ExpensePaymentMethod {
  creditCard,
  cash,
  check,
  bankTransfer;

  String get dbValue {
    switch (this) {
      case ExpensePaymentMethod.creditCard:
        return 'credit_card';
      case ExpensePaymentMethod.cash:
        return 'cash';
      case ExpensePaymentMethod.check:
        return 'check';
      case ExpensePaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  String get label {
    switch (this) {
      case ExpensePaymentMethod.creditCard:
        return 'Credit Card';
      case ExpensePaymentMethod.cash:
        return 'Cash';
      case ExpensePaymentMethod.check:
        return 'Check';
      case ExpensePaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  static ExpensePaymentMethod fromString(String? value) {
    if (value == null) return ExpensePaymentMethod.cash;
    switch (value) {
      case 'credit_card':
        return ExpensePaymentMethod.creditCard;
      case 'cash':
        return ExpensePaymentMethod.cash;
      case 'check':
        return ExpensePaymentMethod.check;
      case 'bank_transfer':
        return ExpensePaymentMethod.bankTransfer;
      default:
        return ExpensePaymentMethod.cash;
    }
  }
}

enum ExpenseOcrStatus {
  none,
  pending,
  processing,
  completed,
  failed;

  String get dbValue => name;

  static ExpenseOcrStatus fromString(String? value) {
    if (value == null) return ExpenseOcrStatus.none;
    return ExpenseOcrStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ExpenseOcrStatus.none,
    );
  }
}

enum ExpenseStatus {
  draft,
  approved,
  posted,
  voided;

  String get dbValue => name;

  String get label {
    switch (this) {
      case ExpenseStatus.draft:
        return 'Draft';
      case ExpenseStatus.approved:
        return 'Approved';
      case ExpenseStatus.posted:
        return 'Posted';
      case ExpenseStatus.voided:
        return 'Voided';
    }
  }

  static ExpenseStatus fromString(String? value) {
    if (value == null) return ExpenseStatus.draft;
    return ExpenseStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ExpenseStatus.draft,
    );
  }
}

class ExpenseRecord {
  final String id;
  final String companyId;
  final String? jobId;
  final String? vendorId;
  final String createdByUserId;
  final DateTime expenseDate;
  final String description;
  final double amount;
  final double taxAmount;
  final double total;
  final ExpenseCategory category;
  final ExpensePaymentMethod paymentMethod;
  final String? receiptStoragePath;
  final String? receiptUrl;
  final ExpenseOcrStatus ocrStatus;
  final ExpenseStatus status;
  final String? notes;
  final DateTime? deletedAt;
  final DateTime createdAt;

  const ExpenseRecord({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.vendorId,
    this.createdByUserId = '',
    required this.expenseDate,
    this.description = '',
    this.amount = 0,
    this.taxAmount = 0,
    this.total = 0,
    this.category = ExpenseCategory.uncategorized,
    this.paymentMethod = ExpensePaymentMethod.cash,
    this.receiptStoragePath,
    this.receiptUrl,
    this.ocrStatus = ExpenseOcrStatus.none,
    this.status = ExpenseStatus.draft,
    this.notes,
    this.deletedAt,
    required this.createdAt,
  });

  // Supabase INSERT — omit id, created_at (DB defaults).
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        if (vendorId != null) 'vendor_id': vendorId,
        'created_by_user_id': createdByUserId,
        'expense_date': expenseDate.toUtc().toIso8601String(),
        'description': description,
        'amount': amount,
        'tax_amount': taxAmount,
        'total': total,
        'category': category.dbValue,
        'payment_method': paymentMethod.dbValue,
        if (receiptStoragePath != null)
          'receipt_storage_path': receiptStoragePath,
        if (receiptUrl != null) 'receipt_url': receiptUrl,
        'ocr_status': ocrStatus.dbValue,
        'status': status.dbValue,
        if (notes != null) 'notes': notes,
      };

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    return ExpenseRecord(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      vendorId: json['vendor_id'] as String?,
      createdByUserId: json['created_by_user_id'] as String? ?? '',
      expenseDate: _parseDate(json['expense_date']),
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      category: ExpenseCategory.fromString(json['category'] as String?),
      paymentMethod:
          ExpensePaymentMethod.fromString(json['payment_method'] as String?),
      receiptStoragePath: json['receipt_storage_path'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      ocrStatus: ExpenseOcrStatus.fromString(json['ocr_status'] as String?),
      status: ExpenseStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      deletedAt: _parseOptionalDate(json['deleted_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  ExpenseRecord copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? vendorId,
    String? createdByUserId,
    DateTime? expenseDate,
    String? description,
    double? amount,
    double? taxAmount,
    double? total,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    String? receiptStoragePath,
    String? receiptUrl,
    ExpenseOcrStatus? ocrStatus,
    ExpenseStatus? status,
    String? notes,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      vendorId: vendorId ?? this.vendorId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptStoragePath: receiptStoragePath ?? this.receiptStoragePath,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deletedAt: deletedAt,
      createdAt: createdAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
