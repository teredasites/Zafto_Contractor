import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Heat Pump Systems Diagram - Design System v2.6
class HeatPumpScreen extends ConsumerWidget {
  const HeatPumpScreen({super.key});

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
        title: Text('Heat Pump Systems', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildCoolingMode(colors),
            const SizedBox(height: 16),
            _buildHeatingMode(colors),
            const SizedBox(height: 16),
            _buildReversingValve(colors),
            const SizedBox(height: 16),
            _buildDefrostCycle(colors),
            const SizedBox(height: 16),
            _buildAuxiliaryHeat(colors),
            const SizedBox(height: 16),
            _buildHeatPumpTypes(colors),
            const SizedBox(height: 16),
            _buildEfficiencyRatings(colors),
            const SizedBox(height: 16),
            _buildBalancePoint(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(ZaftoColors colors) {
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
            Icon(LucideIcons.repeat, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('WHAT IS A HEAT PUMP?', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('A heat pump is an air conditioner that can reverse its refrigeration cycle to provide heating. It moves heat rather than generating it.', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          _benefitRow('Efficiency', '200-400% efficient (moves more heat than energy used)', colors),
          _benefitRow('Dual function', 'Both heating and cooling from one system', colors),
          _benefitRow('Electric', 'No combustion, no gas line needed', colors),
          _benefitRow('Lower cost', 'Cheaper to operate than resistance heat', colors),
        ],
      ),
    );
  }

  Widget _benefitRow(String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoolingMode(ZaftoColors colors) {
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
            Text('COOLING MODE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('         OUTDOOR UNIT              INDOOR UNIT', colors.textTertiary),
                _diagramLine('    ┌──────────────────┐      ┌──────────────────┐', colors.textTertiary),
                _diagramLine('    │    CONDENSER     │      │    EVAPORATOR    │', colors.textTertiary),
                _diagramLine('    │   (rejects heat) │      │  (absorbs heat)  │', colors.textTertiary),
                _diagramLine('    │        │         │      │        │         │', colors.textTertiary),
                _diagramLine('    │   HOT  ▼   FAN   │      │   COLD ▼   FAN   │', colors.textTertiary),
                _diagramLine('    │   AIR  ▼  →→→→   │      │   AIR  ▼   →→→   │', colors.accentInfo),
                _diagramLine('    │        ▼ OUT     │      │        ▼ TO HOME │', colors.textTertiary),
                _diagramLine('    └────────┼─────────┘      └────────┼─────────┘', colors.textTertiary),
                _diagramLine('             │                         │', colors.textTertiary),
                _diagramLine('    HOT GAS ─┴─────────────────────────┴─ COLD GAS', colors.accentError),
                _diagramLine('              LIQUID LINE →→→→→→→→→→→→→', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Same as standard A/C: Indoor coil absorbs heat, outdoor coil rejects heat to outside.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHeatingMode(ZaftoColors colors) {
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
            Text('HEATING MODE', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('         OUTDOOR UNIT              INDOOR UNIT', colors.textTertiary),
                _diagramLine('    ┌──────────────────┐      ┌──────────────────┐', colors.textTertiary),
                _diagramLine('    │    EVAPORATOR    │      │    CONDENSER     │', colors.textTertiary),
                _diagramLine('    │  (absorbs heat)  │      │  (rejects heat)  │', colors.textTertiary),
                _diagramLine('    │        │         │      │        │         │', colors.textTertiary),
                _diagramLine('    │  COLD  ▼   FAN   │      │   HOT  ▼   FAN   │', colors.textTertiary),
                _diagramLine('    │  AIR   ▼  ←←←←   │      │   AIR  ▼   →→→   │', colors.accentError),
                _diagramLine('    │        ▼ IN      │      │        ▼ TO HOME │', colors.textTertiary),
                _diagramLine('    └────────┼─────────┘      └────────┼─────────┘', colors.textTertiary),
                _diagramLine('             │                         │', colors.textTertiary),
                _diagramLine('    COLD GAS ┴─────────────────────────┴─ HOT GAS', colors.accentInfo),
                _diagramLine('              ←←←←←←←←←←←←← LIQUID LINE', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('REVERSED: Outdoor coil absorbs heat from outside air (even cold air has heat), indoor coil releases heat to home.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReversingValve(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.gitCompare, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('REVERSING VALVE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('The reversing valve (4-way valve) changes the direction of refrigerant flow to switch between heating and cooling modes.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('        REVERSING VALVE', colors.accentWarning),
                _diagramLine('    ┌───────────────────┐', colors.accentWarning),
                _diagramLine('    │  OUTDOOR  INDOOR  │', colors.textTertiary),
                _diagramLine('    │    COIL    COIL   │', colors.textTertiary),
                _diagramLine('    │     │       │     │', colors.textTertiary),
                _diagramLine('    │    [1]     [3]    │', colors.accentPrimary),
                _diagramLine('    │     \\     /       │', colors.textTertiary),
                _diagramLine('    │      \\   /        │', colors.textTertiary),
                _diagramLine('    │       [S]         │ ← Solenoid slides', colors.accentError),
                _diagramLine('    │      /   \\        │   internal shuttle', colors.textTertiary),
                _diagramLine('    │     /     \\       │', colors.textTertiary),
                _diagramLine('    │    [4]     [2]    │', colors.accentPrimary),
                _diagramLine('    │     │       │     │', colors.textTertiary),
                _diagramLine('    │  COMP    COMP     │', colors.textTertiary),
                _diagramLine('    │  DISCH   SUCT     │', colors.textTertiary),
                _diagramLine('    └───────────────────┘', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _valveRow('Energized (B-O)', 'Cooling mode (most manufacturers)', colors),
          _valveRow('De-energized (B-O)', 'Heating mode', colors),
          _valveRow('Rheem/Ruud (O-B)', 'Opposite - energized for heat', colors),
        ],
      ),
    );
  }

  Widget _valveRow(String state, String mode, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(state, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(mode, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildDefrostCycle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.thermometer, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('DEFROST CYCLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('In heating mode, the outdoor coil can frost over. The system must periodically defrost:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _defrostStep('1', 'Sensors detect frost buildup (time + temp)', colors),
          _defrostStep('2', 'Reversing valve shifts to cooling mode', colors),
          _defrostStep('3', 'Hot gas flows to outdoor coil, melting ice', colors),
          _defrostStep('4', 'Outdoor fan OFF to speed defrost', colors),
          _defrostStep('5', 'Auxiliary heat ON to prevent cold air to home', colors),
          _defrostStep('6', 'Defrost complete, returns to heating mode', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Defrost typically runs 30-90 seconds every 30-90 minutes in cold weather. Steam from outdoor unit during defrost is normal.', style: TextStyle(color: colors.accentWarning, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _defrostStep(String num, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.accentInfo, borderRadius: BorderRadius.circular(10)),
            child: Text(num, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildAuxiliaryHeat(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.zap, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('AUXILIARY & EMERGENCY HEAT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _heatRow('Auxiliary heat (Aux)', 'Electric strips that supplement heat pump when it can\'t keep up', colors),
          _heatRow('Emergency heat (Em)', 'Locks out heat pump, uses only electric strips', colors),
          _heatRow('Strip heat', 'Electric resistance elements (100% efficient)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('When Aux Heat Activates:', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('• Temperature differential too large\n• Outdoor temp below balance point\n• During defrost cycle\n• Heat pump can\'t keep up with setpoint', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Emergency heat should only be used if heat pump fails - it is expensive to operate.', style: TextStyle(color: colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _heatRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildHeatPumpTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HEAT PUMP TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _typeRow('Air-source', 'Exchanges heat with outdoor air', 'Most common, lower cost', colors),
          _typeRow('Ground-source', 'Exchanges heat with ground (geothermal)', 'More efficient, high install cost', colors),
          _typeRow('Water-source', 'Exchanges heat with water loop', 'Commercial buildings', colors),
          _typeRow('Ductless mini-split', 'No ductwork, wall-mounted heads', 'Zoned, additions', colors),
          _typeRow('Dual fuel', 'Heat pump + gas furnace backup', 'Cold climates', colors),
        ],
      ),
    );
  }

  Widget _typeRow(String type, String desc, String notes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 95, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                Text(notes, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
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
            Icon(LucideIcons.trendingUp, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('EFFICIENCY RATINGS', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Cooling:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _effRow('SEER/SEER2', 'Seasonal cooling efficiency (higher=better)', colors),
          _effRow('Minimum', '14-15 SEER2 (depends on region)', colors),
          const SizedBox(height: 8),
          Text('Heating:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _effRow('HSPF/HSPF2', 'Heating Seasonal Performance Factor', colors),
          _effRow('Minimum', '7.5 HSPF2', colors),
          _effRow('COP', 'Coefficient of Performance (output/input)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('A COP of 3.0 means 3 units of heat delivered for every 1 unit of electricity used - 300% efficient! (vs. 100% for electric resistance)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _effRow(String rating, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(rating, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildBalancePoint(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.scale, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('BALANCE POINT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('The outdoor temperature at which heat pump output equals building heat loss. Below this, supplemental heat is needed.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _balanceRow('Standard HP', '30-40°F balance point', colors),
          _balanceRow('Cold climate HP', '0-15°F balance point', colors),
          _balanceRow('Below balance', 'Aux heat supplements', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Modern cold-climate heat pumps (ccHP) can operate efficiently down to -15°F or lower, reducing reliance on expensive backup heat.', style: TextStyle(color: colors.accentInfo, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _balanceRow(String type, String temp, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Text(temp, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
