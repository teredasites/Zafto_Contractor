// ZAFTO Message Repository
// Created: Sprint FIELD1 (Session 131)
//
// Supabase CRUD for messages + conversations tables.
// Real-time subscriptions via Supabase Realtime.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class MessageRepository {
  // ============================================================
  // CONVERSATIONS
  // ============================================================

  /// Get all conversations for the current user, ordered by last message.
  /// Joins conversation_members for unread count.
  Future<List<Conversation>> getConversations() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw AuthError('Not authenticated');

      final response = await supabase
          .from('conversations')
          .select('*, conversation_members!inner(unread_count, is_muted, is_pinned)')
          .contains('participant_ids', [userId])
          .eq('conversation_members.user_id', userId)
          .isFilter('deleted_at', null)
          .order('last_message_at', ascending: false, nullsFirst: false);

      return (response as List).map((row) {
        final members = row['conversation_members'] as List?;
        final memberData = members?.isNotEmpty == true ? members!.first : {};
        return Conversation.fromJson({
          ...row,
          'unread_count': memberData['unread_count'] ?? 0,
          'is_muted': memberData['is_muted'] ?? false,
          'is_pinned': memberData['is_pinned'] ?? false,
        });
      }).toList();
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to fetch conversations: $e', cause: e);
    }
  }

  /// Get or create a direct conversation with another user.
  Future<Conversation> getOrCreateDirectConversation(String otherUserId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw AuthError('Not authenticated');
      final companyId = currentUser!.appMetadata['company_id'] as String?;
      if (companyId == null) throw AuthError('No company');

      // Check for existing direct conversation
      final existing = await supabase
          .from('conversations')
          .select()
          .eq('type', 'direct')
          .eq('company_id', companyId)
          .contains('participant_ids', [userId, otherUserId])
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (existing != null) return Conversation.fromJson(existing);

      // Create new direct conversation via Edge Function
      final response = await supabase.functions.invoke(
        'send-message',
        body: {
          'action': 'create_conversation',
          'type': 'direct',
          'participant_ids': [otherUserId],
        },
      );

      if (response.status != 200) {
        throw DatabaseError('Failed to create conversation: ${response.data}');
      }

      return Conversation.fromJson(response.data['conversation']);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to get/create conversation: $e', cause: e);
    }
  }

  /// Create a group or job conversation.
  Future<Conversation> createGroupConversation({
    required String title,
    required List<String> participantIds,
    String? jobId,
    String? firstMessage,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'send-message',
        body: {
          'action': 'create_conversation',
          'type': jobId != null ? 'job' : 'group',
          'title': title,
          'participant_ids': participantIds,
          'job_id': jobId,
          'content': firstMessage,
        },
      );

      if (response.status != 200) {
        throw DatabaseError('Failed to create group: ${response.data}');
      }

      return Conversation.fromJson(response.data['conversation']);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to create group conversation: $e', cause: e);
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  /// Get messages for a conversation, paginated.
  Future<List<Message>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((row) => Message.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch messages: $e', cause: e);
    }
  }

  /// Send a text message.
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'send-message',
        body: {
          'conversation_id': conversationId,
          'content': content,
          'message_type': 'text',
          'reply_to_id': replyToId,
        },
      );

      if (response.status != 200) {
        throw DatabaseError('Failed to send message: ${response.data}');
      }

      return Message.fromJson(response.data['message']);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to send message: $e', cause: e);
    }
  }

  /// Send a file/image message.
  Future<Message> sendFileMessage({
    required String conversationId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String fileMimeType,
    String? caption,
  }) async {
    try {
      final isImage = fileMimeType.startsWith('image/');
      final response = await supabase.functions.invoke(
        'send-message',
        body: {
          'conversation_id': conversationId,
          'content': caption,
          'message_type': isImage ? 'image' : 'file',
          'file_url': fileUrl,
          'file_name': fileName,
          'file_size': fileSize,
          'file_mime_type': fileMimeType,
        },
      );

      if (response.status != 200) {
        throw DatabaseError('Failed to send file: ${response.data}');
      }

      return Message.fromJson(response.data['message']);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to send file message: $e', cause: e);
    }
  }

  /// Mark all messages in a conversation as read.
  Future<void> markConversationRead(String conversationId) async {
    try {
      await supabase.functions.invoke(
        'mark-messages-read',
        body: {'conversation_id': conversationId},
      );
    } catch (e) {
      throw DatabaseError('Failed to mark messages read: $e', cause: e);
    }
  }

  // ============================================================
  // REAL-TIME
  // ============================================================

  /// Subscribe to new messages in a conversation.
  Stream<Message> subscribeToMessages(String conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map((r) => Message.fromJson(r)).toList())
        .expand((messages) => messages);
  }

  /// Subscribe to conversation list updates (unread count changes).
  Stream<List<Map<String, dynamic>>> subscribeToUnreadUpdates() {
    final userId = currentUser?.id;
    if (userId == null) return const Stream.empty();

    return supabase
        .from('conversation_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }

  // ============================================================
  // TEAM MEMBERS (for new conversation picker)
  // ============================================================

  /// Get team members in the current company (for creating new conversations).
  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    try {
      final response = await supabase
          .from('users')
          .select('id, first_name, last_name, role, avatar_url')
          .isFilter('deleted_at', null)
          .order('first_name');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw DatabaseError('Failed to fetch team members: $e', cause: e);
    }
  }
}
