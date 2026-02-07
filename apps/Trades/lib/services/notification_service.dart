// ZAFTO Notification Service — Supabase Backend
// Providers, notifier, and auth-enriched service for notifications.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../core/errors.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';
import 'auth_service.dart';

// --- Providers ---

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return NotificationService(repo, authState);
});

// User notifications — auto-dispose when no longer listened to.
final userNotificationsProvider = StateNotifierProvider.autoDispose<
    UserNotificationsNotifier, AsyncValue<List<AppNotification>>>(
  (ref) {
    final service = ref.watch(notificationServiceProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.uid;
    final notifier = UserNotificationsNotifier(service, userId);
    ref.onDispose(() => notifier.dispose());
    return notifier;
  },
);

// Derived: unread notification count.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  return notificationsAsync.whenData((list) {
    return list.where((n) => !n.isRead).length;
  }).valueOrNull ?? 0;
});

// --- User Notifications Notifier ---

class UserNotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationService _service;
  final String? _userId;
  RealtimeChannel? _channel;
  bool _disposed = false;

  UserNotificationsNotifier(this._service, this._userId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    await loadNotifications();
    _subscribeToRealtime();
  }

  Future<void> loadNotifications() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final notifications = await _service.getNotifications();
      if (!_disposed) {
        state = AsyncValue.data(notifications);
      }
    } catch (e, st) {
      if (!_disposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _subscribeToRealtime() {
    if (_userId == null) return;

    _channel = _service.subscribeToNotifications(
      onInsert: (notification) {
        if (_disposed) return;
        final current = state.valueOrNull ?? [];
        state = AsyncValue.data([notification, ...current]);
      },
    );
  }

  int get unreadCount {
    final list = state.valueOrNull ?? [];
    return list.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }
          return n;
        }).toList(),
      );
    } catch (_) {
      // Silently fail — UI state stays unchanged
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      final current = state.valueOrNull ?? [];
      final now = DateTime.now();
      state = AsyncValue.data(
        current.map((n) {
          if (!n.isRead) {
            return n.copyWith(isRead: true, readAt: now);
          }
          return n;
        }).toList(),
      );
    } catch (_) {
      // Silently fail — UI state stays unchanged
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }
}

// --- Service ---

class NotificationService {
  final NotificationRepository _repo;
  final AuthState _authState;

  NotificationService(this._repo, this._authState);

  // Get notifications for the current user.
  Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    final userId = _authState.user?.uid;
    if (userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to view notifications.',
        code: AuthErrorCode.sessionExpired,
      );
    }
    return _repo.getNotifications(userId, limit: limit);
  }

  // Get unread count for the current user.
  Future<int> getUnreadCount() async {
    final userId = _authState.user?.uid;
    if (userId == null) return 0;
    return _repo.getUnreadCount(userId);
  }

  // Mark a single notification as read.
  Future<void> markAsRead(String notificationId) {
    return _repo.markAsRead(notificationId);
  }

  // Mark all unread notifications as read for the current user.
  Future<void> markAllAsRead() async {
    final userId = _authState.user?.uid;
    if (userId == null) {
      throw const AuthError(
        'Not authenticated',
        userMessage: 'Please sign in to update notifications.',
        code: AuthErrorCode.sessionExpired,
      );
    }
    return _repo.markAllAsRead(userId);
  }

  // Delete a notification.
  Future<void> deleteNotification(String notificationId) {
    return _repo.deleteNotification(notificationId);
  }

  // Subscribe to real-time notifications for the current user.
  // Returns null if not authenticated.
  RealtimeChannel? subscribeToNotifications({
    required void Function(AppNotification notification) onInsert,
  }) {
    final userId = _authState.user?.uid;
    if (userId == null) return null;

    return _repo.subscribeToNotifications(
      userId: userId,
      onInsert: onInsert,
    );
  }
}
