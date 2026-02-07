// ZAFTO Invoice Model — Supabase Schema
// Rewritten: Sprint B1d (Session 42)
//
// Matches public.invoices table exactly.
// Replaces both models/invoice.dart (Firebase) and models/business/invoice.dart.

enum InvoiceStatus {
  draft,
  pendingApproval,
  approved,
  rejected,
  sent,
  viewed,
  partiallyPaid,
  paid,
  voided,
  overdue,
}

// Payment source for insurance/warranty invoice line items
enum PaymentSource {
  standard,   // Normal retail — no insurance involvement
  carrier,    // Insurance company pays (approved estimate scope)
  deductible, // Homeowner pays (their deductible portion)
  upgrade,    // Homeowner pays (upgrade beyond pre-loss condition)
}

class InvoiceLineItem {
  final String id;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double total;
  final bool isTaxable;
  final PaymentSource paymentSource;

  const InvoiceLineItem({
    required this.id,
    required this.description,
    this.quantity = 1,
    this.unit = 'each',
    required this.unitPrice,
    double? total,
    this.isTaxable = true,
    this.paymentSource = PaymentSource.standard,
  }) : total = total ?? (quantity * unitPrice);

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'total': total,
        'isTaxable': isTaxable,
        'paymentSource': paymentSource.name,
      };

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) =>
      InvoiceLineItem(
        id: json['id'] as String? ?? '',
        description: json['description'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unit: json['unit'] as String? ?? 'each',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble(),
        isTaxable: json['isTaxable'] as bool? ?? true,
        paymentSource: _parsePaymentSource(json['paymentSource'] as String?),
      );

  static PaymentSource _parsePaymentSource(String? value) {
    if (value == null) return PaymentSource.standard;
    return PaymentSource.values.asNameMap()[value] ?? PaymentSource.standard;
  }

  InvoiceLineItem copyWith({
    String? id,
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? total,
    bool? isTaxable,
    PaymentSource? paymentSource,
  }) {
    return InvoiceLineItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      isTaxable: isTaxable ?? this.isTaxable,
      paymentSource: paymentSource ?? this.paymentSource,
    );
  }

  InvoiceLineItem recalculate() => copyWith(total: quantity * unitPrice);
}

// Backward compat alias for code that referenced LineItem directly.
typedef LineItem = InvoiceLineItem;

class Invoice {
  final String id;
  final String companyId;
  final String createdByUserId;
  final String? jobId;
  final String? customerId;
  final String invoiceNumber;

  // Customer (denormalized for PDF)
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String customerAddress;

  // Line items (stored as JSONB in DB)
  final List<InvoiceLineItem> lineItems;

  // Totals
  final double subtotal;
  final double discountAmount;
  final String? discountReason;
  final double taxRate;
  final double taxAmount;
  final double total;
  final double amountPaid;
  final double amountDue;

  // Status
  final InvoiceStatus status;

  // Approval workflow
  final bool requiresApproval;
  final String? approvedByUserId;
  final DateTime? approvedAt;
  final String? rejectionReason;

  // Sending
  final DateTime? sentAt;
  final String? sentVia;
  final DateTime? viewedAt;

  // Payment
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? paymentReference;

  // Signature
  final String? signatureData;
  final String? signedByName;
  final DateTime? signedAt;

  // PDF
  final String? pdfPath;
  final String? pdfUrl;

  // Dates
  final DateTime? dueDate;
  final String? notes;
  final String? terms;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Invoice({
    this.id = '',
    this.companyId = '',
    this.createdByUserId = '',
    this.jobId,
    this.customerId,
    this.invoiceNumber = '',
    this.customerName = '',
    this.customerEmail,
    this.customerPhone,
    this.customerAddress = '',
    this.lineItems = const [],
    this.subtotal = 0,
    this.discountAmount = 0,
    this.discountReason,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.total = 0,
    this.amountPaid = 0,
    this.amountDue = 0,
    this.status = InvoiceStatus.draft,
    this.requiresApproval = false,
    this.approvedByUserId,
    this.approvedAt,
    this.rejectionReason,
    this.sentAt,
    this.sentVia,
    this.viewedAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentReference,
    this.signatureData,
    this.signedByName,
    this.signedAt,
    this.pdfPath,
    this.pdfUrl,
    this.dueDate,
    this.notes,
    this.terms,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ============================================================
  // SERIALIZATION
  // ============================================================

  // Generic JSON output (camelCase for legacy code).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'createdByUserId': createdByUserId,
      'jobId': jobId,
      'customerId': customerId,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'lineItems': lineItems.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'discountReason': discountReason,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'amountPaid': amountPaid,
      'amountDue': amountDue,
      'status': status.name,
      'requiresApproval': requiresApproval,
      'approvedByUserId': approvedByUserId,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'sentAt': sentAt?.toIso8601String(),
      'sentVia': sentVia,
      'viewedAt': viewedAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'signatureData': signatureData,
      'signedByName': signedByName,
      'signedAt': signedAt?.toIso8601String(),
      'pdfPath': pdfPath,
      'pdfUrl': pdfUrl,
      'dueDate': dueDate?.toIso8601String(),
      'notes': notes,
      'terms': terms,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Insert payload (snake_case for Supabase).
  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      'created_by_user_id': createdByUserId,
      'job_id': jobId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'line_items': lineItems.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'discount_reason': discountReason,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'amount_paid': amountPaid,
      'amount_due': amountDue,
      'status': status.name,
      'requires_approval': requiresApproval,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'notes': notes,
      'terms': terms,
    };
  }

  // Update payload (snake_case for Supabase).
  Map<String, dynamic> toUpdateJson() {
    return {
      'job_id': jobId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'line_items': lineItems.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'discount_reason': discountReason,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'amount_paid': amountPaid,
      'amount_due': amountDue,
      'status': status.name,
      'requires_approval': requiresApproval,
      'approved_by_user_id': approvedByUserId,
      'approved_at': approvedAt?.toUtc().toIso8601String(),
      'rejection_reason': rejectionReason,
      'sent_at': sentAt?.toUtc().toIso8601String(),
      'sent_via': sentVia,
      'viewed_at': viewedAt?.toUtc().toIso8601String(),
      'paid_at': paidAt?.toUtc().toIso8601String(),
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'signature_data': signatureData,
      'signed_by_name': signedByName,
      'signed_at': signedAt?.toUtc().toIso8601String(),
      'pdf_path': pdfPath,
      'pdf_url': pdfUrl,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'notes': notes,
      'terms': terms,
    };
  }

  // Handles both snake_case (Supabase) and camelCase (legacy).
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      createdByUserId:
          (json['created_by_user_id'] ?? json['createdByUserId'])
              as String? ??
              '',
      jobId: (json['job_id'] ?? json['jobId']) as String?,
      customerId:
          (json['customer_id'] ?? json['customerId']) as String?,
      invoiceNumber:
          (json['invoice_number'] ?? json['invoiceNumber'])
              as String? ??
              '',
      customerName:
          (json['customer_name'] ?? json['customerName'])
              as String? ??
              '',
      customerEmail:
          (json['customer_email'] ?? json['customerEmail'])
              as String?,
      customerPhone:
          (json['customer_phone'] ?? json['customerPhone'])
              as String?,
      customerAddress:
          (json['customer_address'] ?? json['customerAddress'])
              as String? ??
              '',
      lineItems: _parseLineItems(
          json['line_items'] ?? json['lineItems']),
      subtotal:
          ((json['subtotal'] as num?)?.toDouble()) ?? 0,
      discountAmount:
          ((json['discount_amount'] ?? json['discountAmount'])
                  as num?)
              ?.toDouble() ??
              0,
      discountReason:
          (json['discount_reason'] ?? json['discountReason'])
              as String?,
      taxRate:
          ((json['tax_rate'] ?? json['taxRate']) as num?)
              ?.toDouble() ??
              0,
      taxAmount:
          ((json['tax_amount'] ?? json['taxAmount']) as num?)
              ?.toDouble() ??
              0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      amountPaid:
          ((json['amount_paid'] ?? json['amountPaid']) as num?)
              ?.toDouble() ??
              0,
      amountDue:
          ((json['amount_due'] ?? json['amountDue']) as num?)
              ?.toDouble() ??
              0,
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      requiresApproval:
          (json['requires_approval'] ?? json['requiresApproval'])
              as bool? ??
              false,
      approvedByUserId:
          (json['approved_by_user_id'] ?? json['approvedByUserId'])
              as String?,
      approvedAt: _parseOptionalDate(
          json['approved_at'] ?? json['approvedAt']),
      rejectionReason:
          (json['rejection_reason'] ?? json['rejectionReason'])
              as String?,
      sentAt: _parseOptionalDate(
          json['sent_at'] ?? json['sentAt']),
      sentVia:
          (json['sent_via'] ?? json['sentVia']) as String?,
      viewedAt: _parseOptionalDate(
          json['viewed_at'] ?? json['viewedAt']),
      paidAt: _parseOptionalDate(
          json['paid_at'] ?? json['paidAt'] ?? json['paidDate']),
      paymentMethod:
          (json['payment_method'] ?? json['paymentMethod'])
              as String?,
      paymentReference:
          (json['payment_reference'] ?? json['paymentReference'])
              as String?,
      signatureData:
          (json['signature_data'] ?? json['signatureData'])
              as String?,
      signedByName:
          (json['signed_by_name'] ?? json['signedByName'])
              as String?,
      signedAt: _parseOptionalDate(
          json['signed_at'] ?? json['signedAt']),
      pdfPath:
          (json['pdf_path'] ?? json['pdfPath']) as String?,
      pdfUrl:
          (json['pdf_url'] ?? json['pdfUrl']) as String?,
      dueDate: _parseOptionalDate(
          json['due_date'] ?? json['dueDate']),
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      createdAt: _parseDate(
          json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(
          json['updated_at'] ?? json['updatedAt']),
      deletedAt: _parseOptionalDate(
          json['deleted_at'] ?? json['deletedAt']),
    );
  }

  static List<InvoiceLineItem> _parseLineItems(dynamic data) {
    if (data == null) return const [];
    if (data is List) {
      return data
          .map((e) =>
              InvoiceLineItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  String get statusLabel => switch (status) {
        InvoiceStatus.draft => 'Draft',
        InvoiceStatus.pendingApproval => 'Pending Approval',
        InvoiceStatus.approved => 'Approved',
        InvoiceStatus.rejected => 'Rejected',
        InvoiceStatus.sent => 'Sent',
        InvoiceStatus.viewed => 'Viewed',
        InvoiceStatus.partiallyPaid => 'Partially Paid',
        InvoiceStatus.paid => 'Paid',
        InvoiceStatus.voided => 'Voided',
        InvoiceStatus.overdue => 'Overdue',
      };

  // Alias for screens that used statusDisplay.
  String get statusDisplay => statusLabel;

  bool get isPaid =>
      status == InvoiceStatus.paid ||
      status == InvoiceStatus.partiallyPaid;

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == InvoiceStatus.paid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isEditable =>
      status == InvoiceStatus.draft ||
      status == InvoiceStatus.rejected;

  bool get canSend =>
      status == InvoiceStatus.approved ||
      (status == InvoiceStatus.draft && !requiresApproval);

  double get balanceDue => amountDue;

  bool get hasSigned =>
      signatureData != null && signedByName != null;

  String get amountDueDisplay =>
      '\$${amountDue.toStringAsFixed(2)}';

  String get totalDisplay => '\$${total.toStringAsFixed(2)}';

  // ============================================================
  // CALCULATIONS
  // ============================================================

  Invoice recalculate() {
    final newSubtotal = lineItems.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );
    final taxableAmount = lineItems
        .where((item) => item.isTaxable)
        .fold<double>(0.0, (sum, item) => sum + item.total);
    final newTaxAmount = taxableAmount * (taxRate / 100);
    final newTotal = newSubtotal - discountAmount + newTaxAmount;
    final newAmountDue = newTotal - amountPaid;

    return copyWith(
      subtotal: newSubtotal,
      taxAmount: newTaxAmount,
      total: newTotal,
      amountDue: newAmountDue,
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Invoice copyWith({
    String? id,
    String? companyId,
    String? createdByUserId,
    String? jobId,
    String? customerId,
    String? invoiceNumber,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    List<InvoiceLineItem>? lineItems,
    double? subtotal,
    double? discountAmount,
    String? discountReason,
    double? taxRate,
    double? taxAmount,
    double? total,
    double? amountPaid,
    double? amountDue,
    InvoiceStatus? status,
    bool? requiresApproval,
    String? approvedByUserId,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? sentAt,
    String? sentVia,
    DateTime? viewedAt,
    DateTime? paidAt,
    String? paymentMethod,
    String? paymentReference,
    String? signatureData,
    String? signedByName,
    DateTime? signedAt,
    String? pdfPath,
    String? pdfUrl,
    DateTime? dueDate,
    String? notes,
    String? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountReason: discountReason ?? this.discountReason,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      amountPaid: amountPaid ?? this.amountPaid,
      amountDue: amountDue ?? this.amountDue,
      status: status ?? this.status,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      sentAt: sentAt ?? this.sentAt,
      sentVia: sentVia ?? this.sentVia,
      viewedAt: viewedAt ?? this.viewedAt,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      signatureData: signatureData ?? this.signatureData,
      signedByName: signedByName ?? this.signedByName,
      signedAt: signedAt ?? this.signedAt,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  factory Invoice.fromJob({
    required String companyId,
    required String createdByUserId,
    required String invoiceNumber,
    required String jobId,
    required String customerName,
    required String customerAddress,
    String? customerId,
    String? customerEmail,
    String? customerPhone,
    double taxRate = 0,
  }) {
    final now = DateTime.now();
    return Invoice(
      companyId: companyId,
      createdByUserId: createdByUserId,
      jobId: jobId,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      taxRate: taxRate,
      dueDate: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Invoice.create({
    required String companyId,
    required String createdByUserId,
    required String invoiceNumber,
    required String customerName,
    required String customerAddress,
    String? customerId,
    double taxRate = 0,
  }) {
    final now = DateTime.now();
    return Invoice(
      companyId: companyId,
      createdByUserId: createdByUserId,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      customerAddress: customerAddress,
      taxRate: taxRate,
      dueDate: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );
  }
}
