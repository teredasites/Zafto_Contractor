import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Conduit Fill Tables - Design System v2.6
class RacewayFillTableScreen extends ConsumerWidget {
  const RacewayFillTableScreen({super.key});

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
        title: Text('Conduit Fill Tables', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFillPercentages(colors),
            const SizedBox(height: 16),
            _buildEMTTable(colors),
            const SizedBox(height: 16),
            _buildPVCTable(colors),
            const SizedBox(height: 16),
            _buildWireAreas(colors),
            const SizedBox(height: 16),
            _buildQuickRef(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildFillPercentages(ZaftoColors colors) {
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
            Icon(LucideIcons.percent, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('NEC CHAPTER 9 - FILL PERCENTAGES', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _fillRow('1 conductor', '53%', colors),
          _fillRow('2 conductors', '31%', colors),
          _fillRow('3+ conductors', '40%', colors),
          const SizedBox(height: 8),
          Text('These percentages allow for heat dissipation and pulling ease', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _fillRow(String cond, String pct, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(cond, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
          Text(pct, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEMTTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EMT - MAX THHN/THWN CONDUCTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _conduitHeader(['EMT', '14', '12', '10', '8', '6', '4'], colors),
                _conduitRow(['1/2"', '12', '9', '5', '3', '2', '1'], colors),
                _conduitRow(['3/4"', '22', '16', '10', '6', '4', '2'], colors),
                _conduitRow(['1"', '35', '26', '16', '9', '7', '4'], colors),
                _conduitRow(['1-1/4"', '61', '45', '28', '16', '12', '7'], colors),
                _conduitRow(['1-1/2"', '84', '61', '38', '22', '16', '9'], colors),
                _conduitRow(['2"', '138', '101', '63', '36', '26', '15'], colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPVCTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PVC SCHEDULE 40 - MAX THHN/THWN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _conduitHeader(['PVC', '14', '12', '10', '8', '6', '4'], colors),
                _conduitRow(['1/2"', '11', '8', '5', '3', '1', '1'], colors),
                _conduitRow(['3/4"', '21', '15', '9', '5', '4', '2'], colors),
                _conduitRow(['1"', '34', '25', '15', '9', '6', '4'], colors),
                _conduitRow(['1-1/4"', '60', '44', '27', '15', '11', '6'], colors),
                _conduitRow(['1-1/2"', '82', '60', '37', '21', '15', '9'], colors),
                _conduitRow(['2"', '135', '98', '61', '35', '25', '15'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('PVC Schedule 80 has smaller ID - fewer conductors', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildWireAreas(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRE AREAS (THHN/THWN)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Wire', 'Area (sq in)'], colors),
                _areaRow(['14 AWG', '0.0097'], colors),
                _areaRow(['12 AWG', '0.0133'], colors),
                _areaRow(['10 AWG', '0.0211'], colors),
                _areaRow(['8 AWG', '0.0366'], colors),
                _areaRow(['6 AWG', '0.0507'], colors),
                _areaRow(['4 AWG', '0.0824'], colors),
                _areaRow(['3 AWG', '0.0973'], colors),
                _areaRow(['2 AWG', '0.1158'], colors),
                _areaRow(['1 AWG', '0.1562'], colors),
                _areaRow(['1/0 AWG', '0.1855'], colors),
                _areaRow(['2/0 AWG', '0.2223'], colors),
                _areaRow(['3/0 AWG', '0.2679'], colors),
                _areaRow(['4/0 AWG', '0.3237'], colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRef(ZaftoColors colors) {
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
            Icon(LucideIcons.bookmark, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('QUICK REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• 1/2" EMT: 9× #12 or 12× #14\n'
            '• 3/4" EMT: 16× #12 or 22× #14\n'
            '• 1" EMT: 26× #12 or 35× #14\n\n'
            '• For exact calculations, use app\'s Conduit Fill Calculator\n'
            '• NEC Chapter 9 Tables 4 & 5 for all raceway types\n'
            '• Equipment grounding conductors count toward fill',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _conduitHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.asMap().entries.map((e) => Expanded(
          flex: e.key == 0 ? 2 : 1,
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 9)),
        )).toList(),
      ),
    );
  }

  Widget _conduitRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          flex: e.key == 0 ? 2 : 1,
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 10)),
        )).toList(),
      ),
    );
  }

  Widget _headerRow(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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

  Widget _areaRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.accentSuccess, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 11)),
        )).toList(),
      ),
    );
  }
}
