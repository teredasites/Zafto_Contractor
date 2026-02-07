// ZAFTO Sentry Service — Error Monitoring Helper
// Created: Session 55
//
// Thin wrapper around Sentry SDK. Keeps Sentry calls centralized
// so every screen/service doesn't import sentry_flutter directly.
//
// Usage:
//   SentryService.configureScope(userId, companyId, role);
//   SentryService.captureException(e, stackTrace: s);
//   SentryService.addBreadcrumb('Navigated to jobs');

import 'package:sentry_flutter/sentry_flutter.dart';

class SentryService {
  SentryService._();

  /// Set Sentry user context (call on login / profile load).
  /// Pass all nulls to clear (call on logout).
  static void configureScope(
    String? userId,
    String? companyId,
    String? role,
  ) {
    Sentry.configureScope((scope) {
      if (userId != null) {
        scope.setUser(SentryUser(id: userId));
        if (companyId != null) {
          scope.setTag('company_id', companyId);
        }
        if (role != null) {
          scope.setTag('role', role);
        }
      } else {
        scope.setUser(null);
        scope.removeTag('company_id');
        scope.removeTag('role');
      }
    });
  }

  /// Capture an exception with optional stack trace and extra data.
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: extras != null
          ? (scope) {
              for (final entry in extras.entries) {
                scope.setExtra(entry.key, entry.value);
              }
            }
          : null,
    );
  }

  /// Add a breadcrumb for tracing user actions / navigation.
  static void addBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }
}
