import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Single Pole Switch Wiring Diagram - Design System v2.6
class SinglePoleSwitchScreen extends ConsumerWidget {
  const SinglePoleSwitchScreen({super.key});

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
        title: Text('Single Pole Switch', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicDiagram(colors),
            const SizedBox(height: 16),
            _buildPowerAtSwitch(colors),
            const SizedBox(height: 16),
            _buildPowerAtLight(colors),
            const SizedBox(height: 16),
            _buildSwitchLoop(colors),
            const SizedBox(height: 16),
            _buildWiringSteps(colors),
            const SizedBox(height: 16),
            _buildCodeNotes(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.toggleLeft, color: colors.accentPrimary, size: 24),
            const SizedBox(width: 8),
            Text('Single Pole Switch Basics', style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('A single pole switch controls a light or outlet from ONE location only. It has two brass terminals (for hot wires) and a green ground terminal.', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('┌─────────────────────┐', colors.textTertiary),
                _diagramLine('│   SINGLE POLE       │', colors.accentPrimary),
                _diagramLine('│      SWITCH         │', colors.accentPrimary),
                _diagramLine('│                     │', colors.textTertiary),
                _diagramLine('│  ○ ──────────── ○   │ ← Two brass terminals', colors.accentWarning),
                _diagramLine('│ IN           OUT    │', colors.textTertiary),
                _diagramLine('│ (from power) (to load)│', colors.textTertiary),
                _diagramLine('│                     │', colors.textTertiary),
                _diagramLine('│        ◉            │ ← Green ground screw', colors.accentSuccess),
                _diagramLine('└─────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11));
  }

  Widget _buildPowerAtSwitch(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POWER AT SWITCH (Most Common)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('FROM PANEL                    TO LIGHT', colors.textTertiary),
                _diagramLine('    │                              │', colors.textTertiary),
                _diagramLine('    │      ┌────────────┐          │', colors.textTertiary),
                _diagramLine('    ├─HOT──┤  SWITCH    ├──HOT─────┤', colors.accentError),
                _diagramLine('    │      │            │          │', colors.textTertiary),
                _diagramLine('    │      └────────────┘          │', colors.textTertiary),
                _diagramLine('    │                              │', colors.textTertiary),
                _diagramLine('    ├──────── NEUTRAL ─────────────┤', colors.textSecondary),
                _diagramLine('    │      (spliced through)       │', colors.textTertiary),
                _diagramLine('    │                              │', colors.textTertiary),
                _diagramLine('    └──────── GROUND ──────────────┘', colors.accentSuccess),
                _diagramLine('           (to switch & light)', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Neutral passes through switch box to light. Hot is switched.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPowerAtLight(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POWER AT LIGHT FIXTURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('          ┌─── LIGHT ───┐', colors.textTertiary),
                _diagramLine('          │   FIXTURE   │', colors.accentWarning),
                _diagramLine('    HOT ──┤             ├── FROM PANEL', colors.accentError),
                _diagramLine('          │             │', colors.textTertiary),
                _diagramLine('          └──────┬──────┘', colors.textTertiary),
                _diagramLine('                 │', colors.textTertiary),
                _diagramLine('          SWITCH LOOP', colors.textTertiary),
                _diagramLine('          (2-wire cable)', colors.textTertiary),
                _diagramLine('                 │', colors.textTertiary),
                _diagramLine('          ┌──────┴──────┐', colors.textTertiary),
                _diagramLine('          │   SWITCH    │', colors.accentPrimary),
                _diagramLine('          │ HOT ─── HOT │', colors.accentError),
                _diagramLine('          │ (return leg)│', colors.textTertiary),
                _diagramLine('          └─────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('NEC 404.2(C): Neutral now required at switch location for lighting in dwellings. This method may not be code compliant.', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchLoop(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SWITCH LOOP WIRING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('When power comes to light first, a 2-wire "switch loop" goes to the switch:', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          _wireInfo('White wire (re-identified)', 'Carries HOT to switch - mark with black tape', colors.accentError, colors),
          _wireInfo('Black wire', 'Switched hot returning to light', colors.accentError, colors),
          _wireInfo('Ground (bare/green)', 'Equipment ground to switch', colors.accentSuccess, colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Text('NEC 200.7(C)(1): White wire used as ungrounded conductor must be re-identified (marked) with black or red tape at each end.', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _wireInfo(String wire, String purpose, Color color, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(wire, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          Text(purpose, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildWiringSteps(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRING STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _stepItem('1', 'Turn OFF power at breaker and verify dead', colors),
          _stepItem('2', 'Connect incoming HOT to one brass terminal', colors),
          _stepItem('3', 'Connect outgoing HOT (to light) to other brass terminal', colors),
          _stepItem('4', 'Splice neutrals together (white wires, if present)', colors),
          _stepItem('5', 'Connect all grounds together + to switch green screw', colors),
          _stepItem('6', 'Fold wires and mount switch in box', colors),
          _stepItem('7', 'Install cover plate and restore power', colors),
        ],
      ),
    );
  }

  Widget _stepItem(String number, String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 22, height: 22, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(11)), child: Center(child: Text(number, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 11)))),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildCodeNotes(ZaftoColors colors) {
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
            '• NEC 404.2 - Switch Connections\n'
            '• NEC 404.2(C) - Neutral at Switch Location Required\n'
            '• NEC 404.9(B) - Grounding Switches\n'
            '• NEC 200.7(C)(1) - Re-identification of White Wire\n'
            '• NEC 404.14(A) - Rating for Switches',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
