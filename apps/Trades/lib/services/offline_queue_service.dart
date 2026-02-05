import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/pending_scan.dart';
// Conditional import for File operations
import 'platform_stub.dart' if (dart.library.io) 'dart:io';

/// Offline queue service provider
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

/// Offline queue state provider
final offlineQueueProvider =
    StateNotifierProvider<OfflineQueueNotifier, List<PendingScan>>((ref) {
  final service = ref.watch(offlineQueueServiceProvider);
  return OfflineQueueNotifier(service);
});

/// Queue summary provider
final queueSummaryProvider = Provider<OfflineQueueSummary>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  return OfflineQueueService.getSummary(queue);
});

/// Pending scans count provider (for badge display)
final pendingScansCountProvider = Provider<int>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  return queue.where((s) => s.isPending).length;
});

/// Connectivity status provider
final isOnlineProvider = StateProvider<bool>((ref) => true);

/// Offline queue state notifier
class OfflineQueueNotifier extends StateNotifier<List<PendingScan>> {
  final OfflineQueueService _service;
  bool _initialized = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  OfflineQueueNotifier(this._service) : super([]) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    // Load existing queue
    state = await _service.getAllScans();

    // Listen to connectivity
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // Could trigger auto-process here, but per requirements:
    // "User manually triggers queued scans when back online"
    // So we just update state - UI will show "You're back online" prompt
  }

  /// Add a scan to the queue (user chose "Save for Later")
  Future<PendingScan> addToQueue(PendingScan scan) async {
    final saved = await _service.saveScan(scan);
    state = [saved, ...state];
    return saved;
  }

  /// Remove a scan from queue (user chose "Discard")
  Future<void> removeFromQueue(String scanId) async {
    await _service.deleteScan(scanId);
    state = state.where((s) => s.id != scanId).toList();
  }

  /// Update scan status
  Future<void> updateScan(PendingScan scan) async {
    await _service.saveScan(scan);
    state = state.map((s) => s.id == scan.id ? scan : s).toList();
  }

  /// Process a single scan (user triggered)
  Future<void> processScan(
    String scanId,
    Future<Map<String, dynamic>> Function(PendingScan) processor,
  ) async {
    final scan = state.firstWhere((s) => s.id == scanId);

    // Mark as processing
    final processing = scan.markProcessing();
    await updateScan(processing);

    try {
      final result = await processor(scan);
      final completed = processing.markCompleted(result);
      await updateScan(completed);
    } catch (e) {
      final failed = processing.markFailed(e.toString());
      await updateScan(failed);
    }
  }

  /// Process all pending scans (user triggered)
  Future<void> processAllPending(
    Future<Map<String, dynamic>> Function(PendingScan) processor, {
    Function(int processed, int total)? onProgress,
  }) async {
    final pending = state.where((s) => s.isPending).toList();
    int processed = 0;

    for (final scan in pending) {
      await processScan(scan.id, processor);
      processed++;
      onProgress?.call(processed, pending.length);
    }
  }

  /// Cancel a pending scan
  Future<void> cancelScan(String scanId) async {
    final scan = state.firstWhere((s) => s.id == scanId);
    final cancelled = scan.markCancelled();
    await updateScan(cancelled);
  }

  /// Clear completed scans
  Future<void> clearCompleted() async {
    final completed = state
        .where((s) => s.status == PendingScanStatus.completed)
        .map((s) => s.id)
        .toList();

    for (final id in completed) {
      await _service.deleteScan(id);
    }

    state = state.where((s) => s.status != PendingScanStatus.completed).toList();
  }

  /// Clear all scans
  Future<void> clearAll() async {
    await _service.clearAll();
    state = [];
  }

  /// Refresh from storage
  Future<void> refresh() async {
    state = await _service.getAllScans();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Core offline queue service with Hive persistence
class OfflineQueueService {
  static const String _boxName = 'offline_scan_queue';
  static const String _imageDir = 'pending_scans';
  static const int _maxQueueSize = 50;

  /// Get Hive box
  Future<Box<PendingScan>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox<PendingScan>(_boxName);
    }
    return Hive.box<PendingScan>(_boxName);
  }

  /// Get directory for storing images
  Future<Directory> _getImageDirectory() async {
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/$_imageDir');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  /// Save scan to queue
  Future<PendingScan> saveScan(PendingScan scan) async {
    final box = await _getBox();

    // Store image bytes to file if provided
    PendingScan scanToSave = scan;
    if (scan.imageBytes != null && scan.imagePath.isEmpty) {
      final imagePath = await _saveImageBytes(scan.id, scan.imageBytes!);
      scanToSave = scan.copyWith(imagePath: imagePath);
    }

    await box.put(scan.id, scanToSave);
    return scanToSave;
  }

  /// Save image bytes to file
  Future<String> _saveImageBytes(String scanId, Uint8List bytes) async {
    final dir = await _getImageDirectory();
    final file = File('${dir.path}/$scanId.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Get image bytes for a scan
  Future<Uint8List?> getImageBytes(PendingScan scan) async {
    // Return stored bytes if available
    if (scan.imageBytes != null) return scan.imageBytes;

    // Otherwise load from file
    if (scan.imagePath.isNotEmpty) {
      final file = File(scan.imagePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    return null;
  }

  /// Delete scan from queue
  Future<void> deleteScan(String scanId) async {
    final box = await _getBox();
    final scan = box.get(scanId);

    // Delete image file if exists
    if (scan != null && scan.imagePath.isNotEmpty) {
      final file = File(scan.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await box.delete(scanId);
  }

  /// Get all scans (sorted by date, newest first)
  Future<List<PendingScan>> getAllScans() async {
    final box = await _getBox();
    final scans = box.values.toList();
    scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return scans;
  }

  /// Get pending scans only
  Future<List<PendingScan>> getPendingScans() async {
    final all = await getAllScans();
    return all.where((s) => s.isPending).toList();
  }

  /// Get scan by ID
  Future<PendingScan?> getScan(String scanId) async {
    final box = await _getBox();
    return box.get(scanId);
  }

  /// Clear all scans
  Future<void> clearAll() async {
    // Delete all image files
    final dir = await _getImageDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // Clear Hive box
    final box = await _getBox();
    await box.clear();
  }

  /// Check if queue is full
  Future<bool> isQueueFull() async {
    final box = await _getBox();
    return box.length >= _maxQueueSize;
  }

  /// Get queue count
  Future<int> getQueueCount() async {
    final box = await _getBox();
    return box.length;
  }

  /// Get summary of queue
  static OfflineQueueSummary getSummary(List<PendingScan> scans) {
    int queued = 0;
    int processing = 0;
    int completed = 0;
    int failed = 0;
    DateTime? oldestPending;

    for (final scan in scans) {
      switch (scan.status) {
        case PendingScanStatus.queued:
          queued++;
          if (oldestPending == null || scan.createdAt.isBefore(oldestPending)) {
            oldestPending = scan.createdAt;
          }
          break;
        case PendingScanStatus.processing:
          processing++;
          break;
        case PendingScanStatus.completed:
          completed++;
          break;
        case PendingScanStatus.failed:
          failed++;
          if (scan.canRetry) {
            if (oldestPending == null || scan.createdAt.isBefore(oldestPending)) {
              oldestPending = scan.createdAt;
            }
          }
          break;
        case PendingScanStatus.cancelled:
          // Don't count cancelled
          break;
      }
    }

    return OfflineQueueSummary(
      totalCount: scans.length,
      queuedCount: queued,
      processingCount: processing,
      completedCount: completed,
      failedCount: failed,
      oldestPending: oldestPending,
    );
  }

  /// Check connectivity
  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
  }
}

/// Register Hive adapters for offline queue
Future<void> registerOfflineQueueAdapters() async {
  if (!Hive.isAdapterRegistered(20)) {
    Hive.registerAdapter(ScanTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(21)) {
    Hive.registerAdapter(PendingScanStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(22)) {
    Hive.registerAdapter(PendingScanAdapter());
  }
}

/// Dialog result for offline scan prompt
enum OfflineScanChoice {
  saveForLater,
  discard,
  tryAgain,
}

/// Helper for showing offline scan dialog
/// UI should call this when a scan fails due to no connectivity
/// Returns user's choice - NOT auto-processed per requirements
class OfflineScanDialog {
  /// Get dialog options text
  static Map<OfflineScanChoice, String> get options => {
        OfflineScanChoice.saveForLater: 'Save for Later',
        OfflineScanChoice.discard: 'Discard',
        OfflineScanChoice.tryAgain: 'Try Again',
      };

  /// Get dialog message
  static String get message =>
      'No internet connection. Would you like to save this scan to process later?';

  /// Get dialog title
  static String get title => 'Offline';
}
