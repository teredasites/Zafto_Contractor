// ZAFTO — Generic BLE Laser Meter Adapter (BETA)
// Created: Sprint FIELD4 (Session 131)
//
// Catch-all adapter for unknown BLE laser meters (Hilti, Milwaukee, Stabila,
// or any unrecognized brand). Scans all BLE peripherals, attempts common
// measurement GATT profiles, and displays raw data for debugging.
//
// Always ships with beta badge. Users can submit bug reports to help
// us add native support for their device.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'laser_meter_adapter.dart';

// =============================================================================
// COMMON GATT UUIDS TO TRY
// =============================================================================

/// List of common measurement-related GATT service UUIDs to probe.
const List<String> _kCommonServiceUuids = [
  // Nordic UART Service (many BLE devices use this)
  '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
  // Generic Attribute
  '00001801-0000-1000-8000-00805f9b34fb',
  // Custom services seen in various laser meters
  '0000fff0-0000-1000-8000-00805f9b34fb',
  '0000ffe0-0000-1000-8000-00805f9b34fb',
];

const String _kBatteryServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb';
const String _kBatteryLevelCharUuid = '00002a19-0000-1000-8000-00805f9b34fb';
const String _kDeviceInfoServiceUuid = '0000180a-0000-1000-8000-00805f9b34fb';
const String _kModelNumberCharUuid = '00002a24-0000-1000-8000-00805f9b34fb';
const String _kFirmwareRevisionCharUuid =
    '00002a26-0000-1000-8000-00805f9b34fb';

// =============================================================================
// GENERIC BLE ADAPTER
// =============================================================================

class GenericBleAdapter implements LaserMeterAdapter {
  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  final List<StreamSubscription<List<int>>> _charSubs = [];

  final _connectionController =
      StreamController<LaserConnectionState>.broadcast();
  final _measurementController = StreamController<LaserMeasurement>.broadcast();

  /// The detected brand (may be refined after connection).
  LaserMeterBrand _detectedBrand = LaserMeterBrand.generic;

  @override
  LaserMeterBrand get brand => _detectedBrand;

  @override
  List<String> get serviceUuids => []; // Scan all devices

  @override
  bool canHandle(String deviceName, List<int>? manufacturerData) {
    // Generic adapter handles everything no other adapter claims.
    // Detect sub-brands for better labeling.
    final nameLower = deviceName.toLowerCase();

    if (nameLower.contains('hilti') || nameLower.contains('pd-')) {
      _detectedBrand = LaserMeterBrand.hilti;
      return true;
    }
    if (nameLower.contains('milwaukee') || nameLower.contains('mlw')) {
      _detectedBrand = LaserMeterBrand.milwaukee;
      return true;
    }
    if (nameLower.contains('stabila') || nameLower.contains('ld-')) {
      _detectedBrand = LaserMeterBrand.stabila;
      return true;
    }

    // Accept any device that looks like a measurement tool
    if (nameLower.contains('laser') ||
        nameLower.contains('measure') ||
        nameLower.contains('distance') ||
        nameLower.contains('range')) {
      return true;
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

      _emitState(LaserConnectionState.pairing);

      // Subscribe to ALL notify/indicate characteristics across all services.
      // For unknown devices, we don't know which characteristic carries
      // measurement data, so we listen to everything.
      int subscribedCount = 0;

      for (final service in services) {
        // Skip standard services that won't have measurement data
        final sid = service.uuid.toString().toLowerCase();
        if (sid == _kBatteryServiceUuid ||
            sid == _kDeviceInfoServiceUuid ||
            sid == '00001800-0000-1000-8000-00805f9b34fb' || // GAP
            sid == '00001801-0000-1000-8000-00805f9b34fb') {
          // GATT
          continue;
        }

        for (final char in service.characteristics) {
          if (char.properties.notify || char.properties.indicate) {
            try {
              await char.setNotifyValue(true);
              final sub = char.lastValueStream.listen(
                (value) => _parseMeasurement(value, deviceId),
                onError: (_) {},
              );
              _charSubs.add(sub);
              subscribedCount++;
            } catch (_) {
              // Some characteristics may fail to subscribe
            }
          }
        }
      }

      if (subscribedCount == 0) {
        _emitState(LaserConnectionState.error);
        return;
      }

      _emitState(LaserConnectionState.ready);
    } catch (e) {
      _emitState(LaserConnectionState.error);
    }
  }

  @override
  Future<void> disconnect() async {
    for (final sub in _charSubs) {
      await sub.cancel();
    }
    _charSubs.clear();

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
        name: 'Unknown Device',
        brand: _detectedBrand,
      );
    }

    String? modelNumber;
    String? firmwareVersion;
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
          : _detectedBrand.displayName,
      brand: _detectedBrand,
      modelNumber: modelNumber,
      firmwareVersion: firmwareVersion,
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

  void _emitState(LaserConnectionState state) {
    if (!_connectionController.isClosed) {
      _connectionController.add(state);
    }
  }

  /// Parse measurement from unknown device.
  /// Tries multiple common formats:
  /// 1. IEEE 754 float (4 bytes, little-endian) in meters
  /// 2. IEEE 754 float (4 bytes, big-endian) in meters
  /// 3. 16-bit unsigned integer in millimeters
  /// 4. ASCII string (some devices send text like "1.234m")
  void _parseMeasurement(List<int> value, String deviceId) {
    if (value.isEmpty) return;

    double? inches;
    double originalValue = 0;
    MeasurementSourceUnit unit = MeasurementSourceUnit.meters;
    double confidence = 0.6; // Lower confidence for generic parsing

    // Try ASCII format first (e.g., "1.234" or "1.234m" or "4.5ft")
    final ascii = String.fromCharCodes(value).trim();
    final numMatch = RegExp(r'([\d.]+)\s*(m|mm|ft|in|cm)?').firstMatch(ascii);
    if (numMatch != null) {
      final num = double.tryParse(numMatch.group(1)!);
      final suffix = numMatch.group(2)?.toLowerCase();
      if (num != null && num > 0 && num < 500) {
        switch (suffix) {
          case 'mm':
            inches = num / 25.4;
            originalValue = num;
            break;
          case 'cm':
            inches = num / 2.54;
            originalValue = num;
            break;
          case 'ft':
            inches = num * 12;
            originalValue = num;
            unit = MeasurementSourceUnit.feet;
            break;
          case 'in':
            inches = num;
            originalValue = num;
            unit = MeasurementSourceUnit.inches;
            break;
          case 'm':
          default:
            inches = num * 39.3701;
            originalValue = num;
            break;
        }
        confidence = 0.7;
      }
    }

    // Try binary float if ASCII didn't work
    if (inches == null && value.length >= 4) {
      try {
        final bytes = Uint8List.fromList(value);
        final byteData = ByteData.view(bytes.buffer);

        // Little-endian float (most common)
        final le = byteData.getFloat32(0, Endian.little);
        if (!le.isNaN && !le.isInfinite && le > 0.01 && le < 300) {
          inches = le * 39.3701;
          originalValue = le;
          confidence = 0.65;
        }

        // Big-endian float
        if (inches == null) {
          final be = byteData.getFloat32(0, Endian.big);
          if (!be.isNaN && !be.isInfinite && be > 0.01 && be < 300) {
            inches = be * 39.3701;
            originalValue = be;
            confidence = 0.55;
          }
        }
      } catch (_) {}
    }

    // Try 16-bit unsigned millimeters
    if (inches == null && value.length >= 2) {
      final mm = value[0] | (value[1] << 8);
      if (mm > 10 && mm < 100000) {
        inches = mm / 25.4;
        originalValue = mm.toDouble();
        confidence = 0.5;
      }
    }

    if (inches == null || inches <= 0) return;

    final measurement = LaserMeasurement(
      distanceInches: inches,
      originalValue: originalValue,
      originalUnit: unit,
      timestamp: DateTime.now(),
      confidence: confidence,
      deviceId: deviceId,
      rawBytes: Uint8List.fromList(value),
    );

    if (!_measurementController.isClosed) {
      _measurementController.add(measurement);
    }
  }
}
