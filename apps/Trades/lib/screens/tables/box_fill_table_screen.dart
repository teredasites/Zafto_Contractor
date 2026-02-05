import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Box Fill Calculations Table - Design System v2.6
class BoxFillTableScreen extends ConsumerWidget {
  const BoxFillTableScreen({super.key});

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
        title: Text('Box Fill Calculations', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVolumePerConductor(colors),
            const SizedBox(height: 16),
            _buildCountingRules(colors),
            const SizedBox(height: 16),
            _buildBoxVolumes(colors),
            const SizedBox(height: 16),
            _buildExample(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumePerConductor(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.box, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('VOLUME PER CONDUCTOR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 4),
          Text('NEC Table 314.16(B)', style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Wire Size', 'Volume (cu in)'], colors),
                _dataRow(['18 AWG', '1.50'], colors),
                _dataRow(['16 AWG', '1.75'], colors),
                _dataRow(['14 AWG', '2.00'], colors),
                _dataRow(['12 AWG', '2.25'], colors),
                _dataRow(['10 AWG', '2.50'], colors),
                _dataRow(['8 AWG', '3.00'], colors),
                _dataRow(['6 AWG', '5.00'], colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountingRules(ZaftoColors colors) {
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
            Icon(LucideIcons.hash, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('COUNTING CONDUCTORS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 4),
          Text('NEC 314.16(B)', style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
          const SizedBox(height: 12),
          _ruleRow('Each hot/neutral entering box', '1 conductor each', colors),
          _ruleRow('All grounds combined', '1 conductor (use largest)', colors),
          _ruleRow('All cable clamps combined', '1 conductor (largest wire)', colors),
          _ruleRow('Each device (switch/outlet)', '2 conductors (largest wire to device)', colors),
          _ruleRow('Pigtails inside box', '0 (don\'t count)', colors),
          _ruleRow('Wire passing through', '1 conductor', colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Remember: Grounds = 1, Clamps = 1, Device = 2\nAll at the LARGEST wire size present',
              style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(String item, String count, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(flex: 2, child: Text(count, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildBoxVolumes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMON BOX VOLUMES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text('NEC Table 314.16(A)', style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
          const SizedBox(height: 12),
          Text('Device Boxes:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          _boxRow('3x2x1.5" (single gang)', '7.5 cu in', colors),
          _boxRow('3x2x2" (single gang)', '10.0 cu in', colors),
          _boxRow('3x2x2.25" (single gang)', '10.5 cu in', colors),
          _boxRow('3x2x2.5" (single gang)', '12.5 cu in', colors),
          _boxRow('3x2x2.75" (single gang)', '14.0 cu in', colors),
          _boxRow('3x2x3.5" (single gang)', '18.0 cu in', colors),
          const SizedBox(height: 10),
          Text('2-Gang Boxes:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          _boxRow('4x3x1.5" (2-gang)', '13.0 cu in', colors),
          _boxRow('4x3x2.125" (2-gang)', '22.0 cu in', colors),
          const SizedBox(height: 10),
          Text('Round/Octagon Boxes:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          _boxRow('4" round 1.5" deep', '12.5 cu in', colors),
          _boxRow('4" octagon 1.5" deep', '15.5 cu in', colors),
          _boxRow('4" octagon 2.125" deep', '21.5 cu in', colors),
          const SizedBox(height: 10),
          Text('Square Boxes:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          _boxRow('4" square 1.25" deep', '18.0 cu in', colors),
          _boxRow('4" square 1.5" deep', '21.0 cu in', colors),
          _boxRow('4" square 2.125" deep', '30.3 cu in', colors),
          _boxRow('4-11/16" square 1.5" deep', '29.5 cu in', colors),
          _boxRow('4-11/16" square 2.125" deep', '42.0 cu in', colors),
        ],
      ),
    );
  }

  Widget _boxRow(String box, String volume, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(box, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Text(volume, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildExample(ZaftoColors colors) {
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
            Icon(LucideIcons.calculator, color: colors.accentSuccess, size: 18),
            const SizedBox(width: 8),
            Text('EXAMPLE CALCULATION', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Single switch box with 14/2 in and 14/2 out:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2 hots (black)     = 2 × 2.0 = 4.0 cu in', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'monospace')),
                Text('2 neutrals (white) = 2 × 2.0 = 4.0 cu in', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'monospace')),
                Text('All grounds        = 1 × 2.0 = 2.0 cu in', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'monospace')),
                Text('Cable clamps       = 1 × 2.0 = 2.0 cu in', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'monospace')),
                Text('Switch (device)    = 2 × 2.0 = 4.0 cu in', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'monospace')),
                Text('─────────────────────────────────', style: TextStyle(color: colors.borderSubtle, fontSize: 11, fontFamily: 'monospace')),
                Text('TOTAL REQUIRED     = 16.0 cu in', style: TextStyle(color: colors.accentSuccess, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Use: 3x2x3.5" box (18.0 cu in)', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
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

  Widget _dataRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.accentSuccess, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        )).toList(),
      ),
    );
  }
}
