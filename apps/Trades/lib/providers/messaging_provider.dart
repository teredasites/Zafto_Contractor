// ZAFTO Messaging Provider
// Created: Sprint FIELD1 (Session 131)
//
// Riverpod providers for real-time messaging.
// Conversations list, message history, unread counts, send/read actions.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../repositories/message_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER (singleton)
// ════════════════════════════════════════════════════════════════

final messageRepoProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

// ════════════════════════════════════════════════════════════════
// CONVERSATION LIST PROVIDER
// ════════════════════════════════════════════════════════════════

final conversationListProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final repo = ref.read(messageRepoProvider);
  return repo.getConversations();
});

// ════════════════════════════════════════════════════════════════
// MESSAGES FOR A CONVERSATION (.family by conversation ID)
// ════════════════════════════════════════════════════════════════

final messagesProvider = FutureProvider.autoDispose
    .family<List<Message>, String>((ref, conversationId) async {
  final repo = ref.read(messageRepoProvider);
  return repo.getMessages(conversationId);
});

// ════════════════════════════════════════════════════════════════
// TOTAL UNREAD COUNT (badge across all screens)
// ════════════════════════════════════════════════════════════════

final totalUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final conversations = await ref.watch(conversationListProvider.future);
  return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
});

// ════════════════════════════════════════════════════════════════
// TEAM MEMBERS (for new conversation picker)
// ════════════════════════════════════════════════════════════════

final teamMembersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(messageRepoProvider);
  return repo.getTeamMembers();
});

// ════════════════════════════════════════════════════════════════
// MESSAGING ACTIONS NOTIFIER
// ════════════════════════════════════════════════════════════════

class MessagingActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    final repo = ref.read(messageRepoProvider);
    final message = await repo.sendMessage(
      conversationId: conversationId,
      content: content,
      replyToId: replyToId,
    );
    // Invalidate to refresh conversation list (new last_message_at)
    ref.invalidate(conversationListProvider);
    return message;
  }

  Future<void> markRead(String conversationId) async {
    final repo = ref.read(messageRepoProvider);
    await repo.markConversationRead(conversationId);
    ref.invalidate(conversationListProvider);
  }

  Future<Conversation> getOrCreateDirect(String otherUserId) async {
    final repo = ref.read(messageRepoProvider);
    return repo.getOrCreateDirectConversation(otherUserId);
  }

  Future<Conversation> createGroup({
    required String title,
    required List<String> participantIds,
    String? jobId,
    String? firstMessage,
  }) async {
    final repo = ref.read(messageRepoProvider);
    final conv = await repo.createGroupConversation(
      title: title,
      participantIds: participantIds,
      jobId: jobId,
      firstMessage: firstMessage,
    );
    ref.invalidate(conversationListProvider);
    return conv;
  }
}

final messagingActionsProvider =
    AsyncNotifierProvider<MessagingActionsNotifier, void>(
        MessagingActionsNotifier.new);
