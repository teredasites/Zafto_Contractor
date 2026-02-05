import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Thermostat Wiring Diagram - Design System v2.6
class ThermostatWiringScreen extends ConsumerWidget {
  const ThermostatWiringScreen({super.key});

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
        title: Text('Thermostat Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWireColors(colors),
            const SizedBox(height: 16),
            _buildBasicHeatCool(colors),
            const SizedBox(height: 16),
            _buildHeatPump(colors),
            const SizedBox(height: 16),
            _buildCommonWire(colors),
            const SizedBox(height: 16),
            _buildSmartThermostat(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWireColors(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('STANDARD WIRE COLORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _wireRow('R', 'Red', '24V Power (from transformer)', Colors.red, colors),
          _wireRow('Rc', 'Red', '24V Power - Cooling', Colors.red, colors),
          _wireRow('Rh', 'Red', '24V Power - Heating', Colors.red, colors),
          _wireRow('C', 'Blue', 'Common (24V return)', Colors.blue, colors),
          _wireRow('G', 'Green', 'Fan', Colors.green, colors),
          _wireRow('Y', 'Yellow', 'Cooling (compressor)', Colors.yellow, colors),
          _wireRow('Y2', 'Yellow', 'Stage 2 Cooling', Colors.yellow, colors),
          _wireRow('W', 'White', 'Heating', Colors.white, colors),
          _wireRow('W2', 'White', 'Stage 2 Heating / Aux', Colors.white, colors),
          _wireRow('O', 'Orange', 'Heat Pump - Cooling', Colors.orange, colors),
          _wireRow('B', 'Brown', 'Heat Pump - Heating', Colors.brown, colors),
          _wireRow('E', 'Brown', 'Emergency Heat', Colors.brown, colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Colors can vary - always verify at equipment!', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _wireRow(String terminal, String color, String function, Color dotColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(
          width: 28, height: 20,
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Center(child: Text(terminal, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
        ),
        const SizedBox(width: 8),
        Container(width: 14, height: 14, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: dotColor == Colors.white ? Border.all(color: colors.borderSubtle) : null)),
        const SizedBox(width: 8),
        SizedBox(width: 55, child: Text(color, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        Expanded(child: Text(function, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
      ]),
    );
  }

  Widget _buildBasicHeatCool(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BASIC FURNACE + A/C (5-WIRE)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('THERMOSTAT              FURNACE/AIR HANDLER', colors.textTertiary),
                _diagramLine('┌─────────┐            ┌─────────────────┐', colors.textTertiary),
                _diagramLine('│ R  ─────┼── Red ────►│ R  (24V Hot)    │', colors.accentError),
                _diagramLine('│ C  ─────┼── Blue ───►│ C  (24V Common) │', colors.accentInfo),
                _diagramLine('│ G  ─────┼── Green ──►│ G  (Fan)        │', colors.accentSuccess),
                _diagramLine('│ Y  ─────┼── Yellow ─►│ Y  (Cooling)    │──► A/C', colors.accentWarning),
                _diagramLine('│ W  ─────┼── White ──►│ W  (Heat)       │', colors.textSecondary),
                _diagramLine('└─────────┘            └─────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Most common residential setup - gas/oil furnace with central A/C', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _buildHeatPump(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HEAT PUMP SYSTEM (8-WIRE)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('THERMOSTAT              AIR HANDLER / HEAT PUMP', colors.textTertiary),
                _diagramLine('┌─────────┐            ┌─────────────────────┐', colors.textTertiary),
                _diagramLine('│ R  ─────┼── Red ────►│ R   (24V Power)     │', colors.accentError),
                _diagramLine('│ C  ─────┼── Blue ───►│ C   (Common)        │', colors.accentInfo),
                _diagramLine('│ G  ─────┼── Green ──►│ G   (Fan)           │', colors.accentSuccess),
                _diagramLine('│ Y  ─────┼── Yellow ─►│ Y   (Compressor)    │', colors.accentWarning),
                _diagramLine('│ O  ─────┼── Orange ─►│ O   (Reversing-Cool)│', colors.accentWarning),
                _diagramLine('│ W2 ─────┼── White ──►│ W2  (Aux/Emerg Heat)│', colors.textSecondary),
                _diagramLine('│ E  ─────┼── Brown ──►│ E   (Emergency Heat)│', colors.accentWarning),
                _diagramLine('└─────────┘            └─────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text('O vs B: O energizes reversing valve in COOLING (most common). B energizes in HEATING (Rheem, Ruud). Check equipment!', style: TextStyle(color: colors.accentInfo, fontSize: 11))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonWire(ZaftoColors colors) {
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
            Icon(LucideIcons.plug, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('NO C-WIRE? OPTIONS:', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _optionItem('1', 'Run new wire', 'Best solution - run 18/5 or 18/8 thermostat wire', colors),
          _optionItem('2', 'Add-A-Wire kit', 'Converts existing wire to add C (Venstar ACC0410)', colors),
          _optionItem('3', 'Use G wire', 'Some stats can use G as C (loses independent fan control)', colors),
          _optionItem('4', 'C-wire adapter', 'Installs at furnace, creates C from existing wires', colors),
          _optionItem('5', 'Power stealing', 'Some WiFi stats work without C (not recommended)', colors),
        ],
      ),
    );
  }

  Widget _optionItem(String num, String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(color: colors.accentWarning, borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(num, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 10))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildSmartThermostat(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.wifi, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('SMART THERMOSTAT REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _smartRow('Nest', 'Works without C (power stealing) but C recommended', colors),
          _smartRow('Ecobee', 'Includes Power Extender Kit if no C-wire', colors),
          _smartRow('Honeywell', 'Most models require C-wire', colors),
          _smartRow('Sensi', 'Works without C for heat-only, needs C for A/C', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Always verify compatibility before purchase!', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _smartRow(String brand, String requirement, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(brand, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(requirement, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
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
            Text('TROUBLESHOOTING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _troubleRow('No power to stat', 'Check transformer (24V), fuse on control board', colors),
          _troubleRow("Heat won't turn on", 'Check W wire connection, limit switches', colors),
          _troubleRow("A/C won't turn on", 'Check Y wire, contactor, capacitor', colors),
          _troubleRow('Fan runs constantly', 'Check G wire, fan limit switch', colors),
          _troubleRow('Heat pump stuck cool', 'Check O/B wire, reversing valve', colors),
          _troubleRow('Short cycling', 'Check for shorted wires, dirty filter', colors),
        ],
      ),
    );
  }

  Widget _troubleRow(String problem, String solution, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertCircle, color: colors.accentError, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(problem, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w500, fontSize: 12))),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 2),
            child: Text(solution, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
