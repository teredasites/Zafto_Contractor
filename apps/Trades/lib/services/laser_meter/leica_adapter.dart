// ZAFTO — Leica DISTO Laser Meter Adapter (BETA)
// Created: Sprint FIELD4 (Session 131)
//
// Handles Leica DISTO laser meters (D2, D510, X3, X4, S910, etc.).
// Leica DISTO uses a custom BLE profile for measurement transfer.
// Ships as BETA — Leica does not publish an open SDK.
//
// Leica DISTO BLE protocol (reverse-engineered):
// - Custom service UUID for measurement transfer
// - Measurement data: 4-byte IEEE 754 float, little-endian, meters
// - Supports continuous measurement mode on some models
// - Battery level via standard BLE Battery Service

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'laser_meter_adapter.dart';

// =============================================================================
// LEICA BLE CONSTANTS
// =============================================================================

/// Leica DISTO custom measurement service UUID.
const String _kLeicaMeasurementServiceUuid =
    '3ab10100-f831-4395-b29d-570977d5bf94';

/// Leica DISTO measurement characteristic UUID.
const String _kLeicaMeasurementCharUuid =
    '3ab10101-f831-4395-b29d-570977d5bf94';

/// Leica DISTO command characteristic UUID (trigger measurement).
const String _kLeicaCommandCharUuid =
    '3ab10102-f831-4395-b29d-570977d5bf94';

/// Standard BLE Battery Service UUID.
const String _kBatteryServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb';
const String _kBatteryLevelCharUuid = '00002a19-0000-1000-8000-00805f9b34fb';
const String _kDeviceInfoServiceUuid = '0000180a-0000-1000-8000-00805f9b34fb';
const String _kModelNumberCharUuid = '00002a24-0000-1000-8000-00805f9b34fb';
const String _kFirmwareRevisionCharUuid =
    '00002a26-0000-1000-8000-00805f9b34fb';
const String _kSerialNumberCharUuid = '00002a25-0000-1000-8000-00805f9b34fb';

// =============================================================================
// LEICA ADAPTER
// =============================================================================

class LeicaAdapter implements LaserMeterAdapter {
  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _measurementSub;

  final _connectionController =
      StreamController<LaserConnectionState>.broadcast();
  final _measurementController = StreamController<LaserMeasurement>.broadcast();

  @override
  LaserMeterBrand get brand => LaserMeterBrand.leica;

  @override
  List<String> get serviceUuids => [_kLeicaMeasurementServiceUuid];

  @override
  bool canHandle(String deviceName, List<int>? manufacturerData) {
    final nameLower = deviceName.toLowerCase();
    if (nameLower.contains('disto') || nameLower.contains('leica')) return true;

    // Leica/Hexagon manufacturer ID (0x0267)
    if (manufacturerData != null && manufacturerData.length >= 2) {
      final companyId = manufacturerData[0] | (manufacturerData[1] << 8);
      if (companyId == 0x0267) return true;
    }

    return false;
  }

  @override
  Future<void> connect(String deviceId) async {
    try {
      _emitState(LaserConnectionState.connecting);

      _device = BluetoothDevice.fromId(deviceId);

      _connectionSub = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _emitState(LaserConnectionState.disconnected);
        }
      });

      await _device!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _emitState(LaserConnectionState.discoveringServices);
      final services = await _device!.discoverServices();

      BluetoothService? measurementService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            _kLeicaMeasurementServiceUuid) {
          measurementService = service;
          break;
        }
      }

      if (measurementService == null) {
        // Fallback: try to find any service with notify characteristics
        // (some Leica models use slightly different UUIDs)
        for (final service in services) {
          for (final char in service.characteristics) {
            if (char.properties.notify || char.properties.indicate) {
              measurementService = service;
              break;
            }
          }
          if (measurementService != null) break;
        }
      }

      if (measurementService == null) {
        _emitState(LaserConnectionState.error);
        return;
      }

      _emitState(LaserConnectionState.pairing);

      for (final char in measurementService.characteristics) {
        final cid = char.uuid.toString().toLowerCase();

        if (cid == _kLeicaMeasurementCharUuid ||
            char.properties.notify ||
            char.properties.indicate) {
          await char.setNotifyValue(true);

          _measurementSub = char.lastValueStream.listen(
            (value) => _parseMeasurement(value, deviceId),
            onError: (_) {},
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
    } catch (_) {}

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
    if (_device == null) {
      return LaserDeviceInfo(
        deviceId: '',
        name: 'Unknown Leica',
        brand: brand,
      );
    }

    String? modelNumber;
    String? firmwareVersion;
    String? serialNumber;
    int? battery;

    try {
      final services = await _device!.discoverServices();
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
              } else if (cid == _kSerialNumberCharUuid) {
                serialNumber = String.fromCharCodes(await char.read());
              }
            } catch (_) {}
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
    } catch (_) {}

    return LaserDeviceInfo(
      deviceId: _device!.remoteId.str,
      name: _device!.platformName.isNotEmpty
          ? _device!.platformName
          : 'Leica DISTO',
      brand: brand,
      modelNumber: modelNumber,
      firmwareVersion: firmwareVersion,
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
    if (!_connectionController.isClosed) {
      _connectionController.add(state);
    }
  }

  /// Parse Leica DISTO measurement packet.
  ///
  /// Leica DISTO typically sends measurement as IEEE 754 float (little-endian)
  /// in meters, similar to Bosch but with a different packet structure.
  /// Some models include a status byte prefix.
  void _parseMeasurement(List<int> value, String deviceId) {
    if (value.length < 4) return;

    try {
      final bytes = Uint8List.fromList(value);
      final byteData = ByteData.view(bytes.buffer);

      // Try parsing from offset 0 first (most common)
      double meters = byteData.getFloat32(0, Endian.little);

      // If unreasonable, try offset 1 (some models have status byte prefix)
      if (meters.isNaN || meters.isInfinite || meters < 0 || meters > 300) {
        if (value.length >= 5) {
          meters = byteData.getFloat32(1, Endian.little);
        }
      }

      // Final validation
      if (meters.isNaN || meters.isInfinite || meters < 0 || meters > 300) {
        return;
      }

      final inches = meters * 39.3701;

      final measurement = LaserMeasurement(
        distanceInches: inches,
        originalValue: meters,
        originalUnit: MeasurementSourceUnit.meters,
        timestamp: DateTime.now(),
        confidence: 0.85, // Beta adapter — slightly lower confidence
        deviceId: deviceId,
        rawBytes: bytes,
      );

      if (!_measurementController.isClosed) {
        _measurementController.add(measurement);
      }
    } catch (_) {}
  }
}
