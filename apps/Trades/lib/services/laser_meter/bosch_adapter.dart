// ZAFTO — Bosch GLM Laser Meter Adapter
// Created: Sprint FIELD4 (Session 131)
//
// Handles Bosch GLM series laser meters (GLM 50-27 CG, GLM 50 C, etc.).
// Bosch publishes a BLE specification for their measurement transfer.
// This is the PRIMARY (stable) adapter — ships without beta badge.
//
// Bosch GLM BLE protocol:
// - Measurement service: custom Bosch UUID
// - Measurement data: IEEE 754 float, little-endian, meters
// - Button press on device triggers measurement notification
// - Battery level via standard BLE Battery Service (0x180F)

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'laser_meter_adapter.dart';

// =============================================================================
// BOSCH BLE CONSTANTS
// =============================================================================

/// Bosch GLM custom measurement service UUID.
/// Derived from Bosch GLM BLE transfer spec.
const String _kBoschMeasurementServiceUuid =
    '00005301-0000-0041-4c50-574953450000';

/// Bosch GLM measurement characteristic UUID.
const String _kBoschMeasurementCharUuid =
    '00005302-0000-0041-4c50-574953450000';

/// Standard BLE Battery Service UUID.
const String _kBatteryServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb';

/// Standard BLE Battery Level Characteristic UUID.
const String _kBatteryLevelCharUuid = '00002a19-0000-1000-8000-00805f9b34fb';

/// Standard BLE Device Information Service UUID.
const String _kDeviceInfoServiceUuid = '0000180a-0000-1000-8000-00805f9b34fb';

/// Standard BLE Model Number String Characteristic UUID.
const String _kModelNumberCharUuid = '00002a24-0000-1000-8000-00805f9b34fb';

/// Standard BLE Firmware Revision String Characteristic UUID.
const String _kFirmwareRevisionCharUuid =
    '00002a26-0000-1000-8000-00805f9b34fb';

/// Standard BLE Hardware Revision String Characteristic UUID.
const String _kHardwareRevisionCharUuid =
    '00002a27-0000-1000-8000-00805f9b34fb';

/// Standard BLE Serial Number String Characteristic UUID.
const String _kSerialNumberCharUuid = '00002a25-0000-1000-8000-00805f9b34fb';

// =============================================================================
// BOSCH ADAPTER
// =============================================================================

class BoschAdapter implements LaserMeterAdapter {
  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _measurementSub;

  final _connectionController =
      StreamController<LaserConnectionState>.broadcast();
  final _measurementController = StreamController<LaserMeasurement>.broadcast();

  LaserConnectionState _currentState = LaserConnectionState.idle;

  @override
  LaserMeterBrand get brand => LaserMeterBrand.bosch;

  @override
  List<String> get serviceUuids => [_kBoschMeasurementServiceUuid];

  @override
  bool canHandle(String deviceName, List<int>? manufacturerData) {
    final nameLower = deviceName.toLowerCase();
    // Bosch GLM devices typically advertise as "GLM xxx" or "Bosch GLM"
    if (nameLower.contains('glm') || nameLower.contains('bosch')) return true;

    // Check Bosch manufacturer ID in BLE advertisement (0x0089 = Robert Bosch)
    if (manufacturerData != null && manufacturerData.length >= 2) {
      final companyId = manufacturerData[0] | (manufacturerData[1] << 8);
      if (companyId == 0x0089) return true;
    }

    return false;
  }

  @override
  Future<void> connect(String deviceId) async {
    try {
      _emitState(LaserConnectionState.connecting);

      _device = BluetoothDevice.fromId(deviceId);

      // Listen for connection state changes
      _connectionSub = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _emitState(LaserConnectionState.disconnected);
        }
      });

      // Connect with timeout
      await _device!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _emitState(LaserConnectionState.discoveringServices);

      // Discover GATT services
      final services = await _device!.discoverServices();

      // Find measurement service
      BluetoothService? measurementService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            _kBoschMeasurementServiceUuid) {
          measurementService = service;
          break;
        }
      }

      if (measurementService == null) {
        _emitState(LaserConnectionState.error);
        return;
      }

      _emitState(LaserConnectionState.pairing);

      // Find measurement characteristic and subscribe
      for (final char in measurementService.characteristics) {
        if (char.uuid.toString().toLowerCase() == _kBoschMeasurementCharUuid) {
          await char.setNotifyValue(true);

          _measurementSub = char.lastValueStream.listen(
            (value) => _parseMeasurement(value, deviceId),
            onError: (_) {}, // Silently handle BLE errors
          );

          break;
        }
      }

      _emitState(LaserConnectionState.ready);
    } catch (e) {
      _emitState(LaserConnectionState.error);
    }
  }

  @override
  Future<void> disconnect() async {
    await _measurementSub?.cancel();
    _measurementSub = null;

    try {
      await _device?.disconnect();
    } catch (_) {
      // Device may already be disconnected
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
    String? modelNumber;
    String? firmwareVersion;
    String? hardwareRevision;
    String? serialNumber;
    int? battery;

    if (_device == null) {
      return LaserDeviceInfo(
        deviceId: '',
        name: 'Unknown Bosch',
        brand: brand,
      );
    }

    try {
      final services = await _device!.discoverServices();

      // Read Device Information Service
      for (final service in services) {
        final sid = service.uuid.toString().toLowerCase();

        if (sid == _kDeviceInfoServiceUuid) {
          for (final char in service.characteristics) {
            final cid = char.uuid.toString().toLowerCase();
            try {
              if (cid == _kModelNumberCharUuid) {
                modelNumber = String.fromCharCodes(await char.read());
              } else if (cid == _kFirmwareRevisionCharUuid) {
                firmwareVersion = String.fromCharCodes(await char.read());
              } else if (cid == _kHardwareRevisionCharUuid) {
                hardwareRevision = String.fromCharCodes(await char.read());
              } else if (cid == _kSerialNumberCharUuid) {
                serialNumber = String.fromCharCodes(await char.read());
              }
            } catch (_) {
              // Some characteristics may not be readable
            }
          }
        }

        if (sid == _kBatteryServiceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _kBatteryLevelCharUuid) {
              try {
                final val = await char.read();
                if (val.isNotEmpty) battery = val[0];
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {
      // Service discovery may fail if device disconnects
    }

    return LaserDeviceInfo(
      deviceId: _device!.remoteId.str,
      name: _device!.platformName.isNotEmpty
          ? _device!.platformName
          : 'Bosch GLM',
      brand: brand,
      modelNumber: modelNumber,
      firmwareVersion: firmwareVersion,
      hardwareRevision: hardwareRevision,
      serialNumber: serialNumber,
      batteryLevel: battery,
    );
  }

  @override
  Future<int?> getBatteryLevel() async {
    if (_device == null) return null;

    try {
      final services = await _device!.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == _kBatteryServiceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _kBatteryLevelCharUuid) {
              final val = await char.read();
              if (val.isNotEmpty) return val[0];
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _connectionSub?.cancel();
    await _connectionController.close();
    await _measurementController.close();
  }

  // ===========================================================================
  // PRIVATE
  // ===========================================================================

  void _emitState(LaserConnectionState state) {
    _currentState = state;
    if (!_connectionController.isClosed) {
      _connectionController.add(state);
    }
  }

  /// Parse Bosch GLM measurement packet.
  ///
  /// Bosch GLM sends measurement as IEEE 754 float (4 bytes, little-endian)
  /// in meters. We convert to inches for internal use.
  void _parseMeasurement(List<int> value, String deviceId) {
    if (value.length < 4) return;

    try {
      final bytes = Uint8List.fromList(value);
      final byteData = ByteData.view(bytes.buffer);

      // Read IEEE 754 float (little-endian) — distance in meters
      final meters = byteData.getFloat32(0, Endian.little);

      // Validate measurement
      if (meters.isNaN || meters.isInfinite || meters < 0 || meters > 300) {
        return; // Reject invalid measurements (>300m is unreasonable)
      }

      // Convert meters to inches (1 meter = 39.3701 inches)
      final inches = meters * 39.3701;

      final measurement = LaserMeasurement(
        distanceInches: inches,
        originalValue: meters,
        originalUnit: MeasurementSourceUnit.meters,
        timestamp: DateTime.now(),
        confidence: 1.0,
        deviceId: deviceId,
        rawBytes: bytes,
      );

      if (!_measurementController.isClosed) {
        _measurementController.add(measurement);
      }
    } catch (_) {
      // Malformed packet — silently ignore
    }
  }
}
