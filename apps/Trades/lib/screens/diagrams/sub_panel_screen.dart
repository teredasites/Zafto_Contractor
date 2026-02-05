import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Sub-Panel Wiring Diagram - Design System v2.6
class SubPanelScreen extends ConsumerWidget {
  const SubPanelScreen({super.key});

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
        title: Text('Sub-Panel Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildDiagram(colors),
            const SizedBox(height: 16),
            _buildFeederSizing(colors),
            const SizedBox(height: 16),
            _buildGroundingRules(colors),
            const SizedBox(height: 16),
            _buildWiringSteps(colors),
            const SizedBox(height: 16),
            _buildCommonMistakes(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
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
            Icon(LucideIcons.info, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('Sub-Panel Basics', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('A sub-panel extends your main panel\'s capacity to another location. Key difference from main panel: neutral and ground are NOT bonded in a sub-panel.', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          _infoRow('Main Panel', 'Neutral and ground bonded together', colors),
          _infoRow('Sub-Panel', 'Neutral and ground kept SEPARATE', colors),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 90, child: Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
        Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUB-PANEL WIRING DIAGRAM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('MAIN PANEL                    SUB-PANEL', colors.textTertiary),
                _diagramLine('                                   │', colors.textTertiary),
                _diagramLine('┌───────────────┐           ┌──────┴──────┐', colors.textTertiary),
                _diagramLine('│  MAIN BREAKER │           │ MAIN LUG or │', colors.accentPrimary),
                _diagramLine('│     200A      │           │ MAIN BREAKER│', colors.accentPrimary),
                _diagramLine('│               │           │    60-100A  │', colors.textTertiary),
                _diagramLine('│               │           │             │', colors.textTertiary),
                _diagramLine('│  ┌─────────┐  │           │ ┌─────────┐ │', colors.textTertiary),
                _diagramLine('│  │60-100A  │  │           │ │ NEUTRAL │ │', colors.textSecondary),
                _diagramLine('│  │ FEEDER  │  │           │ │  BAR    │ │ ← ISOLATED', colors.textSecondary),
                _diagramLine('│  │ BREAKER │  │           │ │(floating)│ │', colors.textSecondary),
                _diagramLine('│  └────┬────┘  │           │ └─────────┘ │', colors.textTertiary),
                _diagramLine('│       │       │           │             │', colors.textTertiary),
                _diagramLine('│ ══════╪══════ │  4-WIRE   │ ┌─────────┐ │', colors.textTertiary),
                _diagramLine('│  N    G       │  FEEDER   │ │ GROUND  │ │', colors.accentSuccess),
                _diagramLine('│  │    │       │══════════►│ │  BAR    │ │ ← BONDED TO', colors.accentSuccess),
                _diagramLine('│  │    │       │  L1 L2    │ │(to box) │ │   ENCLOSURE', colors.accentSuccess),
                _diagramLine('│  │    │       │  N  G     │ └─────────┘ │', colors.textTertiary),
                _diagramLine('└──┼────┼───────┘           └─────────────┘', colors.textTertiary),
                _diagramLine('   │    │', colors.textTertiary),
                _diagramLine('═══╧════╧═══ GES', colors.accentSuccess),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }

  Widget _buildFeederSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FEEDER SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _tableHeader(['Sub-Panel', 'Copper', 'Aluminum', 'Breaker'], colors),
              _tableRow(['60A', '6 AWG', '4 AWG', '60A 2-pole'], colors),
              _tableRow(['100A', '3 AWG', '1 AWG', '100A 2-pole'], colors),
              _tableRow(['125A', '2 AWG', '1/0 AWG', '125A 2-pole'], colors),
              _tableRow(['150A', '1 AWG', '2/0 AWG', '150A 2-pole'], colors, isLast: true),
            ]),
          ),
          const SizedBox(height: 12),
          Text('4-wire feeder required: 2 hots, 1 neutral, 1 ground. Use appropriate conduit or cable type.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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

  Widget _buildGroundingRules(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentError.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('CRITICAL: GROUNDING RULES', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
          ]),
          const SizedBox(height: 12),
          _ruleRow('Neutral bar MUST be isolated (floating)', 'Do NOT bond to enclosure', colors),
          _ruleRow('Ground bar bonded to enclosure', 'Via bonding screw or direct mount', colors),
          _ruleRow('Remove bonding strap/screw if present', 'Many panels ship bonded', colors),
          _ruleRow('4-wire feeder required', 'Separate neutral AND ground conductors', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Text('WHY: If neutral and ground are bonded at sub-panel, neutral current can flow on ground wires and metal enclosures - shock and fire hazard.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(String rule, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.check, color: colors.accentError, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rule, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
          Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
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
          Text('INSTALLATION STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _stepItem('1', 'Install feeder breaker in main panel (properly sized)', colors),
          _stepItem('2', 'Run 4-wire feeder cable/conductors to sub-panel location', colors),
          _stepItem('3', 'Mount sub-panel with proper clearances (NEC 110.26)', colors),
          _stepItem('4', 'Connect two hot conductors to main lugs/breaker', colors),
          _stepItem('5', 'Connect neutral to ISOLATED neutral bar', colors),
          _stepItem('6', 'Connect ground to ground bar (bonded to enclosure)', colors),
          _stepItem('7', 'REMOVE any neutral-ground bonding strap', colors),
          _stepItem('8', 'Install branch circuit breakers and wiring', colors),
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

  Widget _buildCommonMistakes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.xCircle, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('COMMON MISTAKES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 16),
          _mistakeRow('Bonding N and G in sub-panel', 'Creates parallel ground path', colors),
          _mistakeRow('Using 3-wire feeder', '4-wire required (separate G)', colors),
          _mistakeRow('Undersized feeder conductors', 'Based on breaker, not panel rating', colors),
          _mistakeRow('No main disconnect in sub', 'OK if main panel provides protection', colors),
          _mistakeRow('Improper working clearances', '30" wide, 36" deep, headroom per 110.26', colors),
        ],
      ),
    );
  }

  Widget _mistakeRow(String mistake, String fix, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.x, color: colors.accentError, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mistake, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
          Text(fix, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ])),
      ]),
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
            '• NEC 250.24 - Grounding Service-Supplied Systems\n'
            '• NEC 250.32 - Buildings/Structures Supplied by Feeder\n'
            '• NEC 250.142 - Use of Grounded Conductor for Grounding\n'
            '• NEC 408.40 - Grounding of Panelboards\n'
            '• NEC 110.26 - Working Space Requirements',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
