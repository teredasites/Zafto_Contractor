// ZAFTO Notification Model — Supabase Backend
// Maps to `notifications` table in Supabase PostgreSQL.
// Uses AppNotification name to avoid conflict with Flutter's built-in Notification.

enum NotificationType {
  jobAssigned,
  invoicePaid,
  bidAccepted,
  bidRejected,
  changeOrderApproved,
  changeOrderRejected,
  timeEntryApproved,
  timeEntryRejected,
  customerMessage,
  deadManSwitch,
  system;

  String get dbValue {
    switch (this) {
      case NotificationType.jobAssigned:
        return 'job_assigned';
      case NotificationType.invoicePaid:
        return 'invoice_paid';
      case NotificationType.bidAccepted:
        return 'bid_accepted';
      case NotificationType.bidRejected:
        return 'bid_rejected';
      case NotificationType.changeOrderApproved:
        return 'change_order_approved';
      case NotificationType.changeOrderRejected:
        return 'change_order_rejected';
      case NotificationType.timeEntryApproved:
        return 'time_entry_approved';
      case NotificationType.timeEntryRejected:
        return 'time_entry_rejected';
      case NotificationType.customerMessage:
        return 'customer_message';
      case NotificationType.deadManSwitch:
        return 'dead_man_switch';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.system;
    return NotificationType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => NotificationType.system,
    );
  }
}

class AppNotification {
  final String id;
  final String companyId;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    this.id = '',
    this.companyId = '',
    this.userId = '',
    this.title = '',
    this.body = '',
    this.type = NotificationType.system,
    this.entityType,
    this.entityId,
    this.isRead = false,
    this.readAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: _parseOptionalDate(json['read_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  AppNotification copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? entityType,
    String? entityId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Whether the notification was created within the last 24 hours.
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(createdAt).inHours < 24;
  }

  // Relative time string (e.g. "2m ago", "3h ago", "1d ago").
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
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
