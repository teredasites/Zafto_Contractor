import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Grounding Electrode System Diagram - Design System v2.6
class GroundingElectrodeScreen extends ConsumerWidget {
  const GroundingElectrodeScreen({super.key});

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
        title: Text('Grounding Electrode System', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            _buildElectrodeTypes(colors),
            const SizedBox(height: 16),
            _buildConductorSizing(colors),
            const SizedBox(height: 16),
            _buildBonding(colors),
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
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.anchor, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('What is a Grounding Electrode System?', style: TextStyle(color: colors.accentSuccess, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text(
            'The grounding electrode system connects the electrical system to the earth, providing a reference to ground potential and a path for lightning and surge currents to dissipate safely.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GROUNDING ELECTRODE SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('                    SERVICE PANEL', colors.textTertiary),
                _diagramLine('                   ┌─────────────┐', colors.textTertiary),
                _diagramLine('                   │  Main Bond  │', colors.accentPrimary),
                _diagramLine('                   │  N ─── G    │', colors.accentSuccess),
                _diagramLine('                   └──────┬──────┘', colors.textTertiary),
                _diagramLine('                          │ GEC', colors.accentSuccess),
                _diagramLine('    ┌──────────┬──────────┼──────────┬──────────┐', colors.accentSuccess),
                _diagramLine('    │          │          │          │          │', colors.accentSuccess),
                _diagramLine('    ▼          ▼          ▼          ▼          ▼', colors.accentSuccess),
                _diagramLine('┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐', colors.textTertiary),
                _diagramLine('│GROUND│  │METAL │  │UFER  │  │GROUND│  │METAL │', colors.textPrimary),
                _diagramLine('│ ROD  │  │WATER │  │(CEE) │  │ RING │  │ GAS  │', colors.textPrimary),
                _diagramLine('└──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘', colors.textTertiary),
                _diagramLine('   │         │         │         │         │', colors.textTertiary),
                _diagramLine('═══╧═════════╧═════════╧═════════╧═════════╧═══', colors.accentWarning),
                _diagramLine('                    EARTH', colors.accentWarning),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _buildElectrodeTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ELECTRODE TYPES (NEC 250.52)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _electrodeRow('Ground Rod', '8 ft min, 5/8" copper or 3/4" galv steel', '250.52(A)(5)', colors),
          _electrodeRow('Metal Water Pipe', '10 ft min in contact with earth', '250.52(A)(1)', colors),
          _electrodeRow('Concrete-Encased (Ufer)', '20 ft of #4 AWG in footing', '250.52(A)(3)', colors),
          _electrodeRow('Ground Ring', '#2 AWG min, 20 ft encircling building', '250.52(A)(4)', colors),
          _electrodeRow('Metal Frame', 'Effectively grounded structural steel', '250.52(A)(2)', colors),
          _electrodeRow('Plate Electrode', '2 sq ft min surface area', '250.52(A)(7)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('If single rod >25 ohms resistance, supplemental electrode required', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _electrodeRow(String type, String req, String code, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(req, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          Text(code, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildConductorSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GEC SIZING (NEC TABLE 250.66)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _tableHeader(['Service Conductor', 'GEC (Cu)', 'GEC (Al)'], colors),
              _tableRow(['Up to 2 AWG Cu', '8 AWG', '6 AWG'], colors),
              _tableRow(['1 or 1/0 AWG Cu', '6 AWG', '4 AWG'], colors),
              _tableRow(['2/0 or 3/0 AWG Cu', '4 AWG', '2 AWG'], colors),
              _tableRow(['Over 3/0 to 350 kcmil', '2 AWG', '1/0 AWG'], colors),
              _tableRow(['Over 350 to 600 kcmil', '1/0 AWG', '3/0 AWG'], colors),
              _tableRow(['Over 600 to 1100 kcmil', '2/0 AWG', '4/0 AWG'], colors, isLast: true),
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

  Widget _buildBonding(ZaftoColors colors) {
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
            Icon(LucideIcons.link, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('BONDING REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _bondingItem('Metal water piping', 'Must be bonded within 5 ft of entry point', colors),
          _bondingItem('Gas piping (CSST)', 'Bonded per manufacturer requirements', colors),
          _bondingItem('All electrodes', 'Must be bonded together', colors),
          _bondingItem('Connections', 'Use irreversible compression or exothermic welds', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Text('Bonding ensures all grounded metal objects are at the same potential, preventing shock hazards and ensuring proper fault clearing.', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _bondingItem(String item, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
            Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ])),
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
            '• NEC 250.50 - Grounding Electrode System\n'
            '• NEC 250.52 - Grounding Electrodes\n'
            '• NEC 250.53 - Installation Requirements\n'
            '• NEC 250.66 - GEC Sizing\n'
            '• NEC 250.68 - GEC Connections\n'
            '• NEC 250.104 - Bonding of Piping Systems',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
