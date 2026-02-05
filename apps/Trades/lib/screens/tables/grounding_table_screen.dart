import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Grounding Conductor Table - Design System v2.6
class GroundingTableScreen extends ConsumerWidget {
  const GroundingTableScreen({super.key});

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
        title: Text('Grounding Conductor Table', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEGCTable(colors),
            const SizedBox(height: 16),
            _buildGECTable(colors),
            const SizedBox(height: 16),
            _buildBondingJumperTable(colors),
            const SizedBox(height: 16),
            _buildNotes(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildEGCTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader('NEC Table 250.122', 'Equipment Grounding Conductor (EGC)', colors),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['OCPD (Amps)', 'Copper', 'Aluminum'], colors),
                _dataRow(['15', '14 AWG', '12 AWG'], colors),
                _dataRow(['20', '12 AWG', '10 AWG'], colors),
                _dataRow(['30', '10 AWG', '8 AWG'], colors),
                _dataRow(['40', '10 AWG', '8 AWG'], colors),
                _dataRow(['60', '10 AWG', '8 AWG'], colors),
                _dataRow(['100', '8 AWG', '6 AWG'], colors),
                _dataRow(['200', '6 AWG', '4 AWG'], colors),
                _dataRow(['300', '4 AWG', '2 AWG'], colors),
                _dataRow(['400', '3 AWG', '1 AWG'], colors),
                _dataRow(['500', '2 AWG', '1/0 AWG'], colors),
                _dataRow(['600', '1 AWG', '2/0 AWG'], colors),
                _dataRow(['800', '1/0 AWG', '3/0 AWG'], colors),
                _dataRow(['1000', '2/0 AWG', '4/0 AWG'], colors),
                _dataRow(['1200', '3/0 AWG', '250 kcmil'], colors),
                _dataRow(['1600', '4/0 AWG', '350 kcmil'], colors),
                _dataRow(['2000', '250 kcmil', '400 kcmil'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('OCPD = Overcurrent Protective Device (breaker/fuse)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGECTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader('NEC Table 250.66', 'Grounding Electrode Conductor (GEC)', colors),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Service Conductor', 'Copper GEC', 'Aluminum GEC'], colors),
                _dataRow(['2 AWG or smaller', '8 AWG', '6 AWG'], colors),
                _dataRow(['1 AWG or 1/0 AWG', '6 AWG', '4 AWG'], colors),
                _dataRow(['2/0 or 3/0 AWG', '4 AWG', '2 AWG'], colors),
                _dataRow(['Over 3/0 to 350 kcmil', '2 AWG', '1/0 AWG'], colors),
                _dataRow(['Over 350 to 600 kcmil', '1/0 AWG', '3/0 AWG'], colors),
                _dataRow(['Over 600 to 1100 kcmil', '2/0 AWG', '4/0 AWG'], colors),
                _dataRow(['Over 1100 kcmil', '3/0 AWG', '250 kcmil'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('GEC connects service equipment to grounding electrode (rod, plate, etc)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBondingJumperTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader('NEC Table 250.102(C)(1)', 'Main Bonding Jumper / System Bonding Jumper', colors),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Service Conductor', 'Copper', 'Aluminum'], colors),
                _dataRow(['2 AWG or smaller', '8 AWG', '6 AWG'], colors),
                _dataRow(['1 AWG or 1/0 AWG', '6 AWG', '4 AWG'], colors),
                _dataRow(['2/0 or 3/0 AWG', '4 AWG', '2 AWG'], colors),
                _dataRow(['Over 3/0 to 350 kcmil', '2 AWG', '1/0 AWG'], colors),
                _dataRow(['Over 350 to 600 kcmil', '1/0 AWG', '3/0 AWG'], colors),
                _dataRow(['Over 600 to 1100 kcmil', '2/0 AWG', '4/0 AWG'], colors),
                _dataRow(['Over 1100 kcmil', '3/0 AWG', '250 kcmil'], colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String code, String title, ZaftoColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(4)),
          child: Text(code, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _headerRow(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
        )).toList(),
      ),
    );
  }

  Widget _dataRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(
            e.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: e.key == 0 ? colors.textPrimary : colors.textSecondary,
              fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildNotes(ZaftoColors colors) {
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
            Text('KEY TERMS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• EGC: Equipment Grounding Conductor - green wire in circuit\n'
            '• GEC: Grounding Electrode Conductor - to ground rod\n'
            '• MBJ: Main Bonding Jumper - bonds neutral to ground at service\n'
            '• OCPD: Overcurrent Protective Device - breaker or fuse\n'
            '\n'
            'NEC 250.122(B): If circuit conductors are increased in size, EGC must be proportionally increased.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
