// ZAFTO RoomPlan Bridge — SK5
// Dart side of the platform channel for Apple RoomPlan LiDAR scanning.
// Communicates with native Swift RoomPlanService via MethodChannel.
// Falls back gracefully on non-LiDAR devices (Android, older iPhones).

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RoomPlanBridge {
  static const _channel = MethodChannel('com.zafto.roomplan');
  static const _eventChannel = EventChannel('com.zafto.roomplan/progress');

  bool _isAvailable = false;
  bool _isScanning = false;

  bool get isAvailable => _isAvailable;
  bool get isScanning => _isScanning;

  // Check if device supports RoomPlan (iOS 16+ with LiDAR)
  Future<bool> checkAvailability() async {
    if (!Platform.isIOS) {
      _isAvailable = false;
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('checkAvailability');
      _isAvailable = result ?? false;
      return _isAvailable;
    } on PlatformException catch (e) {
      debugPrint('RoomPlan availability check failed: ${e.message}');
      _isAvailable = false;
      return false;
    } on MissingPluginException {
      // Native side not registered (debug mode, simulator, etc.)
      _isAvailable = false;
      return false;
    }
  }

  // Start a LiDAR scanning session
  Future<void> startScan() async {
    if (!_isAvailable) {
      throw PlatformException(
        code: 'NOT_AVAILABLE',
        message: 'RoomPlan is not available on this device',
      );
    }

    try {
      await _channel.invokeMethod<void>('startScan');
      _isScanning = true;
    } on PlatformException catch (e) {
      _isScanning = false;
      throw PlatformException(
        code: e.code,
        message: 'Failed to start RoomPlan scan: ${e.message}',
      );
    }
  }

  // Stop the scanning session and get captured room data
  Future<Map<String, dynamic>?> stopScan() async {
    if (!_isScanning) return null;

    try {
      final result = await _channel.invokeMethod<Map>('stopScan');
      _isScanning = false;
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      _isScanning = false;
      debugPrint('Failed to stop RoomPlan scan: ${e.message}');
      return null;
    }
  }

  // Get the last captured room data (after scan stopped)
  Future<Map<String, dynamic>?> getCapturedRoom() async {
    try {
      final result = await _channel.invokeMethod<Map>('getCapturedRoom');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('Failed to get captured room: ${e.message}');
      return null;
    }
  }

  // Stream of scan progress updates (wall count, door count, etc.)
  Stream<RoomPlanProgress> get progressStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => RoomPlanProgress.fromMap(
            Map<String, dynamic>.from(event as Map)));
  }

  // Dispose — stop any active scan
  Future<void> dispose() async {
    if (_isScanning) {
      try {
        await _channel.invokeMethod<void>('cancelScan');
      } catch (_) {
        // Ignore errors during cleanup
      }
      _isScanning = false;
    }
  }
}

// Progress update from RoomPlan native scan
class RoomPlanProgress {
  final int wallCount;
  final int doorCount;
  final int windowCount;
  final int objectCount;
  final String status; // 'scanning', 'processing', 'complete', 'error'
  final String? message;

  const RoomPlanProgress({
    this.wallCount = 0,
    this.doorCount = 0,
    this.windowCount = 0,
    this.objectCount = 0,
    this.status = 'scanning',
    this.message,
  });

  factory RoomPlanProgress.fromMap(Map<String, dynamic> map) {
    return RoomPlanProgress(
      wallCount: map['wall_count'] as int? ?? 0,
      doorCount: map['door_count'] as int? ?? 0,
      windowCount: map['window_count'] as int? ?? 0,
      objectCount: map['object_count'] as int? ?? 0,
      status: map['status'] as String? ?? 'scanning',
      message: map['message'] as String?,
    );
  }
}
