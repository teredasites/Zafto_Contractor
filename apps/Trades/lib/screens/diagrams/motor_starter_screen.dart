import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Motor Starter Wiring Diagram - Design System v2.6
class MotorStarterScreen extends ConsumerWidget {
  const MotorStarterScreen({super.key});

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
        title: Text('Motor Starter Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStarterBasics(colors),
            const SizedBox(height: 16),
            _buildAcrossTheLineDiagram(colors),
            const SizedBox(height: 16),
            _buildControlCircuit(colors),
            const SizedBox(height: 16),
            _buildOverloadProtection(colors),
            const SizedBox(height: 16),
            _buildReversingStarter(colors),
            const SizedBox(height: 16),
            _buildSizing(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterBasics(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.settings, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('Motor Starter Components', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('A motor starter consists of a contactor (power switching) and overload relay (motor protection). It allows remote control and protects the motor.', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          _compRow('Contactor', 'Electromagnetically operated switch for motor power', colors),
          _compRow('Overload Relay', 'Thermal or electronic protection against overcurrent', colors),
          _compRow('Control Circuit', 'Low voltage circuit for start/stop/status', colors),
          _compRow('Auxiliary Contacts', 'For control logic and status indication', colors),
        ],
      ),
    );
  }

  Widget _compRow(String comp, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text(comp, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
        Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildAcrossTheLineDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACROSS-THE-LINE (DOL) STARTER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('L1 ─────┬─────────────────────── T1 ──► MOTOR', colors.accentError),
                _diagramLine('        │                             U', colors.textTertiary),
                _diagramLine('L2 ─────┼────┬────────────────── T2 ──► MOTOR', colors.accentError),
                _diagramLine('        │    │                        V', colors.textTertiary),
                _diagramLine('L3 ─────┼────┼───┬───────────── T3 ──► MOTOR', colors.accentError),
                _diagramLine('        │    │   │                    W', colors.textTertiary),
                _diagramLine('        │    │   │', colors.textTertiary),
                _diagramLine('   ┌────┴────┴───┴────┐', colors.textTertiary),
                _diagramLine('   │    CONTACTOR     │', colors.accentPrimary),
                _diagramLine('   │      (M)         │', colors.accentPrimary),
                _diagramLine('   │                  │', colors.textTertiary),
                _diagramLine('   │   ○   ○   ○      │ ← Main contacts', colors.accentWarning),
                _diagramLine('   │                  │', colors.textTertiary),
                _diagramLine('   │   COIL: A1-A2   │ ← Control voltage', colors.accentInfo),
                _diagramLine('   └──────────────────┘', colors.textTertiary),
                _diagramLine('           │', colors.textTertiary),
                _diagramLine('   ┌───────┴───────┐', colors.textTertiary),
                _diagramLine('   │   OVERLOAD    │', colors.accentWarning),
                _diagramLine('   │     RELAY     │', colors.accentWarning),
                _diagramLine('   │   (OL/95-96)  │', colors.textTertiary),
                _diagramLine('   └───────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('DOL (Direct On-Line) applies full voltage instantly. Simple but causes high inrush current (6-8x FLA).', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _buildControlCircuit(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3-WIRE CONTROL CIRCUIT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('L1 ──────┬───────────────────────────── L2/N', colors.accentError),
                _diagramLine('         │                               │', colors.textTertiary),
                _diagramLine('    ┌────┴────┐                          │', colors.textTertiary),
                _diagramLine('    │  STOP   │ ←─ NC pushbutton         │', colors.accentError),
                _diagramLine('    │  (NC)   │                          │', colors.textTertiary),
                _diagramLine('    └────┬────┘                          │', colors.textTertiary),
                _diagramLine('         │                               │', colors.textTertiary),
                _diagramLine('    ┌────┴────┐                          │', colors.textTertiary),
                _diagramLine('    │  OL     │ ←─ Overload NC contact   │', colors.accentWarning),
                _diagramLine('    │(95-96)  │                          │', colors.textTertiary),
                _diagramLine('    └────┬────┘                          │', colors.textTertiary),
                _diagramLine('         │                               │', colors.textTertiary),
                _diagramLine('    ┌────┴────┐  ┌────────┐              │', colors.textTertiary),
                _diagramLine('    │  START  ├──┤   M    │              │', colors.accentSuccess),
                _diagramLine('    │  (NO)   │  │ (seal) │ ←─ Holding   │', colors.accentSuccess),
                _diagramLine('    └─────────┘  └────┬───┘   contact    │', colors.textTertiary),
                _diagramLine('                      │                  │', colors.textTertiary),
                _diagramLine('                 ┌────┴────┐             │', colors.textTertiary),
                _diagramLine('                 │  COIL   │             │', colors.accentInfo),
                _diagramLine('                 │   (M)   ├─────────────┘', colors.accentInfo),
                _diagramLine('                 │  A1-A2  │', colors.textTertiary),
                _diagramLine('                 └─────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('3-wire control provides low-voltage release protection. If power fails, motor stops and must be restarted manually.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOverloadProtection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.thermometer, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('OVERLOAD RELAY SETTING', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
          ]),
          const SizedBox(height: 12),
          Text('Set overload relay to motor nameplate FLA:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          _olRow('Service Factor 1.15+', 'Set OL at 125% of FLA', colors),
          _olRow('Service Factor < 1.15', 'Set OL at 115% of FLA', colors),
          _olRow('Temperature Rise 40°C', 'Set OL at 125% of FLA', colors),
          _olRow('Class 10', 'Standard motors (trips in 10s at 600% FLA)', colors),
          _olRow('Class 20', 'High inertia loads (longer trip time)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Text('NEC 430.32: Motor overload protection shall not exceed 125% of motor nameplate FLA (115% for motors without service factor marking).', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _olRow(String setting, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 130, child: Text(setting, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 12))),
        Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildReversingStarter(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REVERSING STARTER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('A reversing starter uses two contactors to swap two phases, reversing motor direction:', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('FORWARD (F):  L1→T1  L2→T2  L3→T3', colors.accentSuccess),
                _diagramLine('REVERSE (R):  L1→T3  L2→T2  L3→T1', colors.accentInfo),
                _diagramLine('                (swap L1 and L3)', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _revRow('Mechanical Interlock', 'Physical barrier prevents both contactors closing', colors),
          _revRow('Electrical Interlock', 'F aux contact in series with R coil (and vice versa)', colors),
          _revRow('Both Required', 'NEC 430.84 requires interlock to prevent phase-to-phase short', colors),
        ],
      ),
    );
  }

  Widget _revRow(String item, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEMA STARTER SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _tableHeader(['NEMA Size', '200V HP', '460V HP', 'Max Amps'], colors),
              _tableRow(['00', '1.5', '2', '9'], colors),
              _tableRow(['0', '3', '5', '18'], colors),
              _tableRow(['1', '7.5', '10', '27'], colors),
              _tableRow(['2', '10', '25', '45'], colors),
              _tableRow(['3', '25', '50', '90'], colors),
              _tableRow(['4', '40', '100', '135'], colors, isLast: true),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Select starter size based on motor HP and voltage. Always verify motor FLA does not exceed starter rating.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11))),
      child: Row(children: headers.map((h) => Expanded(child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10)))).toList()),
    );
  }

  Widget _tableRow(List<String> values, ZaftoColors colors, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(children: values.asMap().entries.map((e) => Expanded(child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.w600 : FontWeight.w400, fontSize: 11)))).toList()),
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3))),
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
            '• NEC 430.32 - Continuous-Duty Motors (Overload Protection)\n'
            '• NEC 430.52 - Short-Circuit & Ground-Fault Protection\n'
            '• NEC 430.83 - Rating & Interrupting Capacity\n'
            '• NEC 430.84 - Reversing Motors (Interlock Required)\n'
            '• NEC 430.102 - Location of Disconnecting Means',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
