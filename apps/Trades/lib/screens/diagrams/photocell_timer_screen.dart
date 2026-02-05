import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Photocell & Timer Wiring Diagram - Design System v2.6
class PhotocellTimerScreen extends ConsumerWidget {
  const PhotocellTimerScreen({super.key});

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
        title: Text('Photocell & Timer Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotocellDiagram(colors),
            const SizedBox(height: 16),
            _buildPhotocellTypes(colors),
            const SizedBox(height: 16),
            _buildTimerDiagram(colors),
            const SizedBox(height: 16),
            _buildAstroTimer(colors),
            const SizedBox(height: 16),
            _buildCombination(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotocellDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.sunMoon, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('BASIC PHOTOCELL WIRING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Turns lights ON at dusk, OFF at dawn', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('PANEL                     PHOTOCELL                LIGHT', colors.textTertiary),
                _diagramLine('  │                      ┌─────────┐             ┌─────┐', colors.textTertiary),
                _diagramLine('  │ Black (Hot)          │         │             │     │', colors.textTertiary),
                _diagramLine('  ├──────────────────────┤ BLACK   │             │     │', colors.accentError),
                _diagramLine('  │                      │   IN    │             │     │', colors.textTertiary),
                _diagramLine('  │                      │         │   Red       │     │', colors.textTertiary),
                _diagramLine('  │                      │ RED  ───┼─────────────┤ Hot │', colors.accentError),
                _diagramLine('  │                      │  OUT    │  (switched) │     │', colors.textTertiary),
                _diagramLine('  │                      │         │             │     │', colors.textTertiary),
                _diagramLine('  │ White (Neutral)      │         │             │     │', colors.textTertiary),
                _diagramLine('  ├──────────────────────┤ WHITE ──┼─────────────┤ Neu │', colors.textSecondary),
                _diagramLine('  │                      └─────────┘             └─────┘', colors.textTertiary),
                _diagramLine('  │ Ground', colors.accentSuccess),
                _diagramLine('  └──────────────────────────────────────────────── Gnd', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _wireGuide('Black', 'Line (constant hot)', Colors.grey[800]!, colors),
          _wireGuide('Red', 'Load (switched hot to light)', Colors.red, colors),
          _wireGuide('White', 'Neutral (common)', Colors.white, colors),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }

  Widget _wireGuide(String color, String purpose, Color dotColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: dotColor == Colors.white ? Border.all(color: colors.borderSubtle) : null)),
        const SizedBox(width: 10),
        SizedBox(width: 60, child: Text(color, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
        Expanded(child: Text(purpose, style: TextStyle(color: colors.textTertiary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildPhotocellTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PHOTOCELL TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _typeRow('Button Type', 'Twist-lock into socket, common residential', colors),
          _typeRow('Stem Mount', 'Threads into knockout, commercial', colors),
          _typeRow('Swivel', 'Adjustable angle for optimal sensing', colors),
          _typeRow('Wire-In', 'Hardwired, junction box mount', colors),
          _typeRow('Combo', 'Photocell + motion sensor in one', colors),
          const SizedBox(height: 12),
          Text('Photocell typically activates at ~1-3 foot-candles (dusk level)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _typeRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTimerDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.clock, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('TIMER WIRING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('PANEL                      TIMER                   LIGHT', colors.textTertiary),
                _diagramLine('  │                     ┌──────────┐             ┌─────┐', colors.textTertiary),
                _diagramLine('  │ Hot ────────────────┤ LINE     │             │     │', colors.accentError),
                _diagramLine('  │                     │          │             │     │', colors.textTertiary),
                _diagramLine('  │                     │ LOAD ────┼─────────────┤ Hot │', colors.accentWarning),
                _diagramLine('  │                     │          │             │     │', colors.textTertiary),
                _diagramLine('  │ Neu ────────────────┤ NEUTRAL ─┼─────────────┤ Neu │', colors.textSecondary),
                _diagramLine('  │                     │          │             │     │', colors.textTertiary),
                _diagramLine('  │ Gnd ────────────────┤ GROUND ──┼─────────────┤ Gnd │', colors.accentSuccess),
                _diagramLine('  │                     └──────────┘             └─────┘', colors.textTertiary),
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
              Expanded(child: Text('Digital timers usually require neutral for clock/display power', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAstroTimer(ZaftoColors colors) {
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
            Icon(LucideIcons.sunset, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('ASTRONOMICAL TIMERS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Digital timers with astronomical feature calculate sunrise/sunset based on location. No photocell needed.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text('Benefits:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          _benefitItem('No photocell to fail or get dirty', colors),
          _benefitItem('Adjusts automatically year-round', colors),
          _benefitItem('Can add offset (+/- minutes)', colors),
          _benefitItem('Often includes random vacation mode', colors),
        ],
      ),
    );
  }

  Widget _benefitItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildCombination(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PHOTOCELL + TIMER COMBINATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Photocell ON at dusk, Timer OFF at set time (e.g., midnight)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('HOT ──► PHOTOCELL ──► TIMER ──► LIGHT', colors.accentPrimary),
                _diagramLine('         (dusk on)    (off@12am)', colors.textTertiary),
                const SizedBox(height: 8),
                _diagramLine('Wire photocell output to timer input,', colors.textTertiary),
                _diagramLine('timer output to light fixture.', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 16),
              const SizedBox(width: 8),
              Text('Both devices must be ON for light to operate', style: TextStyle(color: colors.accentSuccess, fontSize: 12)),
            ]),
          ),
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
          _troubleRow('Light stays on 24/7', 'Photocell failed closed, or aimed at light source', colors),
          _troubleRow('Light never turns on', 'Photocell failed open, bad connection, or bulb dead', colors),
          _troubleRow('Light cycles on/off', 'Photocell sensing its own light (relocate or shield)', colors),
          _troubleRow('Timer not holding time', 'Battery backup dead, or power interruption', colors),
          _troubleRow('Erratic operation', 'Dirty photocell lens, or nearby light interference', colors),
        ],
      ),
    );
  }

  Widget _troubleRow(String problem, String solution, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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

  Widget _buildCodeReference(ZaftoColors colors) {
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
            '• NEC 410.130 - General Lighting Requirements\n'
            '• NEC 404.14 - Rating and Use of Switches\n'
            '• NEC 430.72 - Motor Circuit Controllers\n'
            '• UL 773 - Plug-In Locking Photocontrol\n'
            '• UL 917 - Clock-Operated Switches',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
