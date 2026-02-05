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
  /// TODO: Integrate with Cloud Vision or on-device ML Kit
  Future<String> _extractTextFromImages(List<String> imagePaths) async {
    // For now, return placeholder - will integrate with OCR service
    // Options:
    // 1. Google Cloud Vision API
    // 2. Firebase ML Kit (on-device)
    // 3. Claude's vision capability via Cloud Function

    await Future.delayed(const Duration(seconds: 1)); // Simulate processing
    return 'Contract text will be extracted from ${imagePaths.length} images';
  }

  /// Extract text from PDF
  /// TODO: Integrate with PDF text extraction
  Future<String> _extractTextFromPdf(String pdfPath) async {
    // Will use pdf_text or similar package
    await Future.delayed(const Duration(seconds: 1)); // Simulate processing
    return 'Contract text will be extracted from PDF';
  }

  /// Analyze contract text with AI (Opus 4.5)
  /// TODO: Call Cloud Function for production
  Future<ContractAnalysis> _analyzeContractText({
    required String text,
    required String fileName,
    String? pdfPath,
    List<String>? imagePaths,
  }) async {
    // In production, this will call a Cloud Function that uses Opus 4.5
    // The Cloud Function will:
    // 1. Receive the contract text
    // 2. Send to Claude API with specialized prompt
    // 3. Parse structured response
    // 4. Return analysis

    // For now, generate a demo analysis to build/test UI
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    final id = _uuid.v4();

    // Demo analysis - shows what the AI would return
    return ContractAnalysis(
      id: id,
      fileName: fileName,
      customerName: 'Demo General Contractor',
      projectName: 'Commercial Office Build-Out',
      contractValue: 125000.00,
      analyzedAt: DateTime.now(),
      contractType: ContractType.subcontractor,
      riskScore: 7,
      summary: 'This subcontractor agreement contains several provisions that significantly favor the general contractor. The pay-when-paid clause creates cash flow risk, and the broad indemnification language exposes you to liability beyond your scope of work. Consider negotiating these terms before signing.',
      redFlags: [
        RedFlag(
          id: '${id}_rf1',
          title: 'Pay-When-Paid Clause',
          description: 'Payment is contingent on the GC receiving payment from the owner. This transfers financial risk to you.',
          excerpt: '"Subcontractor shall be paid within 30 days of Contractor receiving corresponding payment from Owner."',
          location: 'Section 5.2',
          severity: IssueSeverity.high,
          suggestedChange: 'Request modification to "payment within 30 days of invoice approval" regardless of owner payment status.',
        ),
        RedFlag(
          id: '${id}_rf2',
          title: 'Broad Indemnification',
          description: 'The indemnification clause requires you to indemnify the GC even for their own negligence in some states.',
          excerpt: '"Subcontractor shall indemnify, defend, and hold harmless Contractor from any and all claims..."',
          location: 'Section 12.1',
          severity: IssueSeverity.critical,
          suggestedChange: 'Limit indemnification to claims arising from your own negligence or work.',
        ),
        RedFlag(
          id: '${id}_rf3',
          title: 'One-Sided Termination',
          description: 'Contractor can terminate for convenience with 5 days notice, but you cannot.',
          excerpt: '"Contractor may terminate this Agreement for any reason upon five (5) days written notice."',
          location: 'Section 15.1',
          severity: IssueSeverity.medium,
          suggestedChange: 'Request mutual termination rights with equal notice periods.',
        ),
      ],
      missingProtections: [
        MissingProtection(
          id: '${id}_mp1',
          title: 'Change Order Process',
          description: 'No clear process for change order pricing and approval timelines.',
          severity: IssueSeverity.high,
          recommendedLanguage: 'Add: "Change orders shall be priced within 5 business days and approved/rejected within 10 business days. Work shall not commence until written approval is received."',
        ),
        MissingProtection(
          id: '${id}_mp2',
          title: 'Delay Compensation',
          description: 'No provisions for compensation if you are delayed by others.',
          severity: IssueSeverity.medium,
          recommendedLanguage: 'Add: "Subcontractor shall be entitled to additional time and compensation for delays caused by Contractor, Owner, or other trades."',
        ),
        MissingProtection(
          id: '${id}_mp3',
          title: 'Retainage Release',
          description: 'No timeline specified for retainage release after substantial completion.',
          severity: IssueSeverity.medium,
          recommendedLanguage: 'Add: "Retainage shall be released within 30 days of substantial completion of Subcontractor\'s work."',
        ),
      ],
      recommendations: [
        ContractRecommendation(
          id: '${id}_rec1',
          title: 'Negotiate Payment Terms',
          description: 'The pay-when-paid clause is the biggest risk. Push for payment within 30 days of invoice regardless of owner payment.',
          actionItem: 'Send email to GC requesting payment term modification',
          isUrgent: true,
        ),
        ContractRecommendation(
          id: '${id}_rec2',
          title: 'Limit Indemnification',
          description: 'Have your attorney review the indemnification clause. In many states, indemnification for the other party\'s negligence is unenforceable.',
          actionItem: 'Forward to attorney for review',
          isUrgent: true,
        ),
        ContractRecommendation(
          id: '${id}_rec3',
          title: 'Add Change Order Language',
          description: 'Protect yourself from scope creep by requiring written change orders before additional work.',
          actionItem: 'Propose change order addendum',
          isUrgent: false,
        ),
        ContractRecommendation(
          id: '${id}_rec4',
          title: 'Document Project Conditions',
          description: 'Given the one-sided termination clause, document all work and communications carefully.',
          actionItem: 'Set up project documentation folder',
          isUrgent: false,
        ),
      ],
      rawText: text,
      pdfPath: pdfPath,
      imagePaths: imagePaths,
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
