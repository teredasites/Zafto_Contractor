import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Transfer Switch / Generator Wiring Diagram - Design System v2.6
class TransferSwitchScreen extends ConsumerWidget {
  const TransferSwitchScreen({super.key});

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
        title: Text('Transfer Switch / Generator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildManualTransfer(colors),
            const SizedBox(height: 16),
            _buildInterlockKit(colors),
            const SizedBox(height: 16),
            _buildAutoTransfer(colors),
            const SizedBox(height: 16),
            _buildGeneratorSizing(colors),
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
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 24),
            const SizedBox(width: 10),
            Text('CRITICAL SAFETY', style: TextStyle(color: colors.accentError, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Transfer switches PREVENT BACKFEED to utility lines.\n\n'
            'Without proper transfer switch:\n'
            '• Utility workers can be ELECTROCUTED\n'
            '• Generator can be destroyed when power returns\n'
            '• Fire hazard from overloaded circuits\n'
            '• Illegal in all jurisdictions',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTransfer(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.toggleRight, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('MANUAL TRANSFER SWITCH', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Selected circuits only - you choose what to power', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('         UTILITY                    GENERATOR', colors.textTertiary),
                _diagramLine('            │                           │', colors.textTertiary),
                _diagramLine('            ▼                           ▼', colors.textTertiary),
                _diagramLine('       ┌────────────────────────────────────┐', colors.textTertiary),
                _diagramLine('       │     MANUAL TRANSFER SWITCH         │', colors.accentPrimary),
                _diagramLine('       │                                    │', colors.textTertiary),
                _diagramLine('       │  ○ UTILITY ←──────── ○ GENERATOR   │', colors.textPrimary),
                _diagramLine('       │      │     (toggle)     │          │', colors.textTertiary),
                _diagramLine('       └──────┼──────────────────┼──────────┘', colors.textTertiary),
                _diagramLine('              ▼                  ▼', colors.textTertiary),
                _diagramLine('       SELECTED CIRCUITS (6-10 typical)', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Typical circuits to include:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          _bulletItem('Refrigerator', colors),
          _bulletItem('Furnace/boiler', colors),
          _bulletItem('Sump pump', colors),
          _bulletItem('Well pump', colors),
          _bulletItem('Some lights', colors),
          _bulletItem('Garage door opener', colors),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _bulletItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildInterlockKit(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.lock, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('INTERLOCK KIT (at Main Panel)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Mechanical device prevents both breakers from being ON', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('     ┌─────────────────────────┐', colors.textTertiary),
                _diagramLine('     │       MAIN PANEL        │', colors.textTertiary),
                _diagramLine('     │ ┌──────┐  ┌──────────┐  │', colors.textTertiary),
                _diagramLine('     │ │MAIN  │  │INTERLOCK │  │', colors.accentPrimary),
                _diagramLine('     │ │BRKR  │  │  PLATE   │  │', colors.textTertiary),
                _diagramLine('     │ │      │  │ ┌──────┐ │  │ ← Slides to allow', colors.textTertiary),
                _diagramLine('     │ │ ON   │  │ │ GEN  │ │  │   only ONE breaker', colors.accentSuccess),
                _diagramLine('     │ │      │  │ │ BRKR │ │  │   ON at a time', colors.textTertiary),
                _diagramLine('     │ │      │  │ │ OFF  │ │  │', colors.accentError),
                _diagramLine('     │ └──────┘  │ └──────┘ │  │', colors.textTertiary),
                _diagramLine('     │           └──────────┘  │', colors.textTertiary),
                _diagramLine('     └─────────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 14),
            const SizedBox(width: 6),
            Text('Pros: Lower cost, powers entire panel', style: TextStyle(color: colors.accentSuccess, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(LucideIcons.alertCircle, color: colors.accentWarning, size: 14),
            const SizedBox(width: 6),
            Text('Cons: Manual, must manage loads carefully', style: TextStyle(color: colors.accentWarning, fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  Widget _buildAutoTransfer(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.zap, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('AUTOMATIC TRANSFER SWITCH (ATS)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Senses outage, starts generator, transfers automatically', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sequenceStep('1', 'Utility fails', colors.accentError, colors),
                _sequenceStep('2', 'ATS senses loss (10-30 sec delay)', colors.textSecondary, colors),
                _sequenceStep('3', 'ATS sends START signal to generator', colors.accentWarning, colors),
                _sequenceStep('4', 'Generator starts and stabilizes', colors.textSecondary, colors),
                _sequenceStep('5', 'ATS transfers load to generator', colors.accentSuccess, colors),
                _sequenceStep('6', 'When utility returns, reverse process', colors.textSecondary, colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Used with standby generators (natural gas/propane)', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sequenceStep(String num, String text, Color numColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: numColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(num, style: TextStyle(color: numColor, fontWeight: FontWeight.w700, fontSize: 11))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildGeneratorSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GENERATOR SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _tableHeader(['Size', 'Type', 'Coverage'], colors),
              _tableRow(['3-5 kW', 'Portable', 'Few circuits, sump, fridge, lights'], colors),
              _tableRow(['7-10 kW', 'Portable/Standby', 'Essential circuits, small A/C'], colors),
              _tableRow(['12-16 kW', 'Standby', 'Most of house, 3-ton central A/C'], colors),
              _tableRow(['20-24 kW', 'Standby', 'Whole house incl A/C, well pump'], colors),
              _tableRow(['30+ kW', 'Standby', 'Large home, multiple A/C, pool'], colors, isLast: true),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text('Rule of thumb: Add starting watts of largest motor loads + running watts of all other loads', style: TextStyle(color: colors.accentPrimary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
      ),
      child: Row(children: headers.asMap().entries.map((e) => Expanded(
        flex: e.key == 2 ? 2 : 1,
        child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10)),
      )).toList()),
    );
  }

  Widget _tableRow(List<String> values, ZaftoColors colors, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(children: values.asMap().entries.map((e) => Expanded(
        flex: e.key == 2 ? 2 : 1,
        child: Text(e.value, textAlign: e.key == 2 ? TextAlign.left : TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.accentPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.w600 : FontWeight.w400, fontSize: 11)),
      )).toList()),
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
            '• NEC 702 - Optional Standby Systems\n'
            '• NEC 700 - Emergency Systems (commercial)\n'
            '• NEC 445 - Generators\n'
            '• Transfer equipment must prevent interconnection\n'
            '• Portable gen: GFCI outlet required\n'
            '• Inlet box: minimum 20A for portable connection\n'
            '• Permit usually required for permanent installation',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
