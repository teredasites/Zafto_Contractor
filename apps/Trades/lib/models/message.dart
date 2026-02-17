// ZAFTO Message Model — Supabase Backend
// Maps to `messages` table.
// Types: text, image, file, system, voice.

import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  file,
  system,
  voice;

  String get dbValue {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.system:
        return 'system';
      case MessageType.voice:
        return 'voice';
    }
  }

  static MessageType fromString(String? value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }
}

class Message extends Equatable {
  final String id;
  final String companyId;
  final String conversationId;
  final String senderId;
  final String? content;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileMimeType;
  final List<String> readBy;
  final String? replyToId;
  final Map<String, dynamic> metadata;
  final DateTime? editedAt;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.companyId,
    required this.conversationId,
    required this.senderId,
    this.content,
    required this.messageType,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileMimeType,
    required this.readBy,
    this.replyToId,
    this.metadata = const {},
    this.editedAt,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final readBy = json['read_by'];
    List<String> readByList = [];
    if (readBy is List) {
      readByList = readBy.map((e) => e.toString()).toList();
    }

    return Message(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      messageType: MessageType.fromString(json['message_type'] as String?),
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      fileMimeType: json['file_mime_type'] as String?,
      readBy: readByList,
      replyToId: json['reply_to_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType.dbValue,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'file_mime_type': fileMimeType,
        'reply_to_id': replyToId,
        'metadata': metadata,
      };

  bool isReadBy(String userId) => readBy.contains(userId);
  bool get isTextMessage => messageType == MessageType.text;
  bool get isSystemMessage => messageType == MessageType.system;
  bool get hasFile => fileUrl != null;

  @override
  List<Object?> get props => [id, createdAt];
}
