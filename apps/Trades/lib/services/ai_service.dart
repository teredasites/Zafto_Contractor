// ZAFTO AI Service — Supabase Edge Functions
// Rewritten: Z Intelligence Mobile Integration
//
// Service + providers for AI communication via Supabase Edge Functions.
// Replaces Firebase Cloud Functions approach.
//
// Pattern: AiService (Edge Function calls) -> AiChatNotifier (state) -> providers
//
// Legacy types (ScanResult, ScanType, AIService) preserved at bottom for
// backward compatibility with ai_scanner screens until they are rewritten.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import '../core/errors.dart';
import 'auth_service.dart';
import 'error_service.dart' hide AppError;

// Conditional imports for legacy scanner support
import 'ai_service_stub.dart'
    if (dart.library.io) 'ai_service_io.dart';
import 'image_compress_stub.dart'
    if (dart.library.io) 'image_compress_io.dart';

// =============================================================================
// MESSAGE MODEL (for Z chat sheet)
// =============================================================================

enum AiMessageRole { user, assistant, system }

enum AiMessageType {
  text,
  photoAnalysis,
  partIdentification,
  repairGuide,
  error,
}

class AiMessage {
  final String id;
  final AiMessageRole role;
  final String content;
  final AiMessageType type;
  final DateTime timestamp;
  final String? photoUrl;
  final Map<String, dynamic>? structuredData;

  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    this.type = AiMessageType.text,
    required this.timestamp,
    this.photoUrl,
    this.structuredData,
  });

  bool get isUser => role == AiMessageRole.user;
  bool get isAssistant => role == AiMessageRole.assistant;
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasStructuredData =>
      structuredData != null && structuredData!.isNotEmpty;
}

// =============================================================================
// CHAT STATE
// =============================================================================

class AiChatState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// =============================================================================
// AI SERVICE (Supabase Edge Function calls)
// =============================================================================

class AiService {
  static const _uuid = Uuid();

  // Call the ai-troubleshoot Edge Function
  Future<Map<String, dynamic>> troubleshoot(
    String trade,
    String issue, {
    Map<String, dynamic>? context,
  }) async {
    return _invokeFunction('ai-troubleshoot', {
      'trade': trade,
      'issue': issue,
      if (context != null) 'context': context,
    });
  }

  // Call the ai-photo-diagnose Edge Function
  Future<Map<String, dynamic>> diagnosePhoto(
    String photoUrl, {
    String? trade,
  }) async {
    return _invokeFunction('ai-photo-diagnose', {
      'photoUrl': photoUrl,
      if (trade != null) 'trade': trade,
    });
  }

  // Call the ai-parts-identify Edge Function
  Future<Map<String, dynamic>> identifyPart(
    String description, {
    String? photoUrl,
  }) async {
    return _invokeFunction('ai-parts-identify', {
      'description': description,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  // Call the ai-repair-guide Edge Function
  Future<Map<String, dynamic>> repairGuide(
    String trade,
    String issue, {
    String? skillLevel,
  }) async {
    return _invokeFunction('ai-repair-guide', {
      'trade': trade,
      'issue': issue,
      if (skillLevel != null) 'skillLevel': skillLevel,
    });
  }

  // Call the walkthrough-transcribe Edge Function (already exists)
  Future<Map<String, dynamic>> transcribeVoice(String audioUrl) async {
    return _invokeFunction('walkthrough-transcribe', {
      'audioUrl': audioUrl,
    });
  }

  // Call ai-photo-diagnose with receipt-specific prompt
  Future<Map<String, dynamic>> ocrReceipt(String photoUrl) async {
    return _invokeFunction('ai-photo-diagnose', {
      'photoUrl': photoUrl,
      'mode': 'receipt_ocr',
    });
  }

  // Generic Edge Function invoker
  Future<Map<String, dynamic>> _invokeFunction(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await supabase.functions.invoke(
        functionName,
        body: body,
      );

      if (response.status != 200) {
        throw NetworkError(
          'Edge Function returned status ${response.status}',
          userMessage:
              'AI service is temporarily unavailable. Please try again.',
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }

      // If response is a string, try to parse as JSON
      if (data is String) {
        try {
          return jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          return {'content': data};
        }
      }

      return {'content': data.toString()};
    } catch (e) {
      if (e is AppError) rethrow;
      debugPrint('AI service error: $e');
      throw NetworkError(
        'Failed to call AI service: $e',
        userMessage: 'Could not reach AI service. Check your connection.',
        cause: e,
      );
    }
  }

  // Generate a unique message ID
  static String generateId() => _uuid.v4();
}

// =============================================================================
// CHAT NOTIFIER (state management)
// =============================================================================

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiService _service;
  final AuthState _authState;

  AiChatNotifier(this._service, this._authState) : super(const AiChatState());

  String? get _userTrade => _authState.user?.trade;

  // Send a text message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMsg = AiMessage(
      id: AiService.generateId(),
      role: AiMessageRole.user,
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _service.troubleshoot(
        _userTrade ?? 'general',
        content.trim(),
      );

      final assistantMsg = AiMessage(
        id: AiService.generateId(),
        role: AiMessageRole.assistant,
        content: response['content'] as String? ??
            response['message'] as String? ??
            'No response received.',
        type: AiMessageType.text,
        timestamp: DateTime.now(),
        structuredData: response['data'] as Map<String, dynamic>?,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  // Analyze a photo
  Future<void> analyzePhoto(String photoUrl, {String? caption}) async {
    final userMsg = AiMessage(
      id: AiService.generateId(),
      role: AiMessageRole.user,
      content: caption ?? 'Analyze this photo',
      timestamp: DateTime.now(),
      photoUrl: photoUrl,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _service.diagnosePhoto(
        photoUrl,
        trade: _userTrade,
      );

      final assistantMsg = AiMessage(
        id: AiService.generateId(),
        role: AiMessageRole.assistant,
        content: response['content'] as String? ??
            response['analysis'] as String? ??
            'Photo analysis complete.',
        type: AiMessageType.photoAnalysis,
        timestamp: DateTime.now(),
        structuredData: response,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  // Identify a part
  Future<void> identifyPart(String description, {String? photoUrl}) async {
    final userMsg = AiMessage(
      id: AiService.generateId(),
      role: AiMessageRole.user,
      content: 'Identify part: $description',
      timestamp: DateTime.now(),
      photoUrl: photoUrl,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _service.identifyPart(
        description,
        photoUrl: photoUrl,
      );

      final assistantMsg = AiMessage(
        id: AiService.generateId(),
        role: AiMessageRole.assistant,
        content: response['content'] as String? ??
            response['identification'] as String? ??
            'Part identification complete.',
        type: AiMessageType.partIdentification,
        timestamp: DateTime.now(),
        structuredData: response,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  // Get a repair guide
  Future<void> getRepairGuide(String issue, {String? skillLevel}) async {
    final userMsg = AiMessage(
      id: AiService.generateId(),
      role: AiMessageRole.user,
      content: 'Repair guide: $issue',
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _service.repairGuide(
        _userTrade ?? 'general',
        issue,
        skillLevel: skillLevel,
      );

      final assistantMsg = AiMessage(
        id: AiService.generateId(),
        role: AiMessageRole.assistant,
        content: response['content'] as String? ??
            response['guide'] as String? ??
            'Repair guide generated.',
        type: AiMessageType.repairGuide,
        timestamp: DateTime.now(),
        structuredData: response,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  // Clear the chat
  void clearChat() {
    state = const AiChatState();
  }

  void _handleError(dynamic e) {
    final message = e is AppError
        ? (e.userMessage ?? e.message)
        : 'Something went wrong. Please try again.';

    final errorMsg = AiMessage(
      id: AiService.generateId(),
      role: AiMessageRole.assistant,
      content: message,
      type: AiMessageType.error,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, errorMsg],
      isLoading: false,
      error: message,
    );
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final service = ref.watch(aiServiceProvider);
  final authState = ref.watch(authStateProvider);
  return AiChatNotifier(service, authState);
});

// =============================================================================
// LEGACY TYPES (backward compatibility for ai_scanner screens)
// These will be removed when ai_scanner screens are rewritten for Supabase.
// =============================================================================

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

// Legacy AIService class — kept for ai_scanner screens.
// New code should use AiService + providers above.
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final ErrorService _errorService = ErrorService();

  int _freeCredits = 3;
  int _paidCredits = 0;
  int _totalScans = 0;

  int get freeCredits => _freeCredits;
  int get paidCredits => _paidCredits;
  int get totalCredits => _freeCredits + _paidCredits;
  int get totalScans => _totalScans;

  Future<void> initialize() async {
    final box = Hive.box('ai_credits');
    _freeCredits = box.get('free_scans', defaultValue: 3);
    _paidCredits = box.get('paid_scans', defaultValue: 0);
    _totalScans = box.get('total_scans', defaultValue: 0);
    try {
      await refreshCredits();
    } catch (_) {
      // Use cached values if offline
    }
  }

  Future<void> refreshCredits() async {
    // Legacy — no-op until scanner screens are rewritten
  }

  Future<ScanResult> analyzeFromPath(String path, String scanType) async {
    if (kIsWeb) {
      return ScanResult.error(
          scanType, 'AI scanning is only available on mobile devices.');
    }

    try {
      final bytes = await readFileBytes(path);
      return _performScanFromBytes(scanType, bytes, path);
    } catch (e) {
      return ScanResult.error(scanType, 'Failed to read image: $e');
    }
  }

  Future<ScanResult> _performScanFromBytes(
      String scanType, Uint8List bytes, String path) async {
    if (totalCredits <= 0) {
      return ScanResult.error(
          scanType, 'No credits remaining. Purchase more scans to continue.');
    }

    try {
      // Compress if needed
      Uint8List finalBytes = bytes;
      if (bytes.length > 4 * 1024 * 1024) {
        finalBytes = await compressImageBytes(bytes);
      }

      final base64Image = base64Encode(finalBytes);
      final mimeType = _getMimeType(path);

      // Use Supabase Edge Function instead of Firebase
      final response = await supabase.functions.invoke(
        'ai-photo-diagnose',
        body: {
          'imageBase64': base64Image,
          'mimeType': mimeType,
          'scanType': scanType,
        },
      );

      if (response.status != 200) {
        return ScanResult.error(scanType, 'Scan failed. Please try again.');
      }

      await _deductLocalCredits(scanType);

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ScanResult.fromJson(data, scanType);
      }
      return ScanResult.error(scanType, 'Invalid response from AI service.');
    } catch (e) {
      _errorService.logError(e,
          stackTrace: StackTrace.current, reason: 'AI scan: $scanType');
      return ScanResult.error(scanType, 'Scan failed. Please try again.');
    }
  }

  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _deductLocalCredits(String scanType) async {
    final cost = scanType == 'violation' ? 2 : 1;

    if (_freeCredits >= cost) {
      _freeCredits -= cost;
    } else {
      final fromFree = _freeCredits;
      _freeCredits = 0;
      _paidCredits -= (cost - fromFree);
    }
    _totalScans++;

    final box = Hive.box('ai_credits');
    await box.put('free_scans', _freeCredits);
    await box.put('paid_scans', _paidCredits);
    await box.put('total_scans', _totalScans);
  }

  Future<void> addCredits(int amount) async {
    _paidCredits += amount;
    final box = Hive.box('ai_credits');
    await box.put('paid_scans', _paidCredits);
  }
}

// Global instance for legacy scanner screens
final aiLegacyService = AIService();

// Backward-compatible alias — scanner screens import this name
final aiService = aiLegacyService;
