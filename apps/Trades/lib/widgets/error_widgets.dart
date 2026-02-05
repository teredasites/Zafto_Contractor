import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/error_service.dart';

/// ZAFTO Error Widgets
/// 
/// Reusable error UI components for consistent UX across app.
/// - Error snackbars
/// - Retry buttons
/// - Offline banners
/// 
/// PRESERVES: All existing app functionality - this is an ADDITION.

/// Show an error snackbar with optional retry action
void showErrorSnackbar(
  BuildContext context, {
  required String message,
  VoidCallback? onRetry,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: onRetry != null
          ? SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
            )
          : null,
    ),
  );
}

/// Show a success snackbar
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Retry button widget with loading state
class RetryButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onRetry;
  final Color? color;

  const RetryButton({
    super.key,
    this.label = 'Try Again',
    required this.onRetry,
    this.color,
  });

  @override
  State<RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<RetryButton> {
  bool _isLoading = false;

  Future<void> _handleRetry() async {
    if (_isLoading) return;
    
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    
    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleRetry,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
              ),
            )
          : const Icon(Icons.refresh, size: 20),
      label: Text(_isLoading ? 'Retrying...' : widget.label),
    );
  }
}

/// Offline banner that shows at top of screen
class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange.shade800,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'You\'re offline. Some features may be unavailable.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            if (onRetry != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onRetry!();
                },
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Error state widget for empty/error screens
class ErrorStateWidget extends StatelessWidget {
  final AppError? error;
  final String? message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.error,
    this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? error?.userMessage ?? 'Something went wrong';
    final displayDetails = details ?? error?.technicalDetails;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
              textAlign: TextAlign.center,
            ),
            if (displayDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                displayDetails,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              RetryButton(onRetry: () async => onRetry!()),
            ],
          ],
        ),
      ),
    );
  }
}
