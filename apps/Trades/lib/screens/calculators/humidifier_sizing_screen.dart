import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Humidifier Sizing Calculator - Design System v2.6
/// Whole-house and commercial humidifier capacity
class HumidifierSizingScreen extends ConsumerStatefulWidget {
  const HumidifierSizingScreen({super.key});
  @override
  ConsumerState<HumidifierSizingScreen> createState() => _HumidifierSizingScreenState();
}

class _HumidifierSizingScreenState extends ConsumerState<HumidifierSizingScreen> {
  double _squareFeet = 2500;
  double _ceilingHeight = 9;
  double _outdoorTemp = 20;
  double _targetRh = 35;
  String _construction = 'average';
  String _humidifierType = 'bypass';
  bool _hasFurnace = true;

  double? _cubicFeet;
  double? _gallonsPerDay;
  double? _airChanges;
  String? _recommendedUnit;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final volume = _squareFeet * _ceilingHeight;

    // Air changes based on construction tightness
    double airChanges;
    switch (_construction) {
      case 'tight': airChanges = 0.35; break;
      case 'average': airChanges = 0.5; break;
      case 'loose': airChanges = 0.75; break;
      default: airChanges = 0.5;
    }

    // Moisture needed (gallons per day)
    // Based on ASHRAE and AHRI standards
    // GPD = (Volume × ACH × ΔGrains) / 7000 / 8.33

    // Outdoor grains at design temp (very low in winter)
    double outdoorGrains;
    if (_outdoorTemp <= 0) {
      outdoorGrains = 4;
    } else if (_outdoorTemp <= 20) {
      outdoorGrains = 8;
    } else if (_outdoorTemp <= 40) {
      outdoorGrains = 20;
    } else {
      outdoorGrains = 40;
    }

    // Indoor grains at target RH (at 70°F)
    final indoorGrains = _targetRh * 1.1; // Approximate

    // Moisture differential
    final deltaGrains = indoorGrains - outdoorGrains;

    // Gallons per day
    final cfh = volume * airChanges;
    final gallonsPerDay = (cfh * 24 * deltaGrains) / 7000 / 8.33;

    // Size recommendation
    String recommendedUnit;
    if (gallonsPerDay <= 12) {
      recommendedUnit = '12 GPD Bypass';
    } else if (gallonsPerDay <= 17) {
      recommendedUnit = '17 GPD Bypass/Fan';
    } else if (gallonsPerDay <= 25) {
      recommendedUnit = '25 GPD Power';
    } else if (gallonsPerDay <= 34) {
      recommendedUnit = '34 GPD Power';
    } else {
      recommendedUnit = 'Steam Humidifier';
    }

    String recommendation;
    if (_humidifierType == 'bypass') {
      recommendation = 'Bypass humidifier: Uses furnace blower. Install on supply or return plenum. Requires 6" bypass duct.';
    } else if (_humidifierType == 'fan') {
      recommendation = 'Fan-powered: Independent operation. Can run without furnace. Better for heat pumps.';
    } else {
      recommendation = 'Steam humidifier: Best capacity and control. No water waste. Higher cost.';
    }

    if (!_hasFurnace) {
      recommendation += ' No furnace: Fan-powered or steam type required.';
    }

    if (_targetRh > 40) {
      recommendation += ' High RH target: Monitor for window condensation. May need vapor barrier.';
    }

    if (_outdoorTemp < 10) {
      recommendation += ' Very cold climate: Reduce RH to prevent condensation on cold surfaces.';
    }

    setState(() {
      _cubicFeet = volume;
      _gallonsPerDay = gallonsPerDay;
      _airChanges = airChanges;
      _recommendedUnit = recommendedUnit;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _squareFeet = 2500;
      _ceilingHeight = 9;
      _outdoorTemp = 20;
      _targetRh = 35;
      _construction = 'average';
      _humidifierType = 'bypass';
      _hasFurnace = true;
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
        title: Text('Humidifier Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'HOME'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Floor Area', value: _squareFeet, min: 500, max: 5000, unit: ' sq ft', onChanged: (v) { setState(() => _squareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 7, max: 12, unit: ' ft', onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Outdoor Temp', _outdoorTemp, -20, 50, '°F', (v) { setState(() => _outdoorTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Target RH', _targetRh, 25, 50, '%', (v) { setState(() => _targetRh = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildConstructionSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HUMIDIFIER TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Has furnace with blower', _hasFurnace, (v) { setState(() => _hasFurnace = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'HUMIDIFIER SIZING'),
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
        Icon(LucideIcons.droplets, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Humidifier sizing based on home volume, air changes, and outdoor temp. Target 30-40% RH in winter.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildConstructionSelector(ZaftoColors colors) {
    final levels = [('tight', 'Tight'), ('average', 'Average'), ('loose', 'Loose')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Construction', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: levels.map((l) {
            final selected = _construction == l.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _construction = l.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: l != levels.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(l.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = [
      ('bypass', 'Bypass'),
      ('fan', 'Fan-Powered'),
      ('steam', 'Steam'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _humidifierType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _humidifierType = t.$1); _calculate(); },
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

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderDefault, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
      ),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
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
    if (_gallonsPerDay == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_gallonsPerDay?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('Gallons Per Day Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_recommendedUnit ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Volume', '${(_cubicFeet! / 1000).toStringAsFixed(1)}k cu ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'ACH', '${_airChanges?.toStringAsFixed(2)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Target', '${_targetRh.toStringAsFixed(0)}% RH')),
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
