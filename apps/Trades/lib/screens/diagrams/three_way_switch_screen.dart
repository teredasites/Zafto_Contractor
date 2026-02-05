import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// 3-Way Switch Wiring Diagram - Design System v2.6
class ThreeWaySwitchScreen extends ConsumerWidget {
  const ThreeWaySwitchScreen({super.key});

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
          '3-Way Switch Wiring',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDiagramCard(colors),
            const SizedBox(height: 16),
            _buildWiringSteps(colors),
            const SizedBox(height: 16),
            _buildTerminalGuide(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagramCard(ZaftoColors colors) {
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
              Icon(LucideIcons.zap, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 8),
              Text(
                '3-Way Switch Circuit',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('     POWER SOURCE (120V)', colors.accentError),
                _diagramLine('           │', colors.accentError),
                _diagramLine('     ┌─────┴─────┐', colors.textTertiary),
                _diagramLine('     │  SWITCH 1  │', colors.accentPrimary),
                _diagramLine('     │ (3-WAY)    │', colors.accentPrimary),
                _diagramLine('     └──┬───┬────┘', colors.textTertiary),
                _diagramLine('  COM──┘   └──TRAVELERS (2)', colors.textTertiary),
                _diagramLine('              │   │', colors.accentInfo),
                _diagramLine('     ┌────────┴───┴──┐', colors.textTertiary),
                _diagramLine('     │   SWITCH 2    │', colors.accentPrimary),
                _diagramLine('     │   (3-WAY)     │', colors.accentPrimary),
                _diagramLine('     └───────┬───────┘', colors.textTertiary),
                _diagramLine('             │ COM', colors.textTertiary),
                _diagramLine('        ┌────┴────┐', colors.textTertiary),
                _diagramLine('        │  LIGHT  │', colors.accentWarning),
                _diagramLine('        └────┬────┘', colors.textTertiary),
                _diagramLine('             │', colors.textSecondary),
                _diagramLine('         NEUTRAL', colors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildWireColorLegend(colors),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12),
    );
  }

  Widget _buildWireColorLegend(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WIRE COLORS',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _colorDot(Colors.black, 'Hot (Line)', colors),
            _colorDot(Colors.red, 'Traveler 1', colors),
            _colorDot(Colors.blue, 'Traveler 2', colors),
            _colorDot(Colors.white, 'Neutral', colors),
            _colorDot(Colors.green, 'Ground', colors),
            _colorDot(Colors.orange, 'Switch Leg', colors),
          ],
        ),
      ],
    );
  }

  Widget _colorDot(Color wireColor, String label, ZaftoColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: wireColor,
            shape: BoxShape.circle,
            border: wireColor == Colors.white
                ? Border.all(color: colors.borderDefault)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
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
          Text(
            'WIRING STEPS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _stepItem('1', 'Turn OFF power at breaker and verify with tester', colors),
          _stepItem('2', 'Connect HOT (black) from source to COMMON terminal of Switch 1', colors),
          _stepItem('3', 'Connect two TRAVELER wires between switches (red & black of 3-wire cable)', colors),
          _stepItem('4', 'Connect COMMON terminal of Switch 2 to light fixture (switch leg)', colors),
          _stepItem('5', 'Connect all NEUTRALS together (white wires)', colors),
          _stepItem('6', 'Connect all GROUNDS together and to each switch box', colors),
          _stepItem('7', 'Restore power and test from both switch locations', colors),
        ],
      ),
    );
  }

  Widget _stepItem(String number, String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: colors.isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalGuide(ZaftoColors colors) {
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
          Text(
            '3-WAY SWITCH TERMINALS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _terminalRow('COMMON', 'Darker screw (usually black or copper)', 'Hot in OR switch leg out', colors),
          _terminalRow('TRAVELER 1', 'Brass screw', 'Connects to other switch', colors),
          _terminalRow('TRAVELER 2', 'Brass screw', 'Connects to other switch', colors),
          _terminalRow('GROUND', 'Green screw', 'Equipment ground', colors),
        ],
      ),
    );
  }

  Widget _terminalRow(String terminal, String screw, String purpose, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(terminal, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(screw, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          Text(purpose, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
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
              Icon(LucideIcons.wrench, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'TROUBLESHOOTING',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _troubleItem("Light doesn't work from either switch", 'Check COMMON connections - hot must be on SW1 common, switch leg on SW2 common', colors),
          _troubleItem('Light works from one switch only', 'Travelers are likely crossed or one is disconnected', colors),
          _troubleItem('Light stays on always', 'Hot wire connected to traveler instead of common', colors),
          _troubleItem('Breaker trips', 'Short circuit - check for bare wires touching or wrong connections', colors),
        ],
      ),
    );
  }

  Widget _troubleItem(String problem, String solution, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.alertCircle, color: colors.accentError, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(problem, style: TextStyle(color: colors.accentError, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Text(solution, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
              const SizedBox(width: 8),
              Text(
                'NEC REFERENCE',
                style: TextStyle(
                  color: colors.accentInfo,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• NEC 404.2 - Switch Connections\n'
            '• NEC 404.9(B) - Grounding of Switches\n'
            '• NEC 200.7 - Use of White Wire as Ungrounded Conductor\n'
            '• NEC 404.2(C) - Switches Controlling Lighting Loads (Neutral Required)',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
