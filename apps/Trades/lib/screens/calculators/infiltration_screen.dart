import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Infiltration Calculator - Design System v2.6
/// Air leakage BTU load calculation
class InfiltrationScreen extends ConsumerStatefulWidget {
  const InfiltrationScreen({super.key});
  @override
  ConsumerState<InfiltrationScreen> createState() => _InfiltrationScreenState();
}

class _InfiltrationScreenState extends ConsumerState<InfiltrationScreen> {
  double _squareFeet = 2000;
  double _ceilingHeight = 9;
  double _ach = 0.5;
  int _deltaT = 50;
  String _tightness = 'average';
  bool _includeLatent = true;

  double? _volumeCuFt;
  double? _cfmInfiltration;
  double? _sensibleBtu;
  double? _latentBtu;
  double? _totalBtu;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final volume = _squareFeet * _ceilingHeight;

    // ACH based on tightness
    double achActual;
    switch (_tightness) {
      case 'tight': achActual = 0.25; break;
      case 'average': achActual = 0.50; break;
      case 'loose': achActual = 0.75; break;
      case 'leaky': achActual = 1.0; break;
      default: achActual = _ach;
    }

    // CFM infiltration
    final cfm = (volume * achActual) / 60;

    // Sensible heat: Q = 1.08 × CFM × ΔT
    final sensible = 1.08 * cfm * _deltaT;

    // Latent heat (assume 20 grain difference summer): Q = 0.68 × CFM × Δgr
    final latent = _includeLatent ? 0.68 * cfm * 20 : 0.0;

    final total = sensible + latent;

    String recommendation;
    if (achActual <= 0.25) {
      recommendation = 'Very tight construction. May need mechanical ventilation (ERV/HRV) for IAQ.';
    } else if (achActual <= 0.5) {
      recommendation = 'Good air sealing. Meets Energy Star requirements.';
    } else if (achActual <= 0.75) {
      recommendation = 'Average tightness. Consider air sealing for energy savings.';
    } else {
      recommendation = 'High infiltration. Significant energy loss. Prioritize air sealing.';
    }

    setState(() {
      _volumeCuFt = volume;
      _cfmInfiltration = cfm;
      _sensibleBtu = sensible;
      _latentBtu = latent;
      _totalBtu = total;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _squareFeet = 2000;
      _ceilingHeight = 9;
      _ach = 0.5;
      _deltaT = 50;
      _tightness = 'average';
      _includeLatent = true;
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
        title: Text('Infiltration Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING VOLUME'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Conditioned Area', value: _squareFeet, min: 500, max: 6000, unit: ' sq ft', onChanged: (v) { setState(() => _squareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 8, max: 14, unit: ' ft', decimals: 1, onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIR TIGHTNESS'),
              const SizedBox(height: 12),
              _buildTightnessSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Custom ACH (Natural)', value: _ach, min: 0.1, max: 1.5, unit: ' ACH', decimals: 2, onChanged: (v) { setState(() { _ach = v; _tightness = 'custom'; }); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DESIGN CONDITIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Temperature Difference', value: _deltaT.toDouble(), min: 20, max: 80, unit: '\u00B0F', isInt: true, onChanged: (v) { setState(() => _deltaT = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, label: 'Include Latent Load (Summer)', value: _includeLatent, onChanged: (v) { setState(() => _includeLatent = v ?? true); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'INFILTRATION LOAD'),
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
        Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Calculate BTU load from air leakage. Tight homes: 0.25 ACH. Average: 0.50 ACH. Leaky: 1.0+ ACH.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildTightnessSelector(ZaftoColors colors) {
    final options = [
      ('tight', 'Tight', '0.25 ACH'),
      ('average', 'Average', '0.50 ACH'),
      ('loose', 'Loose', '0.75 ACH'),
      ('leaky', 'Leaky', '1.0 ACH'),
    ];
    return Row(
      children: options.map((o) {
        final selected = _tightness == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _tightness = o.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: o != options.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Text(o.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(o.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 10)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(isInt ? '${value.round()}$unit' : (decimals > 0 ? '${value.toStringAsFixed(decimals)}$unit' : '${value.round()}$unit'), style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildCheckboxRow(ZaftoColors colors, {required String label, required bool value, required ValueChanged<bool?> onChanged}) {
    return Row(children: [
      Checkbox(value: value, onChanged: onChanged, activeColor: colors.accentPrimary),
      Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
    ]);
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_totalBtu == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${(_totalBtu! / 1000).toStringAsFixed(1)}k', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('BTU/hr Infiltration Load', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Volume', '${_volumeCuFt?.toStringAsFixed(0)} cu ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Infiltration', '${_cfmInfiltration?.toStringAsFixed(0)} CFM')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Sensible', '${(_sensibleBtu! / 1000).toStringAsFixed(1)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Latent', '${(_latentBtu! / 1000).toStringAsFixed(1)}k BTU')),
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
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
