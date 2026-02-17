// ZAFTO — Laser Measurement Overlay
// Created: Sprint FIELD4 (Session 131)
//
// Canvas overlay for the Sketch Engine that shows:
// - Live distance readout near the last drawn point
// - Dashed line from last point to where measurement applies
// - Haptic feedback on measurement received
// - Visual pulse animation on new measurement
//
// This is a non-interactive overlay that sits on top of the sketch canvas
// and reads from the laser meter provider.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/laser_meter_provider.dart';
import '../services/laser_meter/laser_meter_adapter.dart';

// =============================================================================
// OVERLAY WIDGET
// =============================================================================

class LaserMeasurementOverlay extends ConsumerStatefulWidget {
  /// Position on canvas where the last wall endpoint was placed.
  final Offset? lastEndpoint;

  /// Whether the user is currently drawing a wall (show readout).
  final bool isDrawingWall;

  /// Callback when user taps "Apply" on a measurement.
  final void Function(double distanceInches)? onApplyMeasurement;

  const LaserMeasurementOverlay({
    super.key,
    this.lastEndpoint,
    this.isDrawingWall = false,
    this.onApplyMeasurement,
  });

  @override
  ConsumerState<LaserMeasurementOverlay> createState() =>
      _LaserMeasurementOverlayState();
}

class _LaserMeasurementOverlayState
    extends ConsumerState<LaserMeasurementOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  LaserMeasurement? _previousMeasurement;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laserMeterProvider);
    final measurement = state.lastMeasurement;

    // Trigger pulse animation + haptic on new measurement
    if (measurement != null && measurement != _previousMeasurement) {
      _previousMeasurement = measurement;
      _pulseController.forward(from: 0);
      HapticFeedback.lightImpact();
    }

    if (!state.isReady || measurement == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Measurement icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.straighten, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),

              // Measurement value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      measurement.displayImperial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      measurement.displayMetric,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Apply button (when drawing a wall)
              if (widget.isDrawingWall && widget.onApplyMeasurement != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onApplyMeasurement!(measurement.distanceInches);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Emerald
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Confidence warning
              if (measurement.confidence < 0.9 &&
                  !(widget.isDrawingWall &&
                      widget.onApplyMeasurement != null))
                Tooltip(
                  message:
                      'Low confidence: ${(measurement.confidence * 100).round()}%',
                  child: Icon(
                    Icons.warning_amber,
                    color: Colors.amber.shade300,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COMPACT INDICATOR (for toolbar area)
// =============================================================================

/// Small connected indicator shown in the sketch editor toolbar.
class LaserMeterStatusIndicator extends ConsumerWidget {
  const LaserMeterStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isLaserMeterConnectedProvider);

    if (!isConnected) return const SizedBox.shrink();

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
