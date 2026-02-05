import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Conditional import for dart:io (only on non-web platforms)
import 'ai_service_stub.dart'
    if (dart.library.io) 'ai_service_io.dart';

// Conditional import for image compression
import 'image_compress_stub.dart'
    if (dart.library.io) 'image_compress_io.dart';

import 'error_service.dart';

/// ZAFTO AI Service - Interface to Cloud Functions AI endpoints
/// 
/// Handles image analysis via Firebase Cloud Functions + Claude.
/// Manages credits, caching, and error handling.
/// 
/// PRESERVES: All existing app functionality - this is an ADDITION.

enum ScanType { panel, nameplate, wire, violation, smart }

class ScanResult {
  final bool success;
  final String scanType;
  final Map<String, dynamic>? analysis;
  final String? error;
  final double? confidence;
  final DateTime timestamp;

  ScanResult({
    required this.success,
    required this.scanType,
    this.analysis,
    this.error,
    this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ScanResult.fromJson(Map<String, dynamic> json, String type) {
    final analysis = json['analysis'] as Map<String, dynamic>?;
    return ScanResult(
      success: json['success'] == true,
      scanType: type,
      analysis: analysis,
      confidence: (analysis?['confidence'] as num?)?.toDouble(),
    );
  }

  factory ScanResult.error(String type, String message) {
    return ScanResult(
      success: false,
      scanType: type,
      error: message,
    );
  }
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final ErrorService _errorService = ErrorService();
  
  // Credit tracking
  int _freeCredits = 3;
  int _paidCredits = 0;
  int _totalScans = 0;

  int get freeCredits => _freeCredits;
  int get paidCredits => _paidCredits;
  int get totalCredits => _freeCredits + _paidCredits;
  int get totalScans => _totalScans;

  /// Initialize service and load cached credits
  Future<void> initialize() async {
    final box = Hive.box('ai_credits');
    _freeCredits = box.get('free_scans', defaultValue: 3);
    _paidCredits = box.get('paid_scans', defaultValue: 0);
    _totalScans = box.get('total_scans', defaultValue: 0);
    
    // Sync with server if online
    try {
      await refreshCredits();
    } catch (_) {
      // Use cached values if offline
    }
  }

  /// Refresh credits from server
  Future<void> refreshCredits() async {
    try {
      final callable = _functions.httpsCallable('getCredits');
      final result = await callable.call();
      
      final data = result.data as Map<String, dynamic>;
      _freeCredits = data['freeCredits'] ?? 0;
      _paidCredits = data['paidCredits'] ?? 0;
      _totalScans = data['totalScans'] ?? 0;
      
      // Cache locally
      final box = Hive.box('ai_credits');
      await box.put('free_scans', _freeCredits);
      await box.put('paid_scans', _paidCredits);
      await box.put('total_scans', _totalScans);
    } catch (e) {
      debugPrint('Failed to refresh credits: $e');
    }
  }

  /// Analyze from file path (for native platforms)
  Future<ScanResult> analyzeFromPath(String path, String scanType) async {
    if (kIsWeb) {
      return ScanResult.error(scanType, 'AI scanning is only available on mobile devices.');
    }
    
    try {
      final bytes = await readFileBytes(path);
      final functionName = _getFunctionName(scanType);
      return _performScanFromBytes(functionName, scanType, bytes, path);
    } catch (e) {
      return ScanResult.error(scanType, 'Failed to read image: $e');
    }
  }

  String _getFunctionName(String scanType) {
    switch (scanType) {
      case 'panel': return 'analyzePanel';
      case 'nameplate': return 'analyzeNameplate';
      case 'wire': return 'analyzeWire';
      case 'violation': return 'analyzeViolation';
      case 'smart': default: return 'smartScan';
    }
  }

  /// Core scan method using bytes
  Future<ScanResult> _performScanFromBytes(String functionName, String scanType, Uint8List bytes, String path) async {
    // Check credits first
    if (totalCredits <= 0) {
      return ScanResult.error(scanType, 'No credits remaining. Purchase more scans to continue.');
    }

    try {
      // Compress and encode image
      final imageData = await _prepareImageBytes(bytes, path);
      
      // Call Cloud Function
      final callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      
      final result = await callable.call({
        'imageBase64': imageData['base64'],
        'mimeType': imageData['mimeType'],
      });

      // Update local credits
      await _deductLocalCredits(scanType);
      
      return ScanResult.fromJson(result.data as Map<String, dynamic>, scanType);
    } on FirebaseFunctionsException catch (e) {
      _errorService.logError(e, stackTrace: StackTrace.current, reason: 'AI scan: $scanType');
      return ScanResult.error(scanType, _mapFirebaseError(e));
    } catch (e) {
      _errorService.logError(e, stackTrace: StackTrace.current, reason: 'AI scan: $scanType');
      return ScanResult.error(scanType, 'Scan failed. Please try again.');
    }
  }

  /// Prepare image bytes for upload - compress and encode
  Future<Map<String, String>> _prepareImageBytes(Uint8List bytes, String path) async {
    final mimeType = _getMimeType(path);
    
    // Compress if too large (max 4MB for Claude)
    Uint8List finalBytes = bytes;
    if (bytes.length > 4 * 1024 * 1024) {
      finalBytes = await _compressImage(bytes);
    }
    
    return {
      'base64': base64Encode(finalBytes),
      'mimeType': mimeType,
    };
  }

  /// Compress image to reduce upload size (native only)
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    return compressImageBytes(bytes);
  }

  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

  /// Deduct credits locally (server also deducts)
  Future<void> _deductLocalCredits(String scanType) async {
    final cost = _getCreditCost(scanType);
    
    if (_freeCredits >= cost) {
      _freeCredits -= cost;
    } else {
      final fromFree = _freeCredits;
      _freeCredits = 0;
      _paidCredits -= (cost - fromFree);
    }
    _totalScans++;
    
    // Persist
    final box = Hive.box('ai_credits');
    await box.put('free_scans', _freeCredits);
    await box.put('paid_scans', _paidCredits);
    await box.put('total_scans', _totalScans);
  }

  int _getCreditCost(String scanType) {
    switch (scanType) {
      case 'violation': return 2;
      default: return 1;
    }
  }

  String _mapFirebaseError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in to use AI scanning.';
      case 'resource-exhausted':
        return 'No credits remaining. Purchase more scans to continue.';
      case 'invalid-argument':
        return 'Invalid image. Please try a different photo.';
      case 'deadline-exceeded':
        return 'Analysis timed out. Please try again.';
      default:
        return 'Scan failed: ${e.message}';
    }
  }

  /// Add credits after purchase
  Future<void> addCredits(int amount) async {
    _paidCredits += amount;
    final box = Hive.box('ai_credits');
    await box.put('paid_scans', _paidCredits);
  }
}

// Global instance
final aiService = AIService();
