// ZAFTO Conversation Model — Supabase Backend
// Maps to `conversations` table.
// Types: direct (1:1), group, job (linked to a specific job).

import 'package:equatable/equatable.dart';

enum ConversationType {
  direct,
  group,
  job;

  String get dbValue {
    switch (this) {
      case ConversationType.direct:
        return 'direct';
      case ConversationType.group:
        return 'group';
      case ConversationType.job:
        return 'job';
    }
  }

  static ConversationType fromString(String? value) {
    switch (value) {
      case 'direct':
        return ConversationType.direct;
      case 'group':
        return ConversationType.group;
      case 'job':
        return ConversationType.job;
      default:
        return ConversationType.direct;
    }
  }
}

class Conversation extends Equatable {
  final String id;
  final String companyId;
  final ConversationType type;
  final String? title;
  final List<String> participantIds;
  final String? jobId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final bool isArchived;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;

  const Conversation({
    required this.id,
    required this.companyId,
    required this.type,
    this.title,
    required this.participantIds,
    this.jobId,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.isArchived = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final participantIds = json['participant_ids'];
    List<String> ids = [];
    if (participantIds is List) {
      ids = participantIds.map((e) => e.toString()).toList();
    }

    return Conversation(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      type: ConversationType.fromString(json['type'] as String?),
      title: json['title'] as String?,
      participantIds: ids,
      jobId: json['job_id'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      unreadCount: json['unread_count'] as int? ?? 0,
      isMuted: json['is_muted'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'type': type.dbValue,
        'title': title,
        'participant_ids': participantIds,
        'job_id': jobId,
        'is_archived': isArchived,
      };

  Conversation copyWith({
    String? title,
    List<String>? participantIds,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    bool? isArchived,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
  }) {
    return Conversation(
      id: id,
      companyId: companyId,
      type: type,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      jobId: jobId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      isArchived: isArchived ?? this.isArchived,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Display name for the conversation (for direct chats, derive from other participant)
  String displayTitle(String currentUserId, Map<String, String> userNameMap) {
    if (title != null && title!.isNotEmpty) return title!;
    if (type == ConversationType.direct) {
      final otherId = participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => currentUserId,
      );
      return userNameMap[otherId] ?? 'Unknown';
    }
    return 'Group Chat';
  }

  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [id, updatedAt, unreadCount];
}
