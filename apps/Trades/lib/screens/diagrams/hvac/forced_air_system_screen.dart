import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Forced Air System Diagram - Design System v2.6
class ForcedAirSystemScreen extends ConsumerWidget {
  const ForcedAirSystemScreen({super.key});

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
        title: Text('Forced Air Systems', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemOverview(colors),
            const SizedBox(height: 16),
            _buildHeatingCycle(colors),
            const SizedBox(height: 16),
            _buildCoolingCycle(colors),
            const SizedBox(height: 16),
            _buildFurnaceComponents(colors),
            const SizedBox(height: 16),
            _buildAirflowPath(colors),
            const SizedBox(height: 16),
            _buildDuctSystem(colors),
            const SizedBox(height: 16),
            _buildEfficiencyRatings(colors),
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
          Text('FORCED AIR HVAC SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('           ┌─────────────────────────────┐', colors.textTertiary),
                _diagramLine('           │      CONDITIONED SPACE      │', colors.textTertiary),
                _diagramLine('           │                             │', colors.textTertiary),
                _diagramLine('  SUPPLY ══╡  ↓ ↓ ↓     ↑ ↑ ↑          ╞══ RETURN', colors.accentError),
                _diagramLine('    AIR    │  warm      cool            │    AIR', colors.accentInfo),
                _diagramLine('           │  air       air             │', colors.textTertiary),
                _diagramLine('           └─────────────────────────────┘', colors.textTertiary),
                _diagramLine('                    │', colors.textTertiary),
                _diagramLine('              ┌─────┴─────┐', colors.accentWarning),
                _diagramLine('              │  FURNACE  │ ← Blower, heat exchanger', colors.accentWarning),
                _diagramLine('              │   + A/C   │   evaporator coil', colors.accentWarning),
                _diagramLine('              └─────┬─────┘', colors.accentWarning),
                _diagramLine('                    │', colors.textTertiary),
                _diagramLine('              ┌─────┴─────┐', colors.accentPrimary),
                _diagramLine('              │ CONDENSER │ ← Outdoor unit', colors.accentPrimary),
                _diagramLine('              └───────────┘', colors.accentPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('A forced air system uses a blower to distribute heated or cooled air through ductwork to conditioned spaces.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHeatingCycle(ZaftoColors colors) {
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
            Icon(LucideIcons.flame, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('HEATING CYCLE (GAS FURNACE)', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _cycleStep('1', 'Thermostat calls for heat', colors),
          _cycleStep('2', 'Inducer motor starts (80%+ efficient)', colors),
          _cycleStep('3', 'Pressure switch verifies draft', colors),
          _cycleStep('4', 'Igniter heats up (HSI) or pilot lights', colors),
          _cycleStep('5', 'Gas valve opens, burners ignite', colors),
          _cycleStep('6', 'Flame sensor proves flame present', colors),
          _cycleStep('7', 'Heat exchanger warms up', colors),
          _cycleStep('8', 'Blower motor starts (after delay)', colors),
          _cycleStep('9', 'Warm air distributed through ducts', colors),
          _cycleStep('10', 'Thermostat satisfied, burners off', colors),
          _cycleStep('11', 'Blower runs to extract remaining heat', colors),
        ],
      ),
    );
  }

  Widget _cycleStep(String num, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(10)),
            child: Text(num, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCoolingCycle(ZaftoColors colors) {
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
            Icon(LucideIcons.snowflake, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('COOLING CYCLE (AIR CONDITIONING)', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _cycleStep('1', 'Thermostat calls for cooling', colors),
          _cycleStep('2', 'Blower motor starts', colors),
          _cycleStep('3', 'Condenser (outdoor) fan starts', colors),
          _cycleStep('4', 'Compressor engages', colors),
          _cycleStep('5', 'Refrigerant cycles through system', colors),
          _cycleStep('6', 'Evaporator coil absorbs heat from air', colors),
          _cycleStep('7', 'Cool air distributed through ducts', colors),
          _cycleStep('8', 'Condensate drains from evaporator', colors),
          _cycleStep('9', 'Thermostat satisfied, compressor off', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Note: The furnace blower circulates air over the evaporator coil mounted in the supply plenum - same ductwork for heating and cooling.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildFurnaceComponents(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GAS FURNACE COMPONENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _compRow('Heat exchanger', 'Transfers heat from combustion to air', colors),
          _compRow('Burners', 'Combust gas to produce heat', colors),
          _compRow('Blower motor', 'Circulates air through system', colors),
          _compRow('Inducer motor', 'Creates draft for combustion (80%+)', colors),
          _compRow('Gas valve', 'Controls gas flow to burners', colors),
          _compRow('Igniter (HSI)', 'Hot surface igniter lights gas', colors),
          _compRow('Flame sensor', 'Proves burner flame is present', colors),
          _compRow('Pressure switch', 'Verifies proper draft/venting', colors),
          _compRow('Limit switch', 'High temp safety shutoff', colors),
          _compRow('Control board', 'Sequences all operations', colors),
          _compRow('Filter', 'Removes particles from return air', colors),
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
          SizedBox(width: 100, child: Text(component, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(function, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildAirflowPath(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('AIRFLOW PATH', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('  RETURN GRILLE → RETURN DUCT → FILTER', colors.accentInfo),
                _diagramLine('                                  │', colors.textTertiary),
                _diagramLine('                                  ▼', colors.textTertiary),
                _diagramLine('                              BLOWER', colors.accentWarning),
                _diagramLine('                                  │', colors.textTertiary),
                _diagramLine('           ┌──────────────────────┤', colors.textTertiary),
                _diagramLine('           │                      │', colors.textTertiary),
                _diagramLine('    HEAT EXCHANGER          EVAP COIL', colors.accentError),
                _diagramLine('      (heating)             (cooling)', colors.textTertiary),
                _diagramLine('           │                      │', colors.textTertiary),
                _diagramLine('           └──────────┬───────────┘', colors.textTertiary),
                _diagramLine('                      ▼', colors.textTertiary),
                _diagramLine('              SUPPLY PLENUM', colors.accentWarning),
                _diagramLine('                      │', colors.textTertiary),
                _diagramLine('              SUPPLY DUCTS', colors.accentError),
                _diagramLine('                      │', colors.textTertiary),
                _diagramLine('              SUPPLY REGISTERS', colors.accentPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuctSystem(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DUCT SYSTEM BASICS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _ductRow('Supply trunk', 'Main duct from furnace', colors),
          _ductRow('Supply branches', 'Individual runs to rooms', colors),
          _ductRow('Supply registers', 'Outlets in rooms', colors),
          _ductRow('Return trunk', 'Collects air back to furnace', colors),
          _ductRow('Return grilles', 'Intakes in rooms/hallways', colors),
          _ductRow('Plenum', 'Box connecting furnace to ducts', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Critical: Return Air', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('System needs adequate return air. Undersized returns cause high static pressure, reduced efficiency, and equipment damage.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ductRow(String component, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(component, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildEfficiencyRatings(ZaftoColors colors) {
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
            Icon(LucideIcons.gauge, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('EFFICIENCY RATINGS', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Heating (Furnace):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _effRow('AFUE', 'Annual Fuel Utilization Efficiency', colors),
          _effRow('80% AFUE', 'Standard efficiency, atmospheric vent', colors),
          _effRow('90%+ AFUE', 'High efficiency, condensing', colors),
          _effRow('95-98% AFUE', 'Premium condensing units', colors),
          const SizedBox(height: 12),
          Text('Cooling (A/C):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _effRow('SEER/SEER2', 'Seasonal Energy Efficiency Ratio', colors),
          _effRow('14-15 SEER', 'Minimum efficiency (2023+)', colors),
          _effRow('16-20 SEER', 'High efficiency', colors),
          _effRow('20+ SEER', 'Premium efficiency', colors),
        ],
      ),
    );
  }

  Widget _effRow(String rating, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(rating, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
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
            '• IMC (International Mechanical Code)\n'
            '• IFGC (International Fuel Gas Code)\n'
            '• Equipment sizing per Manual J\n'
            '• Duct sizing per Manual D\n'
            '• Combustion air per IFGC 304\n'
            '• Venting per IFGC Chapter 5\n'
            '• Clearances to combustibles\n'
            '• Electrical per NEC\n'
            '• Condensate disposal required\n'
            '• Emergency shutoff at unit',
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
