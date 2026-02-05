import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO Active Job Card - Design System v2.6 / Phase 0.5
///
/// Current job context card displayed on home screen.
///
/// Structure:
/// ┌─────────────────────────────────────────┐
/// │  ● ACTIVE JOB              Today, 2 PM │
/// │  Panel Upgrade - 200A                   │
/// │  Michael Chen · 1847 Oak Street         │
/// │  $2,850                    [Continue →] │
/// └─────────────────────────────────────────┘
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoActiveJobCard(
///   title: 'Panel Upgrade - 200A',
///   customerName: 'Michael Chen',
///   address: '1847 Oak Street',
///   amount: 2850.00,
///   time: 'Today, 2 PM',
///   onContinue: () => _openJob(),
/// )
/// ```

class ZaftoActiveJobCard extends ConsumerWidget {
  /// Job title/description
  final String title;

  /// Customer name
  final String customerName;

  /// Job address (optional)
  final String? address;

  /// Job amount in dollars
  final double? amount;

  /// Formatted time string (e.g., "Today, 2 PM")
  final String time;

  /// Callback when continue button is tapped
  final VoidCallback? onContinue;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Whether to show the continue button
  final bool showContinueButton;

  /// Custom action button text
  final String continueText;

  /// Whether to add horizontal margin
  final bool addMargin;

  const ZaftoActiveJobCard({
    super.key,
    required this.title,
    required this.customerName,
    this.address,
    this.amount,
    required this.time,
    this.onContinue,
    this.onTap,
    this.showContinueButton = true,
    this.continueText = 'Continue',
    this.addMargin = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        // Spec: margin 20px horizontal
        margin: addMargin ? const EdgeInsets.symmetric(horizontal: 20) : null,
        // Spec: padding 16px
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Spec: bgElevated background
          color: colors.bgElevated,
          // Spec: borderSubtle border
          border: Border.all(color: colors.borderSubtle),
          // Spec: 16px border radius
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            _buildHeader(colors),
            // Spec: 12px gap
            const SizedBox(height: 12),
            // Title - Spec: 17px, w600, textPrimary
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            // Spec: 4px gap
            const SizedBox(height: 4),
            // Customer - Spec: 13px, textSecondary
            Text(
              _buildCustomerText(),
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            // Spec: 12px gap
            const SizedBox(height: 12),
            // Footer row
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Row(
      children: [
        // Live dot - Spec: 8x8px, accentSuccess, circle
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors.accentSuccess,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // "ACTIVE JOB" - Spec: 11px, w600, accentSuccess, letter-spacing 0.5px
        Text(
          'ACTIVE JOB',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.accentSuccess,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        // Time - Spec: 11px, textTertiary
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  String _buildCustomerText() {
    if (address != null && address!.isNotEmpty) {
      return '$customerName · $address';
    }
    return customerName;
  }

  Widget _buildFooter(ZaftoColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Amount - Spec: 20px, w700, textPrimary
        if (amount != null)
          Text(
            _formatAmount(amount!),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          )
        else
          const SizedBox(),
        // Continue button
        if (showContinueButton) _buildContinueButton(colors),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return '\$${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  Widget _buildContinueButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onContinue?.call();
      },
      child: Container(
        // Spec: 20px horizontal, 10px vertical padding
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // Spec: accentPrimary background
          color: colors.accentPrimary,
          // Spec: 20px border radius (pill)
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spec: 13px, w600, black
            Text(
              continueText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            // Spec: arrowRight, 16px, black
            const Icon(
              LucideIcons.arrowRight,
              size: 16,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scheduled job card variant (not active, but upcoming)
///
/// Usage:
/// ```dart
/// ZaftoScheduledJobCard(
///   title: 'Outlet Installation',
///   customerName: 'Sarah Wilson',
///   time: 'Tomorrow, 9 AM',
///   onTap: () => _openJob(),
/// )
/// ```
class ZaftoScheduledJobCard extends ConsumerWidget {
  final String title;
  final String customerName;
  final String? address;
  final double? amount;
  final String time;
  final VoidCallback? onTap;
  final bool addMargin;

  const ZaftoScheduledJobCard({
    super.key,
    required this.title,
    required this.customerName,
    this.address,
    this.amount,
    required this.time,
    this.onTap,
    this.addMargin = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        margin: addMargin ? const EdgeInsets.symmetric(horizontal: 20) : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'SCHEDULED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Customer
            Text(
              address != null ? '$customerName · $address' : customerName,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            if (amount != null) ...[
              const SizedBox(height: 8),
              Text(
                '\$${amount!.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No active job card (empty state)
///
/// Usage:
/// ```dart
/// ZaftoNoActiveJobCard(
///   onCreateJob: () => _createNewJob(),
/// )
/// ```
class ZaftoNoActiveJobCard extends ConsumerWidget {
  final VoidCallback? onCreateJob;
  final bool addMargin;

  const ZaftoNoActiveJobCard({
    super.key,
    this.onCreateJob,
    this.addMargin = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      margin: addMargin ? const EdgeInsets.symmetric(horizontal: 20) : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clipboardList,
            size: 32,
            color: colors.textQuaternary,
          ),
          const SizedBox(height: 12),
          Text(
            'No Active Job',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a job to track time and materials',
            style: TextStyle(
              fontSize: 13,
              color: colors.textTertiary,
            ),
          ),
          if (onCreateJob != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onCreateJob!();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Start Job',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
