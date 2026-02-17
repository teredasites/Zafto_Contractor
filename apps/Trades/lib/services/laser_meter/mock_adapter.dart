// ZAFTO — Mock Laser Meter Adapter (Testing Only)
// Created: Sprint FIELD4 (Session 131)
//
// Simulates a laser meter for testing without hardware.
// Configurable responses: valid measurements, errors, connection drops,
// rapid-fire, zero-length, negative, NaN, timeout, battery-dead-mid-measurement.
// Supports deterministic and random modes.
// Runs in CI without hardware — all BLE mock tests use this adapter.

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'laser_meter_adapter.dart';

// =============================================================================
// MOCK CONFIGURATION
// =============================================================================

/// Configuration for mock adapter behavior.
class MockLaserConfig {
  /// Delay before connection completes.
  final Duration connectDelay;

  /// Whether connection should succeed.
  final bool connectSucceeds;

  /// Whether to simulate connection drops.
  final bool simulateDrops;

  /// Average interval between simulated drops.
  final Duration dropInterval;

  /// Whether to auto-generate measurements at intervals.
  final bool autoMeasure;

  /// Interval between auto-generated measurements.
  final Duration measureInterval;

  /// Fixed measurement value in inches (null = random 12–480 inches).
  final double? fixedMeasurementInches;

  /// Whether to include invalid measurements (NaN, negative, zero).
  final bool includeInvalidMeasurements;

  /// Battery level to report (0–100, null = no battery info).
  final int? batteryLevel;

  /// Whether to simulate battery dying mid-session.
  final bool simulateBatteryDeath;

  /// Simulated latency on all operations.
  final Duration operationLatency;

  /// Whether to use deterministic mode (fixed seed RNG).
  final bool deterministic;

  /// Random seed for deterministic mode.
  final int seed;

  const MockLaserConfig({
    this.connectDelay = const Duration(milliseconds: 500),
    this.connectSucceeds = true,
    this.simulateDrops = false,
    this.dropInterval = const Duration(seconds: 15),
    this.autoMeasure = false,
    this.measureInterval = const Duration(seconds: 2),
    this.fixedMeasurementInches,
    this.includeInvalidMeasurements = false,
    this.batteryLevel = 85,
    this.simulateBatteryDeath = false,
    this.operationLatency = Duration.zero,
    this.deterministic = false,
    this.seed = 42,
  });

  /// Default config for happy-path testing.
  static const normal = MockLaserConfig();

  /// Config for connection failure testing.
  static const connectionFailure = MockLaserConfig(
    connectSucceeds: false,
    connectDelay: Duration(seconds: 10),
  );

  /// Config for rapid-fire measurements.
  static const rapidFire = MockLaserConfig(
    autoMeasure: true,
    measureInterval: Duration(milliseconds: 100),
  );

  /// Config for chaos testing.
  static const chaos = MockLaserConfig(
    simulateDrops: true,
    dropInterval: Duration(seconds: 8),
    autoMeasure: true,
    measureInterval: Duration(seconds: 1),
    includeInvalidMeasurements: true,
    simulateBatteryDeath: true,
  );
}

// =============================================================================
// MOCK ADAPTER
// =============================================================================

class MockLaserAdapter implements LaserMeterAdapter {
  final MockLaserConfig config;
  late final Random _random;

  final _connectionController =
      StreamController<LaserConnectionState>.broadcast();
  final _measurementController = StreamController<LaserMeasurement>.broadcast();

  Timer? _autoMeasureTimer;
  Timer? _dropTimer;
  Timer? _batteryTimer;
  bool _connected = false;
  int _measurementCount = 0;
  int _currentBattery;

  MockLaserAdapter({this.config = const MockLaserConfig()})
      : _currentBattery = config.batteryLevel ?? 85 {
    _random = config.deterministic ? Random(config.seed) : Random();
  }

  @override
  LaserMeterBrand get brand => LaserMeterBrand.bosch; // Mock pretends to be Bosch

  @override
  List<String> get serviceUuids =>
      ['00005301-0000-0041-4c50-574953450000']; // Fake Bosch UUID

  @override
  bool canHandle(String deviceName, List<int>? manufacturerData) {
    return deviceName.toLowerCase().contains('mock') ||
        deviceName.toLowerCase().contains('simulator') ||
        deviceName.toLowerCase().contains('test');
  }

  @override
  Future<void> connect(String deviceId) async {
    _emitState(LaserConnectionState.connecting);

    await Future.delayed(config.connectDelay);

    if (!config.connectSucceeds) {
      _emitState(LaserConnectionState.error);
      return;
    }

    _emitState(LaserConnectionState.discoveringServices);
    await Future.delayed(const Duration(milliseconds: 200));

    _emitState(LaserConnectionState.pairing);
    await Future.delayed(const Duration(milliseconds: 100));

    _connected = true;
    _emitState(LaserConnectionState.ready);

    // Start auto-measurement if configured
    if (config.autoMeasure) {
      _autoMeasureTimer = Timer.periodic(config.measureInterval, (_) {
        if (_connected) _emitMeasurement(deviceId);
      });
    }

    // Start drop simulation if configured
    if (config.simulateDrops) {
      _scheduleNextDrop(deviceId);
    }

    // Start battery drain if configured
    if (config.simulateBatteryDeath) {
      _batteryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _currentBattery = (_currentBattery - 5).clamp(0, 100);
        if (_currentBattery <= 0) {
          _connected = false;
          _emitState(LaserConnectionState.error);
          _batteryTimer?.cancel();
        }
      });
    }
  }

  /// Manually trigger a measurement (simulates button press on device).
  void triggerMeasurement({double? distanceInches}) {
    if (!_connected) return;
    _emitMeasurement('mock-device', overrideInches: distanceInches);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _autoMeasureTimer?.cancel();
    _dropTimer?.cancel();
    _batteryTimer?.cancel();

    if (config.operationLatency > Duration.zero) {
      await Future.delayed(config.operationLatency);
    }

    _emitState(LaserConnectionState.disconnected);
  }

  @override
  Stream<LaserConnectionState> get connectionStateStream =>
      _connectionController.stream;

  @override
  Stream<LaserMeasurement> get measurementStream =>
      _measurementController.stream;

  @override
  Future<LaserDeviceInfo> getDeviceInfo() async {
    if (config.operationLatency > Duration.zero) {
      await Future.delayed(config.operationLatency);
    }

    return LaserDeviceInfo(
      deviceId: 'mock-device-001',
      name: 'Mock Laser Meter',
      brand: LaserMeterBrand.bosch,
      modelNumber: 'GLM-MOCK-50',
      firmwareVersion: '1.0.0-test',
      hardwareRevision: 'MOCK-HW-1',
      serialNumber: 'MOCK-SERIAL-${config.seed}',
      batteryLevel: _currentBattery,
    );
  }

  @override
  Future<int?> getBatteryLevel() async {
    if (config.operationLatency > Duration.zero) {
      await Future.delayed(config.operationLatency);
    }
    return _currentBattery;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _connectionController.close();
    await _measurementController.close();
  }

  // ===========================================================================
  // PRIVATE
  // ===========================================================================

  void _emitState(LaserConnectionState state) {
    if (!_connectionController.isClosed) {
      _connectionController.add(state);
    }
  }

  void _emitMeasurement(String deviceId, {double? overrideInches}) {
    _measurementCount++;

    // Occasionally emit invalid measurements if configured
    if (config.includeInvalidMeasurements && _measurementCount % 10 == 0) {
      final invalidType = _measurementCount % 30;
      if (invalidType < 10) {
        // NaN measurement — should be filtered by consumer
        _measurementController.add(LaserMeasurement(
          distanceInches: double.nan,
          originalValue: double.nan,
          originalUnit: MeasurementSourceUnit.meters,
          timestamp: DateTime.now(),
          confidence: 0.0,
          deviceId: deviceId,
        ));
        return;
      } else if (invalidType < 20) {
        // Negative measurement
        _measurementController.add(LaserMeasurement(
          distanceInches: -1.0,
          originalValue: -0.0254,
          originalUnit: MeasurementSourceUnit.meters,
          timestamp: DateTime.now(),
          confidence: 0.0,
          deviceId: deviceId,
        ));
        return;
      } else {
        // Zero measurement
        _measurementController.add(LaserMeasurement(
          distanceInches: 0.0,
          originalValue: 0.0,
          originalUnit: MeasurementSourceUnit.meters,
          timestamp: DateTime.now(),
          confidence: 0.0,
          deviceId: deviceId,
        ));
        return;
      }
    }

    final inches = overrideInches ??
        config.fixedMeasurementInches ??
        (12.0 + _random.nextDouble() * 468.0); // 1ft to 40ft
    final meters = inches / 39.3701;

    // Generate fake raw bytes (IEEE 754 float LE)
    final byteData = ByteData(4);
    byteData.setFloat32(0, meters, Endian.little);

    final measurement = LaserMeasurement(
      distanceInches: inches,
      originalValue: meters,
      originalUnit: MeasurementSourceUnit.meters,
      timestamp: DateTime.now(),
      confidence: 1.0,
      deviceId: deviceId,
      rawBytes: byteData.buffer.asUint8List(),
    );

    if (!_measurementController.isClosed) {
      _measurementController.add(measurement);
    }
  }

  void _scheduleNextDrop(String deviceId) {
    final delay = Duration(
      milliseconds: config.dropInterval.inMilliseconds ~/ 2 +
          _random.nextInt(config.dropInterval.inMilliseconds),
    );

    _dropTimer = Timer(delay, () {
      if (_connected) {
        _connected = false;
        _emitState(LaserConnectionState.reconnecting);

        // Auto-reconnect after a brief delay
        Timer(const Duration(seconds: 2), () {
          _connected = true;
          _emitState(LaserConnectionState.ready);
          _scheduleNextDrop(deviceId);
        });
      }
    });
  }
}
