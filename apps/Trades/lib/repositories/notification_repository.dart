// ZAFTO Notification Repository — Supabase Backend
// CRUD for the notifications table + real-time subscription.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors.dart';
import '../models/notification.dart';

class NotificationRepository {
  final SupabaseClient _client;
  static const _table = 'notifications';

  NotificationRepository(this._client);

  // Get notifications for a user, ordered by most recent first.
  Future<List<AppNotification>> getNotifications(String userId,
      {int limit = 50}) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((row) => AppNotification.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load notifications for user $userId',
        userMessage: 'Could not load notifications.',
        cause: e,
      );
    }
  }

  // Get count of unread notifications for a user.
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw DatabaseError(
        'Failed to get unread count',
        userMessage: 'Could not load notification count.',
        cause: e,
      );
    }
  }

  // Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from(_table).update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      throw DatabaseError(
        'Failed to mark notification as read',
        userMessage: 'Could not update notification.',
        cause: e,
      );
    }
  }

  // Mark all unread notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client.from(_table).update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId).eq('is_read', false);
    } catch (e) {
      throw DatabaseError(
        'Failed to mark all notifications as read',
        userMessage: 'Could not update notifications.',
        cause: e,
      );
    }
  }

  // Hard delete a notification.
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from(_table).delete().eq('id', notificationId);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete notification',
        userMessage: 'Could not delete notification.',
        cause: e,
      );
    }
  }

  // Subscribe to real-time INSERT events on the notifications table for a user.
  // Returns a RealtimeChannel that the caller must manage (unsubscribe on dispose).
  RealtimeChannel subscribeToNotifications({
    required String userId,
    required void Function(AppNotification notification) onInsert,
  }) {
    final channel = _client.channel('notifications:$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: _table,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        try {
          final notification = AppNotification.fromJson(payload.newRecord);
          onInsert(notification);
        } catch (_) {
          // Silently ignore malformed payloads
        }
      },
    );

    channel.subscribe();
    return channel;
  }
}
