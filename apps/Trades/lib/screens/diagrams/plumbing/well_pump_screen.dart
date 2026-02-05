import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Well Pump Systems Diagram - Design System v2.6
class WellPumpScreen extends ConsumerWidget {
  const WellPumpScreen({super.key});

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
        title: Text('Well Pump Systems', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemOverview(colors),
            const SizedBox(height: 16),
            _buildSubmersibleSystem(colors),
            const SizedBox(height: 16),
            _buildJetPumpSystem(colors),
            const SizedBox(height: 16),
            _buildPressureTank(colors),
            const SizedBox(height: 16),
            _buildPressureSwitch(colors),
            const SizedBox(height: 16),
            _buildWellComponents(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
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
          Row(children: [
            Icon(LucideIcons.waves, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('WELL PUMP TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _pumpTypeRow('Submersible', 'In well, pushes water up', 'Deep wells (25-400 ft)', colors),
          _pumpTypeRow('Shallow jet', 'Above ground, single pipe', 'Shallow wells (<25 ft)', colors),
          _pumpTypeRow('Deep jet', 'Above ground, two pipes', 'Medium depth (25-100 ft)', colors),
          _pumpTypeRow('Convertible jet', 'Configurable shallow/deep', 'Variable depth', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Submersible pumps are most common for residential wells today - more efficient and quieter', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _pumpTypeRow(String type, String desc, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
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

  Widget _buildSubmersibleSystem(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUBMERSIBLE PUMP SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('      ┌──────────────────────────────────┐', colors.textTertiary),
                _diagramLine('      │         PRESSURE TANK            │', colors.accentWarning),
                _diagramLine('      │            ┌───┐                 │', colors.accentWarning),
                _diagramLine('      │            │   │ ← Pre-charged   │', colors.textTertiary),
                _diagramLine('      │            │AIR│   air bladder   │', colors.textTertiary),
                _diagramLine('      │            ├───┤                 │', colors.textTertiary),
                _diagramLine('      │            │H2O│                 │', colors.accentInfo),
                _diagramLine('      │            └─┬─┘                 │', colors.textTertiary),
                _diagramLine('      │              │                   │', colors.textTertiary),
                _diagramLine('      │  [SWITCH]────┼────→ TO HOUSE     │', colors.accentPrimary),
                _diagramLine('      │              │                   │', colors.textTertiary),
                _diagramLine('      └──────────────┼───────────────────┘', colors.textTertiary),
                _diagramLine('      WELL CAP ══════╧══════', colors.accentWarning),
                _diagramLine('           ║    ↑ Pitless', colors.textTertiary),
                _diagramLine('           ║      adapter', colors.textTertiary),
                _diagramLine('           ║', colors.textTertiary),
                _diagramLine('      ─────╫───── FROST LINE', colors.accentError),
                _diagramLine('           ║', colors.textTertiary),
                _diagramLine('      Well casing', colors.textTertiary),
                _diagramLine('           ║', colors.textTertiary),
                _diagramLine('     ══════╬══════ STATIC WATER LEVEL', colors.accentInfo),
                _diagramLine('           ║', colors.textTertiary),
                _diagramLine('        ┌──┴──┐', colors.accentPrimary),
                _diagramLine('        │PUMP │ ← Submersible', colors.accentPrimary),
                _diagramLine('        │MOTOR│   pump/motor', colors.accentPrimary),
                _diagramLine('        └─────┘', colors.accentPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJetPumpSystem(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('JET PUMP SYSTEMS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SHALLOW JET', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10)),
                      const SizedBox(height: 8),
                      _diagramLine('[PUMP]', colors.accentPrimary),
                      _diagramLine('  │', colors.textTertiary),
                      _diagramLine('  │ Single', colors.textTertiary),
                      _diagramLine('  │ pipe', colors.textTertiary),
                      _diagramLine('  ▼', colors.textTertiary),
                      _diagramLine('WATER', colors.accentInfo),
                      const SizedBox(height: 6),
                      Text('<25 ft lift', style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DEEP JET', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 10)),
                      const SizedBox(height: 8),
                      _diagramLine('[PUMP]', colors.accentWarning),
                      _diagramLine(' │  │', colors.textTertiary),
                      _diagramLine(' │  │ Two', colors.textTertiary),
                      _diagramLine(' ▼  ▲ pipes', colors.textTertiary),
                      _diagramLine('[JET]', colors.accentWarning),
                      _diagramLine('WATER', colors.accentInfo),
                      const SizedBox(height: 6),
                      Text('25-100 ft', style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Deep jet pump uses ejector (jet) assembly in well to boost suction. One pipe pushes water down to jet, other brings water up.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPressureTank(ZaftoColors colors) {
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
            Icon(LucideIcons.database, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('PRESSURE TANK', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Stores water under pressure to reduce pump cycling:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _tankRow('Pre-charge pressure', '2 PSI below cut-in', colors),
          _tankRow('Typical cut-in', '30 or 40 PSI', colors),
          _tankRow('Typical cut-out', '50 or 60 PSI', colors),
          _tankRow('Common settings', '30/50 or 40/60 PSI', colors),
          const SizedBox(height: 12),
          Text('Tank Types:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _tankTypeRow('Bladder tank', 'Most common - bladder separates air/water', colors),
          _tankTypeRow('Diaphragm tank', 'Rubber diaphragm divider', colors),
          _tankTypeRow('Galvanized tank', 'Old style - air contacts water, needs recharging', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Tank sizing: Generally 1-2 gallons of drawdown per GPM of pump capacity. A 10 GPM pump needs 10-20 gallon drawdown capacity.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _tankRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tankTypeRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildPressureSwitch(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.toggleRight, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('PRESSURE SWITCH', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Controls pump based on system pressure:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _switchRow('Cut-in', 'Low pressure point - pump starts', colors),
          _switchRow('Cut-out', 'High pressure point - pump stops', colors),
          _switchRow('Differential', 'Usually 20 PSI (fixed or adjustable)', colors),
          const SizedBox(height: 12),
          Text('Common Settings:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _settingRow('20/40', 'Low pressure system', colors),
                _settingRow('30/50', 'Standard residential', colors),
                _settingRow('40/60', 'Higher pressure demand', colors),
                _settingRow('50/70', 'Special applications', colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Tank pre-charge must be 2 PSI below cut-in when empty, or bladder will fail', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchRow(String term, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(term, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _settingRow(String setting, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(setting, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(use, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildWellComponents(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WELL SYSTEM COMPONENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _compRow('Well cap', 'Sanitary seal at top of casing', colors),
          _compRow('Pitless adapter', 'Below frost line pipe connection', colors),
          _compRow('Well casing', 'Steel or PVC pipe lining well', colors),
          _compRow('Well screen', 'Allows water in, keeps sand out', colors),
          _compRow('Check valve', 'Prevents backflow into well', colors),
          _compRow('Torque arrester', 'Stabilizes pump in casing', colors),
          _compRow('Safety rope', 'Supports pump if pipe fails', colors),
          _compRow('Drop pipe', 'Connects pump to pitless adapter', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Critical Measurements:', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('• Total well depth\n• Static water level (resting)\n• Pumping level (during operation)\n• Recovery rate (GPM)\n• Pump depth setting', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compRow(String component, String function, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(component, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(function, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
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
            Icon(LucideIcons.wrench, color: colors.accentWarning, size: 18),
            const SizedBox(width: 8),
            Text('TROUBLESHOOTING', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _troubleRow('Pump runs constantly', 'Leak in system, low water, bad check valve', colors),
          _troubleRow('Pump short cycles', 'Waterlogged tank (check pre-charge)', colors),
          _troubleRow('No water', 'Power issue, pump failure, low water', colors),
          _troubleRow('Low pressure', 'Clogged filter, failing pump, tank issue', colors),
          _troubleRow('Surging pressure', 'Bad pressure switch, air in system', colors),
          _troubleRow('Air in water', 'Failing pump, low water level', colors),
          _troubleRow('Pump won\'t start', 'Power, switch, capacitor, motor', colors),
        ],
      ),
    );
  }

  Widget _troubleRow(String symptom, String causes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(symptom, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
          Text(causes, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
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
            Text('WELL & CODE REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• IPC Section 602 - Water Source\n'
            '• Well separation from septic: 100 ft minimum\n'
            '• Casing: 6" min diameter (4" for some)\n'
            '• Sanitary well cap required\n'
            '• Grout seal around casing\n'
            '• Pitless adapter below frost line\n'
            '• Annual water testing recommended\n'
            '• Electrical: NEC 430 for motors\n'
            '• Dedicated circuit for pump\n'
            '• State well construction permits',
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
