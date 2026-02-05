/// ZAFTO Clock In/Out Button Widget
/// Session 23 - February 2026
///
/// A prominent clock button for the home screen that shows:
/// - Clock In state (green pulse)
/// - Clock Out state (red with elapsed time)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/zafto_colors.dart';
import '../theme/theme_provider.dart';
import '../models/time_entry.dart';
import '../services/time_clock_service.dart';

/// Compact clock button for header area
class ClockButtonCompact extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const ClockButtonCompact({super.key, this.onTap});

  @override
  ConsumerState<ClockButtonCompact> createState() => _ClockButtonCompactState();
}

class _ClockButtonCompactState extends ConsumerState<ClockButtonCompact> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every minute to refresh elapsed time
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final activeEntry = ref.watch(activeClockEntryProvider);
    final isClockedIn = activeEntry != null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isClockedIn
              ? const Color(0xFF22C55E).withOpacity(0.15)
              : colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isClockedIn
                ? const Color(0xFF22C55E)
                : colors.borderSubtle,
            width: isClockedIn ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.clock,
              size: 16,
              color: isClockedIn
                  ? const Color(0xFF22C55E)
                  : colors.textSecondary,
            ),
            if (isClockedIn) ...[
              const SizedBox(width: 6),
              Text(
                activeEntry.elapsedFormatted,
                style: TextStyle(
                  color: const Color(0xFF22C55E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Large clock button card for prominent display
class ClockButtonCard extends ConsumerStatefulWidget {
  final VoidCallback? onClockAction;

  const ClockButtonCard({super.key, this.onClockAction});

  @override
  ConsumerState<ClockButtonCard> createState() => _ClockButtonCardState();
}

class _ClockButtonCardState extends ConsumerState<ClockButtonCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Update every second when clocked in
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<GpsLocation?> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions permanently denied. Please enable in settings.');
        return null;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return GpsLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e) {
      _showError('Could not get location: $e');
      return null;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleClockAction() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    try {
      final location = await _getCurrentLocation();
      if (location == null) {
        setState(() => _isLoading = false);
        return;
      }

      final activeEntry = ref.read(activeClockEntryProvider);

      if (activeEntry == null) {
        // Clock in
        await ref.read(activeClockEntryProvider.notifier).clockIn(location);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clocked in successfully'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } else {
        // Clock out
        await ref.read(activeClockEntryProvider.notifier).clockOut(location);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Clocked out - ${activeEntry.workedTimeFormatted} worked'),
              backgroundColor: const Color(0xFF3B82F6),
            ),
          );
        }
      }

      widget.onClockAction?.call();
    } catch (e) {
      _showError('Clock action failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final activeEntry = ref.watch(activeClockEntryProvider);
    final isClockedIn = activeEntry != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _handleClockAction,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseValue = isClockedIn ? _pulseController.value * 0.3 : 0.0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isClockedIn
                      ? [
                          const Color(0xFF22C55E).withOpacity(0.15 + pulseValue),
                          const Color(0xFF16A34A).withOpacity(0.1 + pulseValue),
                        ]
                      : [
                          colors.bgElevated,
                          colors.bgBase,
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isClockedIn
                      ? const Color(0xFF22C55E).withOpacity(0.5 + pulseValue)
                      : colors.borderSubtle,
                  width: isClockedIn ? 2 : 1,
                ),
                boxShadow: isClockedIn
                    ? [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.2 + pulseValue * 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Clock icon with animation
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isClockedIn
                          ? const Color(0xFF22C55E)
                          : colors.accentPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            isClockedIn ? LucideIcons.pause : LucideIcons.play,
                            size: 28,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isClockedIn ? 'ON THE CLOCK' : 'CLOCK IN',
                          style: TextStyle(
                            color: isClockedIn
                                ? const Color(0xFF22C55E)
                                : colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isClockedIn) ...[
                          Text(
                            activeEntry.workedTimeFormatted,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (activeEntry.jobId != null)
                            Text(
                              'Working on job',
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                        ] else ...[
                          Text(
                            'Tap to start your shift',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    isClockedIn ? LucideIcons.logOut : LucideIcons.chevronRight,
                    color: isClockedIn
                        ? const Color(0xFF22C55E)
                        : colors.textTertiary,
                    size: 24,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Clock status widget showing current status (for dashboard/lists)
class ClockStatusBadge extends ConsumerWidget {
  final String? userId;
  final bool showTime;

  const ClockStatusBadge({
    super.key,
    this.userId,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final activeEntry = ref.watch(activeClockEntryProvider);
    final isClockedIn = activeEntry != null;

    if (!isClockedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.textTertiary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'OFF',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            showTime ? activeEntry.elapsedFormatted : 'ON',
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
