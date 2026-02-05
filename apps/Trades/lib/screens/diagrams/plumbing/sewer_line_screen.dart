import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Sewer Line Basics Diagram - Design System v2.6
class SewerLineScreen extends ConsumerWidget {
  const SewerLineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sewer Line Basics', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemOverview(colors),
            const SizedBox(height: 16),
            _buildSewerLateral(colors),
            const SizedBox(height: 16),
            _buildPipeMaterials(colors),
            const SizedBox(height: 16),
            _buildSlopeRequirements(colors),
            const SizedBox(height: 16),
            _buildTrenchingRequirements(colors),
            const SizedBox(height: 16),
            _buildConnections(colors),
            const SizedBox(height: 16),
            _buildCommonProblems(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SANITARY SEWER SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('┌──────────────────────────────────────────┐', colors.textTertiary),
                _diagramLine('│            BUILDING                      │', colors.textTertiary),
                _diagramLine('│  [FIX]──[FIX]──[FIX]                     │', colors.accentInfo),
                _diagramLine('│         │                                │', colors.textTertiary),
                _diagramLine('│    Building Drain                        │', colors.textTertiary),
                _diagramLine('│  ════════════════╗                       │', colors.accentWarning),
                _diagramLine('└──────────────────╬───────────────────────┘', colors.textTertiary),
                _diagramLine('                   ║', colors.accentWarning),
                _diagramLine('              Building Sewer', colors.textTertiary),
                _diagramLine('              (Lateral)', colors.textTertiary),
                _diagramLine('                   ║', colors.accentWarning),
                _diagramLine('═══════════════════╬═════════════════════════', colors.accentError),
                _diagramLine('           PUBLIC SEWER MAIN', colors.accentError),
                _diagramLine('           (City responsibility)', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _termRow('Building drain', 'Inside the building, to 30" outside', colors),
          _termRow('Building sewer', 'From 30" outside to main (lateral)', colors),
          _termRow('Public sewer', 'City main in street or easement', colors),
        ],
      ),
    );
  }

  Widget _termRow(String term, String def, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(term, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(def, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSewerLateral(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.arrowRightLeft, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('BUILDING SEWER (LATERAL)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _lateralRow('Minimum size', '4" (typical residential)', colors),
          _lateralRow('Material', 'PVC, ABS, cast iron, clay', colors),
          _lateralRow('Slope', '1/8" to 1/4" per foot (1-2%)', colors),
          _lateralRow('Depth', 'Below frost line, 12" cover minimum', colors),
          _lateralRow('Ownership', 'Property owner to main connection', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Property owner is typically responsible for the lateral from house to property line or main connection', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _lateralRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Expanded(child: Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildPipeMaterials(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEWER PIPE MATERIALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _materialRow('PVC SDR-35', 'Most common new install', 'Solvent weld joints', true, colors),
          _materialRow('ABS', 'Similar to PVC', 'Solvent weld joints', true, colors),
          _materialRow('Cast Iron', 'Durable, quiet', 'No-hub or bell & spigot', true, colors),
          _materialRow('Orangeburg', 'Old tar paper pipe', 'REPLACE - it collapses', false, colors),
          _materialRow('Clay/VCP', 'Very old, brittle', 'Replace when possible', false, colors),
          _materialRow('Concrete', 'Large mains only', 'Municipal use', true, colors),
          const SizedBox(height: 12),
          Text('SDR Rating (Standard Dimension Ratio):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Text('SDR-35: Lighter duty (sewer laterals)\nSDR-26: Medium duty\nSchedule 40: Heavy duty (under buildings, drives)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _materialRow(String material, String use, String joints, bool recommended, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(recommended ? LucideIcons.check : LucideIcons.x, color: recommended ? colors.accentSuccess : colors.accentError, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text('$use - $joints', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.trendingDown, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('SLOPE REQUIREMENTS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Proper slope ensures solids transport without settling:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _slopeRow('3" pipe or less', '1/4" per foot minimum', colors),
                _slopeRow('4" pipe', '1/8" per foot minimum', colors),
                _slopeRow('6" pipe', '1/8" per foot minimum', colors),
                _slopeRow('8" pipe', '1/16" per foot minimum', colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Too steep (>1/2"/ft) can cause liquids to outrun solids, leaving deposits', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slopeRow(String pipe, String slope, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(pipe, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Text(slope, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTrenchingRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.shovel, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('TRENCHING & BEDDING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('     ─────────────── GRADE', colors.textTertiary),
                _diagramLine('     │             │', colors.textTertiary),
                _diagramLine('     │  12" min    │ ← Cover', colors.accentPrimary),
                _diagramLine('     │   cover     │', colors.textTertiary),
                _diagramLine('     │             │', colors.textTertiary),
                _diagramLine('     │  ═══════    │ ← Backfill', colors.accentWarning),
                _diagramLine('     │   PIPE      │    (no rocks)', colors.textTertiary),
                _diagramLine('     │  ═══════    │', colors.accentWarning),
                _diagramLine('     │  :::::::    │ ← Bedding', colors.accentInfo),
                _diagramLine('     │  4-6" sand  │    (sand/gravel)', colors.textTertiary),
                _diagramLine('     └─────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _trenchRow('Cover depth', '12" minimum (more in traffic areas)', colors),
          _trenchRow('Bedding', '4-6" sand/gravel under pipe', colors),
          _trenchRow('Haunching', 'Compact material around pipe sides', colors),
          _trenchRow('Initial backfill', '6-12" above pipe, no rocks', colors),
          _trenchRow('Final backfill', 'Native soil OK after initial', colors),
        ],
      ),
    );
  }

  Widget _trenchRow(String item, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildConnections(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONNECTION METHODS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _connRow('Wye fitting', 'Preferred - at 45° into main', colors),
          _connRow('Saddle tap', 'Cut-in connection to existing main', colors),
          _connRow('Manhole', 'Large systems, commercial', colors),
          const SizedBox(height: 12),
          Text('PVC Joint Methods:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _connRow('Solvent weld', 'Permanent, use primer + cement', colors),
          _connRow('Gasketed', 'Push-fit with rubber gasket', colors),
          _connRow('Mechanical', 'Fernco/no-hub couplings', colors),
        ],
      ),
    );
  }

  Widget _connRow(String method, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(method, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCommonProblems(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 18),
            const SizedBox(width: 8),
            Text('COMMON SEWER PROBLEMS', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _problemRow('Root intrusion', 'Trees seek water, enter joints', 'Root cutting, pipe lining', colors),
          _problemRow('Bellied pipe', 'Section sags, collects waste', 'Replace affected section', colors),
          _problemRow('Offset joint', 'Joints shift, catch debris', 'Replace or line', colors),
          _problemRow('Collapsed pipe', 'Orangeburg, old clay fails', 'Full replacement', colors),
          _problemRow('Grease buildup', 'FOG accumulation', 'Hydro jetting', colors),
          _problemRow('Scale buildup', 'Mineral deposits', 'Mechanical cleaning', colors),
        ],
      ),
    );
  }

  Widget _problemRow(String problem, String cause, String solution, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(problem, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          Row(
            children: [
              Expanded(child: Text(cause, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
              Text(solution, style: TextStyle(color: colors.accentSuccess, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('CODE REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• IPC Section 703 - Building Sewer\n'
            '• UPC Section 720 - Building Sewers\n'
            '• Minimum 3" for 1-2 water closets\n'
            '• Minimum 4" for 3+ water closets\n'
            '• Cleanout every 100 ft\n'
            '• Cleanout at property line\n'
            '• Testing required before covering\n'
            '• Air test: 5 PSI for 15 minutes\n'
            '• Water test: 10 ft head for 15 min\n'
            '• Inspection before backfill',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
