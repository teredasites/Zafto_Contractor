import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class HardscapeBasicsScreen extends ConsumerWidget {
  const HardscapeBasicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Hardscape Basics',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasePreparation(colors),
            const SizedBox(height: 24),
            _buildPatioInstallation(colors),
            const SizedBox(height: 24),
            _buildPaverPatterns(colors),
            const SizedBox(height: 24),
            _buildEdgeRestraints(colors),
            const SizedBox(height: 24),
            _buildSlopeAndDrainage(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBasePreparation(ZaftoColors colors) {
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
                'Base Preparation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''PAVER BASE CROSS-SECTION

    ═══════════════════════════ ← PAVERS (2-3")
    ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ← Bedding sand (1")
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░ ← Compacted base
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░   (4-6" residential)
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░   (8-12" vehicular)
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ← Geotextile fabric
    ═══════════════════════════ ← Compacted subgrade

EXCAVATION DEPTH:
• Patio: 7-9" total
• Driveway: 12-14" total
• Add depth for poor soil''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBaseLayer(colors, 'Subgrade', 'Undisturbed soil, compacted to 95%'),
          _buildBaseLayer(colors, 'Geotextile', 'Prevents soil migration'),
          _buildBaseLayer(colors, 'Base material', '3/4" crushed stone, compacted in lifts'),
          _buildBaseLayer(colors, 'Bedding sand', 'Coarse concrete sand, screeded flat'),
          _buildBaseLayer(colors, 'Pavers', 'Interlocking units, tapped level'),
          _buildBaseLayer(colors, 'Joint sand', 'Polymeric sand, swept and wetted'),
        ],
      ),
    );
  }

  Widget _buildBaseLayer(ZaftoColors colors, String layer, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentPrimary, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(layer, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildPatioInstallation(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Layout and string lines', 'detail': 'Mark area, set grade stakes'},
      {'step': '2', 'task': 'Excavate to depth', 'detail': '7-9" for patios, plus slope'},
      {'step': '3', 'task': 'Compact subgrade', 'detail': 'Plate compactor, 95% compaction'},
      {'step': '4', 'task': 'Install geotextile', 'detail': 'Overlap seams 12"'},
      {'step': '5', 'task': 'Spread and compact base', 'detail': '2" lifts, compact each'},
      {'step': '6', 'task': 'Set edge restraints', 'detail': 'Stake every 12"'},
      {'step': '7', 'task': 'Screed bedding sand', 'detail': '1" depth, do not walk on'},
      {'step': '8', 'task': 'Lay pavers', 'detail': 'Start corner, work outward'},
      {'step': '9', 'task': 'Cut edge pavers', 'detail': 'Wet saw or splitter'},
      {'step': '10', 'task': 'Compact pavers', 'detail': 'Plate with pad, 2-3 passes'},
      {'step': '11', 'task': 'Apply joint sand', 'detail': 'Sweep, compact, repeat'},
      {'step': '12', 'task': 'Seal (optional)', 'detail': 'After 30 days curing'},
    ];

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
          Row(
            children: [
              Icon(LucideIcons.listOrdered, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Patio Installation Steps',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.accentSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(s['step']!, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 9)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['task']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                      Text(s['detail']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaverPatterns(ZaftoColors colors) {
    final patterns = [
      {'name': 'Running Bond', 'diagram': '══════\n ══════\n══════', 'waste': '5%'},
      {'name': 'Herringbone 45°', 'diagram': '╲╱╲╱╲╱\n╱╲╱╲╱╲', 'waste': '10%'},
      {'name': 'Herringbone 90°', 'diagram': '═║═║═\n║═║═║', 'waste': '10%'},
      {'name': 'Basket Weave', 'diagram': '══ ║║\n║║ ══', 'waste': '5%'},
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
              Icon(LucideIcons.layoutGrid, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Paver Patterns',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: patterns.map((p) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('${p['waste']} cut', style: TextStyle(color: colors.accentWarning, fontSize: 9)),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      p['diagram']!,
                      style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '45° herringbone is strongest for driveways - resists shifting under vehicle loads.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdgeRestraints(ZaftoColors colors) {
    final types = [
      {'type': 'Plastic paver edge', 'use': 'Residential patios, curved edges', 'stake': '12" OC'},
      {'type': 'Aluminum edge', 'use': 'Commercial, heavy traffic', 'stake': '18" OC'},
      {'type': 'Concrete curb', 'use': 'Driveways, permanent', 'stake': 'N/A'},
      {'type': 'Soldier course', 'use': 'Decorative border', 'stake': 'Set in concrete'},
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
              Icon(LucideIcons.square, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Edge Restraints',
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
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''EDGE RESTRAINT INSTALLATION

        ┌──────────────────────────┐
        │     PAVER FIELD          │
        │                          │
    ════╪══════════════════════════╪════
        │                          │
    ┌───┴───┐                  ┌───┴───┐
    │ EDGE  │←── Spike 12" OC ─→│ EDGE  │
    │       │                  │       │
    └───┬───┘                  └───┬───┘
        │                          │
    ════╧══════════════════════════╧════
             COMPACTED BASE

Edge sits on base, not bedding sand
Stakes driven into base material''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...types.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(t['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(t['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
                Text(t['stake']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSlopeAndDrainage(ZaftoColors colors) {
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
              Icon(LucideIcons.trendingDown, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Slope & Drainage',
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
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''DRAINAGE SLOPE

    HOUSE
    ║║║║║║
    ║║║║║║
────────────┐
PATIO       │
  ↘         │ Slope AWAY from
    ↘       │ foundation
      ↘     │
────────────┘
        ↓
    DRAINAGE

MINIMUM SLOPES:
• Patio: 1/8" per foot (1%)
• Driveway: 1/4" per foot (2%)
• Recommend: 1/4" per foot

10' patio = 2.5" drop minimum''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Water pooling causes settling, erosion, and ice hazards. Always slope away from structures.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
