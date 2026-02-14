/// ZAFTO Contract Analyzer Service
/// Sprint P0 - February 2026
/// AI-powered contract review using Opus 4.5

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/contract_analysis.dart';

// ============================================================
// PROVIDERS
// ============================================================

final contractAnalyzerServiceProvider = Provider<ContractAnalyzerService>((ref) {
  return ContractAnalyzerService();
});

/// All contract analyses
final contractAnalysesProvider = StateNotifierProvider<ContractAnalysesNotifier, AsyncValue<List<ContractAnalysis>>>((ref) {
  final service = ref.watch(contractAnalyzerServiceProvider);
  return ContractAnalysesNotifier(service);
});

/// Recent analyses (last 10)
final recentAnalysesProvider = Provider<List<ContractAnalysis>>((ref) {
  final analyses = ref.watch(contractAnalysesProvider);
  return analyses.maybeWhen(
    data: (list) {
      final sorted = List<ContractAnalysis>.from(list)
        ..sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
      return sorted.take(10).toList();
    },
    orElse: () => [],
  );
});

/// Analyses with red flags
final flaggedAnalysesProvider = Provider<List<ContractAnalysis>>((ref) {
  final analyses = ref.watch(contractAnalysesProvider);
  return analyses.maybeWhen(
    data: (list) => list.where((a) => a.hasSignificantIssues).toList(),
    orElse: () => [],
  );
});

/// Favorite analyses
final favoriteAnalysesProvider = Provider<List<ContractAnalysis>>((ref) {
  final analyses = ref.watch(contractAnalysesProvider);
  return analyses.maybeWhen(
    data: (list) => list.where((a) => a.isFavorite).toList(),
    orElse: () => [],
  );
});

/// Analysis count
final analysisCountProvider = Provider<int>((ref) {
  final analyses = ref.watch(contractAnalysesProvider);
  return analyses.maybeWhen(
    data: (list) => list.length,
    orElse: () => 0,
  );
});

/// Free scan count remaining
final freeScansRemainingProvider = StateProvider<int>((ref) => 3);

// ============================================================
// STATE NOTIFIER
// ============================================================

class ContractAnalysesNotifier extends StateNotifier<AsyncValue<List<ContractAnalysis>>> {
  final ContractAnalyzerService _service;

  ContractAnalysesNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    try {
      final analyses = await _service.getAllAnalyses();
      state = AsyncValue.data(analyses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAnalysis(ContractAnalysis analysis) async {
    await _service.saveAnalysis(analysis);
    await _loadAnalyses();
  }

  Future<void> deleteAnalysis(String id) async {
    await _service.deleteAnalysis(id);
    await _loadAnalyses();
  }

  Future<void> toggleFavorite(String id) async {
    final analyses = state.value ?? [];
    final index = analyses.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updated = analyses[index].copyWith(isFavorite: !analyses[index].isFavorite);
      await _service.saveAnalysis(updated);
      await _loadAnalyses();
    }
  }

  Future<void> updateNotes(String id, String notes) async {
    final analyses = state.value ?? [];
    final index = analyses.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updated = analyses[index].copyWith(notes: notes);
      await _service.saveAnalysis(updated);
      await _loadAnalyses();
    }
  }

  void refresh() {
    _loadAnalyses();
  }
}

// ============================================================
// SERVICE
// ============================================================

class ContractAnalyzerService {
  static const String _boxName = 'contract_analyses';
  static const _uuid = Uuid();

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Analyze a contract from images
  Future<ContractAnalysis> analyzeFromImages({
    required List<String> imagePaths,
    required String fileName,
  }) async {
    // Extract text from images (OCR)
    final extractedText = await _extractTextFromImages(imagePaths);

    // Analyze with AI
    final analysis = await _analyzeContractText(
      text: extractedText,
      fileName: fileName,
      imagePaths: imagePaths,
    );

    // Save locally
    await saveAnalysis(analysis);

    return analysis;
  }

  /// Analyze a contract from PDF
  Future<ContractAnalysis> analyzeFromPdf({
    required String pdfPath,
    required String fileName,
  }) async {
    // Extract text from PDF
    final extractedText = await _extractTextFromPdf(pdfPath);

    // Analyze with AI
    final analysis = await _analyzeContractText(
      text: extractedText,
      fileName: fileName,
      pdfPath: pdfPath,
    );

    // Save locally
    await saveAnalysis(analysis);

    return analysis;
  }

  /// Analyze directly from text
  Future<ContractAnalysis> analyzeFromText({
    required String text,
    required String fileName,
  }) async {
    final analysis = await _analyzeContractText(
      text: text,
      fileName: fileName,
    );

    await saveAnalysis(analysis);

    return analysis;
  }

  /// Extract text from images using OCR
  /// Requires Phase E AI integration
  Future<String> _extractTextFromImages(List<String> imagePaths) async {
    throw UnsupportedError(
      'Contract OCR is not yet available. AI-powered contract analysis will be enabled in a future update.',
    );
  }

  /// Extract text from PDF
  /// Requires Phase E AI integration
  Future<String> _extractTextFromPdf(String pdfPath) async {
    throw UnsupportedError(
      'Contract PDF extraction is not yet available. AI-powered contract analysis will be enabled in a future update.',
    );
  }

  /// Analyze contract text with AI
  /// Requires Phase E AI integration
  Future<ContractAnalysis> _analyzeContractText({
    required String text,
    required String fileName,
    String? pdfPath,
    List<String>? imagePaths,
  }) async {
    throw UnsupportedError(
      'AI contract analysis is not yet available. This feature will be enabled in a future update.',
    );
  }

  /// Save analysis to local storage
  Future<void> saveAnalysis(ContractAnalysis analysis) async {
    final box = await _getBox();
    await box.put(analysis.id, jsonEncode(analysis.toJson()));
  }

  /// Get analysis by ID
  Future<ContractAnalysis?> getAnalysis(String id) async {
    final box = await _getBox();
    final json = box.get(id);
    if (json == null) return null;
    return ContractAnalysis.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Get all analyses
  Future<List<ContractAnalysis>> getAllAnalyses() async {
    final box = await _getBox();
    final analyses = <ContractAnalysis>[];

    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        try {
          analyses.add(ContractAnalysis.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          ));
        } catch (e) {
          debugPrint('Error parsing analysis $key: $e');
        }
      }
    }

    // Sort by date, newest first
    analyses.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    return analyses;
  }

  /// Delete analysis
  Future<void> deleteAnalysis(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  /// Export analysis as PDF
  Future<String> exportToPdf(ContractAnalysis analysis) async {
    // TODO: Generate PDF report using pdf package
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/contract_analysis_${analysis.id}.pdf';
    // Will generate PDF with analysis details
    return path;
  }

  /// Share analysis
  Future<void> shareAnalysis(ContractAnalysis analysis) async {
    // TODO: Implement sharing via platform share sheet
  }
}

// ============================================================
// ANALYSIS PROMPTS
// ============================================================

/// System prompt for contract analysis
class ContractAnalyzerPrompts {
  static const String systemPrompt = '''
You are an expert construction contract analyst specializing in subcontractor agreements.
Analyze the provided contract and identify:

1. RED FLAGS - Provisions that are unfavorable or risky:
   - Pay-when-paid/pay-if-paid clauses
   - Broad indemnification language
   - Unfair termination clauses
   - Excessive liquidated damages
   - One-sided dispute resolution
   - Flow-down clauses without review rights
   - Unreasonable insurance requirements
   - Waiver of lien rights

2. MISSING PROTECTIONS - Standard protections that should be included:
   - Progress payment schedules
   - Change order processes
   - Delay compensation provisions
   - Retainage release timelines
   - Dispute resolution mechanisms
   - Scope of work definitions

3. RECOMMENDATIONS - Specific actions to take before signing

For each issue, provide:
- Clear title
- Explanation in plain English
- The problematic text excerpt
- Severity (low/medium/high/critical)
- Suggested alternative language

Also extract:
- Contract type
- Customer/GC name
- Project name
- Contract value
- Risk score (1-10)
- Executive summary (2-3 sentences)

Respond in JSON format.
''';

  static String userPrompt(String contractText) => '''
Analyze this construction contract:

---
$contractText
---

Provide your analysis in the following JSON format:
{
  "contractType": "subcontractor|primeContractor|serviceAgreement|...",
  "customerName": "...",
  "projectName": "...",
  "contractValue": 0.00,
  "riskScore": 1-10,
  "summary": "...",
  "redFlags": [...],
  "missingProtections": [...],
  "recommendations": [...]
}
''';
}
