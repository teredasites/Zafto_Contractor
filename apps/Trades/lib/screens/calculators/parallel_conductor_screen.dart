import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Parallel Conductor Calculator - Design System v2.6
class ParallelConductorScreen extends ConsumerStatefulWidget {
  const ParallelConductorScreen({super.key});
  @override
  ConsumerState<ParallelConductorScreen> createState() => _ParallelConductorScreenState();
}

class _ParallelConductorScreenState extends ConsumerState<ParallelConductorScreen> {
  final _loadAmpsController = TextEditingController();
  String _wireSize = '500';
  String _material = 'Copper';
  String _tempRating = '75';
  int _setsCount = 2;
  Map<String, dynamic>? _result;

  static const Map<String, Map<String, Map<String, int>>> _ampacityTable = {
    'Copper': {
      '1/0': {'60': 125, '75': 150, '90': 170}, '2/0': {'60': 145, '75': 175, '90': 195}, '3/0': {'60': 165, '75': 200, '90': 225}, '4/0': {'60': 195, '75': 230, '90': 260},
      '250': {'60': 215, '75': 255, '90': 290}, '300': {'60': 240, '75': 285, '90': 320}, '350': {'60': 260, '75': 310, '90': 350}, '400': {'60': 280, '75': 335, '90': 380},
      '500': {'60': 320, '75': 380, '90': 430}, '600': {'60': 350, '75': 420, '90': 475}, '700': {'60': 385, '75': 460, '90': 520}, '750': {'60': 400, '75': 475, '90': 535},
      '800': {'60': 410, '75': 490, '90': 555}, '900': {'60': 435, '75': 520, '90': 585}, '1000': {'60': 455, '75': 545, '90': 615},
    },
    'Aluminum': {
      '1/0': {'60': 100, '75': 120, '90': 135}, '2/0': {'60': 115, '75': 135, '90': 150}, '3/0': {'60': 130, '75': 155, '90': 175}, '4/0': {'60': 150, '75': 180, '90': 205},
      '250': {'60': 170, '75': 205, '90': 230}, '300': {'60': 190, '75': 230, '90': 260}, '350': {'60': 210, '75': 250, '90': 280}, '400': {'60': 225, '75': 270, '90': 305},
      '500': {'60': 260, '75': 310, '90': 350}, '600': {'60': 285, '75': 340, '90': 385}, '700': {'60': 310, '75': 375, '90': 420}, '750': {'60': 320, '75': 385, '90': 435},
      '800': {'60': 330, '75': 395, '90': 450}, '900': {'60': 355, '75': 425, '90': 480}, '1000': {'60': 375, '75': 445, '90': 500},
    },
  };
  static const List<String> _wireSizes = ['1/0', '2/0', '3/0', '4/0', '250', '300', '350', '400', '500', '600', '700', '750', '800', '900', '1000'];

  void _calculate() {
    final loadAmps = double.tryParse(_loadAmpsController.text);
    if (loadAmps == null || loadAmps <= 0) { setState(() => _result = null); return; }
    final singleAmpacity = _ampacityTable[_material]?[_wireSize]?[_tempRating] ?? 0;
    final totalAmpacity = singleAmpacity * _setsCount;
    final ampsPerSet = loadAmps / _setsCount;
    final utilizationPercent = (loadAmps / totalAmpacity) * 100;
    final meetsMinSize = _wireSizes.indexOf(_wireSize) >= 0;
    final meetsLoadRequirement = totalAmpacity >= loadAmps;
    setState(() => _result = {'loadAmps': loadAmps, 'singleAmpacity': singleAmpacity, 'totalAmpacity': totalAmpacity, 'ampsPerSet': ampsPerSet, 'utilizationPercent': utilizationPercent, 'setsCount': _setsCount, 'wireSize': _wireSize, 'meetsMinSize': meetsMinSize, 'meetsLoadRequirement': meetsLoadRequirement, 'compliant': meetsMinSize && meetsLoadRequirement});
  }

  @override
  void dispose() { _loadAmpsController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Parallel Conductors', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: () { _loadAmpsController.clear(); setState(() => _result = null); })],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildInputCard(colors),
        const SizedBox(height: 16),
        _buildWireSelectionCard(colors),
        const SizedBox(height: 16),
        _buildSetsCard(colors),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CALCULATE', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1))),
        const SizedBox(height: 20),
        if (_result != null) _buildResults(colors),
        const SizedBox(height: 16),
        _buildNecInfo(colors),
      ]),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total Load', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        TextField(controller: _loadAmpsController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: 'Enter load', hintStyle: TextStyle(color: colors.textTertiary), suffixText: 'Amps', suffixStyle: TextStyle(color: colors.textTertiary), filled: true, fillColor: colors.bgBase, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
      ]),
    );
  }

  Widget _buildWireSelectionCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Conductor Selection', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildToggle(colors, 'Copper', _material == 'Copper', () => setState(() => _material = 'Copper'))),
          const SizedBox(width: 8),
          Expanded(child: _buildToggle(colors, 'Aluminum', _material == 'Aluminum', () => setState(() => _material = 'Aluminum'))),
        ]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)), child: DropdownButton<String>(value: _wireSize, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary), items: _wireSizes.map((size) => DropdownMenuItem(value: size, child: Text(int.tryParse(size) != null ? '$size kcmil' : '$size AWG'))).toList(), onChanged: (v) => setState(() => _wireSize = v!))),
        const SizedBox(height: 12),
        Row(children: ['60', '75', '90'].map((t) => Expanded(child: Padding(padding: EdgeInsets.only(right: t != '90' ? 8 : 0), child: _buildToggle(colors, '$t°C', _tempRating == t, () => setState(() => _tempRating = t))))).toList()),
      ]),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)), child: Center(child: Text(label, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)))),
    );
  }

  Widget _buildSetsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Number of Parallel Sets', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          IconButton(onPressed: _setsCount > 2 ? () => setState(() => _setsCount--) : null, icon: Icon(LucideIcons.minusCircle, color: _setsCount > 2 ? colors.accentPrimary : colors.textTertiary)),
          Expanded(child: Center(child: Text('$_setsCount sets', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)))),
          IconButton(onPressed: _setsCount < 10 ? () => setState(() => _setsCount++) : null, icon: Icon(LucideIcons.plusCircle, color: _setsCount < 10 ? colors.accentPrimary : colors.textTertiary)),
        ]),
        Center(child: Text('(${_setsCount * 3} conductors total for 3-phase)', style: TextStyle(color: colors.textTertiary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    final r = _result!;
    final compliant = r['compliant'] as bool;
    final statusColor = compliant ? colors.accentSuccess : colors.accentError;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(compliant ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor), const SizedBox(width: 10), Text(compliant ? 'NEC Compliant' : 'Does Not Meet Requirements', style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 15))]),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Load Current', '${r['loadAmps'].toStringAsFixed(1)} A'),
        _buildResultRow(colors, 'Sets', '${r['setsCount']} parallel sets'),
        _buildResultRow(colors, 'Current Per Set', '${r['ampsPerSet'].toStringAsFixed(1)} A'),
        Divider(color: colors.borderSubtle, height: 24),
        _buildResultRow(colors, 'Single Conductor Ampacity', '${r['singleAmpacity']} A'),
        _buildResultRow(colors, 'Total Ampacity', '${r['totalAmpacity']} A', highlight: true),
        _buildResultRow(colors, 'Utilization', '${r['utilizationPercent'].toStringAsFixed(1)}%'),
        if (!r['meetsLoadRequirement']) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(LucideIcons.alertCircle, color: colors.accentError, size: 18), const SizedBox(width: 8), Expanded(child: Text('Total ampacity (${r['totalAmpacity']} A) is less than load (${r['loadAmps'].toStringAsFixed(0)} A)', style: TextStyle(color: colors.accentError, fontSize: 12)))])),
        ],
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text(value, style: TextStyle(fontWeight: highlight ? FontWeight.w700 : FontWeight.w500, fontSize: highlight ? 16 : 14, color: highlight ? colors.accentPrimary : colors.textPrimary))]));

  Widget _buildNecInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.info, color: colors.accentInfo, size: 18), const SizedBox(width: 8), Text('NEC 310.10(G) Requirements', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.w600, fontSize: 13))]),
        const SizedBox(height: 10),
        Text('• Minimum size: 1/0 AWG (copper or aluminum)\n• All conductors must be same length\n• All conductors must be same material\n• All conductors must be same size\n• All conductors must be same insulation type\n• All conductors must be terminated the same way', style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5)),
      ]),
    );
  }
}
