// ZAFTO Receipt Model — Supabase Backend
// Maps to `receipts` table in Supabase PostgreSQL.
// Stores scanned/uploaded receipts with optional OCR data.

enum ReceiptCategory {
  materials,
  tools,
  fuel,
  meals,
  equipment,
  permits,
  subcontractor,
  other;

  String get dbValue => name;

  String get label {
    switch (this) {
      case ReceiptCategory.materials:
        return 'Materials';
      case ReceiptCategory.tools:
        return 'Tools';
      case ReceiptCategory.fuel:
        return 'Fuel';
      case ReceiptCategory.meals:
        return 'Meals';
      case ReceiptCategory.equipment:
        return 'Equipment';
      case ReceiptCategory.permits:
        return 'Permits';
      case ReceiptCategory.subcontractor:
        return 'Subcontractor';
      case ReceiptCategory.other:
        return 'Other';
    }
  }

  static ReceiptCategory fromString(String? value) {
    if (value == null) return ReceiptCategory.other;
    return ReceiptCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ReceiptCategory.other,
    );
  }
}

enum OcrStatus {
  pending,
  processing,
  completed,
  failed;

  String get dbValue => name;

  static OcrStatus fromString(String? value) {
    if (value == null) return OcrStatus.pending;
    return OcrStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OcrStatus.pending,
    );
  }
}

class Receipt {
  final String id;
  final String companyId;
  final String? jobId;
  final String uploadedByUserId;
  final String? storagePath;
  final String vendorName;
  final double amount;
  final ReceiptCategory category;
  final String description;
  final DateTime receiptDate;
  final Map<String, dynamic> ocrData;
  final OcrStatus ocrStatus;
  final String? paymentMethod;
  final DateTime? deletedAt;
  final DateTime createdAt;

  const Receipt({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.uploadedByUserId = '',
    this.storagePath,
    this.vendorName = '',
    this.amount = 0,
    this.category = ReceiptCategory.other,
    this.description = '',
    required this.receiptDate,
    this.ocrData = const {},
    this.ocrStatus = OcrStatus.pending,
    this.paymentMethod,
    this.deletedAt,
    required this.createdAt,
  });

  // Supabase INSERT — omit id, created_at (DB defaults)
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        'uploaded_by_user_id': uploadedByUserId,
        if (storagePath != null) 'storage_path': storagePath,
        'vendor_name': vendorName,
        'amount': amount,
        'category': category.dbValue,
        'description': description,
        'receipt_date': receiptDate.toUtc().toIso8601String(),
        'ocr_data': ocrData,
        'ocr_status': ocrStatus.dbValue,
        if (paymentMethod != null) 'payment_method': paymentMethod,
      };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      uploadedByUserId: json['uploaded_by_user_id'] as String? ?? '',
      storagePath: json['storage_path'] as String?,
      vendorName: json['vendor_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: ReceiptCategory.fromString(json['category'] as String?),
      description: json['description'] as String? ?? '',
      receiptDate: _parseDate(json['receipt_date']),
      ocrData: (json['ocr_data'] as Map<String, dynamic>?) ?? const {},
      ocrStatus: OcrStatus.fromString(json['ocr_status'] as String?),
      paymentMethod: json['payment_method'] as String?,
      deletedAt: _parseOptionalDate(json['deleted_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Receipt copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? uploadedByUserId,
    String? storagePath,
    String? vendorName,
    double? amount,
    ReceiptCategory? category,
    String? description,
    DateTime? receiptDate,
    Map<String, dynamic>? ocrData,
    OcrStatus? ocrStatus,
    String? paymentMethod,
  }) {
    return Receipt(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      storagePath: storagePath ?? this.storagePath,
      vendorName: vendorName ?? this.vendorName,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      receiptDate: receiptDate ?? this.receiptDate,
      ocrData: ocrData ?? this.ocrData,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
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
