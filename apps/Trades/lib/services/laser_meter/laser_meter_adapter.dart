// ZAFTO — Laser Meter Adapter Interface
// Created: Sprint FIELD4 (Session 131)
//
// Abstract interface for Bluetooth laser meter communication.
// Each brand (Bosch, Leica, DeWalt, etc.) implements this interface
// with brand-specific GATT profiles and measurement parsing.
//
// All adapters normalize measurements to inches (internal unit).

import 'dart:async';
import 'dart:typed_data';

// =============================================================================
// MEASUREMENT MODEL
// =============================================================================

/// A single measurement received from a laser meter.
class LaserMeasurement {
  /// Distance in inches (internal standard unit).
  final double distanceInches;

  /// Original distance value as reported by device.
  final double originalValue;

  /// Original unit from device (meters, feet, inches).
  final MeasurementSourceUnit originalUnit;

  /// When the measurement was captured.
  final DateTime timestamp;

  /// Confidence level 0.0–1.0 (1.0 = high confidence, <0.5 = questionable).
  final double confidence;

  /// BLE device ID that produced this measurement.
  final String deviceId;

  /// Raw bytes from the BLE characteristic (for debugging/bug reports).
  final Uint8List? rawBytes;

  const LaserMeasurement({
    required this.distanceInches,
    required this.originalValue,
    required this.originalUnit,
    required this.timestamp,
    this.confidence = 1.0,
    required this.deviceId,
    this.rawBytes,
  });

  /// Convert inches to feet and inches display string.
  String get displayImperial {
    final feet = (distanceInches / 12).floor();
    final inches = distanceInches % 12;
    if (feet == 0) return '${inches.toStringAsFixed(1)}"';
    return '$feet\' ${inches.toStringAsFixed(1)}"';
  }

  /// Convert inches to meters display string.
  String get displayMetric {
    final meters = distanceInches * 0.0254;
    return '${meters.toStringAsFixed(3)} m';
  }

  /// Display in the given unit system.
  String displayIn(MeasurementSourceUnit unit) {
    switch (unit) {
      case MeasurementSourceUnit.meters:
        return displayMetric;
      case MeasurementSourceUnit.feet:
      case MeasurementSourceUnit.inches:
        return displayImperial;
    }
  }

  Map<String, dynamic> toJson() => {
        'distance_inches': distanceInches,
        'original_value': originalValue,
        'original_unit': originalUnit.name,
        'timestamp': timestamp.toIso8601String(),
        'confidence': confidence,
        'device_id': deviceId,
        'raw_bytes': rawBytes?.toList(),
      };
}

/// Source unit from the laser device.
enum MeasurementSourceUnit {
  meters,
  feet,
  inches,
}

// =============================================================================
// CONNECTION STATE
// =============================================================================

/// BLE connection lifecycle states.
enum LaserConnectionState {
  /// Not connected, not scanning.
  idle,

  /// Actively scanning for BLE devices.
  scanning,

  /// Found a device matching our filters.
  found,

  /// Establishing BLE connection.
  connecting,

  /// BLE connected, discovering services.
  discoveringServices,

  /// Connected and paired, subscribing to measurement characteristic.
  pairing,

  /// Bonded and ready to receive measurements.
  ready,

  /// Connection lost, attempting auto-reconnect.
  reconnecting,

  /// Intentionally disconnected.
  disconnected,

  /// Unrecoverable error.
  error,
}

// =============================================================================
// DISCOVERED DEVICE
// =============================================================================

/// A BLE device discovered during scanning.
class DiscoveredLaserDevice {
  /// BLE peripheral ID (platform-specific).
  final String deviceId;

  /// User-visible device name from BLE advertisement.
  final String name;

  /// Detected brand based on manufacturer data / name patterns.
  final LaserMeterBrand brand;

  /// Signal strength in dBm (closer to 0 = stronger).
  final int rssi;

  /// Whether the device has been previously bonded.
  final bool isBonded;

  /// Battery level 0–100 if available from advertisement, null otherwise.
  final int? batteryLevel;

  const DiscoveredLaserDevice({
    required this.deviceId,
    required this.name,
    required this.brand,
    required this.rssi,
    this.isBonded = false,
    this.batteryLevel,
  });

  /// Signal quality: strong (> -60), medium (-60 to -80), weak (< -80).
  String get signalQuality {
    if (rssi > -60) return 'Strong';
    if (rssi > -80) return 'Medium';
    return 'Weak';
  }
}

// =============================================================================
// BRAND ENUM
// =============================================================================

/// Supported laser meter brands.
enum LaserMeterBrand {
  bosch('Bosch', false),
  leica('Leica', true),
  dewalt('DeWalt', true),
  hilti('Hilti', true),
  milwaukee('Milwaukee', true),
  stabila('Stabila', true),
  generic('Unknown', true);

  final String displayName;
  final bool isBeta;

  const LaserMeterBrand(this.displayName, this.isBeta);
}

// =============================================================================
// DEVICE INFO
// =============================================================================

/// Detailed device information after connection.
class LaserDeviceInfo {
  final String deviceId;
  final String name;
  final LaserMeterBrand brand;
  final String? modelNumber;
  final String? firmwareVersion;
  final String? hardwareRevision;
  final String? serialNumber;
  final int? batteryLevel;

  const LaserDeviceInfo({
    required this.deviceId,
    required this.name,
    required this.brand,
    this.modelNumber,
    this.firmwareVersion,
    this.hardwareRevision,
    this.serialNumber,
    this.batteryLevel,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'name': name,
        'brand': brand.name,
        'model_number': modelNumber,
        'firmware_version': firmwareVersion,
        'hardware_revision': hardwareRevision,
        'serial_number': serialNumber,
        'battery_level': batteryLevel,
      };
}

// =============================================================================
// ADAPTER INTERFACE
// =============================================================================

/// Abstract interface for communicating with a specific brand of laser meter.
///
/// Each brand adapter handles:
/// - BLE GATT service/characteristic discovery
/// - Brand-specific measurement packet parsing
/// - Connection lifecycle management
/// - Battery level monitoring
///
/// Adapters are stateless regarding scan management — that's handled by
/// [LaserMeterService]. Adapters handle the connection + data parsing
/// for a single connected device.
abstract class LaserMeterAdapter {
  /// Brand this adapter handles.
  LaserMeterBrand get brand;

  /// GATT service UUIDs to filter for during scan.
  List<String> get serviceUuids;

  /// Whether this adapter can handle a device based on its advertisement data.
  bool canHandle(String deviceName, List<int>? manufacturerData);

  /// Connect to a device and begin service/characteristic discovery.
  /// Emits connection state changes via [connectionStateStream].
  Future<void> connect(String deviceId);

  /// Disconnect from the currently connected device.
  Future<void> disconnect();

  /// Stream of connection state changes.
  Stream<LaserConnectionState> get connectionStateStream;

  /// Stream of measurements from the connected device.
  /// Measurements are normalized to inches.
  Stream<LaserMeasurement> get measurementStream;

  /// Get detailed device info (model, firmware, serial, battery).
  /// Call after connection is established.
  Future<LaserDeviceInfo> getDeviceInfo();

  /// Read current battery level (0–100). Returns null if unsupported.
  Future<int?> getBatteryLevel();

  /// Clean up resources. Call when adapter is no longer needed.
  Future<void> dispose();
}
