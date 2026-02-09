import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
// Conditional import for SocketException
import 'platform_stub.dart' if (dart.library.io) 'dart:io';

/// ZAFTO Error Service
/// 
/// Centralized error handling for scale (100K+ users).
/// - Network error detection
/// - API error handling with retry logic
/// - Offline state detection
/// - Crashlytics integration
/// 
/// PRESERVES: All existing app functionality - this is an ADDITION.

enum ErrorType {
  network,
  timeout,
  server,
  api,
  offline,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? technicalDetails;
  final bool isRetryable;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.isRetryable = false,
    this.originalError,
    this.stackTrace,
  });

  /// User-friendly error messages
  String get userMessage {
    switch (type) {
      case ErrorType.network:
        return 'Connection problem. Check your internet and try again.';
      case ErrorType.timeout:
        return 'Request timed out. Please try again.';
      case ErrorType.server:
        return 'Server is temporarily unavailable. Try again in a moment.';
      case ErrorType.api:
        return 'Something went wrong. Please try again.';
      case ErrorType.offline:
        return 'You\'re offline. Some features require internet.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  /// Stream for listening to connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Initialize the error service
  Future<void> init() async {
    // Check initial connectivity
    await checkConnectivity();
  }

  /// Check current network connectivity
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _isOnline = false;
    } on TimeoutException catch (_) {
      _isOnline = false;
    }
    _connectivityController.add(_isOnline);
    return _isOnline;
  }

  /// Classify an error into AppError
  AppError classifyError(dynamic error, [StackTrace? stackTrace]) {
    if (error is SocketException) {
      return AppError(
        type: ErrorType.network,
        message: 'Network connection failed',
        technicalDetails: error.message,
        isRetryable: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return AppError(
        type: ErrorType.timeout,
        message: 'Request timed out',
        isRetryable: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is HttpException) {
      return AppError(
        type: ErrorType.server,
        message: 'Server error',
        technicalDetails: error.message,
        isRetryable: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Default to unknown
    return AppError(
      type: ErrorType.unknown,
      message: error.toString(),
      isRetryable: false,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error to Crashlytics (non-fatal)
  Future<void> logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    // Don't log in debug mode to avoid noise
    if (kDebugMode) {
      debugPrint('ERROR: $error');
      if (stackTrace != null) debugPrint('STACK: $stackTrace');
      return;
    }

    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    } catch (e) {
      debugPrint('Failed to log to Sentry: $e');
    }
  }

  /// Execute with retry logic (exponential backoff)
  /// Built for scale - prevents thundering herd on retries
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempt++;
        final appError = classifyError(error, stackTrace);

        if (!appError.isRetryable || attempt >= maxRetries) {
          await logError(error, stackTrace: stackTrace, reason: 'Max retries exceeded');
          rethrow;
        }

        // Add jitter to prevent thundering herd (important at scale)
        final jitter = Duration(milliseconds: (delay.inMilliseconds * 0.2 * (attempt % 3)).round());
        await Future.delayed(delay + jitter);
        
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivityController.close();
  }
}

/// Global error service instance
final errorService = ErrorService();
