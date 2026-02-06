// ZAFTO Job Model — Supabase Schema
// Rewritten: Sprint B1c (Session 41)
//
// Matches public.jobs table exactly.
// Replaces both models/job.dart (Firebase) and models/business/job.dart.

enum JobStatus {
  draft,
  scheduled,
  dispatched,
  enRoute,
  inProgress,
  onHold,
  completed,
  invoiced,
  cancelled,
}

enum JobPriority { low, normal, high, urgent }

enum JobType {
  standard,
  insuranceClaim,
  warrantyDispatch;

  String get dbValue => switch (this) {
        JobType.standard => 'standard',
        JobType.insuranceClaim => 'insurance_claim',
        JobType.warrantyDispatch => 'warranty_dispatch',
      };
}

class Job {
  final String id;
  final String companyId;
  final String createdByUserId;

  // Relationships
  final String? customerId;
  final String? assignedToUserId;
  final List<String> assignedUserIds;
  final String? teamId;

  // Details
  final String? title;
  final String? description;
  final String? internalNotes;
  final String tradeType;

  // Customer (denormalized for offline)
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;

  // Location
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;

  // Status
  final JobStatus status;
  final JobPriority priority;
  final JobType jobType;
  final Map<String, dynamic> typeMetadata;

  // Scheduling
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final int? estimatedDuration; // minutes
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Financial
  final double estimatedAmount;
  final double? actualAmount;

  // Tags
  final List<String> tags;

  // Links
  final String? invoiceId;
  final String? quoteId;

  // Sync
  final bool syncedToCloud;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Job({
    this.id = '',
    this.companyId = '',
    this.createdByUserId = '',
    this.customerId,
    this.assignedToUserId,
    this.assignedUserIds = const [],
    this.teamId,
    this.title,
    this.description,
    this.internalNotes,
    this.tradeType = 'electrical',
    this.customerName = '',
    this.customerEmail,
    this.customerPhone,
    this.address = '',
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.status = JobStatus.draft,
    this.priority = JobPriority.normal,
    this.jobType = JobType.standard,
    this.typeMetadata = const {},
    this.scheduledStart,
    this.scheduledEnd,
    this.estimatedDuration,
    this.startedAt,
    this.completedAt,
    this.estimatedAmount = 0,
    this.actualAmount,
    this.tags = const [],
    this.invoiceId,
    this.quoteId,
    this.syncedToCloud = false,
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
      'customerId': customerId,
      'assignedToUserId': assignedToUserId,
      'title': title,
      'customerName': customerName,
      'address': address,
      'status': status.name,
      'priority': priority.name,
      'scheduledDate': scheduledStart?.toIso8601String(),
      'completedDate': completedAt?.toIso8601String(),
      'estimatedAmount': estimatedAmount,
      'actualAmount': actualAmount,
      'notes': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Insert payload (snake_case for Supabase).
  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      'created_by_user_id': createdByUserId,
      'customer_id': customerId,
      'assigned_to_user_id': assignedToUserId,
      'assigned_user_ids': assignedUserIds,
      'team_id': teamId,
      'title': title,
      'description': description,
      'internal_notes': internalNotes,
      'trade_type': tradeType,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'priority': priority.name,
      'job_type': jobType.dbValue,
      'type_metadata': typeMetadata,
      'scheduled_start': scheduledStart?.toUtc().toIso8601String(),
      'scheduled_end': scheduledEnd?.toUtc().toIso8601String(),
      'estimated_duration': estimatedDuration,
      'estimated_amount': estimatedAmount,
      'tags': tags,
    };
  }

  // Update payload (snake_case for Supabase).
  Map<String, dynamic> toUpdateJson() {
    return {
      'customer_id': customerId,
      'assigned_to_user_id': assignedToUserId,
      'assigned_user_ids': assignedUserIds,
      'team_id': teamId,
      'title': title,
      'description': description,
      'internal_notes': internalNotes,
      'trade_type': tradeType,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'priority': priority.name,
      'job_type': jobType.dbValue,
      'type_metadata': typeMetadata,
      'scheduled_start': scheduledStart?.toUtc().toIso8601String(),
      'scheduled_end': scheduledEnd?.toUtc().toIso8601String(),
      'estimated_duration': estimatedDuration,
      'started_at': startedAt?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'estimated_amount': estimatedAmount,
      'actual_amount': actualAmount,
      'tags': tags,
      'invoice_id': invoiceId,
      'quote_id': quoteId,
    };
  }

  // Handles both snake_case (Supabase) and camelCase (legacy).
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String? ?? '',
      companyId: (json['company_id'] ?? json['companyId']) as String? ?? '',
      createdByUserId:
          (json['created_by_user_id'] ?? json['createdByUserId']) as String? ??
              '',
      customerId:
          (json['customer_id'] ?? json['customerId']) as String?,
      assignedToUserId:
          (json['assigned_to_user_id'] ?? json['assignedToUserId']) as String?,
      assignedUserIds: (json['assigned_user_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      teamId: (json['team_id'] ?? json['teamId']) as String?,
      title: json['title'] as String?,
      description: (json['description'] ?? json['notes']) as String?,
      internalNotes:
          (json['internal_notes'] ?? json['internalNotes']) as String?,
      tradeType:
          (json['trade_type'] ?? json['tradeType']) as String? ?? 'electrical',
      customerName:
          (json['customer_name'] ?? json['customerName']) as String? ?? '',
      customerEmail:
          (json['customer_email'] ?? json['customerEmail']) as String?,
      customerPhone:
          (json['customer_phone'] ?? json['customerPhone']) as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: (json['zip_code'] ?? json['zipCode']) as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: _parseJobStatus(json['status'] as String?),
      priority: JobPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => JobPriority.normal,
      ),
      jobType: _parseJobType(
          (json['job_type'] ?? json['jobType']) as String?),
      typeMetadata: (json['type_metadata'] ?? json['typeMetadata'])
              as Map<String, dynamic>? ??
          const {},
      scheduledStart: _parseOptionalDate(
          json['scheduled_start'] ?? json['scheduledStart'] ?? json['scheduledDate']),
      scheduledEnd: _parseOptionalDate(
          json['scheduled_end'] ?? json['scheduledEnd']),
      estimatedDuration:
          ((json['estimated_duration'] ?? json['estimatedDuration']) as num?)
              ?.toInt(),
      startedAt: _parseOptionalDate(
          json['started_at'] ?? json['startedAt']),
      completedAt: _parseOptionalDate(
          json['completed_at'] ?? json['completedAt'] ?? json['completedDate']),
      estimatedAmount:
          ((json['estimated_amount'] ?? json['estimatedAmount']) as num?)
                  ?.toDouble() ??
              0,
      actualAmount:
          ((json['actual_amount'] ?? json['actualAmount']) as num?)
              ?.toDouble(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      invoiceId:
          (json['invoice_id'] ?? json['invoiceId']) as String?,
      quoteId: (json['quote_id'] ?? json['quoteId']) as String?,
      syncedToCloud:
          (json['synced_to_cloud'] ?? json['syncedToCloud']) as bool? ?? false,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      deletedAt: _parseOptionalDate(
          json['deleted_at'] ?? json['deletedAt']),
    );
  }

  static JobStatus _parseJobStatus(String? value) {
    if (value == null) return JobStatus.draft;
    // Handle legacy 'lead' → 'draft' mapping
    if (value == 'lead') return JobStatus.draft;
    return JobStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => JobStatus.draft,
    );
  }

  static JobType _parseJobType(String? value) {
    if (value == null) return JobType.standard;
    // Handle both camelCase enum name and snake_case DB value
    if (value == 'insurance_claim') return JobType.insuranceClaim;
    if (value == 'warranty_dispatch') return JobType.warrantyDispatch;
    return JobType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => JobType.standard,
    );
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

  String get displayTitle => title ?? 'Untitled Job';

  String get statusLabel => switch (status) {
        JobStatus.draft => 'Draft',
        JobStatus.scheduled => 'Scheduled',
        JobStatus.dispatched => 'Dispatched',
        JobStatus.enRoute => 'En Route',
        JobStatus.inProgress => 'In Progress',
        JobStatus.onHold => 'On Hold',
        JobStatus.completed => 'Completed',
        JobStatus.invoiced => 'Invoiced',
        JobStatus.cancelled => 'Cancelled',
      };

  String get priorityDisplay => switch (priority) {
        JobPriority.low => 'Low',
        JobPriority.normal => 'Normal',
        JobPriority.high => 'High',
        JobPriority.urgent => 'Urgent',
      };

  String get fullAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    return parts.join(', ');
  }

  bool get isActive =>
      status == JobStatus.scheduled ||
      status == JobStatus.dispatched ||
      status == JobStatus.enRoute ||
      status == JobStatus.inProgress;

  bool get canStart =>
      status == JobStatus.scheduled ||
      status == JobStatus.dispatched ||
      status == JobStatus.enRoute;

  bool get canComplete => status == JobStatus.inProgress;

  bool get isEditable =>
      status != JobStatus.invoiced && status != JobStatus.cancelled;

  bool get isAssigned => assignedToUserId != null;

  // ============================================================
  // COPY WITH
  // ============================================================

  Job copyWith({
    String? id,
    String? companyId,
    String? createdByUserId,
    String? customerId,
    String? assignedToUserId,
    List<String>? assignedUserIds,
    String? teamId,
    String? title,
    String? description,
    String? internalNotes,
    String? tradeType,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    JobStatus? status,
    JobPriority? priority,
    JobType? jobType,
    Map<String, dynamic>? typeMetadata,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    int? estimatedDuration,
    DateTime? startedAt,
    DateTime? completedAt,
    double? estimatedAmount,
    double? actualAmount,
    List<String>? tags,
    String? invoiceId,
    String? quoteId,
    bool? syncedToCloud,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Job(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      customerId: customerId ?? this.customerId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
      teamId: teamId ?? this.teamId,
      title: title ?? this.title,
      description: description ?? this.description,
      internalNotes: internalNotes ?? this.internalNotes,
      tradeType: tradeType ?? this.tradeType,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      jobType: jobType ?? this.jobType,
      typeMetadata: typeMetadata ?? this.typeMetadata,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      tags: tags ?? this.tags,
      invoiceId: invoiceId ?? this.invoiceId,
      quoteId: quoteId ?? this.quoteId,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

// Kept for backward compatibility with bid/invoice screens.
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
