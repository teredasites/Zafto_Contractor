import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// AWG Wire Reference Table - Design System v2.6
class AWGReferenceScreen extends ConsumerWidget {
  const AWGReferenceScreen({super.key});

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
        title: Text('AWG Wire Reference', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAWGTable(colors),
            const SizedBox(height: 16),
            _buildLargeWire(colors),
            const SizedBox(height: 16),
            _buildQuickFacts(colors),
            const SizedBox(height: 16),
            _buildStrandingInfo(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildAWGTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.plug, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('AWG WIRE SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['AWG', 'Diameter', 'Area', 'Ω/1000ft'], colors),
                _dataRow(['18', '0.040"', '1,620 CM', '6.51'], colors),
                _dataRow(['16', '0.051"', '2,580 CM', '4.09'], colors),
                _dataRow(['14', '0.064"', '4,110 CM', '2.57'], colors),
                _dataRow(['12', '0.081"', '6,530 CM', '1.62'], colors),
                _dataRow(['10', '0.102"', '10,380 CM', '1.02'], colors),
                _dataRow(['8', '0.128"', '16,510 CM', '0.641'], colors),
                _dataRow(['6', '0.162"', '26,240 CM', '0.403'], colors),
                _dataRow(['4', '0.204"', '41,740 CM', '0.253'], colors),
                _dataRow(['3', '0.229"', '52,620 CM', '0.201'], colors),
                _dataRow(['2', '0.258"', '66,360 CM', '0.159'], colors),
                _dataRow(['1', '0.289"', '83,690 CM', '0.126'], colors),
                _dataRow(['1/0', '0.325"', '105,600 CM', '0.100'], colors),
                _dataRow(['2/0', '0.365"', '133,100 CM', '0.0795'], colors),
                _dataRow(['3/0', '0.410"', '167,800 CM', '0.0631'], colors),
                _dataRow(['4/0', '0.460"', '211,600 CM', '0.0500'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('CM = Circular Mils, Resistance at 75°C copper', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLargeWire(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LARGE WIRE (kcmil)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Above 4/0 AWG, wire is sized in kcmil (thousand circular mils)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['kcmil', 'Diameter', '75°C Amp Cu', '75°C Amp Al'], colors),
                _dataRow(['250', '0.575"', '255', '200'], colors),
                _dataRow(['300', '0.630"', '285', '225'], colors),
                _dataRow(['350', '0.681"', '310', '250'], colors),
                _dataRow(['400', '0.728"', '335', '270'], colors),
                _dataRow(['500', '0.813"', '380', '310'], colors),
                _dataRow(['600', '0.893"', '420', '340'], colors),
                _dataRow(['750', '0.998"', '475', '385'], colors),
                _dataRow(['1000', '1.152"', '545', '445'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Ampacity from NEC Table 310.16 (THWN/THHN)', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildQuickFacts(ZaftoColors colors) {
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
            Icon(LucideIcons.lightbulb, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('QUICK FACTS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _factRow('Each 3 AWG sizes', 'Doubles/halves area', colors),
          _factRow('Each 6 AWG sizes', '4× area change', colors),
          _factRow('Smaller number', 'LARGER wire', colors),
          _factRow('1/0 means', '"One-aught" (bigger than 1)', colors),
          _factRow('4/0 means', '"Four-aught" (biggest AWG)', colors),
          _factRow('Beyond 4/0', 'Use kcmil (250, 300, etc)', colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Memory trick: "Twelve-Two" (12/2 NM cable)\n= 12 AWG wire, 2 conductors + ground',
              style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _factRow(String fact, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(fact, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildStrandingInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SOLID VS STRANDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _compareRow('Solid Wire', 'Stranded Wire', colors),
          const SizedBox(height: 8),
          _detailRow('Easier to terminate', 'More flexible', colors),
          _detailRow('Used for fixed wiring', 'Better for movement', colors),
          _detailRow('14-10 AWG typical', 'Required 8 AWG and larger', colors),
          _detailRow('NM cable, fixed circuits', 'SO cord, conduit runs', colors),
          _detailRow('Holds shape when bent', 'Easier to pull through conduit', colors),
          const SizedBox(height: 12),
          Text('Common Stranding:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text('• 7-strand: Common for building wire', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          Text('• 19-strand: Flexible applications', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          Text('• 37-strand and up: Very flexible cord', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(
              'NEC 310.3: 8 AWG and larger must be stranded when installed in raceways',
              style: TextStyle(color: colors.accentInfo, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareRow(String left, String right, ZaftoColors colors) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
            child: Text(left, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
            child: Text(right, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String left, String right, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text('• $left', style: TextStyle(color: colors.textSecondary, fontSize: 10))),
          Expanded(child: Text('• $right', style: TextStyle(color: colors.textSecondary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _headerRow(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 9)),
        )).toList(),
      ),
    );
  }

  Widget _dataRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 9)),
        )).toList(),
      ),
    );
  }
}
