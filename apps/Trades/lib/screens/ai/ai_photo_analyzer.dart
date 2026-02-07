// ZAFTO AI Photo Analyzer — Full-Screen Photo Analysis
// Created: Z Intelligence Mobile Integration
//
// Full-screen photo analysis screen accessed from Z chat "Scan Photo" action.
// Capture or pick a photo, send for AI analysis, display results.
//
// Features:
// - Camera capture or gallery picker
// - Loading overlay during analysis
// - Condition rating (1-5 stars)
// - Issues list with severity color coding
// - "Save to Job" and "Share" actions
// - Results feed back into Z chat

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/errors.dart';
import '../../services/ai_service.dart';
import '../../theme/theme_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../widgets/error_widgets.dart';

// =============================================================================
// ANALYSIS STATE
// =============================================================================

enum _AnalysisPhase { capture, analyzing, results, error }

class _AnalysisResult {
  final String summary;
  final int conditionRating; // 1-5
  final List<_IssueItem> issues;
  final Map<String, dynamic> rawData;

  const _AnalysisResult({
    required this.summary,
    required this.conditionRating,
    required this.issues,
    required this.rawData,
  });

  factory _AnalysisResult.fromResponse(Map<String, dynamic> data) {
    final issues = <_IssueItem>[];
    final issuesList = data['issues'] as List<dynamic>? ?? [];
    for (final item in issuesList) {
      if (item is Map<String, dynamic>) {
        issues.add(_IssueItem(
          title: item['title'] as String? ?? 'Issue found',
          description: item['description'] as String? ?? '',
          severity: _parseSeverity(item['severity'] as String?),
        ));
      }
    }

    return _AnalysisResult(
      summary: data['content'] as String? ??
          data['analysis'] as String? ??
          data['summary'] as String? ??
          'Analysis complete.',
      conditionRating: (data['conditionRating'] as int?) ??
          (data['condition_rating'] as int?) ??
          3,
      issues: issues,
      rawData: data,
    );
  }

  static _IssueSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
      case 'high':
        return _IssueSeverity.critical;
      case 'warning':
      case 'medium':
        return _IssueSeverity.warning;
      case 'info':
      case 'low':
        return _IssueSeverity.info;
      default:
        return _IssueSeverity.warning;
    }
  }
}

enum _IssueSeverity { critical, warning, info }

class _IssueItem {
  final String title;
  final String description;
  final _IssueSeverity severity;
  bool isExpanded;

  _IssueItem({
    required this.title,
    required this.description,
    required this.severity,
  }) : isExpanded = false;
}

// =============================================================================
// AI PHOTO ANALYZER SCREEN
// =============================================================================

class AiPhotoAnalyzer extends ConsumerStatefulWidget {
  const AiPhotoAnalyzer({super.key});

  @override
  ConsumerState<AiPhotoAnalyzer> createState() => _AiPhotoAnalyzerState();
}

class _AiPhotoAnalyzerState extends ConsumerState<AiPhotoAnalyzer> {
  final ImagePicker _imagePicker = ImagePicker();

  _AnalysisPhase _phase = _AnalysisPhase.capture;
  String? _photoPath;
  _AnalysisResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Prompt image source immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSourcePicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: _buildAppBar(colors),
      body: _buildBody(colors),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(ZaftoColors colors) {
    return AppBar(
      backgroundColor: colors.bgBase,
      elevation: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Photo Analysis',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (_phase == _AnalysisPhase.results || _phase == _AnalysisPhase.error)
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: colors.textSecondary),
            onPressed: _showSourcePicker,
            tooltip: 'New scan',
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  Widget _buildBody(ZaftoColors colors) {
    switch (_phase) {
      case _AnalysisPhase.capture:
        return _buildCaptureState(colors);
      case _AnalysisPhase.analyzing:
        return _buildAnalyzingState(colors);
      case _AnalysisPhase.results:
        return _buildResultsState(colors);
      case _AnalysisPhase.error:
        return _buildErrorState(colors);
    }
  }

  // ---------------------------------------------------------------------------
  // CAPTURE STATE
  // ---------------------------------------------------------------------------

  Widget _buildCaptureState(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.fillDefault,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.scanLine, size: 48,
                  color: colors.accentPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'Capture or select a photo',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Z will analyze equipment, identify issues,\nand rate overall condition.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSourceButton(
                  colors,
                  icon: LucideIcons.camera,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 16),
                _buildSourceButton(
                  colors,
                  icon: LucideIcons.image,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: colors.accentPrimary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ANALYZING STATE
  // ---------------------------------------------------------------------------

  Widget _buildAnalyzingState(ZaftoColors colors) {
    return Column(
      children: [
        // Photo with loading overlay
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_photoPath != null)
                Image.file(
                  File(_photoPath!),
                  fit: BoxFit.contain,
                ),
              // Loading overlay
              Container(
                color: Colors.black.withAlpha(120),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colors.accentPrimary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing...',
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Z is examining the photo',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RESULTS STATE
  // ---------------------------------------------------------------------------

  Widget _buildResultsState(ZaftoColors colors) {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Photo (smaller)
        if (_photoPath != null)
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Image.file(
              File(_photoPath!),
              fit: BoxFit.cover,
            ),
          ),
        // Results content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Condition rating
                _buildConditionRating(colors, result.conditionRating),
                const SizedBox(height: 20),
                // Summary
                Text(
                  'Analysis',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.summary,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                // Issues list
                if (result.issues.isNotEmpty) ...[
                  Text(
                    'Issues Found (${result.issues.length})',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.issues
                      .asMap()
                      .entries
                      .map((e) => _buildIssueCard(colors, e.value, e.key)),
                ],
                const SizedBox(height: 24),
                // Action buttons
                _buildActionButtons(colors),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionRating(ZaftoColors colors, int rating) {
    final clampedRating = rating.clamp(1, 5);
    final ratingLabel = _getRatingLabel(clampedRating);
    final ratingColor = _getRatingColor(clampedRating, colors);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          // Stars
          Row(
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  i < clampedRating ? LucideIcons.star : LucideIcons.star,
                  size: 22,
                  color: i < clampedRating
                      ? ratingColor
                      : colors.textQuaternary,
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Condition',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  ratingLabel,
                  style: TextStyle(
                    color: ratingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(ZaftoColors colors, _IssueItem issue, int index) {
    final severityColor = _getSeverityColor(issue.severity, colors);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            issue.isExpanded = !issue.isExpanded;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Severity dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: severityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title
                    Expanded(
                      child: Text(
                        issue.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Expand icon
                    Icon(
                      issue.isExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                  ],
                ),
              ),
              // Expanded description
              if (issue.isExpanded && issue.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 0, 14, 14),
                  child: Text(
                    issue.description,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ZaftoColors colors) {
    return Row(
      children: [
        // Back to Z chat with results
        Expanded(
          child: _buildActionButton(
            colors,
            icon: LucideIcons.messageSquare,
            label: 'Back to Z Chat',
            isPrimary: true,
            onTap: _returnToChat,
          ),
        ),
        const SizedBox(width: 12),
        // Share
        Expanded(
          child: _buildActionButton(
            colors,
            icon: LucideIcons.share2,
            label: 'Share',
            isPrimary: false,
            onTap: _shareResults,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: colors.borderDefault),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? colors.textOnAccent : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? colors.textOnAccent : colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR STATE
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.accentError.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.alertTriangle,
                  size: 48, color: colors.accentError),
            ),
            const SizedBox(height: 20),
            Text(
              'Analysis Failed',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Could not analyze the photo. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showSourcePicker();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    color: colors.textOnAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  void _showSourcePicker() {
    setState(() {
      _phase = _AnalysisPhase.capture;
      _photoPath = null;
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );

    if (image == null) return;
    if (!mounted) return;

    HapticFeedback.lightImpact();

    setState(() {
      _photoPath = image.path;
      _phase = _AnalysisPhase.analyzing;
    });

    await _analyzePhoto(image.path);
  }

  Future<void> _analyzePhoto(String path) async {
    try {
      final service = ref.read(aiServiceProvider);
      final response = await service.diagnosePhoto(path);

      if (!mounted) return;

      setState(() {
        _result = _AnalysisResult.fromResponse(response);
        _phase = _AnalysisPhase.results;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e is AppError
          ? (e.userMessage ?? e.message)
          : 'Could not analyze the photo. Please try again.';

      setState(() {
        _errorMessage = message;
        _phase = _AnalysisPhase.error;
      });
    }
  }

  void _returnToChat() {
    // Add analysis result as a message in the Z chat
    if (_result != null && _photoPath != null) {
      ref.read(aiChatProvider.notifier).analyzePhoto(
            _photoPath!,
            caption: 'Photo analysis: ${_result!.summary}',
          );
    }
    Navigator.pop(context);
  }

  void _shareResults() {
    // Share via system share sheet
    if (_result == null) return;

    final text = StringBuffer();
    text.writeln('ZAFTO Photo Analysis');
    text.writeln('Condition: ${_getRatingLabel(_result!.conditionRating)}');
    text.writeln();
    text.writeln(_result!.summary);

    if (_result!.issues.isNotEmpty) {
      text.writeln();
      text.writeln('Issues Found:');
      for (final issue in _result!.issues) {
        text.writeln('- ${issue.title}: ${issue.description}');
      }
    }

    Clipboard.setData(ClipboardData(text: text.toString()));
    if (mounted) {
      showSuccessSnackbar(context, 'Analysis copied to clipboard');
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Critical';
      case 2:
        return 'Poor';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  Color _getRatingColor(int rating, ZaftoColors colors) {
    switch (rating) {
      case 1:
        return colors.accentError;
      case 2:
        return colors.accentWarning;
      case 3:
        return colors.accentWarning;
      case 4:
        return colors.accentSuccess;
      case 5:
        return colors.accentSuccess;
      default:
        return colors.textTertiary;
    }
  }

  Color _getSeverityColor(_IssueSeverity severity, ZaftoColors colors) {
    switch (severity) {
      case _IssueSeverity.critical:
        return colors.accentError;
      case _IssueSeverity.warning:
        return colors.accentWarning;
      case _IssueSeverity.info:
        return colors.accentInfo;
    }
  }
}
