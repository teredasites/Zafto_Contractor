import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

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
            _buildTerminalColors(colors),
            const SizedBox(height: 16),
            _buildBasicHeatCool(colors),
            const SizedBox(height: 16),
            _buildHeatPumpWiring(colors),
            const SizedBox(height: 16),
            _buildMultiStage(colors),
            const SizedBox(height: 16),
            _buildCommonWire(colors),
            const SizedBox(height: 16),
            _buildWireGauge(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
            const SizedBox(height: 16),
            _buildSafetyNotes(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalColors(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THERMOSTAT TERMINAL DESIGNATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _terminalRow('R/Rh', 'Red', '24V Power (Heat)', colors.accentError, colors),
          _terminalRow('Rc', 'Red', '24V Power (Cool)', colors.accentError, colors),
          _terminalRow('C', 'Blue', '24V Common (ground)', colors.accentInfo, colors),
          _terminalRow('G', 'Green', 'Fan relay', colors.accentSuccess, colors),
          _terminalRow('Y/Y1', 'Yellow', 'Cooling stage 1', colors.accentWarning, colors),
          _terminalRow('Y2', 'Lt Blue', 'Cooling stage 2', colors.accentInfo, colors),
          _terminalRow('W/W1', 'White', 'Heating stage 1', colors.textPrimary, colors),
          _terminalRow('W2/Aux', 'Brown', 'Heating stage 2/Aux', colors.accentWarning, colors),
          _terminalRow('E', 'Brown', 'Emergency heat', colors.accentWarning, colors),
          _terminalRow('O', 'Orange', 'Reversing valve (cool)', colors.accentError, colors),
          _terminalRow('B', 'Dk Blue', 'Reversing valve (heat)', colors.accentInfo, colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Wire colors are NOT standardized! Always trace wires - colors may vary from installer to installer.', style: TextStyle(color: colors.accentWarning, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _terminalRow(String terminal, String typical, String function, Color termColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 45,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: termColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(terminal, style: TextStyle(color: termColor, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 55, child: Text(typical, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
          Expanded(child: Text(function, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildBasicHeatCool(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BASIC FURNACE + A/C (4-5 WIRE)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('THERMOSTAT              FURNACE/AIR HANDLER', colors.textTertiary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('   [R] ─────────────── [R]  24V Hot', colors.accentError),
                _diagramLine('   [G] ─────────────── [G]  Fan', colors.accentSuccess),
                _diagramLine('   [Y] ─────────────── [Y]  Cool', colors.accentWarning),
                _diagramLine('   [W] ─────────────── [W]  Heat', colors.textPrimary),
                _diagramLine('   [C] ─────────────── [C]  Common (optional)', colors.accentInfo),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Minimum 4 wires: R, G, Y, W\n5th wire (C) needed for WiFi/smart thermostats', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHeatPumpWiring(ZaftoColors colors) {
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
          Text('HEAT PUMP WIRING (7-8 WIRE)', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('THERMOSTAT              AIR HANDLER    OUTDOOR', colors.textTertiary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('   [R] ─────────────── [R] ─────────── 24V', colors.accentError),
                _diagramLine('   [G] ─────────────── [G]             Fan', colors.accentSuccess),
                _diagramLine('   [Y] ─────────────── [Y] ─────────── Compressor', colors.accentWarning),
                _diagramLine('   [O] ─────────────── [O] ─────────── Reversing', colors.accentError),
                _diagramLine('   [C] ─────────────── [C] ─────────── Common', colors.accentInfo),
                _diagramLine('   [W/Aux] ──────────── [W2]           Aux heat', colors.textPrimary),
                _diagramLine('   [E] ─────────────── [E]             Emergency', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('O vs B Terminal:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _obRow('O (Orange)', 'Energize reversing valve in COOL mode', colors),
          _obRow('B (Blue)', 'Energize reversing valve in HEAT mode', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Most manufacturers use O (cool). Rheem/Ruud use B (heat). Check equipment manual!', style: TextStyle(color: colors.accentWarning, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _obRow(String term, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 75, child: Text(term, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildMultiStage(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MULTI-STAGE SYSTEMS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('2-Stage Cooling:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _stageRow('Y1', 'Stage 1 cooling (low)', colors),
          _stageRow('Y2', 'Stage 2 cooling (high)', colors),
          const SizedBox(height: 8),
          Text('2-Stage Heating:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _stageRow('W1', 'Stage 1 heating (low)', colors),
          _stageRow('W2', 'Stage 2 heating (high) or Aux', colors),
          const SizedBox(height: 8),
          Text('Variable Speed / Communicating:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Modern systems may use 2-4 wire communication bus instead of individual control wires. Check manufacturer specs.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _stageRow(String term, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(term, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCommonWire(ZaftoColors colors) {
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
            Icon(LucideIcons.zap, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('THE "C" WIRE (COMMON)', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Modern thermostats need continuous 24V power. The C wire completes the circuit.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Text('If No C Wire:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _cWireOption('Add C Wire Adapter', 'Device connects at furnace, creates C', colors),
          _cWireOption('Use unused wire', 'If extra wire exists, connect to C', colors),
          _cWireOption('Run new wire', 'Best option - proper 18/8 thermostat cable', colors),
          _cWireOption('Battery backup', 'Some thermostats work without C (not ideal)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Without C wire, thermostats may "steal" power through other wires, potentially causing relay chattering or equipment issues.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _cWireOption(String option, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWireGauge(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THERMOSTAT WIRE SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _wireRow('Gauge', '18 AWG (standard)', colors),
          _wireRow('Voltage', '24V AC', colors),
          _wireRow('Conductors', '18/5 minimum (more is better)', colors),
          _wireRow('Type', 'CL2 or CL3 rated', colors),
          const SizedBox(height: 12),
          Text('Recommended Wire Count:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _conductorRow('Basic furnace/AC', '18/5', colors),
          _conductorRow('Heat pump', '18/7 or 18/8', colors),
          _conductorRow('2-stage + HP', '18/8', colors),
          _conductorRow('Future-proof', '18/8 always', colors),
          const SizedBox(height: 12),
          Text('Always run more conductors than currently needed for future upgrades.', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _wireRow(String label, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(spec, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _conductorRow(String system, String wire, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(system, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Text(wire, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
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
          _troubleRow('No power to stat', 'Check transformer, fuse, R wire', colors),
          _troubleRow('No heat', 'Check W wire, limit switch, gas valve', colors),
          _troubleRow('No cool', 'Check Y wire, contactor, compressor', colors),
          _troubleRow('Fan won\'t run', 'Check G wire, fan relay, motor', colors),
          _troubleRow('HP stuck in cool', 'Check O/B wire, reversing valve', colors),
          _troubleRow('Aux always on', 'Check W2/E wire, outdoor stat', colors),
          _troubleRow('Short cycling', 'Check for wire short, thermostat location', colors),
          const SizedBox(height: 12),
          Text('Always measure 24V between R and C at thermostat first. If no voltage, problem is at equipment.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _troubleRow(String problem, String check, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(problem, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(check, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSafetyNotes(ZaftoColors colors) {
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
            Text('SAFETY NOTES', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Turn off power before working on wiring\n'
            '• 24V is low voltage but can damage equipment\n'
            '• Shorting R to C blows transformer fuse\n'
            '• Label existing wires before disconnecting\n'
            '• Photo existing connections first\n'
            '• Never connect line voltage to thermostat\n'
            '• Verify system operation after any change',
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
