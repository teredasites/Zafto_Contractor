// ZAFTO Notifications Screen — In-app notification center.
// Reads from userNotificationsProvider (real-time Supabase).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/error_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(userNotificationsProvider.notifier).markAllAsRead();
              },
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const ZaftoLoadingState(message: 'Loading notifications...'),
        error: (e, _) => ErrorStateWidget(
          message: 'Could not load notifications',
          icon: Icons.notifications_off_outlined,
          onRetry: () => ref.read(userNotificationsProvider.notifier).loadNotifications(),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const ZaftoEmptyState(
              icon: LucideIcons.bellOff,
              title: 'No notifications',
              subtitle: 'You\'re all caught up! Notifications will appear here when there\'s activity.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colors.borderSubtle,
              indent: 64,
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (!notification.isRead) {
          ref.read(userNotificationsProvider.notifier).markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.isRead ? Colors.transparent : colors.accentPrimary.withValues(alpha: 0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type, colors).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTypeIcon(notification.type),
                size: 18,
                color: _getTypeColor(notification.type, colors),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textQuaternary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    return switch (type) {
      NotificationType.jobAssigned => LucideIcons.briefcase,
      NotificationType.invoicePaid => LucideIcons.dollarSign,
      NotificationType.bidAccepted => LucideIcons.checkCircle,
      NotificationType.bidRejected => LucideIcons.xCircle,
      NotificationType.changeOrderApproved => LucideIcons.fileDiff,
      NotificationType.changeOrderRejected => LucideIcons.fileX,
      NotificationType.timeEntryApproved => LucideIcons.clock,
      NotificationType.timeEntryRejected => LucideIcons.clock4,
      NotificationType.customerMessage => LucideIcons.messageSquare,
      NotificationType.system => LucideIcons.bell,
    };
  }

  Color _getTypeColor(NotificationType type, dynamic colors) {
    return switch (type) {
      NotificationType.jobAssigned => colors.accentInfo as Color,
      NotificationType.invoicePaid => colors.accentSuccess as Color,
      NotificationType.bidAccepted => colors.accentSuccess as Color,
      NotificationType.bidRejected => colors.accentError as Color,
      NotificationType.changeOrderApproved => colors.accentSuccess as Color,
      NotificationType.changeOrderRejected => colors.accentError as Color,
      NotificationType.timeEntryApproved => colors.accentInfo as Color,
      NotificationType.timeEntryRejected => colors.accentWarning as Color,
      NotificationType.customerMessage => colors.accentPrimary as Color,
      NotificationType.system => colors.textTertiary as Color,
    };
  }
}
