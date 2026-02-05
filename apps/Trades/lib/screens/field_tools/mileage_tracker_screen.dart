import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Mileage Tracker - GPS-based trip tracking for tax deductions
class MileageTrackerScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const MileageTrackerScreen({super.key, this.jobId});

  @override
  ConsumerState<MileageTrackerScreen> createState() => _MileageTrackerScreenState();
}

class _MileageTrackerScreenState extends ConsumerState<MileageTrackerScreen> {
  final List<_Trip> _trips = [];
  _Trip? _activeTrip;
  Timer? _trackingTimer;
  Position? _lastPosition;
  double _currentDistance = 0.0;
  String? _startAddress;

  // IRS 2024 standard mileage rate
  static const double _irsRate = 0.67; // $0.67 per mile

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  double get _totalMiles => _trips.fold(0.0, (sum, trip) => sum + trip.miles);
  double get _totalDeduction => _totalMiles * _irsRate;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mileage Tracker', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.fileSpreadsheet, color: colors.textSecondary),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          _buildSummaryCard(colors),

          // Active trip or start button
          if (_activeTrip != null)
            _buildActiveTrip(colors)
          else
            _buildStartButton(colors),

          // Trip history
          Expanded(
            child: _trips.isEmpty
                ? _buildEmptyState(colors)
                : _buildTripsList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.accentPrimary, colors.accentPrimary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.accentPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Miles',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_totalMiles.toStringAsFixed(1)} mi',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Tax Deduction',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${_totalDeduction.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTrip(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.accentSuccess,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.accentSuccess.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TRACKING ACTIVE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.accentSuccess,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${_currentDistance.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: colors.textPrimary),
                  ),
                  Text('miles', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                ],
              ),
              Column(
                children: [
                  Text(
                    _formatDuration(DateTime.now().difference(_activeTrip!.startTime)),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: colors.textPrimary),
                  ),
                  Text('duration', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_startAddress != null)
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: colors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'From: $_startAddress',
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.square),
              label: const Text('Stop Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentError,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _stopTracking,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(LucideIcons.navigation),
          label: const Text('Start Tracking'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accentPrimary,
            foregroundColor: colors.isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _startTracking,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.car, size: 48, color: colors.textTertiary),
          const SizedBox(height: 16),
          Text('No trips recorded', style: TextStyle(fontSize: 16, color: colors.textTertiary)),
          const SizedBox(height: 8),
          Text(
            'Start tracking to log mileage\nfor tax deductions',
            style: TextStyle(fontSize: 13, color: colors.textQuaternary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(ZaftoColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[_trips.length - 1 - index]; // Reverse order
        return _buildTripCard(colors, trip, index);
      },
    );
  }

  Widget _buildTripCard(ZaftoColors colors, _Trip trip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentInfo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.car, size: 20, color: colors.accentInfo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.miles.toStringAsFixed(1)} miles',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    ),
                    Text(
                      '\$${(trip.miles * _irsRate).toStringAsFixed(2)} deduction',
                      style: TextStyle(fontSize: 13, color: colors.accentSuccess),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FieldCameraService.formatDate(trip.startTime),
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  Text(
                    _formatDuration(trip.duration),
                    style: TextStyle(fontSize: 11, color: colors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          if (trip.startAddress != null || trip.endAddress != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 12, color: colors.accentSuccess),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.startAddress ?? 'Unknown',
                    style: TextStyle(fontSize: 11, color: colors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.flag, size: 12, color: colors.accentError),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.endAddress ?? 'Unknown',
                    style: TextStyle(fontSize: 11, color: colors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (trip.purpose != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                trip.purpose!,
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _startTracking() async {
    HapticFeedback.heavyImpact();

    // Get starting location
    final cameraService = ref.read(fieldCameraServiceProvider);
    final location = await cameraService.getCurrentLocation();

    setState(() {
      _activeTrip = _Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        startLat: location?.latitude,
        startLng: location?.longitude,
        startAddress: location?.address,
        miles: 0,
        duration: Duration.zero,
      );
      _currentDistance = 0;
      _startAddress = location?.address;
      _lastPosition = location != null
          ? Position(
              latitude: location.latitude,
              longitude: location.longitude,
              timestamp: DateTime.now(),
              accuracy: location.accuracy ?? 0,
              altitude: location.altitude ?? 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            )
          : null;
    });

    // Start tracking timer
    _trackingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateLocation());
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Convert meters to miles
        final miles = distance / 1609.34;

        // Only add if moved more than 10 meters (filter GPS noise)
        if (distance > 10) {
          setState(() => _currentDistance += miles);
        }
      }

      _lastPosition = position;
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _stopTracking() async {
    HapticFeedback.mediumImpact();
    _trackingTimer?.cancel();

    // Get ending location
    final cameraService = ref.read(fieldCameraServiceProvider);
    final location = await cameraService.getCurrentLocation();

    if (_activeTrip != null) {
      final completedTrip = _Trip(
        id: _activeTrip!.id,
        startTime: _activeTrip!.startTime,
        endTime: DateTime.now(),
        startLat: _activeTrip!.startLat,
        startLng: _activeTrip!.startLng,
        endLat: location?.latitude,
        endLng: location?.longitude,
        startAddress: _activeTrip!.startAddress,
        endAddress: location?.address,
        miles: _currentDistance,
        duration: DateTime.now().difference(_activeTrip!.startTime),
      );

      setState(() {
        _trips.add(completedTrip);
        _activeTrip = null;
        _currentDistance = 0;
      });

      // Ask for trip purpose
      _showPurposeDialog(completedTrip);
    }
  }

  void _showPurposeDialog(_Trip trip) {
    final colors = ref.read(zaftoColorsProvider);
    final purposes = ['Job site visit', 'Material pickup', 'Client meeting', 'Equipment delivery', 'Other'];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Trip Purpose', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ),
            const SizedBox(height: 16),
            ...purposes.map((purpose) => ListTile(
                  title: Text(purpose, style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    final index = _trips.indexWhere((t) => t.id == trip.id);
                    if (index >= 0) {
                      setState(() {
                        _trips[index] = _trips[index].copyWith(purpose: purpose);
                      });
                    }
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    HapticFeedback.lightImpact();
    // TODO: BACKEND - Generate CSV/PDF report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon'), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// ============================================================
// DATA CLASS
// ============================================================

class _Trip {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String? startAddress;
  final String? endAddress;
  final double miles;
  final Duration duration;
  final String? purpose;
  final String? jobId;

  const _Trip({
    required this.id,
    required this.startTime,
    this.endTime,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.startAddress,
    this.endAddress,
    required this.miles,
    required this.duration,
    this.purpose,
    this.jobId,
  });

  _Trip copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    String? startAddress,
    String? endAddress,
    double? miles,
    Duration? duration,
    String? purpose,
    String? jobId,
  }) {
    return _Trip(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      startAddress: startAddress ?? this.startAddress,
      endAddress: endAddress ?? this.endAddress,
      miles: miles ?? this.miles,
      duration: duration ?? this.duration,
      purpose: purpose ?? this.purpose,
      jobId: jobId ?? this.jobId,
    );
  }
}
