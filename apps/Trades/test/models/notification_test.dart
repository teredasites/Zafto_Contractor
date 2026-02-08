// ZAFTO Notification Model Tests
// Tests fromJson, NotificationType.fromString, dbValue, copyWith,
// and computed properties (timeAgo, isRecent).

import 'package:flutter_test/flutter_test.dart';
import 'package:zafto/models/notification.dart';

void main() {
  // Fixed timestamps.
  final created = DateTime.utc(2025, 6, 15, 10, 0, 0);
  final readAt = DateTime.utc(2025, 6, 15, 11, 0, 0);

  /// Full snake_case JSON as Supabase would return it.
  Map<String, dynamic> fullSnakeCaseJson() => {
        'id': 'notif-001',
        'company_id': 'comp-001',
        'user_id': 'user-001',
        'title': 'New Job Assigned',
        'body': 'You have been assigned to Panel Upgrade at 123 Main St.',
        'type': 'job_assigned',
        'entity_type': 'job',
        'entity_id': 'job-001',
        'is_read': false,
        'read_at': null,
        'created_at': created.toIso8601String(),
      };

  group('NotificationType', () {
    // ================================================================
    // fromString
    // ================================================================
    group('fromString', () {
      test('parses all 10 types correctly', () {
        final expectedMappings = {
          'job_assigned': NotificationType.jobAssigned,
          'invoice_paid': NotificationType.invoicePaid,
          'bid_accepted': NotificationType.bidAccepted,
          'bid_rejected': NotificationType.bidRejected,
          'change_order_approved': NotificationType.changeOrderApproved,
          'change_order_rejected': NotificationType.changeOrderRejected,
          'time_entry_approved': NotificationType.timeEntryApproved,
          'time_entry_rejected': NotificationType.timeEntryRejected,
          'customer_message': NotificationType.customerMessage,
          'system': NotificationType.system,
        };

        for (final entry in expectedMappings.entries) {
          expect(NotificationType.fromString(entry.key), entry.value,
              reason: '${entry.key} should parse to ${entry.value}');
        }
      });

      test('falls back to system for unknown string', () {
        expect(
            NotificationType.fromString('unknown_type'), NotificationType.system);
      });

      test('falls back to system for null', () {
        expect(NotificationType.fromString(null), NotificationType.system);
      });

      test('falls back to system for empty string', () {
        expect(NotificationType.fromString(''), NotificationType.system);
      });
    });

    // ================================================================
    // dbValue
    // ================================================================
    group('dbValue', () {
      test('returns expected snake_case strings for all types', () {
        final expectedDbValues = {
          NotificationType.jobAssigned: 'job_assigned',
          NotificationType.invoicePaid: 'invoice_paid',
          NotificationType.bidAccepted: 'bid_accepted',
          NotificationType.bidRejected: 'bid_rejected',
          NotificationType.changeOrderApproved: 'change_order_approved',
          NotificationType.changeOrderRejected: 'change_order_rejected',
          NotificationType.timeEntryApproved: 'time_entry_approved',
          NotificationType.timeEntryRejected: 'time_entry_rejected',
          NotificationType.customerMessage: 'customer_message',
          NotificationType.system: 'system',
        };

        for (final entry in expectedDbValues.entries) {
          expect(entry.key.dbValue, entry.value,
              reason: '${entry.key} dbValue should be ${entry.value}');
        }
      });

      test('fromString(dbValue) roundtrips for all types', () {
        for (final type in NotificationType.values) {
          expect(NotificationType.fromString(type.dbValue), type,
              reason: '${type.name} should roundtrip through dbValue');
        }
      });
    });
  });

  group('AppNotification', () {
    // ================================================================
    // fromJson
    // ================================================================
    group('fromJson', () {
      test('parses snake_case Supabase data', () {
        final notification = AppNotification.fromJson(fullSnakeCaseJson());

        expect(notification.id, 'notif-001');
        expect(notification.companyId, 'comp-001');
        expect(notification.userId, 'user-001');
        expect(notification.title, 'New Job Assigned');
        expect(notification.body,
            'You have been assigned to Panel Upgrade at 123 Main St.');
        expect(notification.type, NotificationType.jobAssigned);
        expect(notification.entityType, 'job');
        expect(notification.entityId, 'job-001');
        expect(notification.isRead, isFalse);
        expect(notification.readAt, isNull);
        expect(notification.createdAt, created);
      });

      test('parses read notification with read_at set', () {
        final json = fullSnakeCaseJson();
        json['is_read'] = true;
        json['read_at'] = readAt.toIso8601String();

        final notification = AppNotification.fromJson(json);

        expect(notification.isRead, isTrue);
        expect(notification.readAt, readAt);
      });

      test('defaults to empty strings and system type for minimal data', () {
        final notification = AppNotification.fromJson({
          'created_at': created.toIso8601String(),
        });

        expect(notification.id, '');
        expect(notification.companyId, '');
        expect(notification.userId, '');
        expect(notification.title, '');
        expect(notification.body, '');
        expect(notification.type, NotificationType.system);
        expect(notification.entityType, isNull);
        expect(notification.entityId, isNull);
        expect(notification.isRead, isFalse);
        expect(notification.readAt, isNull);
      });

      test('parses all notification type strings from DB', () {
        for (final type in NotificationType.values) {
          final notification = AppNotification.fromJson({
            'type': type.dbValue,
            'created_at': created.toIso8601String(),
          });
          expect(notification.type, type,
              reason: '${type.dbValue} should parse to ${type.name}');
        }
      });
    });

    // ================================================================
    // copyWith
    // ================================================================
    group('copyWith', () {
      test('marks as read while preserving other fields', () {
        final original = AppNotification.fromJson(fullSnakeCaseJson());
        final now = DateTime.now();
        final marked = original.copyWith(isRead: true, readAt: now);

        expect(marked.isRead, isTrue);
        expect(marked.readAt, now);
        // Preserved
        expect(marked.id, original.id);
        expect(marked.companyId, original.companyId);
        expect(marked.userId, original.userId);
        expect(marked.title, original.title);
        expect(marked.body, original.body);
        expect(marked.type, original.type);
        expect(marked.entityType, original.entityType);
        expect(marked.entityId, original.entityId);
        expect(marked.createdAt, original.createdAt);
      });

      test('changes title while preserving other fields', () {
        final original = AppNotification.fromJson(fullSnakeCaseJson());
        final modified = original.copyWith(title: 'Updated Title');

        expect(modified.title, 'Updated Title');
        expect(modified.id, original.id);
        expect(modified.body, original.body);
        expect(modified.type, original.type);
        expect(modified.isRead, original.isRead);
      });
    });

    // ================================================================
    // Computed: timeAgo
    // ================================================================
    group('timeAgo', () {
      test('returns "just now" for less than 60 seconds ago', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        expect(notification.timeAgo, 'just now');
      });

      test('returns minutes ago for 1-59 minutes', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(notification.timeAgo, '5m ago');
      });

      test('returns "1m ago" for exactly 1 minute', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        expect(notification.timeAgo, '1m ago');
      });

      test('returns hours ago for 1-23 hours', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        );
        expect(notification.timeAgo, '3h ago');
      });

      test('returns "1h ago" for exactly 1 hour', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(notification.timeAgo, '1h ago');
      });

      test('returns days ago for 1-6 days', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        );
        expect(notification.timeAgo, '3d ago');
      });

      test('returns weeks ago for 7-29 days', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        );
        expect(notification.timeAgo, '2w ago');
      });

      test('returns months ago for 30+ days', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        );
        expect(notification.timeAgo, '2mo ago');
      });

      test('returns "1mo ago" for 30-59 days', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(days: 35)),
        );
        expect(notification.timeAgo, '1mo ago');
      });
    });

    // ================================================================
    // Computed: isRecent
    // ================================================================
    group('isRecent', () {
      test('returns true for notification created less than 24 hours ago', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        );
        expect(notification.isRecent, isTrue);
      });

      test('returns true for notification created just now', () {
        final notification = AppNotification(
          createdAt: DateTime.now(),
        );
        expect(notification.isRecent, isTrue);
      });

      test('returns false for notification created 24+ hours ago', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
        );
        expect(notification.isRecent, isFalse);
      });

      test('returns false for notification created days ago', () {
        final notification = AppNotification(
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        );
        expect(notification.isRecent, isFalse);
      });
    });

    // ================================================================
    // Constructor defaults
    // ================================================================
    group('constructor defaults', () {
      test('uses DateTime.now() when createdAt is not provided', () {
        final before = DateTime.now();
        final notification = AppNotification();
        final after = DateTime.now();

        expect(
            notification.createdAt.isAfter(
                before.subtract(const Duration(milliseconds: 100))),
            isTrue);
        expect(
            notification.createdAt
                .isBefore(after.add(const Duration(milliseconds: 100))),
            isTrue);
      });

      test('defaults are correct', () {
        final notification = AppNotification();

        expect(notification.id, '');
        expect(notification.companyId, '');
        expect(notification.userId, '');
        expect(notification.title, '');
        expect(notification.body, '');
        expect(notification.type, NotificationType.system);
        expect(notification.entityType, isNull);
        expect(notification.entityId, isNull);
        expect(notification.isRead, isFalse);
        expect(notification.readAt, isNull);
      });
    });
  });
}
