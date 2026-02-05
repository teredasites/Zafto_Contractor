import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Raceway Selector - Design System v2.6
class ConductorEntry { String size; String type; int count; ConductorEntry({required this.size, required this.type, required this.count}); }

class RacewayScreen extends ConsumerStatefulWidget {
  const RacewayScreen({super.key});
  @override
  ConsumerState<RacewayScreen> createState() => _RacewayScreenState();
}

class _RacewayScreenState extends ConsumerState<RacewayScreen> {
  String _racewayType = 'EMT';
  final List<ConductorEntry> _conductors = [ConductorEntry(size: '12 AWG', type: 'THHN', count: 3)];
  Map<String, dynamic>? _results;

  static const Map<String, Map<String, double>> _racewayAreas = {
    'EMT': {'1/2': 0.304, '3/4': 0.533, '1': 0.864, '1-1/4': 1.496, '1-1/2': 2.036, '2': 3.356, '2-1/2': 5.858, '3': 8.846, '3-1/2': 11.545, '4': 14.753},
    'IMC': {'1/2': 0.342, '3/4': 0.586, '1': 0.959, '1-1/4': 1.647, '1-1/2': 2.225, '2': 3.630, '2-1/2': 5.135, '3': 7.922, '3-1/2': 10.584, '4': 13.631},
    'RMC': {'1/2': 0.314, '3/4': 0.533, '1': 0.864, '1-1/4': 1.496, '1-1/2': 2.036, '2': 3.356, '2-1/2': 4.866, '3': 7.499, '3-1/2': 10.010, '4': 12.882},
    'PVC Sch 40': {'1/2': 0.285, '3/4': 0.508, '1': 0.832, '1-1/4': 1.453, '1-1/2': 1.986, '2': 3.291, '2-1/2': 4.695, '3': 7.268, '3-1/2': 9.737, '4': 12.554},
    'PVC Sch 80': {'1/2': 0.217, '3/4': 0.409, '1': 0.688, '1-1/4': 1.237, '1-1/2': 1.711, '2': 2.874, '2-1/2': 4.119, '3': 6.442, '3-1/2': 8.688, '4': 11.258},
  };
  static const Map<String, Map<String, double>> _wireAreas = {
    'THHN': {'14 AWG': 0.0097, '12 AWG': 0.0133, '10 AWG': 0.0211, '8 AWG': 0.0366, '6 AWG': 0.0507, '4 AWG': 0.0824, '3 AWG': 0.0973, '2 AWG': 0.1158, '1 AWG': 0.1562, '1/0': 0.1855, '2/0': 0.2223, '3/0': 0.2679, '4/0': 0.3237, '250': 0.3970, '300': 0.4608, '350': 0.5242, '400': 0.5863, '500': 0.7073},
    'THWN': {'14 AWG': 0.0097, '12 AWG': 0.0133, '10 AWG': 0.0211, '8 AWG': 0.0366, '6 AWG': 0.0507, '4 AWG': 0.0824, '3 AWG': 0.0973, '2 AWG': 0.1158, '1 AWG': 0.1562, '1/0': 0.1855, '2/0': 0.2223, '3/0': 0.2679, '4/0': 0.3237, '250': 0.3970, '300': 0.4608, '350': 0.5242, '400': 0.5863, '500': 0.7073},
    'XHHW': {'14 AWG': 0.0097, '12 AWG': 0.0133, '10 AWG': 0.0211, '8 AWG': 0.0366, '6 AWG': 0.0507, '4 AWG': 0.0824, '3 AWG': 0.0973, '2 AWG': 0.1158, '1 AWG': 0.1562, '1/0': 0.1855, '2/0': 0.2223, '3/0': 0.2679, '4/0': 0.3237, '250': 0.3970, '300': 0.4608, '350': 0.5242, '400': 0.5863, '500': 0.7073},
    'TW': {'14 AWG': 0.0139, '12 AWG': 0.0181, '10 AWG': 0.0243, '8 AWG': 0.0437, '6 AWG': 0.0726, '4 AWG': 0.1087, '3 AWG': 0.1263, '2 AWG': 0.1473, '1 AWG': 0.1901, '1/0': 0.2223, '2/0': 0.2624, '3/0': 0.3117, '4/0': 0.3718},
  };

  void _calculate() {
    double totalArea = 0; int totalConductors = 0;
    for (final c in _conductors) { final wireArea = _wireAreas[c.type]?[c.size] ?? 0; totalArea += wireArea * c.count; totalConductors += c.count; }
    double maxFill = totalConductors == 1 ? 0.53 : (totalConductors == 2 ? 0.31 : 0.40);
    final racewayAreas = _racewayAreas[_racewayType] ?? {};
    String? selectedSize; double selectedFill = 0;
    for (final entry in racewayAreas.entries) { final allowedArea = entry.value * maxFill; if (totalArea <= allowedArea) { selectedSize = entry.key; selectedFill = (totalArea / entry.value) * 100; break; } }
    if (selectedSize == null) { _showError('Conductors exceed largest raceway size'); return; }
    setState(() => _results = {'size': selectedSize, 'fillPercent': selectedFill, 'totalArea': totalArea, 'maxFill': maxFill});
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: ref.read(zaftoColorsProvider).accentError));
  void _reset() => setState(() { _racewayType = 'EMT'; _conductors.clear(); _conductors.add(ConductorEntry(size: '12 AWG', type: 'THHN', count: 3)); _results = null; });

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Raceway Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset)],
      ),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildNecCard(colors),
        const SizedBox(height: 24),
        Text('RACEWAY TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRacewaySelector(colors),
        const SizedBox(height: 24),
        Text('CONDUCTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._conductors.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildConductorRow(colors, e.key, e.value))),
        TextButton.icon(onPressed: () => setState(() { _conductors.add(ConductorEntry(size: '12 AWG', type: 'THHN', count: 1)); _results = null; }), icon: Icon(LucideIcons.plus, color: colors.accentPrimary), label: Text('Add Conductor', style: TextStyle(color: colors.accentPrimary))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('SIZE RACEWAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
        const SizedBox(height: 24),
        if (_results != null) _buildResults(colors),
        const SizedBox(height: 24),
        _buildFillRulesCard(colors),
      ]))),
    );
  }

  Widget _buildNecCard(ZaftoColors colors) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)), child: Row(children: [
      Icon(LucideIcons.circle, color: colors.accentPrimary, size: 24), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NEC Chapter 9', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)), Text('Conduit & Wire Fill Tables', style: TextStyle(color: colors.textTertiary, fontSize: 12))])),
    ]));
  }

  Widget _buildRacewaySelector(ZaftoColors colors) {
    return Wrap(spacing: 8, runSpacing: 8, children: ['EMT', 'IMC', 'RMC', 'PVC Sch 40', 'PVC Sch 80'].map((t) {
      final sel = t == _racewayType;
      return GestureDetector(onTap: () { HapticFeedback.selectionClick(); setState(() { _racewayType = t; _results = null; }); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: sel ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? colors.accentPrimary : colors.borderSubtle)), child: Text(t, style: TextStyle(color: sel ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))));
    }).toList());
  }

  Widget _buildConductorRow(ZaftoColors colors, int idx, ConductorEntry entry) {
    final sizes = ['14 AWG', '12 AWG', '10 AWG', '8 AWG', '6 AWG', '4 AWG', '3 AWG', '2 AWG', '1 AWG', '1/0', '2/0', '3/0', '4/0', '250', '300', '350', '400', '500'];
    final types = ['THHN', 'THWN', 'XHHW', 'TW'];
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)), child: Row(children: [
      SizedBox(width: 50, child: DropdownButton<int>(value: entry.count, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600), items: List.generate(20, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(), onChanged: (v) => setState(() { _conductors[idx] = ConductorEntry(size: entry.size, type: entry.type, count: v!); _results = null; }))),
      Expanded(child: DropdownButton<String>(value: entry.size, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary, fontSize: 13), items: sizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() { _conductors[idx] = ConductorEntry(size: v!, type: entry.type, count: entry.count); _results = null; }))),
      SizedBox(width: 80, child: DropdownButton<String>(value: entry.type, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary, fontSize: 12), items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() { _conductors[idx] = ConductorEntry(size: entry.size, type: v!, count: entry.count); _results = null; }))),
      if (_conductors.length > 1) IconButton(icon: Icon(LucideIcons.x, color: colors.accentError, size: 20), onPressed: () => setState(() { _conductors.removeAt(idx); _results = null; })),
    ]));
  }

  Widget _buildResults(ZaftoColors colors) {
    final size = _results!['size'] as String; final fillPercent = _results!['fillPercent'] as double; final totalArea = _results!['totalArea'] as double; final maxFill = _results!['maxFill'] as double;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))), child: Column(children: [
      Icon(LucideIcons.circle, color: colors.accentSuccess, size: 32), const SizedBox(height: 12),
      Text('$size"', style: TextStyle(color: colors.accentSuccess, fontSize: 48, fontWeight: FontWeight.w700)),
      Text(_racewayType, style: TextStyle(color: colors.textTertiary, letterSpacing: 1)),
      const SizedBox(height: 20),
      _buildResultRow(colors, 'Fill', '${fillPercent.toStringAsFixed(1)}%'),
      const SizedBox(height: 8),
      _buildResultRow(colors, 'Total Wire Area', '${totalArea.toStringAsFixed(4)} sq in'),
      const SizedBox(height: 8),
      _buildResultRow(colors, 'Max Allowed Fill', '${(maxFill * 100).toStringAsFixed(0)}%'),
      const SizedBox(height: 16),
      Container(height: 12, decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(6)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: (fillPercent / 100).clamp(0, 1), child: Container(decoration: BoxDecoration(color: fillPercent <= 40 ? colors.accentSuccess : colors.accentWarning, borderRadius: BorderRadius.circular(6))))),
    ]));
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: colors.textSecondary)), Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))]));

  Widget _buildFillRulesCard(ZaftoColors colors) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FILL PERCENTAGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 12),
      _buildFillRow(colors, '1 Conductor', '53%'),
      _buildFillRow(colors, '2 Conductors', '31%'),
      _buildFillRow(colors, '3+ Conductors', '40%'),
    ]));
  }

  Widget _buildFillRow(ZaftoColors colors, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600))]));
}
