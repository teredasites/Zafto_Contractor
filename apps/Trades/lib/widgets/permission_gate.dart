import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permission_service.dart';
import '../models/company.dart';

/// Gate widget that shows/hides content based on permissions
///
/// Usage:
/// ```dart
/// PermissionGate(
///   permission: permJobsCreate,
///   child: ElevatedButton(
///     onPressed: () => createJob(),
///     child: Text('New Job'),
///   ),
/// )
/// ```
class PermissionGate extends ConsumerWidget {
  /// Single permission to check
  final String? permission;

  /// Multiple permissions - ALL must be granted
  final List<String>? permissions;

  /// Multiple permissions - ANY must be granted
  final List<String>? anyPermissions;

  /// Child to show when permission is granted
  final Widget child;

  /// Optional widget to show when permission is denied
  /// If null, renders nothing (SizedBox.shrink)
  final Widget? fallback;

  /// If true, show fallback instead of hiding
  final bool showFallback;

  const PermissionGate({
    super.key,
    this.permission,
    this.permissions,
    this.anyPermissions,
    required this.child,
    this.fallback,
    this.showFallback = false,
  }) : assert(
          permission != null || permissions != null || anyPermissions != null,
          'Must provide permission, permissions, or anyPermissions',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permService = ref.watch(permissionServiceProvider);

    bool hasAccess = false;

    if (permission != null) {
      hasAccess = permService.can(permission!);
    } else if (permissions != null) {
      hasAccess = permService.canAll(permissions!);
    } else if (anyPermissions != null) {
      hasAccess = permService.canAny(anyPermissions!);
    }

    if (hasAccess) {
      return child;
    }

    if (showFallback && fallback != null) {
      return fallback!;
    }

    return const SizedBox.shrink();
  }
}

/// Gate widget that shows/hides content based on company tier
///
/// Usage:
/// ```dart
/// TierGate(
///   minimumTier: CompanyTier.team,
///   child: TeamManagementSection(),
///   fallback: UpgradePrompt(),
/// )
/// ```
class TierGate extends ConsumerWidget {
  /// Minimum tier required to see this content
  final CompanyTier minimumTier;

  /// Specific feature to check (alternative to minimumTier)
  final String? feature;

  /// Child to show when tier requirement is met
  final Widget child;

  /// Optional widget to show when tier requirement is not met
  final Widget? fallback;

  /// If true, show fallback instead of hiding
  final bool showFallback;

  const TierGate({
    super.key,
    this.minimumTier = CompanyTier.solo,
    this.feature,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permService = ref.watch(permissionServiceProvider);

    bool hasAccess = false;

    if (feature != null) {
      hasAccess = permService.isTierFeatureAvailable(feature!);
    } else {
      // Check based on minimum tier
      final currentTier = permService.tier;
      if (currentTier != null) {
        hasAccess = _tierMeetsMinimum(currentTier, minimumTier);
      }
    }

    if (hasAccess) {
      return child;
    }

    if (showFallback && fallback != null) {
      return fallback!;
    }

    return const SizedBox.shrink();
  }

  bool _tierMeetsMinimum(CompanyTier current, CompanyTier minimum) {
    const tierOrder = [
      CompanyTier.solo,
      CompanyTier.team,
      CompanyTier.business,
      CompanyTier.enterprise,
    ];

    return tierOrder.indexOf(current) >= tierOrder.indexOf(minimum);
  }
}

/// Upgrade prompt widget shown when a feature requires a higher tier
class UpgradePrompt extends StatelessWidget {
  final String featureName;
  final CompanyTier requiredTier;
  final VoidCallback? onUpgrade;

  const UpgradePrompt({
    super.key,
    required this.featureName,
    required this.requiredTier,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            featureName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Available on ${_tierDisplayName(requiredTier)} plan',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          if (onUpgrade != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onUpgrade,
              child: const Text('Upgrade'),
            ),
          ],
        ],
      ),
    );
  }

  String _tierDisplayName(CompanyTier tier) {
    switch (tier) {
      case CompanyTier.solo:
        return 'Solo';
      case CompanyTier.team:
        return 'Team';
      case CompanyTier.business:
        return 'Business';
      case CompanyTier.enterprise:
        return 'Enterprise';
    }
  }
}

/// Widget that shows a "Pro" badge for tier-gated features
class ProBadge extends StatelessWidget {
  final CompanyTier requiredTier;

  const ProBadge({
    super.key,
    this.requiredTier = CompanyTier.team,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        requiredTier == CompanyTier.enterprise ? 'ENT' : 'PRO',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Extension for easy permission checking in widgets
extension PermissionExtensions on WidgetRef {
  /// Check if current user has permission
  bool can(String permission) {
    return watch(permissionServiceProvider).can(permission);
  }

  /// Check if current user has all permissions
  bool canAll(List<String> permissions) {
    return watch(permissionServiceProvider).canAll(permissions);
  }

  /// Check if tier feature is available
  bool hasTierFeature(String feature) {
    return watch(permissionServiceProvider).isTierFeatureAvailable(feature);
  }

  /// Get current company tier
  CompanyTier? get currentTier {
    return watch(permissionServiceProvider).tier;
  }
}
