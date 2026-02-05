/// ZAFTO Pro Mode Gate Widget
/// Session 23 - Conditionally show/hide features based on UI mode
///
/// Usage:
/// ```dart
/// ProModeGate(
///   child: LeadsTab(),  // Only shows in Pro Mode
///   fallback: null,     // Optional fallback widget
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/company.dart';
import '../services/ui_mode_service.dart';
import '../theme/zafto_colors.dart';
import '../theme/theme_provider.dart';

/// Gate that shows child only in Pro Mode
class ProModeGate extends ConsumerWidget {
  /// Widget to show when in Pro Mode
  final Widget child;

  /// Optional widget to show in Simple Mode (defaults to nothing)
  final Widget? fallback;

  /// Optional specific feature to check (if set, checks feature instead of just pro mode)
  final String? feature;

  /// If true, shows an upgrade prompt instead of fallback
  final bool showUpgradePrompt;

  const ProModeGate({
    super.key,
    required this.child,
    this.fallback,
    this.feature,
    this.showUpgradePrompt = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProMode = ref.watch(isProModeProvider);

    // If checking a specific feature
    if (feature != null) {
      final hasFeature = ref.watch(proFeatureProvider(feature!));
      if (!hasFeature) {
        return showUpgradePrompt
            ? _UpgradePrompt(feature: feature!)
            : (fallback ?? const SizedBox.shrink());
      }
      return child;
    }

    // General pro mode check
    if (!isProMode) {
      return showUpgradePrompt
          ? const _UpgradePrompt()
          : (fallback ?? const SizedBox.shrink());
    }

    return child;
  }
}

/// Conditionally show content only in Simple Mode
class SimpleModeGate extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const SimpleModeGate({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProMode = ref.watch(isProModeProvider);

    if (isProMode) {
      return fallback ?? const SizedBox.shrink();
    }

    return child;
  }
}

/// Badge to indicate a Pro feature
class ProBadge extends ConsumerWidget {
  final double size;
  final bool showLabel;

  const ProBadge({
    super.key,
    this.size = 16,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.accentPrimary,
              colors.accentPrimary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: size - 2, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: size - 4,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accentPrimary,
            colors.accentPrimary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        LucideIcons.sparkles,
        size: size - 4,
        color: Colors.white,
      ),
    );
  }
}

/// Upgrade prompt widget
class _UpgradePrompt extends ConsumerWidget {
  final String? feature;

  const _UpgradePrompt({this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final modeNotifier = ref.read(uiModeNotifierProvider.notifier);

    // Find feature info
    ProFeature? featureInfo;
    if (feature != null) {
      featureInfo = proFeatures.firstWhere(
        (f) => f.id == feature,
        orElse: () => const ProFeature(
          id: 'unknown',
          name: 'Pro Feature',
          description: 'This feature requires Pro Mode',
          icon: 'sparkles',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.sparkles,
              size: 32,
              color: colors.accentPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            featureInfo?.name ?? 'Pro Mode Feature',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            featureInfo?.description ?? 'Enable Pro Mode to access advanced CRM features',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => modeNotifier.setMode(UiMode.pro),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.sparkles, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Enable Pro Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

