import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/services/checklist_cache_service.dart';

// ============================================================
// Offline Banner
//
// Compact status indicator that shows sync state:
//   - Online + all synced  → hidden (no visual noise)
//   - Online + pending     → amber chip "N pending"
//   - Offline              → red chip "Offline — saving locally"
//
// Designed to sit at the top of any screen or inside AppShell.
// ============================================================

/// Riverpod provider for connectivity state.
final connectivityProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();

  // Emit initial state
  Connectivity().checkConnectivity().then((result) {
    controller.add(!result.contains(ConnectivityResult.none));
  });

  // Listen for changes
  final sub = Connectivity().onConnectivityChanged.listen((result) {
    controller.add(!result.contains(ConnectivityResult.none));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final pendingCount =
        ref.watch(checklistCacheServiceProvider).pendingSync;

    // Nothing to show — all good
    if (isOnline && pendingCount == 0) return const SizedBox.shrink();

    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String label;

    if (!isOnline) {
      bgColor = Colors.red.shade900.withValues(alpha: 0.9);
      fgColor = Colors.red.shade100;
      icon = LucideIcons.wifiOff;
      label = 'Offline \u2014 saving locally';
    } else {
      bgColor = Colors.amber.shade900.withValues(alpha: 0.85);
      fgColor = Colors.amber.shade100;
      icon = LucideIcons.uploadCloud;
      label = '$pendingCount pending sync';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
