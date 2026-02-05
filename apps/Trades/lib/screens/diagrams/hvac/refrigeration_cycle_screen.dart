import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Refrigeration Cycle Diagram - Design System v2.6
class RefrigerationCycleScreen extends ConsumerWidget {
  const RefrigerationCycleScreen({super.key});

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
        title: Text('Refrigeration Cycle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicCycle(colors),
            const SizedBox(height: 16),
            _buildFourComponents(colors),
            const SizedBox(height: 16),
            _buildRefrigerantStates(colors),
            const SizedBox(height: 16),
            _buildPressureTemperature(colors),
            const SizedBox(height: 16),
            _buildSuperheatSubcool(colors),
            const SizedBox(height: 16),
            _buildRefrigerantTypes(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
            const SizedBox(height: 16),
            _buildSafetyEPA(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicCycle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BASIC REFRIGERATION CYCLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('           HIGH PRESSURE SIDE', colors.accentError),
                _diagramLine('    ┌────────────────────────────────┐', colors.textTertiary),
                _diagramLine('    │                                │', colors.textTertiary),
                _diagramLine('    │    ┌──────────────────┐       │', colors.accentError),
                _diagramLine('    │    │    CONDENSER     │       │ Hot gas', colors.accentError),
                _diagramLine('    │    │   (rejects heat) │       │ in', colors.textTertiary),
                _diagramLine('    │    └────────┬─────────┘       │', colors.accentError),
                _diagramLine('    │             │                  │', colors.textTertiary),
                _diagramLine('    │        High pressure           │', colors.textTertiary),
                _diagramLine('    │        liquid out              │', colors.textTertiary),
                _diagramLine('    │             │                  │', colors.textTertiary),
                _diagramLine('    │    ┌───────┴────────┐         │', colors.accentWarning),
                _diagramLine('    │    │ METERING DEVICE│         │', colors.accentWarning),
                _diagramLine('    │    │ (TXV/cap tube) │         │', colors.accentWarning),
                _diagramLine('    │    └───────┬────────┘         │', colors.accentWarning),
                _diagramLine('    │             │                  │', colors.textTertiary),
                _diagramLine('    │        Low pressure            │', colors.textTertiary),
                _diagramLine('    │        liquid/vapor            │', colors.textTertiary),
                _diagramLine('    │             │                  │', colors.textTertiary),
                _diagramLine('    │    ┌───────┴────────┐         │', colors.accentInfo),
                _diagramLine('    │    │   EVAPORATOR   │         │', colors.accentInfo),
                _diagramLine('    │    │ (absorbs heat) │         │', colors.accentInfo),
                _diagramLine('    │    └───────┬────────┘         │', colors.accentInfo),
                _diagramLine('    │             │                  │', colors.textTertiary),
                _diagramLine('    │        Low pressure            │', colors.textTertiary),
                _diagramLine('    │        vapor                   │', colors.textTertiary),
                _diagramLine('    │             │                  │', colors.textTertiary),
                _diagramLine('    │    ┌───────┴────────┐         │', colors.accentPrimary),
                _diagramLine('    │    │   COMPRESSOR   │←────────┘', colors.accentPrimary),
                _diagramLine('    │    │ (pumps refrig) │', colors.accentPrimary),
                _diagramLine('    │    └────────────────┘', colors.accentPrimary),
                _diagramLine('           LOW PRESSURE SIDE', colors.accentInfo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourComponents(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FOUR MAIN COMPONENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _componentCard('COMPRESSOR', 'Heart of the system - pumps refrigerant and creates pressure differential', 'Low pressure vapor in, high pressure vapor out', colors.accentPrimary, colors),
          const SizedBox(height: 10),
          _componentCard('CONDENSER', 'Outdoor coil - rejects heat absorbed from building', 'High pressure vapor in, high pressure liquid out', colors.accentError, colors),
          const SizedBox(height: 10),
          _componentCard('METERING DEVICE', 'Creates pressure drop - TXV, cap tube, or EEV', 'High pressure liquid in, low pressure mix out', colors.accentWarning, colors),
          const SizedBox(height: 10),
          _componentCard('EVAPORATOR', 'Indoor coil - absorbs heat from air', 'Low pressure liquid in, low pressure vapor out', colors.accentInfo, colors),
        ],
      ),
    );
  }

  Widget _componentCard(String title, String desc, String flow, Color color, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(flow, style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildRefrigerantStates(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REFRIGERANT STATE CHANGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _stateRow('1. Compressor outlet', 'Hot high pressure VAPOR (superheat)', colors.accentError, colors),
          _stateRow('2. Condenser', 'VAPOR → LIQUID (releases latent heat)', colors.accentError, colors),
          _stateRow('3. Condenser outlet', 'Warm high pressure LIQUID (subcool)', colors.accentWarning, colors),
          _stateRow('4. Metering device', 'Pressure drop creates cold mix', colors.accentWarning, colors),
          _stateRow('5. Evaporator inlet', 'Cold low pressure LIQUID/VAPOR mix', colors.accentInfo, colors),
          _stateRow('6. Evaporator', 'LIQUID → VAPOR (absorbs latent heat)', colors.accentInfo, colors),
          _stateRow('7. Evaporator outlet', 'Cool low pressure VAPOR (superheat)', colors.accentPrimary, colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Key concept: Heat is moved by changing refrigerant state. Evaporation absorbs heat (cooling). Condensation releases heat.', style: TextStyle(color: colors.accentSuccess, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _stateRow(String location, String state, Color color, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(state, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureTemperature(ZaftoColors colors) {
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
            Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('PRESSURE-TEMPERATURE RELATIONSHIP', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('In a saturated state (liquid/vapor mix), refrigerant temperature is directly related to pressure. P-T charts are essential tools.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Text('R-410A Example:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _ptRow('40°F (evap)', '118 PSIG', colors),
                _ptRow('45°F (evap)', '130 PSIG', colors),
                _ptRow('100°F (cond)', '317 PSIG', colors),
                _ptRow('110°F (cond)', '366 PSIG', colors),
                _ptRow('120°F (cond)', '418 PSIG', colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Higher pressure = Higher saturation temp\nLower pressure = Lower saturation temp', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _ptRow(String temp, String pressure, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(temp, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(pressure, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSuperheatSubcool(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUPERHEAT & SUBCOOLING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUPERHEAT (Evaporator)', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Temperature of vapor ABOVE saturation temp at that pressure', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Formula: Actual temp - Saturation temp = Superheat', style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Target: 10-15°F typical (varies by system)', style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUBCOOLING (Condenser)', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Temperature of liquid BELOW saturation temp at that pressure', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Formula: Saturation temp - Actual temp = Subcooling', style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Target: 10-15°F typical (varies by system)', style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('These measurements indicate proper refrigerant charge and system operation.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRefrigerantTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMON REFRIGERANTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _refrigRow('R-410A', 'HFC blend', 'Current residential AC standard', 'Pink', colors),
          _refrigRow('R-32', 'HFC', 'Lower GWP, gaining use', 'Pink', colors),
          _refrigRow('R-454B', 'HFO blend', 'R-410A replacement (A2L)', 'Lt Blue', colors),
          _refrigRow('R-22', 'HCFC', 'PHASED OUT - no new production', 'Green', colors),
          _refrigRow('R-134a', 'HFC', 'Auto AC, medium temp', 'Lt Blue', colors),
          _refrigRow('R-404A', 'HFC blend', 'Commercial refrigeration', 'Orange', colors),
          _refrigRow('R-290', 'Propane', 'Low GWP, flammable (A3)', 'None', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Never mix refrigerants! Each has unique properties. System must be designed for specific refrigerant.', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _refrigRow(String name, String type, String use, String color, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 55, child: Text(name, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 65, child: Text(type, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
          Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.wrench, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('DIAGNOSTIC INDICATORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _diagRow('Low superheat', 'Overcharge, high load, TXV issues', colors),
          _diagRow('High superheat', 'Undercharge, low load, restriction', colors),
          _diagRow('Low subcooling', 'Undercharge, condenser issue', colors),
          _diagRow('High subcooling', 'Overcharge, restriction after cond', colors),
          _diagRow('High head pressure', 'Dirty condenser, overcharge, air', colors),
          _diagRow('Low head pressure', 'Undercharge, compressor issue', colors),
          _diagRow('High suction', 'Overcharge, compressor valve leak', colors),
          _diagRow('Low suction', 'Undercharge, restriction, low load', colors),
        ],
      ),
    );
  }

  Widget _diagRow(String condition, String causes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(condition, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(causes, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSafetyEPA(ZaftoColors colors) {
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
            Icon(LucideIcons.shieldAlert, color: colors.accentError, size: 18),
            const SizedBox(width: 8),
            Text('EPA SECTION 608 REQUIREMENTS', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• EPA certification required to purchase refrigerant\n'
            '• Intentional venting is illegal\n'
            '• Must recover refrigerant before opening system\n'
            '• Leak repair required above threshold\n'
            '• Record keeping for refrigerant transactions\n'
            '• Proper disposal of refrigerant cylinders\n'
            '• Certification types: Type I, II, III, Universal',
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
