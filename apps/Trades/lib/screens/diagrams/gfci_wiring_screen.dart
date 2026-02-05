import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// GFCI Wiring Diagram - Design System v2.6
class GfciWiringScreen extends ConsumerWidget {
  const GfciWiringScreen({super.key});

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
        title: Text(
          'GFCI Outlet Wiring',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLineLoadExplanation(colors),
            const SizedBox(height: 16),
            _buildLineOnlyDiagram(colors),
            const SizedBox(height: 16),
            _buildLineLoadDiagram(colors),
            const SizedBox(height: 16),
            _buildTerminalIdentification(colors),
            const SizedBox(height: 16),
            _buildWiringSteps(colors),
            const SizedBox(height: 16),
            _buildTestingProcedure(colors),
            const SizedBox(height: 16),
            _buildCommonMistakes(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLineLoadExplanation(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'LINE vs LOAD Terminals',
                style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _explanationRow('LINE', 'Power SOURCE coming FROM the panel', colors.accentError, colors),
          _explanationRow('LOAD', 'Power going TO downstream outlets (protected)', colors.accentSuccess, colors),
          const SizedBox(height: 12),
          Text(
            'The LOAD terminals are usually covered with yellow tape - remove only if protecting downstream outlets.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _explanationRow(String term, String description, Color termColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: termColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(term, style: TextStyle(color: termColor, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLineOnlyDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LINE ONLY (Single GFCI)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('FROM PANEL', colors.textTertiary),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('    ├── HOT (Black) ──────┐', colors.accentError),
                _diagramLine('    │                      │', colors.textTertiary),
                _diagramLine('    │                 ┌────┴────┐', colors.textTertiary),
                _diagramLine('    │                 │  LINE   │', colors.accentPrimary),
                _diagramLine('    │                 │  HOT    │', colors.accentPrimary),
                _diagramLine('    │                 │         │', colors.textTertiary),
                _diagramLine('    │                 │  GFCI   │', colors.textPrimary),
                _diagramLine('    │                 │ OUTLET  │', colors.textPrimary),
                _diagramLine('    │                 │         │', colors.textTertiary),
                _diagramLine('    │                 │  LINE   │', colors.textSecondary),
                _diagramLine('    │                 │ NEUTRAL │', colors.textSecondary),
                _diagramLine('    │                 └────┬────┘', colors.textTertiary),
                _diagramLine('    │                      │', colors.textTertiary),
                _diagramLine('    └── NEUTRAL (White) ──┘', colors.textSecondary),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('    └── GROUND (Green/Bare) ── to box & device', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Protects only this outlet. LOAD terminals not used.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _buildLineLoadDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LINE + LOAD (Protecting Downstream)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('PANEL ─────────► GFCI ─────────► OUTLET 2 ───► OUTLET 3', colors.textTertiary),
                _diagramLine('              (LINE)  (LOAD)     (protected)   (protected)', colors.textSecondary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('┌─────────────────────────────────────────────────────────┐', colors.textTertiary),
                _diagramLine('│ FROM PANEL      ┌──────────┐      TO DOWNSTREAM        │', colors.textTertiary),
                _diagramLine('│                 │          │                           │', colors.textTertiary),
                _diagramLine('│ HOT ───────────►│ LINE HOT │                           │', colors.accentError),
                _diagramLine('│                 │          │                           │', colors.textTertiary),
                _diagramLine('│                 │   GFCI   │──► LOAD HOT ─────────────►│', colors.accentWarning),
                _diagramLine('│                 │          │                           │', colors.textTertiary),
                _diagramLine('│ NEUTRAL ───────►│ LINE NEU │                           │', colors.textSecondary),
                _diagramLine('│                 │          │──► LOAD NEU ─────────────►│', colors.textTertiary),
                _diagramLine('│                 └──────────┘                           │', colors.textTertiary),
                _diagramLine('└─────────────────────────────────────────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(LucideIcons.shieldCheck, color: colors.accentSuccess, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('All downstream outlets are GFCI protected!', style: TextStyle(color: colors.accentSuccess, fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalIdentification(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TERMINAL IDENTIFICATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _terminalRow('LINE HOT', 'Brass screw, marked "LINE"', 'Hot from panel', colors.accentError, colors),
          _terminalRow('LINE NEUTRAL', 'Silver screw, marked "LINE"', 'Neutral from panel', colors.textSecondary, colors),
          _terminalRow('LOAD HOT', 'Brass screw, marked "LOAD"', 'Hot to protected outlets', colors.accentWarning, colors),
          _terminalRow('LOAD NEUTRAL', 'Silver screw, marked "LOAD"', 'Neutral to protected outlets', colors.textTertiary, colors),
          _terminalRow('GROUND', 'Green screw', 'Equipment ground', colors.accentSuccess, colors),
        ],
      ),
    );
  }

  Widget _terminalRow(String terminal, String location, String purpose, Color color, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(terminal, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(location, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
          Expanded(child: Text(purpose, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildWiringSteps(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRING STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _stepItem('1', 'Turn OFF breaker and verify power is dead', colors),
          _stepItem('2', 'Identify LINE wires (from panel) vs LOAD wires (to other outlets)', colors),
          _stepItem('3', 'Connect LINE HOT (black) to brass LINE terminal', colors),
          _stepItem('4', 'Connect LINE NEUTRAL (white) to silver LINE terminal', colors),
          _stepItem('5', 'If protecting downstream: connect LOAD wires to LOAD terminals', colors),
          _stepItem('6', 'Connect ground wire to green screw', colors),
          _stepItem('7', 'Fold wires carefully and mount GFCI', colors),
          _stepItem('8', 'Restore power and TEST the GFCI', colors),
        ],
      ),
    );
  }

  Widget _stepItem(String number, String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(number, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTestingProcedure(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text('TESTING PROCEDURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 16),
          _testStep('1', 'Press TEST button - outlet should go dead', colors),
          _testStep('2', 'Verify no power with tester or lamp', colors),
          _testStep('3', 'Press RESET button - power should restore', colors),
          _testStep('4', 'If protecting downstream, test those outlets too', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text('Test GFCI outlets monthly. Replace if TEST button fails to trip.', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _testStep(String number, String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$number.', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildCommonMistakes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.xCircle, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text('COMMON MISTAKES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 16),
          _mistakeRow('LINE and LOAD reversed', 'GFCI will not protect downstream outlets', colors),
          _mistakeRow('Hot and neutral reversed', 'GFCI may not function properly', colors),
          _mistakeRow('Downstream neutral to LINE', 'Creates parallel neutral path - trips randomly', colors),
          _mistakeRow('Missing equipment ground', 'No ground fault path, reduced safety', colors),
          _mistakeRow('Not testing after install', 'Wiring errors go undetected', colors),
        ],
      ),
    );
  }

  Widget _mistakeRow(String mistake, String consequence, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.x, color: colors.accentError, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mistake, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                Text(consequence, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
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
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
              const SizedBox(width: 8),
              Text('NEC REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• NEC 210.8(A) - Dwelling Unit GFCI Locations\n'
            '• NEC 210.8(B) - Other Than Dwelling Units\n'
            '• NEC 210.8(D) - Specific Appliances\n'
            '• NEC 406.4(D)(3) - Replacement Receptacles\n'
            '• NEC 590.6 - Temporary Wiring GFCI\n'
            '• NEC 2023 expanded GFCI to 250V circuits',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
