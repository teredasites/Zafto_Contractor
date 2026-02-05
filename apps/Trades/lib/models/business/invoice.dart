/// ZAFTO Business Models - Invoice
/// Sprint 5.0 - January 2026

enum InvoiceStatus { draft, sent, viewed, paid, overdue, cancelled }

class Invoice {
  final String id;
  final String? jobId;
  final String? customerId;
  final String invoiceNumber;
  final String? customerName;
  final String? customerEmail;
  final InvoiceStatus status;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    this.jobId,
    this.customerId,
    required this.invoiceNumber,
    this.customerName,
    this.customerEmail,
    this.status = InvoiceStatus.draft,
    this.lineItems = const [],
    this.subtotal = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.total = 0,
    required this.issueDate,
    required this.dueDate,
    this.paidDate,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Balance due - for this simple model, same as total unless paid
  double get balanceDue => status == InvoiceStatus.paid ? 0 : total;

  Invoice copyWith({
    String? id, String? jobId, String? customerId, String? invoiceNumber,
    String? customerName, String? customerEmail, InvoiceStatus? status,
    List<InvoiceLineItem>? lineItems, double? subtotal, double? taxRate,
    double? taxAmount, double? total, DateTime? issueDate, DateTime? dueDate,
    DateTime? paidDate, String? paymentMethod, String? notes,
    DateTime? createdAt, DateTime? updatedAt,
  }) => Invoice(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    customerId: customerId ?? this.customerId,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    customerName: customerName ?? this.customerName,
    customerEmail: customerEmail ?? this.customerEmail,
    status: status ?? this.status,
    lineItems: lineItems ?? this.lineItems,
    subtotal: subtotal ?? this.subtotal,
    taxRate: taxRate ?? this.taxRate,
    taxAmount: taxAmount ?? this.taxAmount,
    total: total ?? this.total,
    issueDate: issueDate ?? this.issueDate,
    dueDate: dueDate ?? this.dueDate,
    paidDate: paidDate ?? this.paidDate,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'jobId': jobId, 'customerId': customerId,
    'invoiceNumber': invoiceNumber, 'customerName': customerName,
    'customerEmail': customerEmail, 'status': status.name,
    'lineItems': lineItems.map((e) => e.toJson()).toList(),
    'subtotal': subtotal, 'taxRate': taxRate, 'taxAmount': taxAmount,
    'total': total, 'issueDate': issueDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'paidDate': paidDate?.toIso8601String(),
    'paymentMethod': paymentMethod, 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'] as String,
    jobId: json['jobId'] as String?,
    customerId: json['customerId'] as String?,
    invoiceNumber: json['invoiceNumber'] as String,
    customerName: json['customerName'] as String?,
    customerEmail: json['customerEmail'] as String?,
    status: InvoiceStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => InvoiceStatus.draft),
    lineItems: (json['lineItems'] as List<dynamic>?)?.map((e) => InvoiceLineItem.fromJson(e)).toList() ?? [],
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
    taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    issueDate: DateTime.parse(json['issueDate']),
    dueDate: DateTime.parse(json['dueDate']),
    paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
    paymentMethod: json['paymentMethod'] as String?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  String get statusLabel => switch (status) {
    InvoiceStatus.draft => 'Draft',
    InvoiceStatus.sent => 'Sent',
    InvoiceStatus.viewed => 'Viewed',
    InvoiceStatus.paid => 'Paid',
    InvoiceStatus.overdue => 'Overdue',
    InvoiceStatus.cancelled => 'Cancelled',
  };

  bool get isPaid => status == InvoiceStatus.paid;
  bool get isOverdue => status == InvoiceStatus.overdue || (status == InvoiceStatus.sent && DateTime.now().isAfter(dueDate));
}

class InvoiceLineItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  const InvoiceLineItem({
    required this.id,
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    double? total,
  }) : total = total ?? (quantity * unitPrice);

  Map<String, dynamic> toJson() => {
    'id': id, 'description': description, 'quantity': quantity,
    'unitPrice': unitPrice, 'total': total,
  };

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) => InvoiceLineItem(
    id: json['id'] as String,
    description: json['description'] as String,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble(),
  );
}
