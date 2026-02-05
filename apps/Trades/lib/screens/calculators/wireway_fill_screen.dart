import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Wireway Fill Calculator - Design System v2.6
/// NEC 376.22 - 20% fill for conductors at any cross section
class WirewayFillScreen extends ConsumerStatefulWidget {
  const WirewayFillScreen({super.key});
  @override
  ConsumerState<WirewayFillScreen> createState() => _WirewayFillScreenState();
}

class _WirewayFillScreenState extends ConsumerState<WirewayFillScreen> {
  String _wirewaySize = '4x4';
  final List<_ConductorEntry> _conductors = [
    _ConductorEntry(size: '10', count: 6),
    _ConductorEntry(size: '12', count: 8),
  ];

  double? _wirewayArea;
  double? _maxFillArea;
  double? _conductorArea;
  double? _fillPercent;
  bool? _isCompliant;

  final _wirewaySizes = {
    '2.5x2.5': 6.25,
    '4x4': 16.0,
    '6x6': 36.0,
    '8x8': 64.0,
    '10x10': 100.0,
    '12x12': 144.0,
  };

  final _conductorAreas = {
    '14': 0.0097,
    '12': 0.0133,
    '10': 0.0211,
    '8': 0.0366,
    '6': 0.0507,
    '4': 0.0824,
    '3': 0.0973,
    '2': 0.1158,
    '1': 0.1562,
    '1/0': 0.1855,
    '2/0': 0.2223,
    '3/0': 0.2679,
    '4/0': 0.3237,
    '250': 0.3970,
    '300': 0.4608,
    '350': 0.5242,
    '400': 0.5863,
    '500': 0.7073,
  };

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wireway Fill', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WIREWAY SIZE'),
              const SizedBox(height: 12),
              _buildWirewaySizeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDUCTORS'),
              const SizedBox(height: 12),
              ..._conductors.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildConductorRow(colors, e.key),
              )),
              _buildAddConductorButton(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FILL CALCULATION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('NEC 376.22 - Max 20% fill at any cross section', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildWirewaySizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _wirewaySizes.keys.map((size) => GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _wirewaySize = size); _calculate(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _wirewaySize == size ? colors.accentPrimary : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _wirewaySize == size ? colors.accentPrimary : colors.borderSubtle),
          ),
          child: Text('$size"', style: TextStyle(
            color: _wirewaySize == size ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          )),
        ),
      )).toList(),
    );
  }

  Widget _buildConductorRow(ZaftoColors colors, int index) {
    final entry = _conductors[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(
          child: DropdownButton<String>(
            value: entry.size,
            dropdownColor: colors.bgElevated,
            underline: const SizedBox(),
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            items: _conductorAreas.keys.map((s) => DropdownMenuItem(value: s, child: Text('$s AWG'))).toList(),
            onChanged: (v) { setState(() => entry.size = v!); _calculate(); },
          ),
        ),
        const SizedBox(width: 16),
        Text('Qty:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderSubtle)),
            ),
            controller: TextEditingController(text: entry.count.toString()),
            onChanged: (v) { entry.count = int.tryParse(v) ?? 0; _calculate(); },
          ),
        ),
        const SizedBox(width: 8),
        if (_conductors.length > 1) IconButton(
          icon: Icon(LucideIcons.trash2, color: colors.error, size: 20),
          onPressed: () { setState(() => _conductors.removeAt(index)); _calculate(); },
        ),
      ]),
    );
  }

  Widget _buildAddConductorButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: () { setState(() => _conductors.add(_ConductorEntry(size: '12', count: 1))); _calculate(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle, style: BorderStyle.solid)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.plus, color: colors.accentPrimary, size: 20),
          const SizedBox(width: 8),
          Text('Add Conductor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final compliant = _isCompliant ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: compliant ? colors.accentPrimary.withValues(alpha: 0.3) : colors.error.withValues(alpha: 0.5), width: 1.5)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(compliant ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: compliant ? colors.accentPrimary : colors.error, size: 24),
          const SizedBox(width: 8),
          Text(compliant ? 'COMPLIANT' : 'EXCEEDS 20%', style: TextStyle(color: compliant ? colors.accentPrimary : colors.error, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 16),
        Text('${_fillPercent?.toStringAsFixed(1) ?? '0'}%', style: TextStyle(color: compliant ? colors.accentPrimary : colors.error, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('fill percentage', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Wireway area ($_wirewaySize")', '${_wirewayArea?.toStringAsFixed(2) ?? '0'} sq in'),
        _buildCalcRow(colors, 'Max fill area (20%)', '${_maxFillArea?.toStringAsFixed(2) ?? '0'} sq in'),
        _buildCalcRow(colors, 'Conductor area', '${_conductorArea?.toStringAsFixed(3) ?? '0'} sq in'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Fill percentage', '${_fillPercent?.toStringAsFixed(1) ?? '0'}%', highlight: true),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    final wwArea = _wirewaySizes[_wirewaySize] ?? 16.0;
    final maxFill = wwArea * 0.20;

    double totalCondArea = 0;
    for (final c in _conductors) {
      final area = _conductorAreas[c.size] ?? 0;
      totalCondArea += area * c.count;
    }

    final fillPct = (totalCondArea / wwArea) * 100;
    final compliant = fillPct <= 20;

    setState(() {
      _wirewayArea = wwArea;
      _maxFillArea = maxFill;
      _conductorArea = totalCondArea;
      _fillPercent = fillPct;
      _isCompliant = compliant;
    });
  }

  void _reset() {
    setState(() {
      _wirewaySize = '4x4';
      _conductors.clear();
      _conductors.addAll([
        _ConductorEntry(size: '10', count: 6),
        _ConductorEntry(size: '12', count: 8),
      ]);
    });
    _calculate();
  }
}

class _ConductorEntry {
  String size;
  int count;
  _ConductorEntry({required this.size, required this.count});
}
