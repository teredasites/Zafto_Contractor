import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Furnace Venting Diagram - Design System v2.6
class FurnaceVentingScreen extends ConsumerWidget {
  const FurnaceVentingScreen({super.key});

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
        title: Text('Furnace Venting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVentCategories(colors),
            const SizedBox(height: 16),
            _buildCategoryI(colors),
            const SizedBox(height: 16),
            _buildCategoryII(colors),
            const SizedBox(height: 16),
            _buildCategoryIII(colors),
            const SizedBox(height: 16),
            _buildCategoryIV(colors),
            const SizedBox(height: 16),
            _buildVentMaterials(colors),
            const SizedBox(height: 16),
            _buildTerminationRules(colors),
            const SizedBox(height: 16),
            _buildCommonViolations(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildVentCategories(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APPLIANCE VENT CATEGORIES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('Categories based on pressure and condensation:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _catHeader(colors),
                _catRow('I', 'Non-positive', 'Non-condensing', '80% AFUE natural', colors),
                _catRow('II', 'Non-positive', 'Condensing', 'Rare configuration', colors),
                _catRow('III', 'Positive', 'Non-condensing', '80%+ power vent', colors),
                _catRow('IV', 'Positive', 'Condensing', '90%+ high eff', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('Cat', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
          SizedBox(width: 70, child: Text('Pressure', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
          SizedBox(width: 75, child: Text('Condensing', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
          Expanded(child: Text('Example', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _catRow(String cat, String pressure, String condensing, String example, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(cat, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 12))),
          SizedBox(width: 70, child: Text(pressure, style: TextStyle(color: colors.textPrimary, fontSize: 10))),
          SizedBox(width: 75, child: Text(condensing, style: TextStyle(color: colors.textPrimary, fontSize: 10))),
          Expanded(child: Text(example, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildCategoryI(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentWarning, borderRadius: BorderRadius.circular(4)),
              child: Text('CAT I', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            const SizedBox(width: 10),
            Text('NATURAL DRAFT (80% AFUE)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('           ╔══════╗', colors.textTertiary),
                _diagramLine('           ║ VENT ║ ← Vent cap', colors.textTertiary),
                _diagramLine('           ║  CAP ║', colors.textTertiary),
                _diagramLine('           ╚══╤═══╝', colors.textTertiary),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('     Type B   │', colors.accentWarning),
                _diagramLine('     Vent     │', colors.accentWarning),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('    ══════════╧═════ Roof line', colors.textTertiary),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('   ┌──────────┴──────────┐', colors.accentWarning),
                _diagramLine('   │     DRAFT HOOD      │ ← Dilution air enters', colors.accentWarning),
                _diagramLine('   └──────────┬──────────┘', colors.accentWarning),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('   ┌──────────┴──────────┐', colors.accentError),
                _diagramLine('   │      FURNACE        │', colors.accentError),
                _diagramLine('   │   (heat exchanger)  │', colors.accentError),
                _diagramLine('   └─────────────────────┘', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ventRow('Vent type', 'Type B (double-wall) or single-wall to B', colors),
          _ventRow('Draft', 'Natural (buoyancy driven)', colors),
          _ventRow('Termination', 'Above roof with cap', colors),
          _ventRow('Draft hood', 'Required - provides dilution air', colors),
        ],
      ),
    );
  }

  Widget _buildCategoryII(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentInfo, borderRadius: BorderRadius.circular(4)),
              child: Text('CAT II', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            const SizedBox(width: 10),
            Text('CONDENSING NATURAL DRAFT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Rare configuration - negative pressure with condensing flue. Requires special AL29-4C stainless vent.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Category II is uncommon. Most condensing appliances are Category IV (positive pressure).', style: TextStyle(color: colors.accentWarning, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIII(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(4)),
              child: Text('CAT III', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            const SizedBox(width: 10),
            Text('POWER VENT (80%)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Fan-assisted combustion, but flue gas stays above dew point (no condensation).', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _ventRow('Vent type', 'Type B or special (per manufacturer)', colors),
          _ventRow('Termination', 'Can be sidewall or roof', colors),
          _ventRow('Inducer fan', 'Creates positive vent pressure', colors),
          _ventRow('Joints', 'Must be sealed (positive pressure)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Power-vented water heaters are typically Category III. Follow manufacturer vent tables exactly.', style: TextStyle(color: colors.accentInfo, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIV(ZaftoColors colors) {
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentSuccess, borderRadius: BorderRadius.circular(4)),
              child: Text('CAT IV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            const SizedBox(width: 10),
            Text('HIGH EFFICIENCY (90%+ AFUE)', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('       OUTSIDE           │    INSIDE', colors.textTertiary),
                _diagramLine('                         │', colors.textTertiary),
                _diagramLine('    ┌─────────┐         │', colors.textTertiary),
                _diagramLine('    │  EXHAUST│ ←═══════════ EXHAUST (PVC)', colors.accentError),
                _diagramLine('    │   TERM  │         │', colors.textTertiary),
                _diagramLine('    └─────────┘         │', colors.textTertiary),
                _diagramLine('                         │', colors.textTertiary),
                _diagramLine('    ┌─────────┐         │', colors.textTertiary),
                _diagramLine('    │ INTAKE  │ ═══════════> INTAKE (PVC)', colors.accentInfo),
                _diagramLine('    │  TERM   │         │    (direct vent)', colors.textTertiary),
                _diagramLine('    └─────────┘         │', colors.textTertiary),
                _diagramLine('                         │ ┌─────────────┐', colors.accentSuccess),
                _diagramLine('                         │ │  90%+ AFUE  │', colors.accentSuccess),
                _diagramLine('                         │ │   FURNACE   │', colors.accentSuccess),
                _diagramLine('                         │ └─────────────┘', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ventRow('Vent material', 'PVC, CPVC, or polypropylene', colors),
          _ventRow('Termination', 'Sidewall (most common) or roof', colors),
          _ventRow('Intake', 'Direct vent from outside', colors),
          _ventRow('Condensate', 'Must be drained (acidic)', colors),
          _ventRow('Joints', 'Primer + cement (sealed)', colors),
        ],
      ),
    );
  }

  Widget _ventRow(String item, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildVentMaterials(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VENT MATERIALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _matRow('Type B', 'Double-wall galv/aluminum', 'Cat I, some Cat III', colors),
          _matRow('Single-wall', 'Galvanized steel', 'Cat I connector only', colors),
          _matRow('PVC/CPVC', 'Schedule 40', 'Cat IV (check temp rating)', colors),
          _matRow('CPVC', 'Higher temp rating', 'Cat IV, some Cat III', colors),
          _matRow('Polypropylene', 'High temp plastic', 'Cat III & IV', colors),
          _matRow('AL29-4C', 'Stainless steel', 'Cat II, III, IV', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('ALWAYS follow manufacturer instructions for vent material. Using wrong material can cause fire or CO poisoning!', style: TextStyle(color: colors.accentError, fontSize: 11))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _matRow(String material, String desc, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(material, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                Text(use, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminationRules(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TERMINATION CLEARANCES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('Sidewall (Cat III/IV):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _termRow('Above grade', '12" minimum', colors),
          _termRow('Below window', '12" minimum', colors),
          _termRow('From inside corner', '12" minimum', colors),
          _termRow('From openings', '4 ft to side, 1 ft above', colors),
          _termRow('Adjacent building', '10 ft minimum', colors),
          _termRow('Intake to exhaust', '12" min apart', colors),
          const SizedBox(height: 10),
          Text('Roof (Type B):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _termRow('Above roof', 'Per IFGC table (1-10 ft)', colors),
          _termRow('From vertical wall', '8 ft or 2 ft above', colors),
        ],
      ),
    );
  }

  Widget _termRow(String location, String clearance, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(location, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Text(clearance, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCommonViolations(ZaftoColors colors) {
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
            Text('COMMON VIOLATIONS', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _violationRow('Wrong material', 'Using PVC on Cat I/III', colors),
          _violationRow('Improper slope', 'Must slope back to appliance', colors),
          _violationRow('Undersized', 'Vent too small for BTU input', colors),
          _violationRow('No support', 'Horizontal runs need support', colors),
          _violationRow('Too close', 'Termination clearances violated', colors),
          _violationRow('Obstructed', 'Bird nest, screen, debris', colors),
          _violationRow('Unsealed joints', 'Cat III/IV require sealed joints', colors),
          _violationRow('Single-wall wrong', 'Too long or in wrong location', colors),
        ],
      ),
    );
  }

  Widget _violationRow(String violation, String issue, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.x, color: colors.accentError, size: 14),
          const SizedBox(width: 8),
          SizedBox(width: 95, child: Text(violation, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(issue, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
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
            '• IFGC Chapter 5 - Chimneys & Vents\n'
            '• Sizing per IFGC Tables 504.2, 504.3\n'
            '• Material per appliance category\n'
            '• Termination clearances per code\n'
            '• UL listed components required\n'
            '• Combustion air per IFGC 304\n'
            '• No reduction in vent size\n'
            '• Proper support and pitch\n'
            '• Access for inspection',
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
