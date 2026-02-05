import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class ShingleInstallationScreen extends ConsumerWidget {
  const ShingleInstallationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Shingle Installation',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(colors),
            const SizedBox(height: 24),
            _buildInstallationSequence(colors),
            const SizedBox(height: 24),
            _buildNailingPattern(colors),
            const SizedBox(height: 24),
            _buildStarterStrip(colors),
            const SizedBox(height: 24),
            _buildFieldShingles(colors),
            const SizedBox(height: 24),
            _buildCommonMistakes(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Shingle Installation Overview',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Proper shingle installation ensures weather protection and warranty compliance. Always follow manufacturer specifications and local building codes.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSpecCard(colors, '4-6', 'Nails/Shingle', colors.accentSuccess)),
              const SizedBox(width: 8),
              Expanded(child: _buildSpecCard(colors, '5"', 'Exposure', colors.accentInfo)),
              const SizedBox(width: 8),
              Expanded(child: _buildSpecCard(colors, '6"', 'Offset', colors.accentWarning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(ZaftoColors colors, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildInstallationSequence(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'title': 'Install Drip Edge at Eaves', 'desc': 'Metal drip edge goes UNDER underlayment at eaves'},
      {'step': '2', 'title': 'Apply Underlayment', 'desc': 'Start at eaves, overlap 4-6", cap nail or staple'},
      {'step': '3', 'title': 'Install Drip Edge at Rakes', 'desc': 'Metal drip edge goes OVER underlayment at rakes'},
      {'step': '4', 'title': 'Apply Starter Strip', 'desc': 'Overhang eave/rake 1/4"-3/4", adhesive strip at edge'},
      {'step': '5', 'title': 'Install Field Shingles', 'desc': 'Work bottom to top, left to right, maintain offset'},
      {'step': '6', 'title': 'Cut at Valleys/Hips', 'desc': 'Proper cuts, seal with roofing cement'},
      {'step': '7', 'title': 'Install Ridge Cap', 'desc': 'Pre-formed ridge caps, overlap toward prevailing wind'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.listOrdered, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Installation Sequence',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => _buildStepItem(colors, s)),
        ],
      ),
    );
  }

  Widget _buildStepItem(ZaftoColors colors, Map<String, String> step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.accentSuccess,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(step['step']!, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['title']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(step['desc']!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNailingPattern(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nailing Pattern & Placement',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
STANDARD NAILING (4 Nails) - Slopes up to 21:12
═══════════════════════════════════════════════════════════

        ← 1" from each end →
        ↓                   ↓
┌───────────────────────────────────────────────────────┐
│                                                       │
│  ●              ●              ●              ●       │ ← Nail Line
│                                                       │  (5/8" to 1"
│═══════════════════════════════════════════════════════│   above cutout)
│       │               │               │               │
│       │   TAB 1       │    TAB 2      │    TAB 3      │
│       │               │               │               │
└───────────────────────────────────────────────────────┘
        ↑               ↑               ↑
   Nails placed above cutouts, not in them


HIGH WIND NAILING (6 Nails) - High wind zones
═══════════════════════════════════════════════════════════

┌───────────────────────────────────────────────────────┐
│  ●        ●        ●        ●        ●        ●      │
│                                                       │
│═══════════════════════════════════════════════════════│
│       │               │               │               │
│       │   TAB 1       │    TAB 2      │    TAB 3      │
└───────────────────────────────────────────────────────┘

6 nails: 1" from each end, 2 above each cutout


NAIL PLACEMENT DETAIL
═══════════════════════════════════════════════════════════
                    GOOD                    BAD
                      │                       │
        ┌─────────────┼───────────────────────┼─────────┐
        │             ●                       ●         │
        │      Nail in                  Nail in        │
        │      nailing zone             cutout         │
        │═════════════════════════════════════════════ │
        │       │                    │                 │
        │       │                    │                 │
        └───────┴────────────────────┴─────────────────┘

• Nail flush - not overdriven or underdriven
• Perpendicular to deck - not angled
• 1-1.5" roofing nails (penetrate deck 3/4")''',
              style: TextStyle(
                color: colors.accentPrimary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarterStrip(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alignLeft, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Starter Strip Installation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
STARTER STRIP POSITION
═════════════════════════════════════════════════

          ROOF DECK
    ─────────────────────────────
    │                           │
    │    ┌───────────────────┐  │
    │    │   FIRST COURSE    │  │
    │    │    SHINGLE        │  │
    │    └───────────────────┘  │
    │    ┌───────────────────┐  │
    │    │  STARTER STRIP    │◄─┼── Adhesive strip
    │    │  (adhesive down)  │  │   at EAVE EDGE
    │    └───────────────────┘  │
    │                           │
    ════════════════════════════│ ← Drip Edge
         ↑
    1/4" to 3/4" overhang

PURPOSE:
• Seals first course against wind uplift
• Fills gaps between first course tabs
• Provides adhesive bond at vulnerable edge''',
              style: TextStyle(
                color: colors.accentWarning,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTipRow(colors, 'Use pre-made starter strip or cut tabs off 3-tab shingle'),
          _buildTipRow(colors, 'Adhesive strip faces DOWN toward eave'),
          _buildTipRow(colors, 'Stagger joints from first course by 6"'),
        ],
      ),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFieldShingles(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.layoutGrid, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Field Shingle Pattern',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
6" OFFSET PATTERN (Most Common)
═══════════════════════════════════════════════════════

Course 6: │░░░░░░│          │          │          │
Course 5: │      │░░░░░░│          │          │
Course 4: │          │░░░░░░│          │          │
Course 3: │              │░░░░░░│          │          │
Course 2: │                  │░░░░░░│          │          │
Course 1: │░░░░░░│          │          │          │          │
Starter:  ████████████████████████████████████████████████████
          ════════════════════════════════════════════════════
                              EAVE (Drip Edge)

          ←── 6" offset each course ──→

IMPORTANT:
• 5" exposure (12" shingle minus 7" coverage)
• Minimum 4" end joint offset from course below
• Never align joints in adjacent courses
• Snap chalk lines for straight courses''',
              style: TextStyle(
                color: colors.accentInfo,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPatternCard(colors, '6" Offset', 'Standard residential', colors.accentSuccess),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPatternCard(colors, '5" Offset', 'Some architectural', colors.accentInfo),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPatternCard(colors, 'Random', 'Premium architectural', colors.accentWarning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard(ZaftoColors colors, String name, String usage, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(usage, style: TextStyle(color: colors.textTertiary, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCommonMistakes(ZaftoColors colors) {
    final mistakes = [
      {'mistake': 'Overdriven nails', 'fix': 'Adjust gun pressure - nail should be flush'},
      {'mistake': 'Underdriven nails', 'fix': 'Hand-nail to seat properly'},
      {'mistake': 'Nails in cutouts', 'fix': 'Position nails in nailing zone above cutouts'},
      {'mistake': 'Insufficient overhang', 'fix': 'Maintain 1/4"-3/4" past drip edge'},
      {'mistake': 'Aligned joints', 'fix': 'Maintain minimum 4" offset between courses'},
      {'mistake': 'Wrong exposure', 'fix': 'Use chalk lines, follow manufacturer specs'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Mistakes to Avoid',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mistakes.map((m) => _buildMistakeRow(colors, m)),
        ],
      ),
    );
  }

  Widget _buildMistakeRow(ZaftoColors colors, Map<String, String> mistake) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.x, color: colors.accentError, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mistake['mistake']!, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
          ),
          Icon(LucideIcons.arrowRight, color: colors.textTertiary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mistake['fix']!, style: TextStyle(color: colors.accentSuccess, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
