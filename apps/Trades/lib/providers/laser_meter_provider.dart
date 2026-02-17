// ZAFTO — Laser Meter Riverpod Provider
// Created: Sprint FIELD4 (Session 131)
//
// Riverpod state management for Bluetooth laser meters.
// Exposes connection state, measurements, device list, and actions
// to the Flutter UI layer.
//
// StateNotifierProvider pattern per 06_ARCHITECTURE_PATTERNS.md.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/laser_meter/laser_meter_adapter.dart';
import '../services/laser_meter/laser_meter_service.dart';

// =============================================================================
// STATE
// =============================================================================

/// Immutable state for the laser meter system.
class LaserMeterState {
  /// Current BLE connection state.
  final LaserConnectionState connectionState;

  /// Last received measurement (null if none yet).
  final LaserMeasurement? lastMeasurement;

  /// Rolling history of last 50 measurements.
  final List<LaserMeasurement> measurementHistory;

  /// Devices found during the last scan.
  final List<DiscoveredLaserDevice> discoveredDevices;

  /// Info about the currently connected device (null if disconnected).
  final LaserDeviceInfo? connectedDeviceInfo;

  /// Whether a scan is currently active.
  final bool isScanning;

  /// Error message (null if no error).
  final String? errorMessage;

  /// Whether Bluetooth is available on this device.
  final bool bluetoothAvailable;

  /// Whether Bluetooth is currently enabled.
  final bool bluetoothEnabled;

  const LaserMeterState({
    this.connectionState = LaserConnectionState.idle,
    this.lastMeasurement,
    this.measurementHistory = const [],
    this.discoveredDevices = const [],
    this.connectedDeviceInfo,
    this.isScanning = false,
    this.errorMessage,
    this.bluetoothAvailable = true,
    this.bluetoothEnabled = true,
  });

  /// Whether a device is connected and ready for measurements.
  bool get isReady => connectionState == LaserConnectionState.ready;

  /// Whether we're in a connecting/pairing state.
  bool get isConnecting =>
      connectionState == LaserConnectionState.connecting ||
      connectionState == LaserConnectionState.discoveringServices ||
      connectionState == LaserConnectionState.pairing;

  /// Whether there's an active error.
  bool get hasError => connectionState == LaserConnectionState.error;

  LaserMeterState copyWith({
    LaserConnectionState? connectionState,
    LaserMeasurement? lastMeasurement,
    List<LaserMeasurement>? measurementHistory,
    List<DiscoveredLaserDevice>? discoveredDevices,
    LaserDeviceInfo? connectedDeviceInfo,
    bool? isScanning,
    String? errorMessage,
    bool? bluetoothAvailable,
    bool? bluetoothEnabled,
    bool clearError = false,
    bool clearDeviceInfo = false,
  }) {
    return LaserMeterState(
      connectionState: connectionState ?? this.connectionState,
      lastMeasurement: lastMeasurement ?? this.lastMeasurement,
      measurementHistory: measurementHistory ?? this.measurementHistory,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDeviceInfo: clearDeviceInfo
          ? null
          : (connectedDeviceInfo ?? this.connectedDeviceInfo),
      isScanning: isScanning ?? this.isScanning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      bluetoothAvailable: bluetoothAvailable ?? this.bluetoothAvailable,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
    );
  }
}

// =============================================================================
// NOTIFIER
// =============================================================================

class LaserMeterNotifier extends StateNotifier<LaserMeterState> {
  final LaserMeterService _service;

  StreamSubscription<LaserConnectionState>? _connectionSub;
  StreamSubscription<LaserMeasurement>? _measurementSub;
  StreamSubscription<List<DiscoveredLaserDevice>>? _devicesSub;

  LaserMeterNotifier(this._service) : super(const LaserMeterState()) {
    _init();
  }

  Future<void> _init() async {
    final available = await _service.isBluetoothAvailable;
    final enabled = await _service.isBluetoothOn;

    state = state.copyWith(
      bluetoothAvailable: available,
      bluetoothEnabled: enabled,
    );

    // Listen to service streams
    _connectionSub = _service.connectionStateStream.listen((connState) {
      state = state.copyWith(
        connectionState: connState,
        isScanning: connState == LaserConnectionState.scanning,
        clearError: connState != LaserConnectionState.error,
        errorMessage: connState == LaserConnectionState.error
            ? 'Connection failed. Check device and try again.'
            : null,
      );

      // Fetch device info when connection is established
      if (connState == LaserConnectionState.ready) {
        _fetchDeviceInfo();
      }

      // Clear device info on disconnect
      if (connState == LaserConnectionState.disconnected ||
          connState == LaserConnectionState.idle) {
        state = state.copyWith(clearDeviceInfo: true);
      }
    });

    _measurementSub = _service.measurementStream.listen((measurement) {
      final history = [...state.measurementHistory, measurement];
      // Keep only last 50 measurements
      if (history.length > 50) {
        history.removeRange(0, history.length - 50);
      }

      state = state.copyWith(
        lastMeasurement: measurement,
        measurementHistory: history,
      );
    });

    _devicesSub = _service.discoveredDevicesStream.listen((devices) {
      state = state.copyWith(discoveredDevices: devices);
    });
  }

  /// Start scanning for laser meters.
  Future<void> startScan() async {
    state = state.copyWith(
      isScanning: true,
      discoveredDevices: [],
      clearError: true,
    );

    await _service.startScan();
  }

  /// Stop scanning.
  Future<void> stopScan() async {
    await _service.stopScan();
    state = state.copyWith(isScanning: false);
  }

  /// Connect to a discovered device.
  Future<void> connectToDevice(String deviceId) async {
    state = state.copyWith(clearError: true);
    await _service.connectToDevice(deviceId);
  }

  /// Disconnect from the current device.
  Future<void> disconnect() async {
    await _service.disconnect();
  }

  /// Clear measurement history.
  void clearHistory() {
    state = state.copyWith(
      measurementHistory: [],
      lastMeasurement: null,
    );
  }

  /// Refresh battery level.
  Future<void> refreshBattery() async {
    final info = await _service.getDeviceInfo();
    if (info != null) {
      state = state.copyWith(connectedDeviceInfo: info);
    }
  }

  Future<void> _fetchDeviceInfo() async {
    try {
      final info = await _service.getDeviceInfo();
      if (info != null) {
        state = state.copyWith(connectedDeviceInfo: info);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _measurementSub?.cancel();
    _devicesSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Singleton service provider.
final laserMeterServiceProvider = Provider<LaserMeterService>((ref) {
  final service = LaserMeterService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// State provider for laser meter UI.
final laserMeterProvider =
    StateNotifierProvider<LaserMeterNotifier, LaserMeterState>((ref) {
  final service = ref.watch(laserMeterServiceProvider);
  return LaserMeterNotifier(service);
});

/// Convenience provider: whether a laser meter is connected.
final isLaserMeterConnectedProvider = Provider<bool>((ref) {
  return ref.watch(laserMeterProvider).isReady;
});

/// Convenience provider: last measurement value.
final lastLaserMeasurementProvider = Provider<LaserMeasurement?>((ref) {
  return ref.watch(laserMeterProvider).lastMeasurement;
});
