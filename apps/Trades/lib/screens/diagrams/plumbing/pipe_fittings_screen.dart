import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pipe Fittings Reference Diagram - Design System v2.6
class PipeFittingsScreen extends ConsumerWidget {
  const PipeFittingsScreen({super.key});

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
        title: Text('Pipe Fittings Reference', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrainageFittings(colors),
            const SizedBox(height: 16),
            _buildWaterFittings(colors),
            const SizedBox(height: 16),
            _buildElbows(colors),
            const SizedBox(height: 16),
            _buildTees(colors),
            const SizedBox(height: 16),
            _buildWyes(colors),
            const SizedBox(height: 16),
            _buildCouplings(colors),
            const SizedBox(height: 16),
            _buildTransitions(colors),
            const SizedBox(height: 16),
            _buildFittingRules(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDrainageFittings(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.arrowDownCircle, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('DRAINAGE FITTINGS (DWV)', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Drainage fittings have smooth interior curves to prevent blockages. They are NOT interchangeable with pressure fittings.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _fittingRow('Long sweep 90°', 'Horizontal to vertical changes', true, colors),
          _fittingRow('Short sweep 90°', 'Vent lines only', true, colors),
          _fittingRow('Sanitary tee', 'Vertical to horizontal', true, colors),
          _fittingRow('Wye + 1/8 bend', 'Horizontal direction change', true, colors),
          _fittingRow('Combo wye', 'Horizontal branch on horizontal', true, colors),
          _fittingRow('Double sanitary tee', 'Back-to-back fixtures', true, colors),
        ],
      ),
    );
  }

  Widget _buildWaterFittings(ZaftoColors colors) {
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
            Icon(LucideIcons.droplets, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('WATER SUPPLY FITTINGS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Pressure fittings rated for water supply. Can have sharper turns since flow is under pressure.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _fittingRow('90° elbow', 'Direction change', false, colors),
          _fittingRow('45° elbow', 'Gradual direction change', false, colors),
          _fittingRow('Tee', 'Branch connection', false, colors),
          _fittingRow('Coupling', 'Join two pipes', false, colors),
          _fittingRow('Union', 'Removable connection', false, colors),
          _fittingRow('Cap/Plug', 'Close off pipe end', false, colors),
        ],
      ),
    );
  }

  Widget _fittingRow(String name, String use, bool drainage, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: drainage ? colors.accentWarning : colors.accentInfo,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildElbows(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ELBOWS (BENDS)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('  90° (1/4 BEND)     45° (1/8 BEND)    22.5° (1/16 BEND)', colors.accentPrimary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('      │                  │                   │', colors.textTertiary),
                _diagramLine('      │                  │                   │', colors.textTertiary),
                _diagramLine('      └────           ───┘              ─────┘', colors.accentWarning),
                _diagramLine('                   ↗                      ↗', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _elbowRow('1/4 bend', '90°', 'Major direction change', colors),
          _elbowRow('1/5 bend', '72°', 'Less common', colors),
          _elbowRow('1/6 bend', '60°', 'Moderate turn', colors),
          _elbowRow('1/8 bend', '45°', 'Gradual change', colors),
          _elbowRow('1/16 bend', '22.5°', 'Slight offset', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Long sweep (DWV) vs short sweep (vent only) - never use short sweep on drain', style: TextStyle(color: colors.accentError, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _elbowRow(String name, String degrees, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 50, child: Text(degrees, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
          Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTees(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEE FITTINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('  SANITARY TEE        STANDARD TEE      DOUBLE SAN TEE', colors.accentPrimary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('       │                  │                  │', colors.textTertiary),
                _diagramLine('   ────┴────          ────┼────          ────┼────', colors.accentWarning),
                _diagramLine('   (curved)           (90° angle)       ────┴────', colors.textTertiary),
                _diagramLine('                                        (both sides)', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _teeRow('Sanitary tee', 'DWV only - sweeping curve entry', 'Fixture to stack', colors),
          _teeRow('Standard tee', 'Water supply - 90° branch', 'Branch lines', colors),
          _teeRow('Double san tee', 'Back-to-back wet venting', '2 fixtures', colors),
          _teeRow('Test tee', 'Has cleanout plug', 'Cleanout access', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Sanitary tees: Vertical to horizontal ONLY. Never lay flat on horizontal drain!', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _teeRow(String name, String desc, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
              const Spacer(),
              Text(use, style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
            ],
          ),
          Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildWyes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WYE FITTINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('      WYE              COMBO WYE         WYE + 1/8 BEND', colors.accentPrimary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('       ↘                  ↘                   ↘', colors.textTertiary),
                _diagramLine('   ─────┴─────        ─────┴─────         ─────┴──┐', colors.accentWarning),
                _diagramLine('    45° entry         curved entry             └──', colors.textTertiary),
                _diagramLine('                      (combination)         = 90° total', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _wyeRow('Standard wye', '45° branch', 'Horizontal drainage', colors),
          _wyeRow('Combo wye', 'Sweeping 45° + 45°', 'Smooth horizontal entry', colors),
          _wyeRow('Double wye', 'Two 45° branches', 'Two-fixture connection', colors),
          _wyeRow('Reducing wye', 'Smaller branch size', 'Size transitions', colors),
          const SizedBox(height: 12),
          Text('Wye + 1/8 bend = Code-approved 90° for horizontal drains', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _wyeRow(String name, String angle, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 90, child: Text(angle, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
          Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCouplings(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COUPLINGS & UNIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _couplingRow('Coupling', 'Joins two pipes end-to-end', 'Permanent', colors),
          _couplingRow('Slip coupling', 'No internal stop, slides over', 'Repairs', colors),
          _couplingRow('Union', 'Three-piece, can disconnect', 'Removable', colors),
          _couplingRow('Dielectric union', 'Separates dissimilar metals', 'Copper-steel', colors),
          _couplingRow('Fernco/No-hub', 'Rubber with clamps', 'CI to PVC', colors),
          _couplingRow('MJ coupling', 'Mechanical joint', 'Underground', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Dielectric unions REQUIRED when connecting copper to galvanized or steel to prevent galvanic corrosion.', style: TextStyle(color: colors.accentInfo, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _couplingRow(String name, String desc, String type, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(type, style: TextStyle(color: colors.accentPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitions(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRANSITION & ADAPTER FITTINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _transRow('Reducer', 'Change pipe size', 'Concentric or eccentric', colors),
          _transRow('Bushing', 'Reduce fitting size', 'Fits inside fitting', colors),
          _transRow('Male adapter', 'Pipe to male thread', 'Connect to valve/fixture', colors),
          _transRow('Female adapter', 'Pipe to female thread', 'Connect to pipe thread', colors),
          _transRow('Trap adapter', 'Tubular to DWV', 'Fixture drain to trap', colors),
          _transRow('Closet flange', 'Drain to toilet', 'Floor mount', colors),
          const SizedBox(height: 12),
          Text('Eccentric reducers keep bottom of pipe level - required for drainage to maintain slope.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _transRow(String name, String purpose, String notes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 100, child: Text(purpose, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
          Expanded(child: Text(notes, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildFittingRules(ZaftoColors colors) {
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
            Text('CRITICAL FITTING RULES', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• NEVER use sanitary tee on horizontal drain (flat)\n'
            '• Use long sweep elbows on drains, not short\n'
            '• Drainage fittings ONLY for DWV - never pressure\n'
            '• Standard tees OK for vents, not drains\n'
            '• Wye + 1/8 bend for horizontal 90° turns\n'
            '• No double-hub fittings (drainage)\n'
            '• Eccentric reducers for horizontal size change\n'
            '• Match fitting material to pipe material',
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
