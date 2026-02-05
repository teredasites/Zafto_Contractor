import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Job status progression
enum JobStatus {
  draft,        // Not yet scheduled
  scheduled,    // On calendar
  dispatched,   // Sent to technician (Growing+ tiers)
  enRoute,      // Tech on the way
  inProgress,   // Work started
  onHold,       // Waiting on parts, customer, etc.
  completed,    // Work done
  invoiced,     // Invoice sent
  cancelled     // Job cancelled
}

/// Job priority levels
enum JobPriority { low, normal, high, urgent }

/// Time entry for tracking work hours
class TimeEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? minutes;
  final String? notes;

  const TimeEntry({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.minutes,
    this.notes,
  });

  @override
  List<Object?> get props => [id, userId, startTime, endTime];

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'minutes': minutes,
        'notes': notes,
      };

  factory TimeEntry.fromMap(Map<String, dynamic> map) => TimeEntry(
        id: map['id'] as String,
        userId: map['userId'] as String,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: map['endTime'] != null
            ? DateTime.parse(map['endTime'] as String)
            : null,
        minutes: map['minutes'] as int?,
        notes: map['notes'] as String?,
      );
}

/// Job model with assignment and workflow tracking
class Job extends Equatable {
  final String id;
  final String companyId;
  final String createdByUserId;

  // Assignment (Team+ tiers)
  final String? assignedToUserId;
  final List<String> assignedUserIds;
  final String? teamId;

  // Trade
  final String tradeType;

  // Customer (denormalized for offline)
  final String? customerId;
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

  // Scheduling
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final int? estimatedDuration; // Minutes

  // Status
  final JobStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Details
  final String? title;
  final String? description;
  final String? internalNotes;
  final List<String> tags;
  final JobPriority priority;

  // Linked Data
  final List<String> photoIds;
  final List<String> calculationIds;
  final String? invoiceId;
  final String? quoteId;

  // Time Tracking (Business+ tiers)
  final List<TimeEntry> timeEntries;
  final int totalMinutesWorked;

  // Sync
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool syncedToCloud;

  const Job({
    required this.id,
    required this.companyId,
    required this.createdByUserId,
    this.assignedToUserId,
    this.assignedUserIds = const [],
    this.teamId,
    this.tradeType = 'electrical',
    this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.scheduledStart,
    this.scheduledEnd,
    this.estimatedDuration,
    this.status = JobStatus.draft,
    this.startedAt,
    this.completedAt,
    this.title,
    this.description,
    this.internalNotes,
    this.tags = const [],
    this.priority = JobPriority.normal,
    this.photoIds = const [],
    this.calculationIds = const [],
    this.invoiceId,
    this.quoteId,
    this.timeEntries = const [],
    this.totalMinutesWorked = 0,
    required this.createdAt,
    required this.updatedAt,
    this.syncedToCloud = false,
  });

  @override
  List<Object?> get props => [id, companyId, status, updatedAt];

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// Display title - uses title or falls back to address
  String get displayTitle => title ?? address;

  /// Check if job is active (in progress or en route)
  bool get isActive =>
      status == JobStatus.inProgress || status == JobStatus.enRoute;

  /// Check if job can be started
  bool get canStart =>
      status == JobStatus.scheduled || status == JobStatus.dispatched;

  /// Check if job can be completed
  bool get canComplete => status == JobStatus.inProgress;

  /// Check if job is editable
  bool get isEditable =>
      status != JobStatus.invoiced && status != JobStatus.cancelled;

  /// Check if job has been assigned
  bool get isAssigned =>
      assignedToUserId != null || assignedUserIds.isNotEmpty;

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case JobStatus.draft:
        return 'Draft';
      case JobStatus.scheduled:
        return 'Scheduled';
      case JobStatus.dispatched:
        return 'Dispatched';
      case JobStatus.enRoute:
        return 'En Route';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.onHold:
        return 'On Hold';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.invoiced:
        return 'Invoiced';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get priority display text
  String get priorityDisplay {
    switch (priority) {
      case JobPriority.low:
        return 'Low';
      case JobPriority.normal:
        return 'Normal';
      case JobPriority.high:
        return 'High';
      case JobPriority.urgent:
        return 'Urgent';
    }
  }

  /// Full address string
  String get fullAddress {
    final parts = [address];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (zipCode != null) parts.add(zipCode!);
    return parts.join(', ');
  }

  /// Duration in hours and minutes
  String get durationDisplay {
    if (totalMinutesWorked == 0) return '-';
    final hours = totalMinutesWorked ~/ 60;
    final mins = totalMinutesWorked % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'createdByUserId': createdByUserId,
      'assignedToUserId': assignedToUserId,
      'assignedUserIds': assignedUserIds,
      'teamId': teamId,
      'tradeType': tradeType,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'scheduledStart': scheduledStart?.toIso8601String(),
      'scheduledEnd': scheduledEnd?.toIso8601String(),
      'estimatedDuration': estimatedDuration,
      'status': status.name,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'title': title,
      'description': description,
      'internalNotes': internalNotes,
      'tags': tags,
      'priority': priority.name,
      'photoIds': photoIds,
      'calculationIds': calculationIds,
      'invoiceId': invoiceId,
      'quoteId': quoteId,
      'timeEntries': timeEntries.map((e) => e.toMap()).toList(),
      'totalMinutesWorked': totalMinutesWorked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncedToCloud': syncedToCloud,
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      createdByUserId: map['createdByUserId'] as String,
      assignedToUserId: map['assignedToUserId'] as String?,
      assignedUserIds: List<String>.from(map['assignedUserIds'] ?? []),
      teamId: map['teamId'] as String?,
      tradeType: map['tradeType'] as String? ?? 'electrical',
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String,
      customerEmail: map['customerEmail'] as String?,
      customerPhone: map['customerPhone'] as String?,
      address: map['address'] as String,
      city: map['city'] as String?,
      state: map['state'] as String?,
      zipCode: map['zipCode'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      scheduledStart: map['scheduledStart'] != null
          ? _parseDateTime(map['scheduledStart'])
          : null,
      scheduledEnd: map['scheduledEnd'] != null
          ? _parseDateTime(map['scheduledEnd'])
          : null,
      estimatedDuration: map['estimatedDuration'] as int?,
      status: JobStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => JobStatus.draft,
      ),
      startedAt:
          map['startedAt'] != null ? _parseDateTime(map['startedAt']) : null,
      completedAt: map['completedAt'] != null
          ? _parseDateTime(map['completedAt'])
          : null,
      title: map['title'] as String?,
      description: map['description'] as String?,
      internalNotes: map['internalNotes'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      priority: JobPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => JobPriority.normal,
      ),
      photoIds: List<String>.from(map['photoIds'] ?? []),
      calculationIds: List<String>.from(map['calculationIds'] ?? []),
      invoiceId: map['invoiceId'] as String?,
      quoteId: map['quoteId'] as String?,
      timeEntries: (map['timeEntries'] as List<dynamic>?)
              ?.map((e) => TimeEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalMinutesWorked: map['totalMinutesWorked'] as int? ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      syncedToCloud: map['syncedToCloud'] as bool? ?? false,
    );
  }

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job.fromMap({...data, 'id': doc.id});
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

  Job copyWith({
    String? id,
    String? companyId,
    String? createdByUserId,
    String? assignedToUserId,
    List<String>? assignedUserIds,
    String? teamId,
    String? tradeType,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    int? estimatedDuration,
    JobStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? title,
    String? description,
    String? internalNotes,
    List<String>? tags,
    JobPriority? priority,
    List<String>? photoIds,
    List<String>? calculationIds,
    String? invoiceId,
    String? quoteId,
    List<TimeEntry>? timeEntries,
    int? totalMinutesWorked,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? syncedToCloud,
  }) {
    return Job(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
      teamId: teamId ?? this.teamId,
      tradeType: tradeType ?? this.tradeType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      internalNotes: internalNotes ?? this.internalNotes,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      photoIds: photoIds ?? this.photoIds,
      calculationIds: calculationIds ?? this.calculationIds,
      invoiceId: invoiceId ?? this.invoiceId,
      quoteId: quoteId ?? this.quoteId,
      timeEntries: timeEntries ?? this.timeEntries,
      totalMinutesWorked: totalMinutesWorked ?? this.totalMinutesWorked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  /// Create a new job draft
  factory Job.create({
    required String id,
    required String companyId,
    required String createdByUserId,
    required String customerName,
    required String address,
    String? customerId,
    String? title,
  }) {
    final now = DateTime.now();
    return Job(
      id: id,
      companyId: companyId,
      createdByUserId: createdByUserId,
      customerName: customerName,
      address: address,
      customerId: customerId,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
  }
}
