import 'package:equatable/equatable.dart';

/// Message role in the conversation
enum MessageRole {
  user,       // User's message
  assistant,  // AI response
  system,     // System context (not shown to user)
  tool,       // Tool call result
}

/// Attachment type
enum AttachmentType {
  image,      // Photo from camera or gallery
  document,   // PDF or other document
  calculation, // Embedded calculation result
  job,        // Job card embed
  customer,   // Customer card embed
}

/// Message attachment (photo, document, or embedded content)
class MessageAttachment extends Equatable {
  final String id;
  final AttachmentType type;
  final String? url;           // Cloud URL or local path
  final String? base64;        // For inline images
  final String? caption;       // User's description of what they're showing
  final String? mimeType;
  final Map<String, dynamic>? metadata; // For embedded content (calc results, etc.)

  const MessageAttachment({
    required this.id,
    required this.type,
    this.url,
    this.base64,
    this.caption,
    this.mimeType,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, type, url];

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'url': url,
    'base64': base64,
    'caption': caption,
    'mimeType': mimeType,
    'metadata': metadata,
  };

  factory MessageAttachment.fromMap(Map<String, dynamic> map) => MessageAttachment(
    id: map['id'] as String,
    type: AttachmentType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => AttachmentType.image,
    ),
    url: map['url'] as String?,
    base64: map['base64'] as String?,
    caption: map['caption'] as String?,
    mimeType: map['mimeType'] as String?,
    metadata: map['metadata'] as Map<String, dynamic>?,
  );

  /// Create photo attachment
  factory MessageAttachment.photo({
    required String id,
    String? url,
    String? base64,
    String? caption,
  }) {
    return MessageAttachment(
      id: id,
      type: AttachmentType.image,
      url: url,
      base64: base64,
      caption: caption,
      mimeType: 'image/jpeg',
    );
  }

  /// Create calculation result embed
  factory MessageAttachment.calculation({
    required String id,
    required String calculatorName,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> results,
  }) {
    return MessageAttachment(
      id: id,
      type: AttachmentType.calculation,
      metadata: {
        'calculatorName': calculatorName,
        'inputs': inputs,
        'results': results,
      },
    );
  }
}

/// AI tool call (function calling)
class ToolCall extends Equatable {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  final Map<String, dynamic>? result;
  final bool isComplete;
  final String? error;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.result,
    this.isComplete = false,
    this.error,
  });

  @override
  List<Object?> get props => [id, name, isComplete];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'arguments': arguments,
    'result': result,
    'isComplete': isComplete,
    'error': error,
  };

  factory ToolCall.fromMap(Map<String, dynamic> map) => ToolCall(
    id: map['id'] as String,
    name: map['name'] as String,
    arguments: Map<String, dynamic>.from(map['arguments'] ?? {}),
    result: map['result'] as Map<String, dynamic>?,
    isComplete: map['isComplete'] as bool? ?? false,
    error: map['error'] as String?,
  );

  ToolCall copyWith({
    Map<String, dynamic>? result,
    bool? isComplete,
    String? error,
  }) {
    return ToolCall(
      id: id,
      name: name,
      arguments: arguments,
      result: result ?? this.result,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

/// Single message in a conversation
class Message extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final List<MessageAttachment> attachments;
  final List<ToolCall> toolCalls;
  final DateTime createdAt;
  final bool isStreaming;      // For live typing effect
  final String? parentMessageId; // For threading

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.attachments = const [],
    this.toolCalls = const [],
    required this.createdAt,
    this.isStreaming = false,
    this.parentMessageId,
  });

  @override
  List<Object?> get props => [id, conversationId, role, createdAt];

  /// Check if message has photos
  bool get hasPhotos => attachments.any((a) => a.type == AttachmentType.image);

  /// Get photo count for context tips
  int get photoCount => attachments.where((a) => a.type == AttachmentType.image).length;

  /// Check if message has tool calls
  bool get hasToolCalls => toolCalls.isNotEmpty;

  /// Check if all tool calls are complete
  bool get allToolCallsComplete => toolCalls.every((t) => t.isComplete);

  Map<String, dynamic> toMap() => {
    'id': id,
    'conversationId': conversationId,
    'role': role.name,
    'content': content,
    'attachments': attachments.map((a) => a.toMap()).toList(),
    'toolCalls': toolCalls.map((t) => t.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'isStreaming': isStreaming,
    'parentMessageId': parentMessageId,
  };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id'] as String,
    conversationId: map['conversationId'] as String,
    role: MessageRole.values.firstWhere(
      (r) => r.name == map['role'],
      orElse: () => MessageRole.user,
    ),
    content: map['content'] as String? ?? '',
    attachments: (map['attachments'] as List<dynamic>?)
        ?.map((a) => MessageAttachment.fromMap(a as Map<String, dynamic>))
        .toList() ?? [],
    toolCalls: (map['toolCalls'] as List<dynamic>?)
        ?.map((t) => ToolCall.fromMap(t as Map<String, dynamic>))
        .toList() ?? [],
    createdAt: _parseDateTime(map['createdAt']),
    isStreaming: map['isStreaming'] as bool? ?? false,
    parentMessageId: map['parentMessageId'] as String?,
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Message copyWith({
    String? content,
    List<MessageAttachment>? attachments,
    List<ToolCall>? toolCalls,
    bool? isStreaming,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      toolCalls: toolCalls ?? this.toolCalls,
      createdAt: createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
      parentMessageId: parentMessageId,
    );
  }

  /// Create user message
  factory Message.user({
    required String id,
    required String conversationId,
    required String content,
    List<MessageAttachment>? attachments,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      role: MessageRole.user,
      content: content,
      attachments: attachments ?? [],
      createdAt: DateTime.now(),
    );
  }

  /// Create assistant message
  factory Message.assistant({
    required String id,
    required String conversationId,
    required String content,
    List<ToolCall>? toolCalls,
    bool isStreaming = false,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: content,
      toolCalls: toolCalls ?? [],
      createdAt: DateTime.now(),
      isStreaming: isStreaming,
    );
  }
}

/// User context snapshot at conversation start
/// Captures the user's state when they started chatting
class ConversationContext extends Equatable {
  final String userId;
  final String companyId;
  final String roleId;
  final String? currentJobId;
  final String? currentCustomerId;
  final String trade;           // Which trade app they're in
  final String necYear;
  final String? lastCalculatorUsed;
  final List<String> recentCalculatorIds;

  const ConversationContext({
    required this.userId,
    required this.companyId,
    required this.roleId,
    this.currentJobId,
    this.currentCustomerId,
    this.trade = 'electrical',
    this.necYear = '2023',
    this.lastCalculatorUsed,
    this.recentCalculatorIds = const [],
  });

  @override
  List<Object?> get props => [userId, companyId, currentJobId];

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'companyId': companyId,
    'roleId': roleId,
    'currentJobId': currentJobId,
    'currentCustomerId': currentCustomerId,
    'trade': trade,
    'necYear': necYear,
    'lastCalculatorUsed': lastCalculatorUsed,
    'recentCalculatorIds': recentCalculatorIds,
  };

  factory ConversationContext.fromMap(Map<String, dynamic> map) => ConversationContext(
    userId: map['userId'] as String,
    companyId: map['companyId'] as String,
    roleId: map['roleId'] as String,
    currentJobId: map['currentJobId'] as String?,
    currentCustomerId: map['currentCustomerId'] as String?,
    trade: map['trade'] as String? ?? 'electrical',
    necYear: map['necYear'] as String? ?? '2023',
    lastCalculatorUsed: map['lastCalculatorUsed'] as String?,
    recentCalculatorIds: List<String>.from(map['recentCalculatorIds'] ?? []),
  );
}

/// Conversation thread containing messages
class Conversation extends Equatable {
  final String id;
  final String userId;
  final String companyId;
  final ConversationContext context;

  // Metadata
  final String? title;          // Auto-generated from first message
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;

  // State
  final bool isActive;          // Currently open
  final bool isPinned;          // User pinned for quick access
  final int messageCount;
  final int photoCount;         // Track photo context

  // Preview (denormalized for list display)
  final String? lastMessagePreview;
  final MessageRole? lastMessageRole;

  const Conversation({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.context,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.isActive = true,
    this.isPinned = false,
    this.messageCount = 0,
    this.photoCount = 0,
    this.lastMessagePreview,
    this.lastMessageRole,
  });

  @override
  List<Object?> get props => [id, userId, updatedAt];

  /// Display title - uses generated title or "New Conversation"
  String get displayTitle => title ?? 'New Conversation';

  /// Check if this is a new conversation (no messages yet)
  bool get isNew => messageCount == 0;

  /// Check if conversation has photo context
  bool get hasPhotoContext => photoCount > 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'companyId': companyId,
    'context': context.toMap(),
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastMessageAt': lastMessageAt?.toIso8601String(),
    'isActive': isActive,
    'isPinned': isPinned,
    'messageCount': messageCount,
    'photoCount': photoCount,
    'lastMessagePreview': lastMessagePreview,
    'lastMessageRole': lastMessageRole?.name,
  };

  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
    id: map['id'] as String,
    userId: map['userId'] as String,
    companyId: map['companyId'] as String,
    context: ConversationContext.fromMap(
      map['context'] as Map<String, dynamic>? ?? {'userId': map['userId'], 'companyId': map['companyId'], 'roleId': 'owner'},
    ),
    title: map['title'] as String?,
    createdAt: _parseDateTime(map['createdAt']),
    updatedAt: _parseDateTime(map['updatedAt']),
    lastMessageAt: map['lastMessageAt'] != null
        ? _parseDateTime(map['lastMessageAt'])
        : null,
    isActive: map['isActive'] as bool? ?? true,
    isPinned: map['isPinned'] as bool? ?? false,
    messageCount: map['messageCount'] as int? ?? 0,
    photoCount: map['photoCount'] as int? ?? 0,
    lastMessagePreview: map['lastMessagePreview'] as String?,
    lastMessageRole: map['lastMessageRole'] != null
        ? MessageRole.values.firstWhere(
            (r) => r.name == map['lastMessageRole'],
            orElse: () => MessageRole.assistant,
          )
        : null,
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    bool? isActive,
    bool? isPinned,
    int? messageCount,
    int? photoCount,
    String? lastMessagePreview,
    MessageRole? lastMessageRole,
  }) {
    return Conversation(
      id: id,
      userId: userId,
      companyId: companyId,
      context: context,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      isPinned: isPinned ?? this.isPinned,
      messageCount: messageCount ?? this.messageCount,
      photoCount: photoCount ?? this.photoCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageRole: lastMessageRole ?? this.lastMessageRole,
    );
  }

  /// Create new conversation
  factory Conversation.create({
    required String id,
    required String userId,
    required String companyId,
    required ConversationContext context,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: id,
      userId: userId,
      companyId: companyId,
      context: context,
      createdAt: now,
      updatedAt: now,
    );
  }
}
