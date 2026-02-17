// ZAFTO — Laser Meter Service (Orchestrator)
// Created: Sprint FIELD4 (Session 131)
//
// Central service managing BLE laser meter operations:
// - Scans for devices using flutter_blue_plus
// - Auto-detects brand from BLE advertisement manufacturer data
// - Instantiates correct adapter for the detected brand
// - Manages connection lifecycle with auto-reconnect
// - Emits measurements to Riverpod provider
//
// This service is a singleton managed by Riverpod. It does NOT depend on
// any UI or screen — purely a background service.

import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'laser_meter_adapter.dart';
import 'bosch_adapter.dart';
import 'leica_adapter.dart';
import 'dewalt_adapter.dart';
import 'generic_ble_adapter.dart';
import 'mock_adapter.dart';

// =============================================================================
// LASER METER SERVICE
// =============================================================================

class LaserMeterService {
  /// All registered adapters, checked in priority order.
  final List<LaserMeterAdapter> _adapters = [
    BoschAdapter(),
    LeicaAdapter(),
    DewaltAdapter(),
    GenericBleAdapter(),
  ];

  /// Currently active adapter (connected to a device).
  LaserMeterAdapter? _activeAdapter;

  /// Stream controllers for external listeners.
  final _connectionController =
      StreamController<LaserConnectionState>.broadcast();
  final _measurementController = StreamController<LaserMeasurement>.broadcast();
  final _devicesController =
      StreamController<List<DiscoveredLaserDevice>>.broadcast();

  /// Subscriptions to the active adapter's streams.
  StreamSubscription<LaserConnectionState>? _connectionSub;
  StreamSubscription<LaserMeasurement>? _measurementSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// Discovered devices during current scan.
  final List<DiscoveredLaserDevice> _discoveredDevices = [];

  /// Current connection state.
  LaserConnectionState _currentState = LaserConnectionState.idle;

  /// Device we're connected to (for auto-reconnect).
  String? _connectedDeviceId;

  /// Whether auto-reconnect is enabled.
  bool _autoReconnect = true;

  /// Reconnect attempt count.
  int _reconnectAttempts = 0;

  /// Max reconnect attempts before giving up.
  static const int _maxReconnectAttempts = 5;

  /// Timer for reconnect delay.
  Timer? _reconnectTimer;

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  /// Whether Bluetooth is available on this device.
  Future<bool> get isBluetoothAvailable async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Whether Bluetooth is currently turned on.
  Future<bool> get isBluetoothOn async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  /// Current connection state.
  LaserConnectionState get connectionState => _currentState;

  /// Stream of connection state changes.
  Stream<LaserConnectionState> get connectionStateStream =>
      _connectionController.stream;

  /// Stream of measurements from the connected device.
  Stream<LaserMeasurement> get measurementStream =>
      _measurementController.stream;

  /// Stream of discovered devices (updates during scan).
  Stream<List<DiscoveredLaserDevice>> get discoveredDevicesStream =>
      _devicesController.stream;

  /// Currently discovered devices (snapshot).
  List<DiscoveredLaserDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  /// The active adapter (if connected).
  LaserMeterAdapter? get activeAdapter => _activeAdapter;

  /// Start scanning for laser meter devices.
  ///
  /// Scans for 10 seconds by default. Results emitted via
  /// [discoveredDevicesStream].
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    // Check Bluetooth availability
    if (!await isBluetoothAvailable) {
      _emitState(LaserConnectionState.error);
      return;
    }

    if (!await isBluetoothOn) {
      // On Android, we can try to turn it on
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
          // Wait briefly for BT to initialize
          await Future.delayed(const Duration(seconds: 1));
        } catch (_) {
          _emitState(LaserConnectionState.error);
          return;
        }
      } else {
        _emitState(LaserConnectionState.error);
        return;
      }
    }

    _discoveredDevices.clear();
    _emitState(LaserConnectionState.scanning);

    // Cancel any existing scan
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    // Collect all service UUIDs from adapters for filtering
    final filterUuids = <Guid>[];
    for (final adapter in _adapters) {
      for (final uuid in adapter.serviceUuids) {
        if (uuid.isNotEmpty) {
          filterUuids.add(Guid(uuid));
        }
      }
    }

    // Start scan — listen for results
    _scanSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        for (final result in results) {
          _processDiscoveredDevice(result);
        }
      },
      onError: (_) {},
    );

    // Start the scan (no service filter — we want to discover all devices
    // since generic adapter handles unknown brands)
    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );
    } catch (_) {
      _emitState(LaserConnectionState.error);
      return;
    }

    // After scan completes, update state
    _emitState(_discoveredDevices.isEmpty
        ? LaserConnectionState.idle
        : LaserConnectionState.found);
  }

  /// Stop an active scan.
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSub?.cancel();
    _scanSub = null;

    _emitState(_discoveredDevices.isEmpty
        ? LaserConnectionState.idle
        : LaserConnectionState.found);
  }

  /// Connect to a discovered device by ID.
  Future<void> connectToDevice(String deviceId) async {
    // Find the discovered device
    final device = _discoveredDevices.where((d) => d.deviceId == deviceId).firstOrNull;
    if (device == null) return;

    // Find the right adapter for this brand
    LaserMeterAdapter? adapter;
    for (final a in _adapters) {
      if (a.brand == device.brand ||
          (device.brand == LaserMeterBrand.generic && a is GenericBleAdapter)) {
        adapter = a;
        break;
      }
    }

    // Fallback to generic
    adapter ??= _adapters.last;

    // Disconnect existing connection
    if (_activeAdapter != null) {
      await disconnect();
    }

    _activeAdapter = adapter;
    _connectedDeviceId = deviceId;
    _reconnectAttempts = 0;

    // Subscribe to adapter streams
    _connectionSub = adapter.connectionStateStream.listen((state) {
      _emitState(state);

      // Auto-reconnect on unexpected disconnect
      if (state == LaserConnectionState.disconnected &&
          _autoReconnect &&
          _connectedDeviceId != null) {
        _attemptReconnect();
      }
    });

    _measurementSub = adapter.measurementStream.listen((measurement) {
      // Validate measurement before forwarding
      if (_isValidMeasurement(measurement)) {
        if (!_measurementController.isClosed) {
          _measurementController.add(measurement);
        }
      }
    });

    // Connect
    await adapter.connect(deviceId);
  }

  /// Disconnect from the current device.
  Future<void> disconnect() async {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _connectedDeviceId = null;

    await _connectionSub?.cancel();
    _connectionSub = null;
    await _measurementSub?.cancel();
    _measurementSub = null;

    await _activeAdapter?.disconnect();
    _activeAdapter = null;

    _autoReconnect = true;
    _emitState(LaserConnectionState.disconnected);
  }

  /// Get device info for the connected device.
  Future<LaserDeviceInfo?> getDeviceInfo() async {
    return _activeAdapter?.getDeviceInfo();
  }

  /// Get battery level for the connected device.
  Future<int?> getBatteryLevel() async {
    return _activeAdapter?.getBatteryLevel();
  }

  /// Register a mock adapter for testing.
  void registerMockAdapter(MockLaserAdapter adapter) {
    _adapters.insert(0, adapter);
  }

  /// Clean up all resources.
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await stopScan();
    await disconnect();

    for (final adapter in _adapters) {
      await adapter.dispose();
    }

    await _connectionController.close();
    await _measurementController.close();
    await _devicesController.close();
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

  /// Process a BLE scan result into a [DiscoveredLaserDevice].
  void _processDiscoveredDevice(ScanResult result) {
    final deviceName =
        result.device.platformName.isNotEmpty ? result.device.platformName : '';
    final deviceId = result.device.remoteId.str;

    if (deviceName.isEmpty) return; // Skip unnamed devices

    // Check if already discovered
    if (_discoveredDevices.any((d) => d.deviceId == deviceId)) return;

    // Determine brand from manufacturer data + name
    final mfgData = result.advertisementData.manufacturerData;
    List<int>? mfgBytes;
    if (mfgData.isNotEmpty) {
      mfgBytes = mfgData.values.first;
    }

    LaserMeterBrand brand = LaserMeterBrand.generic;
    for (final adapter in _adapters) {
      if (adapter.canHandle(deviceName, mfgBytes)) {
        brand = adapter.brand;
        break;
      }
    }

    // Only add devices that look like laser meters
    // (at least one adapter claims it, or name matches measurement patterns)
    if (brand == LaserMeterBrand.generic) {
      final nameLower = deviceName.toLowerCase();
      final looksLikeLaser = nameLower.contains('laser') ||
          nameLower.contains('measure') ||
          nameLower.contains('distance') ||
          nameLower.contains('glm') ||
          nameLower.contains('disto') ||
          nameLower.contains('dewalt') ||
          nameLower.contains('hilti') ||
          nameLower.contains('pd-') ||
          nameLower.contains('milwaukee') ||
          nameLower.contains('stabila');

      if (!looksLikeLaser) return;
    }

    final device = DiscoveredLaserDevice(
      deviceId: deviceId,
      name: deviceName,
      brand: brand,
      rssi: result.rssi,
    );

    _discoveredDevices.add(device);

    if (!_devicesController.isClosed) {
      _devicesController.add(List.unmodifiable(_discoveredDevices));
    }
  }

  /// Validate a measurement before forwarding to consumers.
  bool _isValidMeasurement(LaserMeasurement m) {
    if (m.distanceInches.isNaN || m.distanceInches.isInfinite) return false;
    if (m.distanceInches <= 0) return false;
    if (m.distanceInches > 12000) return false; // > 1000 feet is unreasonable
    return true;
  }

  /// Attempt auto-reconnect after unexpected disconnect.
  void _attemptReconnect() {
    _reconnectAttempts++;

    if (_reconnectAttempts > _maxReconnectAttempts) {
      _emitState(LaserConnectionState.error);
      return;
    }

    _emitState(LaserConnectionState.reconnecting);

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delay =
        Duration(seconds: 1 << (_reconnectAttempts - 1).clamp(0, 4));

    _reconnectTimer = Timer(delay, () async {
      if (_connectedDeviceId != null && _activeAdapter != null) {
        try {
          await _activeAdapter!.connect(_connectedDeviceId!);
          _reconnectAttempts = 0;
        } catch (_) {
          _attemptReconnect();
        }
      }
    });
  }
}
