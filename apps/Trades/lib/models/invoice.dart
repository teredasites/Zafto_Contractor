import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Invoice status with approval workflow
enum InvoiceStatus {
  draft,           // Being created
  pendingApproval, // Waiting for manager approval (Growing+ tiers)
  approved,        // Approved, ready to send
  rejected,        // Rejected, needs revision
  sent,            // Sent to customer
  viewed,          // Customer opened it
  partiallyPaid,   // Partial payment received
  paid,            // Fully paid
  voided,          // Voided/cancelled
  overdue          // Past due date
}

/// Single line item on an invoice
class LineItem extends Equatable {
  final String id;
  final String description;
  final double quantity;
  final String unit; // 'each', 'hour', 'foot'
  final double unitPrice;
  final double total;
  final bool isTaxable;

  const LineItem({
    required this.id,
    required this.description,
    required this.quantity,
    this.unit = 'each',
    required this.unitPrice,
    required this.total,
    this.isTaxable = true,
  });

  @override
  List<Object?> get props => [id, description, quantity, unitPrice];

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'total': total,
        'isTaxable': isTaxable,
      };

  factory LineItem.fromMap(Map<String, dynamic> map) => LineItem(
        id: map['id'] as String,
        description: map['description'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'each',
        unitPrice: (map['unitPrice'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        isTaxable: map['isTaxable'] as bool? ?? true,
      );

  LineItem copyWith({
    String? id,
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? total,
    bool? isTaxable,
  }) {
    return LineItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      isTaxable: isTaxable ?? this.isTaxable,
    );
  }
}

/// Invoice model with approval workflow support
class Invoice extends Equatable {
  final String id;
  final String companyId;
  final String createdByUserId;
  final String? jobId;

  // Invoice Number
  final String invoiceNumber;

  // Customer (denormalized for PDF generation)
  final String? customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String customerAddress;

  // Line Items
  final List<LineItem> lineItems;

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

  // Approval Workflow (Growing+ tiers)
  final bool requiresApproval;
  final String? approvedByUserId;
  final DateTime? approvedAt;
  final String? rejectionReason;

  // Sending
  final DateTime? sentAt;
  final String? sentVia; // 'email', 'sms', 'both'
  final DateTime? viewedAt;

  // Payment
  final DateTime? paidAt;
  final String? paymentMethod; // 'cash', 'check', 'card', 'other'
  final String? paymentReference; // Check #, transaction ID

  // Signature
  final String? signatureData; // Base64 PNG
  final String? signedByName;
  final DateTime? signedAt;

  // PDF
  final String? pdfPath; // Local path
  final String? pdfUrl; // Cloud URL

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final String? notes;
  final String? terms;

  const Invoice({
    required this.id,
    required this.companyId,
    required this.createdByUserId,
    this.jobId,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.customerAddress,
    this.lineItems = const [],
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.discountReason,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.total = 0.0,
    this.amountPaid = 0.0,
    this.amountDue = 0.0,
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
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.notes,
    this.terms,
  });

  @override
  List<Object?> get props => [id, companyId, invoiceNumber, status, updatedAt];

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// Check if invoice is editable
  bool get isEditable =>
      status == InvoiceStatus.draft ||
      status == InvoiceStatus.rejected;

  /// Check if invoice can be sent
  bool get canSend =>
      status == InvoiceStatus.approved ||
      (status == InvoiceStatus.draft && !requiresApproval);

  /// Check if invoice is paid
  bool get isPaid =>
      status == InvoiceStatus.paid || status == InvoiceStatus.partiallyPaid;

  /// Alias for amountDue
  double get balanceDue => amountDue;

  /// Check if invoice is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == InvoiceStatus.paid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if invoice has signature
  bool get hasSigned => signatureData != null && signedByName != null;

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.pendingApproval:
        return 'Pending Approval';
      case InvoiceStatus.approved:
        return 'Approved';
      case InvoiceStatus.rejected:
        return 'Rejected';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.viewed:
        return 'Viewed';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.voided:
        return 'Voided';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }

  /// Format amount due for display
  String get amountDueDisplay => '\$${amountDue.toStringAsFixed(2)}';

  /// Format total for display
  String get totalDisplay => '\$${total.toStringAsFixed(2)}';

  // ============================================================
  // CALCULATIONS
  // ============================================================

  /// Recalculate totals from line items
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
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'createdByUserId': createdByUserId,
      'jobId': jobId,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'lineItems': lineItems.map((e) => e.toMap()).toList(),
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'notes': notes,
      'terms': terms,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      createdByUserId: map['createdByUserId'] as String,
      jobId: map['jobId'] as String?,
      invoiceNumber: map['invoiceNumber'] as String,
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String,
      customerEmail: map['customerEmail'] as String?,
      customerPhone: map['customerPhone'] as String?,
      customerAddress: map['customerAddress'] as String,
      lineItems: (map['lineItems'] as List<dynamic>?)
              ?.map((e) => LineItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      discountReason: map['discountReason'] as String?,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      amountDue: (map['amountDue'] as num?)?.toDouble() ?? 0.0,
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      requiresApproval: map['requiresApproval'] as bool? ?? false,
      approvedByUserId: map['approvedByUserId'] as String?,
      approvedAt: map['approvedAt'] != null
          ? _parseDateTime(map['approvedAt'])
          : null,
      rejectionReason: map['rejectionReason'] as String?,
      sentAt: map['sentAt'] != null ? _parseDateTime(map['sentAt']) : null,
      sentVia: map['sentVia'] as String?,
      viewedAt:
          map['viewedAt'] != null ? _parseDateTime(map['viewedAt']) : null,
      paidAt: map['paidAt'] != null ? _parseDateTime(map['paidAt']) : null,
      paymentMethod: map['paymentMethod'] as String?,
      paymentReference: map['paymentReference'] as String?,
      signatureData: map['signatureData'] as String?,
      signedByName: map['signedByName'] as String?,
      signedAt:
          map['signedAt'] != null ? _parseDateTime(map['signedAt']) : null,
      pdfPath: map['pdfPath'] as String?,
      pdfUrl: map['pdfUrl'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      dueDate: map['dueDate'] != null ? _parseDateTime(map['dueDate']) : null,
      notes: map['notes'] as String?,
      terms: map['terms'] as String?,
    );
  }

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice.fromMap({...data, 'id': doc.id});
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Invoice copyWith({
    String? id,
    String? companyId,
    String? createdByUserId,
    String? jobId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    List<LineItem>? lineItems,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    String? notes,
    String? terms,
  }) {
    return Invoice(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      jobId: jobId ?? this.jobId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  /// Create a new invoice from a job
  factory Invoice.fromJob({
    required String id,
    required String companyId,
    required String createdByUserId,
    required String invoiceNumber,
    required String jobId,
    required String customerName,
    required String customerAddress,
    String? customerId,
    String? customerEmail,
    String? customerPhone,
    double taxRate = 0.0,
  }) {
    final now = DateTime.now();
    return Invoice(
      id: id,
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
      dueDate: now.add(const Duration(days: 30)), // Net 30
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a standalone invoice (not linked to job)
  factory Invoice.create({
    required String id,
    required String companyId,
    required String createdByUserId,
    required String invoiceNumber,
    required String customerName,
    required String customerAddress,
    String? customerId,
    double taxRate = 0.0,
  }) {
    final now = DateTime.now();
    return Invoice(
      id: id,
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
