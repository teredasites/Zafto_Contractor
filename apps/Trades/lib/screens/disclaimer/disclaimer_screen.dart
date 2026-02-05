import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO First-Launch Disclaimer Screen
/// Design System v2.6 - Polished January 29, 2026

class DisclaimerScreen extends ConsumerStatefulWidget {
  final VoidCallback onAccepted;
  const DisclaimerScreen({super.key, required this.onAccepted});

  @override
  ConsumerState<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends ConsumerState<DisclaimerScreen> {
  bool _hasReadDisclaimer = false;
  bool _hasAcceptedTerms = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      if (!_hasReadDisclaimer) setState(() => _hasReadDisclaimer = true);
    }
  }

  Future<void> _acceptAndContinue() async {
    if (!_hasAcceptedTerms) return;
    HapticFeedback.mediumImpact();
    final appStateBox = Hive.box('app_state');
    await appStateBox.put('disclaimer_accepted', true);
    await appStateBox.put('disclaimer_accepted_at', DateTime.now().toIso8601String());
    await appStateBox.put('disclaimer_version', '1.0');
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    
    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(colors),
              const SizedBox(height: 24),
              Expanded(child: _buildScrollableContent(colors)),
              _buildFooter(colors),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Column(
      children: [
        // Signet Logo - clean, minimal
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.borderStrong, width: 1.5),
          ),
          child: Center(
            child: Text('Z', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: colors.textPrimary)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Welcome to ZAFTO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colors.textPrimary, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('Please read and accept before continuing', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
      ],
    );
  }

  Widget _buildScrollableContent(ZaftoColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
              child: _buildDisclaimerContent(colors),
            ),
          ),
          // Fade gradient at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.bgElevated.withValues(alpha: 0), colors.bgElevated],
                  ),
                ),
              ),
            ),
          ),
          // Scroll indicator
          if (!_hasReadDisclaimer)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.chevronDown, size: 14, color: colors.textTertiary),
                      const SizedBox(width: 4),
                      Text('Scroll to read full disclaimer', style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(ZaftoColors colors) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Checkbox
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _hasAcceptedTerms = !_hasAcceptedTerms);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _hasAcceptedTerms ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _hasAcceptedTerms ? colors.accentPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _hasAcceptedTerms ? colors.accentPrimary : colors.borderDefault, width: 1.5),
                  ),
                  child: _hasAcceptedTerms ? Icon(LucideIcons.check, size: 14, color: colors.isDark ? Colors.black : Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I understand that ZAFTO is for educational reference only and that all calculations must be verified by a licensed professional.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Continue button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _hasAcceptedTerms ? _acceptAndContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasAcceptedTerms ? colors.accentPrimary : colors.fillDefault,
              foregroundColor: _hasAcceptedTerms ? (colors.isDark ? Colors.black : Colors.white) : colors.textQuaternary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerContent(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Please read this entire disclaimer carefully before using ZAFTO Electrical.', style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5)),
        const SizedBox(height: 20),
        _buildSection(colors, 'EDUCATIONAL AND REFERENCE USE ONLY',
          'ZAFTO Electrical ("the App") is designed to provide educational reference information, calculations, and study materials for electrical professionals and students. The App is NOT a substitute for professional training, licensing, or the judgment of a qualified electrician.'),
        const SizedBox(height: 20),
        _buildSection(colors, 'NO PROFESSIONAL ADVICE',
          'The information, calculations, diagrams, and AI-powered analysis provided by this App:',
          bullets: ['Are for REFERENCE and EDUCATIONAL purposes ONLY', 'Do NOT constitute professional electrical advice', 'Do NOT replace the National Electrical Code (NEC) or local code amendments', 'Must be VERIFIED by a licensed professional before use', 'May contain errors or may not reflect the latest code changes']),
        const SizedBox(height: 20),
        _buildSection(colors, 'AI-POWERED FEATURES', 'The AI scanning and analysis features:',
          bullets: ['Use machine learning which may produce incorrect results', 'Should NEVER be the sole basis for electrical decisions', 'Cannot detect all hazards, code violations, or safety issues', 'Are provided as a learning and reference tool only']),
        const SizedBox(height: 20),
        _buildSection(colors, 'LIMITATION OF LIABILITY',
          'Tereda Software LLC, its developers, and affiliates accept NO LIABILITY for any damages, injuries, or losses resulting from the use of this App. By using this App, you agree to hold harmless all parties involved in its creation and distribution.'),
        const SizedBox(height: 20),
        _buildSection(colors, 'YOUR RESPONSIBILITY', 'You acknowledge that:',
          bullets: ['All electrical work must be performed by qualified, licensed professionals', 'All calculations must be verified against the current NEC and local codes', 'You will not rely solely on this App for any electrical decisions', 'You assume all risk associated with using this information']),
      ],
    );
  }

  Widget _buildSection(ZaftoColors colors, String title, String content, {List<String>? bullets}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        Text(content, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5)),
        if (bullets != null) ...[
          const SizedBox(height: 10),
          ...bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                Expanded(child: Text(b, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4))),
              ],
            ),
          )),
        ],
      ],
    );
  }
}
