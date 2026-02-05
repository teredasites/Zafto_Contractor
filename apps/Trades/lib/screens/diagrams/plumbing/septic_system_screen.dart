import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Septic System Basics Diagram - Design System v2.6
class SepticSystemScreen extends ConsumerWidget {
  const SepticSystemScreen({super.key});

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
        title: Text('Septic System Basics', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemOverview(colors),
            const SizedBox(height: 16),
            _buildSepticTank(colors),
            const SizedBox(height: 16),
            _buildDrainField(colors),
            const SizedBox(height: 16),
            _buildDistributionBox(colors),
            const SizedBox(height: 16),
            _buildSizing(colors),
            const SizedBox(height: 16),
            _buildMaintenance(colors),
            const SizedBox(height: 16),
            _buildWarnings(colors),
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
          Text('CONVENTIONAL SEPTIC SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('┌─────────┐', colors.textTertiary),
                _diagramLine('│  HOUSE  │', colors.textTertiary),
                _diagramLine('└────┬────┘', colors.textTertiary),
                _diagramLine('     │', colors.textTertiary),
                _diagramLine('     │ Sewer line (4" min)', colors.accentWarning),
                _diagramLine('     │', colors.textTertiary),
                _diagramLine('┌────┴────┐', colors.accentWarning),
                _diagramLine('│  SEPTIC │ ← Solids settle, scum floats', colors.accentWarning),
                _diagramLine('│  TANK   │   bacteria break down waste', colors.textTertiary),
                _diagramLine('└────┬────┘', colors.accentWarning),
                _diagramLine('     │', colors.textTertiary),
                _diagramLine('     │ Effluent line', colors.accentInfo),
                _diagramLine('     │', colors.textTertiary),
                _diagramLine('┌────┴────┐', colors.accentInfo),
                _diagramLine('│ D-BOX   │ ← Distributes flow', colors.accentInfo),
                _diagramLine('└─┬───┬───┘', colors.accentInfo),
                _diagramLine('  │   │', colors.textTertiary),
                _diagramLine('══════════════════════════', colors.accentSuccess),
                _diagramLine('      DRAIN FIELD', colors.accentSuccess),
                _diagramLine('   (leach field/bed)', colors.textTertiary),
                _diagramLine('══════════════════════════', colors.accentSuccess),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSepticTank(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.archive, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('SEPTIC TANK', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('          ACCESS RISERS', colors.textTertiary),
                _diagramLine('             ↓    ↓', colors.textTertiary),
                _diagramLine('IN ═══════┬────────┬═══════ OUT', colors.accentWarning),
                _diagramLine('          │        │', colors.textTertiary),
                _diagramLine(' ∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼ SCUM', colors.accentError),
                _diagramLine('│                          │ (fats, oils)', colors.textTertiary),
                _diagramLine('│      CLEAR ZONE          │', colors.accentInfo),
                _diagramLine('│     (liquid effluent)    │', colors.textTertiary),
                _diagramLine('│                          │', colors.textTertiary),
                _diagramLine(' ░░░░░░░░░░░░░░░░░░░░░░░░░ SLUDGE', colors.textPrimary),
                _diagramLine('│     (settled solids)     │', colors.textTertiary),
                _diagramLine('└──────────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _tankRow('Inlet baffle', 'Slows incoming flow, directs down', colors),
          _tankRow('Outlet baffle', 'Prevents scum from exiting', colors),
          _tankRow('Effluent filter', 'Additional solids protection', colors),
          _tankRow('Access risers', 'Bring lids to grade level', colors),
        ],
      ),
    );
  }

  Widget _tankRow(String component, String function, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(component, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(function, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildDrainField(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.trees, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('DRAIN FIELD (LEACH FIELD)', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Effluent percolates through soil for final treatment:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('─────────────────── GRADE', colors.textTertiary),
                _diagramLine('│                        │', colors.textTertiary),
                _diagramLine('│  ░░░░░░░░░░░░░░░░░░░░  │ ← Topsoil (6-12")', colors.textTertiary),
                _diagramLine('│  ════════════════════  │ ← Geotextile fabric', colors.accentInfo),
                _diagramLine('│  ○ ○ ○ ○ ○ ○ ○ ○ ○ ○  │ ← Gravel bed', colors.textTertiary),
                _diagramLine('│     ══════════════     │ ← Perforated pipe', colors.accentWarning),
                _diagramLine('│  ○ ○ ○ ○ ○ ○ ○ ○ ○ ○  │ ← Gravel bed', colors.textTertiary),
                _diagramLine('│  ════════════════════  │ ← Geotextile fabric', colors.accentInfo),
                _diagramLine('│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │ ← Native soil', colors.textTertiary),
                _diagramLine('│         ↓ ↓ ↓         │', colors.textTertiary),
                _diagramLine('│     Effluent absorbs   │', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _fieldRow('Trench width', '12-36" typical', colors),
          _fieldRow('Trench depth', '18-36" to gravel', colors),
          _fieldRow('Gravel depth', '6" below, 2" above pipe', colors),
          _fieldRow('Pipe diameter', '4" perforated', colors),
          _fieldRow('Slope', '0" to 4" per 100 ft (level OK)', colors),
        ],
      ),
    );
  }

  Widget _fieldRow(String item, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(spec, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDistributionBox(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISTRIBUTION BOX (D-BOX)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('     FROM TANK', colors.accentWarning),
                _diagramLine('         │', colors.textTertiary),
                _diagramLine('    ┌────┴────┐', colors.accentInfo),
                _diagramLine('    │  D-BOX  │', colors.accentInfo),
                _diagramLine('    └┬──┬──┬──┘', colors.accentInfo),
                _diagramLine('     │  │  │', colors.textTertiary),
                _diagramLine('     ▼  ▼  ▼', colors.textTertiary),
                _diagramLine('   [LINE 1][LINE 2][LINE 3]', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _dboxRow('Function', 'Equally distributes flow to all lines', colors),
          _dboxRow('Level', 'Must be perfectly level', colors),
          _dboxRow('Material', 'Concrete or plastic', colors),
          _dboxRow('Access', 'Lid at or near grade', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('If D-box tips or settles, one field line gets all flow and fails prematurely', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _dboxRow(String label, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('SYSTEM SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Tank Sizing (by bedrooms):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _sizeRow('1-2 bedrooms', '750-1,000 gallons', colors),
                _sizeRow('3 bedrooms', '1,000-1,250 gallons', colors),
                _sizeRow('4 bedrooms', '1,250-1,500 gallons', colors),
                _sizeRow('5-6 bedrooms', '1,500+ gallons', colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Drain Field Sizing:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Text('Based on soil percolation test (perc test). Faster perc = smaller field. Typical residential: 300-900 sq ft of trench bottom.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          _sizeRow('Sandy soil (fast perc)', 'Less field area needed', colors),
          _sizeRow('Clay soil (slow perc)', 'More field area needed', colors),
        ],
      ),
    );
  }

  Widget _sizeRow(String size, String capacity, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(size, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(capacity, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMaintenance(ZaftoColors colors) {
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
            Icon(LucideIcons.wrench, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('MAINTENANCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _maintRow('Pump tank', 'Every 3-5 years (more with garbage disposal)', colors),
          _maintRow('Inspect baffles', 'During each pumping', colors),
          _maintRow('Check effluent filter', 'Clean annually if installed', colors),
          _maintRow('Inspect D-box', 'Check level, condition', colors),
          const SizedBox(height: 12),
          Text('Pump When:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('• Sludge reaches 1/3 of tank depth\n• Scum layer reaches outlet baffle\n• Every 3-5 years regardless', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _maintRow(String task, String frequency, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(task, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(frequency, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildWarnings(ZaftoColors colors) {
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
            Text('DO NOT', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Drive or park on tank or drain field\n'
            '• Plant trees near system (roots invade)\n'
            '• Flush non-biodegradable items\n'
            '• Use excessive water (overloads system)\n'
            '• Dump grease, oils, chemicals, paint\n'
            '• Use garbage disposal excessively\n'
            '• Connect sump pump to septic\n'
            '• Connect roof drains to septic\n'
            '• Ignore warning signs (slow drains, odors)',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeRequirements(ZaftoColors colors) {
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
            Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('CODE & SETBACK REQUIREMENTS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Typical Setbacks (verify local code):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          _setbackRow('Tank to well', '50-100 ft minimum', colors),
          _setbackRow('Field to well', '100-150 ft minimum', colors),
          _setbackRow('Tank to house', '5-10 ft minimum', colors),
          _setbackRow('Field to house', '10-20 ft minimum', colors),
          _setbackRow('To property line', '5-10 ft minimum', colors),
          _setbackRow('To water body', '50-100 ft minimum', colors),
          const SizedBox(height: 12),
          Text(
            '• Perc test required before installation\n'
            '• Permit required - health department\n'
            '• Licensed installer required (most areas)\n'
            '• Inspection at various stages',
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _setbackRow(String from, String distance, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(from, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(distance, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
