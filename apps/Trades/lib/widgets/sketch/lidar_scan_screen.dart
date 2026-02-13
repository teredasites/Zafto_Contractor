// ZAFTO LiDAR Scan Screen — SK5
// Full scanning UX overlay for Apple RoomPlan integration.
// Shows instructions, real-time scan progress, and transitions to
// sketch editor with scanned floor plan loaded.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/roomplan_bridge.dart';
import '../../services/roomplan_converter.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class LidarScanScreen extends ConsumerStatefulWidget {
  const LidarScanScreen({super.key});

  @override
  ConsumerState<LidarScanScreen> createState() => _LidarScanScreenState();
}

class _LidarScanScreenState extends ConsumerState<LidarScanScreen> {
  final RoomPlanBridge _bridge = RoomPlanBridge();
  StreamSubscription<RoomPlanProgress>? _progressSub;
  RoomPlanProgress _progress = const RoomPlanProgress();

  bool _isChecking = true;
  bool _isAvailable = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _bridge.checkAvailability();
    if (mounted) {
      setState(() {
        _isAvailable = available;
        _isChecking = false;
      });
    }
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        _isScanning = true;
        _error = null;
        _progress = const RoomPlanProgress();
      });

      // Listen to progress updates
      _progressSub = _bridge.progressStream.listen(
        (progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() => _error = 'Scan progress error: $e');
          }
        },
      );

      await _bridge.startScan();
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _finishScan() async {
    setState(() => _isProcessing = true);
    _progressSub?.cancel();

    try {
      final roomData = await _bridge.stopScan();
      if (roomData == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isScanning = false;
            _error = 'No room data captured';
          });
        }
        return;
      }

      // Convert CapturedRoom to FloorPlanData
      final planData = RoomPlanConverter.convert(roomData);

      if (mounted) {
        // Return the scanned plan data to caller
        Navigator.pop(context, planData);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isScanning = false;
          _error = 'Failed to process scan: ${e.message}';
        });
      }
    }
  }

  Future<void> _cancelScan() async {
    _progressSub?.cancel();
    await _bridge.dispose();
    if (mounted) {
      setState(() {
        _isScanning = false;
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isChecking
            ? _buildCheckingState(colors)
            : !_isAvailable
                ? _buildUnavailableState(colors)
                : _isScanning
                    ? _buildScanningState(colors)
                    : _buildReadyState(colors),
      ),
    );
  }

  // Checking device capability
  Widget _buildCheckingState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Checking LiDAR availability...',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Device doesn't support RoomPlan
  Widget _buildUnavailableState(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.scanLine, size: 48, color: colors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'LiDAR Not Available',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LiDAR scanning requires an iPhone 12 Pro or newer with iOS 16+. '
              'Use Manual Room Entry instead.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                  'Go Back',
                  LucideIcons.arrowLeft,
                  colors.textSecondary,
                  () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                _buildButton(
                  'Manual Entry',
                  LucideIcons.layoutGrid,
                  colors.accentPrimary,
                  () => Navigator.pop(context, 'manual'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Ready to scan
  Widget _buildReadyState(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.scan, size: 56, color: colors.accentPrimary),
            const SizedBox(height: 20),
            Text(
              'LiDAR Room Scan',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Point your camera at the room and slowly walk around.\n'
              'Make sure all walls, doors, and windows are visible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                _startScan();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.scan, size: 18,
                        color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Start Scanning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active scanning
  Widget _buildScanningState(ZaftoColors colors) {
    return Stack(
      children: [
        // Native RoomPlan view will be shown underneath (platform view)
        // For now, show progress overlay
        Center(
          child: _isProcessing
              ? _buildProcessingOverlay(colors)
              : _buildScanProgressOverlay(colors),
        ),
        // Top bar with cancel
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withValues(alpha: 0.6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.x,
                      size: 20, color: Colors.white),
                  onPressed: _cancelScan,
                ),
                const Spacer(),
                Text(
                  'Scanning...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 40), // Balance
              ],
            ),
          ),
        ),
        // Bottom: Done button
        if (!_isProcessing)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _finishScan();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E)
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.check, size: 18,
                          color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScanProgressOverlay(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.scan, size: 32,
              color: colors.accentPrimary),
          const SizedBox(height: 12),
          Text(
            'Point camera at the room',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Progress counters
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressChip('Walls', _progress.wallCount, colors),
              const SizedBox(width: 8),
              _buildProgressChip('Doors', _progress.doorCount, colors),
              const SizedBox(width: 8),
              _buildProgressChip(
                  'Windows', _progress.windowCount, colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Processing scan...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Converting 3D data to floor plan',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChip(
      String label, int count, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
