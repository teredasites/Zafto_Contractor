// ZAFTO Conversations List Screen
// Created: Sprint FIELD1 (Session 131)
//
// Shows all conversations for the current user.
// Unread badges, last message preview, timestamps.
// Tap to open chat. FAB to start new conversation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../../models/conversation.dart';
import '../../providers/messaging_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';

class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search conversations
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewConversationScreen()),
        ),
        child: const Icon(Icons.edit),
      ),
      body: conversationsAsync.when(
        loading: () => const LoadingState(message: 'Loading conversations...'),
        error: (error, stack) => ErrorState(
          message: 'Failed to load conversations',
          onRetry: () => ref.invalidate(conversationListProvider),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No messages yet',
              subtitle: 'Start a conversation with your team',
              actionLabel: 'New Message',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewConversationScreen()),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(conversationListProvider),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _ConversationTile(conversation: conv);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = currentUser?.id ?? '';
    final theme = Theme.of(context);
    final hasUnread = conversation.hasUnread;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          conversation.type == ConversationType.group
              ? Icons.group
              : conversation.type == ConversationType.job
                  ? Icons.work
                  : Icons.person,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        conversation.displayTitle(userId, {}),
        style: hasUnread
            ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
            : theme.textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: conversation.lastMessagePreview != null
          ? Text(
              conversation.lastMessagePreview!,
              style: hasUnread
                  ? theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)
                  : theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasUnread ? theme.colorScheme.primary : null,
              ),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : '${conversation.unreadCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            title: conversation.displayTitle(userId, {}),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}
