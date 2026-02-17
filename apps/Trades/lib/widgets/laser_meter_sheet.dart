// ZAFTO — Laser Meter Bottom Sheet
// Created: Sprint FIELD4 (Session 131)
//
// Bottom sheet for connecting/managing Bluetooth laser meters.
// Shows: scan results (device name, brand icon, signal strength, battery %),
// connect/disconnect button, live measurement display (large font, real-time),
// measurement history, beta badge for non-Bosch devices.
//
// Launched from Sketch Engine toolbar "Connect Laser" button.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/laser_meter_provider.dart';
import '../services/laser_meter/laser_meter_adapter.dart';

// =============================================================================
// LASER METER SHEET
// =============================================================================

class LaserMeterSheet extends ConsumerWidget {
  const LaserMeterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(laserMeterProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.ruler, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Laser Meter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (state.isReady)
                    _BatteryIndicator(
                        level: state.connectedDeviceInfo?.batteryLevel),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bluetooth status warnings
                    if (!state.bluetoothAvailable) ...[
                      _StatusCard(
                        icon: LucideIcons.bluetoothOff,
                        title: 'Bluetooth Not Available',
                        subtitle:
                            'This device does not support Bluetooth Low Energy.',
                        color: Colors.red,
                      ),
                    ] else if (!state.bluetoothEnabled) ...[
                      _StatusCard(
                        icon: LucideIcons.bluetoothOff,
                        title: 'Bluetooth is Off',
                        subtitle:
                            'Turn on Bluetooth in Settings to connect a laser meter.',
                        color: Colors.orange,
                      ),
                    ] else if (state.isReady) ...[
                      // Connected — show live measurement
                      _ConnectedSection(state: state, ref: ref),
                    ] else if (state.isConnecting) ...[
                      // Connecting state
                      _ConnectingSection(state: state),
                    ] else if (state.connectionState ==
                        LaserConnectionState.reconnecting) ...[
                      _StatusCard(
                        icon: LucideIcons.refreshCw,
                        title: 'Reconnecting...',
                        subtitle:
                            'Connection lost. Attempting to reconnect automatically.',
                        color: Colors.orange,
                        isAnimated: true,
                      ),
                    ] else if (state.hasError) ...[
                      _StatusCard(
                        icon: LucideIcons.alertTriangle,
                        title: 'Connection Failed',
                        subtitle: state.errorMessage ??
                            'Unable to connect. Make sure the laser meter is on and in range.',
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _ScanButton(state: state, ref: ref),
                    ] else ...[
                      // Idle / scan results
                      _ScanSection(state: state, ref: ref),
                    ],

                    // Measurement history (always visible when connected)
                    if (state.measurementHistory.isNotEmpty &&
                        state.isReady) ...[
                      const SizedBox(height: 16),
                      _MeasurementHistory(state: state, ref: ref),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SCAN SECTION
// =============================================================================

class _ScanSection extends StatelessWidget {
  final LaserMeterState state;
  final WidgetRef ref;

  const _ScanSection({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScanButton(state: state, ref: ref),

        if (state.discoveredDevices.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Nearby Devices (${state.discoveredDevices.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...state.discoveredDevices.map(
            (device) => _DeviceCard(
              device: device,
              onTap: () {
                ref.read(laserMeterProvider.notifier).connectToDevice(device.deviceId);
              },
            ),
          ),
        ] else if (!state.isScanning &&
            state.connectionState != LaserConnectionState.idle) ...[
          const SizedBox(height: 24),
          Icon(LucideIcons.searchX, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No laser meters found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Make sure your device is on, in Bluetooth mode, and within range.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// SCAN BUTTON
// =============================================================================

class _ScanButton extends StatelessWidget {
  final LaserMeterState state;
  final WidgetRef ref;

  const _ScanButton({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: state.isScanning
          ? () => ref.read(laserMeterProvider.notifier).stopScan()
          : () => ref.read(laserMeterProvider.notifier).startScan(),
      icon: state.isScanning
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(LucideIcons.bluetooth, size: 18),
      label: Text(state.isScanning ? 'Scanning...' : 'Scan for Devices'),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            state.isScanning ? Colors.orange : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// =============================================================================
// DEVICE CARD
// =============================================================================

class _DeviceCard extends StatelessWidget {
  final DiscoveredLaserDevice device;
  final VoidCallback onTap;

  const _DeviceCard({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Brand icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _brandColor(device.brand).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.ruler,
                    size: 20,
                    color: _brandColor(device.brand),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Device info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            device.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (device.brand.isBeta) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BETA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device.brand.displayName} \u00B7 ${device.signalQuality}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Signal strength indicator
              _SignalBars(rssi: device.rssi),
            ],
          ),
        ),
      ),
    );
  }

  Color _brandColor(LaserMeterBrand brand) {
    switch (brand) {
      case LaserMeterBrand.bosch:
        return const Color(0xFF005691); // Bosch blue
      case LaserMeterBrand.leica:
        return const Color(0xFFE30613); // Leica red
      case LaserMeterBrand.dewalt:
        return const Color(0xFFFFBE00); // DeWalt yellow
      case LaserMeterBrand.hilti:
        return const Color(0xFFDE0000); // Hilti red
      case LaserMeterBrand.milwaukee:
        return const Color(0xFFDB0032); // Milwaukee red
      case LaserMeterBrand.stabila:
        return const Color(0xFFF7D100); // Stabila yellow
      case LaserMeterBrand.generic:
        return Colors.grey;
    }
  }
}

// =============================================================================
// SIGNAL BARS
// =============================================================================

class _SignalBars extends StatelessWidget {
  final int rssi;

  const _SignalBars({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final bars = rssi > -50
        ? 4
        : rssi > -60
            ? 3
            : rssi > -75
                ? 2
                : 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final height = 6.0 + (i * 4);
        final isActive = i < bars;
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// CONNECTING SECTION
// =============================================================================

class _ConnectingSection extends StatelessWidget {
  final LaserMeterState state;

  const _ConnectingSection({required this.state});

  @override
  Widget build(BuildContext context) {
    String message;
    switch (state.connectionState) {
      case LaserConnectionState.connecting:
        message = 'Connecting to device...';
        break;
      case LaserConnectionState.discoveringServices:
        message = 'Discovering services...';
        break;
      case LaserConnectionState.pairing:
        message = 'Pairing with device...';
        break;
      default:
        message = 'Connecting...';
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Keep the laser meter nearby',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// =============================================================================
// CONNECTED SECTION — LIVE MEASUREMENT
// =============================================================================

class _ConnectedSection extends StatelessWidget {
  final LaserMeterState state;
  final WidgetRef ref;

  const _ConnectedSection({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final deviceInfo = state.connectedDeviceInfo;
    final lastMeasurement = state.lastMeasurement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Connected device header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          deviceInfo?.name ?? 'Connected',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (deviceInfo != null &&
                            deviceInfo.brand.isBeta) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BETA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (deviceInfo?.modelNumber != null)
                      Text(
                        '${deviceInfo!.brand.displayName} ${deviceInfo.modelNumber}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    ref.read(laserMeterProvider.notifier).disconnect(),
                icon: const Icon(LucideIcons.unplug, size: 14),
                label: const Text('Disconnect'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Live measurement display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(
                LucideIcons.ruler,
                size: 28,
                color: lastMeasurement != null
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                lastMeasurement?.displayImperial ?? '--\' --"',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: lastMeasurement != null
                      ? Colors.black87
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lastMeasurement != null
                    ? lastMeasurement.displayMetric
                    : 'Waiting for measurement...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              if (lastMeasurement != null &&
                  lastMeasurement.confidence < 0.9) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.alertTriangle,
                        size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Low confidence (${(lastMeasurement.confidence * 100).round()}%)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.amber.shade700),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),
        Text(
          'Press the button on your laser meter to capture a measurement',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

// =============================================================================
// MEASUREMENT HISTORY
// =============================================================================

class _MeasurementHistory extends StatelessWidget {
  final LaserMeterState state;
  final WidgetRef ref;

  const _MeasurementHistory({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'History (${state.measurementHistory.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(laserMeterProvider.notifier).clearHistory(),
              child: const Text('Clear', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Show last 10, reversed (newest first)
        ...state.measurementHistory.reversed.take(10).map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(LucideIcons.arrowRight,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.displayImperial,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      m.displayMetric,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}:${m.timestamp.second.toString().padLeft(2, '0')}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// =============================================================================
// BATTERY INDICATOR
// =============================================================================

class _BatteryIndicator extends StatelessWidget {
  final int? level;

  const _BatteryIndicator({this.level});

  @override
  Widget build(BuildContext context) {
    if (level == null) return const SizedBox.shrink();

    final color = level! > 50
        ? Colors.green
        : level! > 20
            ? Colors.orange
            : Colors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          level! > 80
              ? LucideIcons.batteryFull
              : level! > 50
                  ? LucideIcons.batteryMedium
                  : level! > 20
                      ? LucideIcons.batteryLow
                      : LucideIcons.battery,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$level%',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}

// =============================================================================
// STATUS CARD
// =============================================================================

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isAnimated;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
