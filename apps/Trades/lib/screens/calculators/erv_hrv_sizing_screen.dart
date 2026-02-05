import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ERV/HRV Sizing Calculator - Design System v2.6
/// Energy/Heat recovery ventilator selection
class ErvHrvSizingScreen extends ConsumerStatefulWidget {
  const ErvHrvSizingScreen({super.key});
  @override
  ConsumerState<ErvHrvSizingScreen> createState() => _ErvHrvSizingScreenState();
}

class _ErvHrvSizingScreenState extends ConsumerState<ErvHrvSizingScreen> {
  double _squareFeet = 2000;
  int _bedrooms = 3;
  int _bathrooms = 2;
  double _occupants = 4;
  String _climate = 'cold';
  String _tightness = 'tight';

  double? _ashrae622Cfm;
  double? _recommendedCfm;
  String? _unitType;
  double? _sensibleEfficiency;
  double? _annualSavings;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // ASHRAE 62.2-2019 calculation
    // Qtot = 0.03 × Afloor + 7.5 × (Nbr + 1)
    final ashraeCfm = 0.03 * _squareFeet + 7.5 * (_bedrooms + 1);

    // Additional for tight homes (infiltration credit reduced)
    double tightnessFactor;
    switch (_tightness) {
      case 'leaky': tightnessFactor = 0.7; break; // Less mechanical ventilation needed
      case 'average': tightnessFactor = 0.85; break;
      case 'tight': tightnessFactor = 1.0; break;
      case 'passive': tightnessFactor = 1.15; break; // Need more for passive house
      default: tightnessFactor = 1.0;
    }

    final recommendedCfm = ashraeCfm * tightnessFactor;

    // Unit type recommendation
    String unitType;
    double sensibleEff;
    if (_climate == 'cold' || _climate == 'verycold') {
      unitType = 'HRV (Heat Recovery Ventilator)';
      sensibleEff = 0.75; // Typical HRV efficiency
    } else if (_climate == 'hot' || _climate == 'mixed') {
      unitType = 'ERV (Energy Recovery Ventilator)';
      sensibleEff = 0.70; // ERV recovers latent too
    } else {
      unitType = 'ERV or HRV';
      sensibleEff = 0.72;
    }

    // Estimate annual energy savings (rough)
    // Assuming 4000 HDD or CDD, $0.12/kWh equivalent
    double hddCdd;
    switch (_climate) {
      case 'verycold': hddCdd = 8000; break;
      case 'cold': hddCdd = 5500; break;
      case 'mixed': hddCdd = 4000; break;
      case 'hot': hddCdd = 3000; break;
      default: hddCdd = 4000;
    }

    // Energy saved = CFM × 1.08 × ΔT × hours × efficiency × cost
    // Simplified: ~$0.15 per CFM per 1000 HDD/CDD with recovery
    final annualSavings = recommendedCfm * sensibleEff * (hddCdd / 1000) * 0.15;

    String recommendation;
    if (_climate == 'cold' || _climate == 'verycold') {
      recommendation = 'Cold climate: HRV preferred. Recovers sensible heat without transferring moisture that could freeze.';
    } else if (_climate == 'hot') {
      recommendation = 'Hot/humid climate: ERV preferred. Recovers both heat and moisture to reduce A/C load.';
    } else {
      recommendation = 'Mixed climate: ERV provides year-round benefits. Some prefer HRV for summer humidity control.';
    }

    if (_tightness == 'passive') {
      recommendation += ' Passive house: ERV/HRV is essential and primary ventilation source.';
    }

    setState(() {
      _ashrae622Cfm = ashraeCfm;
      _recommendedCfm = recommendedCfm;
      _unitType = unitType;
      _sensibleEfficiency = sensibleEff * 100;
      _annualSavings = annualSavings;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _squareFeet = 2000;
      _bedrooms = 3;
      _bathrooms = 2;
      _occupants = 4;
      _climate = 'cold';
      _tightness = 'tight';
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
        title: Text('ERV/HRV Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'HOME DETAILS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Floor Area', value: _squareFeet, min: 500, max: 5000, unit: ' sq ft', onChanged: (v) { setState(() => _squareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildStepperInput(colors, label: 'Bedrooms', value: _bedrooms, min: 1, max: 8, onChanged: (v) { setState(() => _bedrooms = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildStepperInput(colors, label: 'Bathrooms', value: _bathrooms, min: 1, max: 6, onChanged: (v) { setState(() => _bathrooms = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BUILDING & CLIMATE'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Climate Zone', options: const ['Very Cold', 'Cold', 'Mixed', 'Hot'], selectedIndex: ['verycold', 'cold', 'mixed', 'hot'].indexOf(_climate), onChanged: (i) { setState(() => _climate = ['verycold', 'cold', 'mixed', 'hot'][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Air Tightness', options: const ['Leaky', 'Average', 'Tight', 'Passive'], selectedIndex: ['leaky', 'average', 'tight', 'passive'].indexOf(_tightness), onChanged: (i) { setState(() => _tightness = ['leaky', 'average', 'tight', 'passive'][i]); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'VENTILATOR SIZING'),
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
        Icon(LucideIcons.refreshCw, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('ERV/HRV provides fresh air while recovering energy. Size per ASHRAE 62.2. HRV for cold, ERV for humid climates.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
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

  Widget _buildStepperInput(ZaftoColors colors, {required String label, required int value, required int min, required int max, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GestureDetector(
              onTap: value > min ? () => onChanged(value - 1) : null,
              child: Icon(LucideIcons.minus, color: value > min ? colors.accentPrimary : colors.textSecondary.withValues(alpha: 0.3), size: 20),
            ),
            Text('$value', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: value < max ? () => onChanged(value + 1) : null,
              child: Icon(LucideIcons.plus, color: value < max ? colors.accentPrimary : colors.textSecondary.withValues(alpha: 0.3), size: 20),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_recommendedCfm == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_recommendedCfm?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('CFM Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text(_unitType ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'ASHRAE 62.2', '${_ashrae622Cfm?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Efficiency', '${_sensibleEfficiency?.toStringAsFixed(0)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Est. Savings', '\$${_annualSavings?.toStringAsFixed(0)}/yr')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.lightbulb, color: colors.accentWarning, size: 16),
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
