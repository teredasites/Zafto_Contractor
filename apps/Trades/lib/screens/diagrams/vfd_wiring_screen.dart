import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// VFD / Variable Frequency Drive Wiring Diagram - Design System v2.6
class VfdWiringScreen extends ConsumerWidget {
  const VfdWiringScreen({super.key});

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
        title: Text('VFD / Variable Frequency Drive', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildBasicWiring(colors),
            const SizedBox(height: 16),
            _buildInputOutput(colors),
            const SizedBox(height: 16),
            _buildControlWiring(colors),
            const SizedBox(height: 16),
            _buildCableRequirements(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
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
            Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('What is a VFD?', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Variable Frequency Drive (also called VSD, AFD, or inverter) controls motor speed by varying the frequency and voltage supplied to the motor.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          _benefitItem('Energy savings (30-50% on pumps/fans)', colors),
          _benefitItem('Soft start (reduces inrush current)', colors),
          _benefitItem('Precise speed control', colors),
          _benefitItem('Reduced mechanical wear', colors),
          _benefitItem('Built-in motor protection', colors),
        ],
      ),
    );
  }

  Widget _benefitItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildBasicWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BASIC VFD WIRING DIAGRAM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('POWER IN                VFD                  MOTOR', colors.textTertiary),
                _diagramLine('                   ┌───────────┐', colors.textTertiary),
                _diagramLine('L1 ──── R ────────►│ R/L1      │', colors.accentError),
                _diagramLine('L2 ──── S ────────►│ S/L2  VFD │', colors.accentError),
                _diagramLine('L3 ──── T ────────►│ T/L3      │', colors.accentError),
                _diagramLine('                   │           │', colors.textTertiary),
                _diagramLine('                   │     U/T1 ─┼────────► U  ┐', colors.accentInfo),
                _diagramLine('                   │     V/T2 ─┼────────► V  ├─ MOTOR', colors.accentInfo),
                _diagramLine('                   │     W/T3 ─┼────────► W  ┘', colors.accentInfo),
                _diagramLine('                   │           │', colors.textTertiary),
                _diagramLine('PE ────────────────┤ PE    PE ─┼────────► PE (Ground)', colors.accentSuccess),
                _diagramLine('                   └───────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _wireLabel('R/S/T or L1/L2/L3', 'AC Input (from disconnect)', Colors.red, colors),
          _wireLabel('U/V/W or T1/T2/T3', 'AC Output (to motor)', Colors.blue, colors),
          _wireLabel('PE', 'Protective Earth (ground)', Colors.green, colors),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _wireLabel(String terminal, String purpose, Color color, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        SizedBox(width: 110, child: Text(terminal, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
        Expanded(child: Text(purpose, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
      ]),
    );
  }

  Widget _buildInputOutput(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INPUT vs OUTPUT POWER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _ioRow('INPUT', '3-phase 480V 60Hz (fixed)', 'From utility', colors),
          _ioRow('', '3-phase 208V 60Hz (fixed)', '', colors),
          _ioRow('', '1-phase 240V 60Hz (small VFDs)', '', colors),
          Divider(color: colors.borderSubtle, height: 20),
          _ioRow('OUTPUT', '3-phase 0-480V 0-60Hz', 'Variable!', colors),
          _ioRow('', 'Frequency controls speed', 'Hz = RPM', colors),
          _ioRow('', 'Voltage controls torque', 'V/Hz ratio', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Motor Speed Formula:', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('RPM = (120 x Frequency) / Poles', style: TextStyle(color: colors.textPrimary, fontFamily: 'monospace', fontSize: 11)),
                Text('At 60Hz, 4-pole motor = 1800 RPM', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                Text('At 30Hz, 4-pole motor = 900 RPM', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ioRow(String type, String value, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 60, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 11))),
        Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        SizedBox(width: 70, child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
      ]),
    );
  }

  Widget _buildControlWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONTROL TERMINAL WIRING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('CONTROL TERMINALS (typical)', colors.textTertiary),
                _diagramLine('┌─────────────────────────────┐', colors.textTertiary),
                _diagramLine('│ +24V ── Common power output │', colors.accentWarning),
                _diagramLine('│ COM ─── Common/Ground       │', colors.textSecondary),
                _diagramLine('│ FWD ─── Forward run         │ ← Digital inputs', colors.accentSuccess),
                _diagramLine('│ REV ─── Reverse run         │', colors.accentSuccess),
                _diagramLine('│ RST ─── Fault reset         │', colors.accentSuccess),
                _diagramLine('│                             │', colors.textTertiary),
                _diagramLine('│ AIN ─── Analog in (0-10V)   │ ← Speed reference', colors.accentInfo),
                _diagramLine('│ AIN ─── Analog in (4-20mA)  │', colors.accentInfo),
                _diagramLine('│                             │', colors.textTertiary),
                _diagramLine('│ RUN ─── Run status output   │ ← Digital outputs', colors.accentWarning),
                _diagramLine('│ FLT ─── Fault output        │', colors.accentWarning),
                _diagramLine('└─────────────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Use shielded cable for analog signals, ground shield at VFD end only', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCableRequirements(ZaftoColors colors) {
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
            Text('VFD CABLE REQUIREMENTS', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('OUTPUT CABLE (VFD to Motor):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
          _reqItem('Use VFD-rated cable or shielded cable', colors),
          _reqItem('Keep as short as possible (<100ft ideal)', colors),
          _reqItem('Symmetrical ground conductors', colors),
          _reqItem('Do NOT run with other cables', colors),
          const SizedBox(height: 10),
          Text('INPUT CABLE:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
          _reqItem('Standard power cable acceptable', colors),
          _reqItem('Size per NEC ampacity tables', colors),
          _reqItem('Line reactor recommended for long runs', colors),
          const SizedBox(height: 10),
          Text('CONTROL CABLE:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
          _reqItem('Shielded twisted pair for analog', colors),
          _reqItem('Separate from power cables (12" min)', colors),
          _reqItem('Cross power cables at 90 degrees only', colors),
        ],
      ),
    );
  }

  Widget _reqItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('  ', style: TextStyle(color: colors.accentWarning)),
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: colors.accentWarning, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
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
            Text('COMMON VFD FAULTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _faultRow('OC (Overcurrent)', 'Check motor, cable, VFD output transistors', colors),
          _faultRow('OV (Overvoltage)', 'Decel too fast, add braking resistor', colors),
          _faultRow('UV (Undervoltage)', 'Check input power, loose connections', colors),
          _faultRow('OH (Overheat)', 'Clean filters, check ambient temp, airflow', colors),
          _faultRow('GF (Ground Fault)', 'Check motor insulation, cable damage', colors),
          _faultRow('OL (Overload)', 'Motor overloaded, check driven equipment', colors),
        ],
      ),
    );
  }

  Widget _faultRow(String fault, String cause, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(fault, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(cause, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
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
            Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• NEC 430 - Motors, Motor Circuits\n'
            '• Disconnect required within sight of VFD\n'
            '• Branch circuit protection per VFD nameplate\n'
            '• Motor overload per 430.32 (often VFD provides)\n'
            '• Ground all equipment properly\n'
            '• Consider output filter for long cable runs',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
