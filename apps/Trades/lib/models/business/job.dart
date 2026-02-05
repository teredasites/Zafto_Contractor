/// ZAFTO Business Models - Job
/// Sprint 5.0 - January 2026

enum JobStatus { lead, scheduled, inProgress, completed, invoiced, cancelled }

class Job {
  final String id;
  final String? customerId;
  final String title;
  final String? customerName;
  final String? address;
  final JobStatus status;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final double estimatedAmount;
  final double? actualAmount;
  final String? notes;
  final List<String> photoUrls;
  final List<JobLineItem> lineItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Job({
    required this.id,
    this.customerId,
    required this.title,
    this.customerName,
    this.address,
    this.status = JobStatus.lead,
    this.scheduledDate,
    this.completedDate,
    this.estimatedAmount = 0,
    this.actualAmount,
    this.notes,
    this.photoUrls = const [],
    this.lineItems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Job copyWith({
    String? id,
    String? customerId,
    String? title,
    String? customerName,
    String? address,
    JobStatus? status,
    DateTime? scheduledDate,
    DateTime? completedDate,
    double? estimatedAmount,
    double? actualAmount,
    String? notes,
    List<String>? photoUrls,
    List<JobLineItem>? lineItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      lineItems: lineItems ?? this.lineItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'title': title,
    'customerName': customerName,
    'address': address,
    'status': status.name,
    'scheduledDate': scheduledDate?.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
    'estimatedAmount': estimatedAmount,
    'actualAmount': actualAmount,
    'notes': notes,
    'photoUrls': photoUrls,
    'lineItems': lineItems.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id'] as String,
    customerId: json['customerId'] as String?,
    title: json['title'] as String,
    customerName: json['customerName'] as String?,
    address: json['address'] as String?,
    status: JobStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => JobStatus.lead),
    scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
    completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
    estimatedAmount: (json['estimatedAmount'] as num?)?.toDouble() ?? 0,
    actualAmount: (json['actualAmount'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
    photoUrls: (json['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
    lineItems: (json['lineItems'] as List<dynamic>?)?.map((e) => JobLineItem.fromJson(e)).toList() ?? [],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  String get statusLabel => switch (status) {
    JobStatus.lead => 'Lead',
    JobStatus.scheduled => 'Scheduled',
    JobStatus.inProgress => 'In Progress',
    JobStatus.completed => 'Completed',
    JobStatus.invoiced => 'Invoiced',
    JobStatus.cancelled => 'Cancelled',
  };

  bool get isActive => status == JobStatus.scheduled || status == JobStatus.inProgress;
}

class JobLineItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  const JobLineItem({
    required this.id,
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    double? total,
  }) : total = total ?? (quantity * unitPrice);

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'total': total,
  };

  factory JobLineItem.fromJson(Map<String, dynamic> json) => JobLineItem(
    id: json['id'] as String,
    description: json['description'] as String,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble(),
  );
}
