import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Pipe Expansion Calculator - Design System v2.6
/// Thermal expansion and expansion loop sizing
class PipeExpansionScreen extends ConsumerStatefulWidget {
  const PipeExpansionScreen({super.key});
  @override
  ConsumerState<PipeExpansionScreen> createState() => _PipeExpansionScreenState();
}

class _PipeExpansionScreenState extends ConsumerState<PipeExpansionScreen> {
  double _pipeLength = 100; // feet
  double _tempChange = 100; // degrees F
  double _pipeSize = 4; // inches
  String _pipeMaterial = 'steel';
  String _expansionType = 'loop';

  double? _expansion;
  double? _loopLength;
  double? _bellowsStroke;
  String? _recommendation;

  // Expansion coefficients (inches per 100 ft per 100°F)
  final Map<String, double> _expansionCoef = {
    'steel': 0.75,
    'copper': 1.12,
    'pvc': 3.0,
    'cpvc': 3.6,
    'stainless': 1.0,
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Expansion = L × C × ΔT / 100 / 100
    final coef = _expansionCoef[_pipeMaterial] ?? 0.75;
    final expansion = _pipeLength * coef * _tempChange / 100 / 100;

    // Expansion loop length: L = √(3 × expansion × pipe OD × 144)
    // Simplified for steel pipe
    final loopLength = 12 * 1.35 * expansion * 12 / _pipeSize;

    // Bellows stroke = 1.5 × expansion (safety factor)
    final bellowsStroke = expansion * 1.5;

    String recommendation;
    recommendation = 'Thermal expansion: ${expansion.toStringAsFixed(2)} inches over ${_pipeLength.toStringAsFixed(0)} ft at ${_tempChange.toStringAsFixed(0)}°F change. ';

    switch (_pipeMaterial) {
      case 'steel':
        recommendation += 'Steel: Low expansion. Expansion loops or bellows typically used.';
        break;
      case 'copper':
        recommendation += 'Copper: Moderate expansion. Use expansion loops or offsets.';
        break;
      case 'pvc':
      case 'cpvc':
        recommendation += 'Plastic: High expansion (4× steel). Expansion loops at max 50 ft intervals.';
        break;
      case 'stainless':
        recommendation += 'Stainless: Similar to steel. Consider stress analysis for high temp.';
        break;
    }

    switch (_expansionType) {
      case 'loop':
        recommendation += ' U-loop: ${loopLength.toStringAsFixed(1)} ft minimum leg length. Requires space but low maintenance.';
        break;
      case 'bellows':
        recommendation += ' Bellows: ${bellowsStroke.toStringAsFixed(2)}" rated stroke. Guide within 4 pipe diameters.';
        break;
      case 'slip':
        recommendation += ' Slip joint: Simple but requires maintenance. Use anchors and guides.';
        break;
    }

    if (expansion > 3) {
      recommendation += ' Large movement: Consider multiple expansion points. Verify anchor loads.';
    }

    recommendation += ' Install guides at 20× pipe diameter max spacing.';

    setState(() {
      _expansion = expansion;
      _loopLength = loopLength;
      _bellowsStroke = bellowsStroke;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _pipeLength = 100;
      _tempChange = 100;
      _pipeSize = 4;
      _pipeMaterial = 'steel';
      _expansionType = 'loop';
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pipe Expansion', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PIPE MATERIAL'),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 12),
              _buildExpansionTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PIPE DIMENSIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Length', _pipeLength, 10, 500, ' ft', (v) { setState(() => _pipeLength = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Size', _pipeSize, 0.5, 12, '"', (v) { setState(() => _pipeSize = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURE CHANGE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Delta T', value: _tempChange, min: 20, max: 300, unit: '°F', onChanged: (v) { setState(() => _tempChange = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EXPANSION REQUIREMENTS'),
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
        Icon(LucideIcons.arrowLeftRight, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Steel expands 0.75"/100ft/100°F. Plastic expands 3-4× more. Expansion must be accommodated or stress will damage piping.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = [('steel', 'Steel'), ('copper', 'Copper'), ('pvc', 'PVC'), ('cpvc', 'CPVC'), ('stainless', 'SS')];
    return Row(
      children: materials.map((m) {
        final selected = _pipeMaterial == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _pipeMaterial = m.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: m != materials.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpansionTypeSelector(ZaftoColors colors) {
    final types = [('loop', 'Expansion Loop'), ('bellows', 'Bellows'), ('slip', 'Slip Joint')];
    return Row(
      children: types.map((t) {
        final selected = _expansionType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _expansionType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_expansion == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_expansion?.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Total Expansion', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          if (_expansionType == 'loop')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text('${_loopLength?.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
                Text('Minimum Loop Leg', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text('${_bellowsStroke?.toStringAsFixed(2)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
                Text('Required Stroke', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Material', _pipeMaterial.toUpperCase())),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Length', '${_pipeLength.toStringAsFixed(0)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Delta T', '${_tempChange.toStringAsFixed(0)}°F')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
