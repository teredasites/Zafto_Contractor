import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Heat Pump Sizing Calculator - Design System v2.6
/// Air-source heat pump heating and cooling capacity
class HeatPumpSizingScreen extends ConsumerStatefulWidget {
  const HeatPumpSizingScreen({super.key});
  @override
  ConsumerState<HeatPumpSizingScreen> createState() => _HeatPumpSizingScreenState();
}

class _HeatPumpSizingScreenState extends ConsumerState<HeatPumpSizingScreen> {
  double _coolingLoad = 36000;
  double _heatingLoad = 48000;
  int _designTemp = 20;
  String _heatPumpType = 'standard';
  bool _hasAuxHeat = true;

  double? _coolingTons;
  double? _heatingCapacity47;
  double? _heatingCapacity17;
  double? _auxHeatNeeded;
  String? _recommendedSize;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final coolingTons = _coolingLoad / 12000;

    // Heat pump capacity derates at low temps
    // At 47°F: rated capacity
    // At 17°F: roughly 60-75% of rated
    // At 0°F: roughly 40-50% of rated (cold climate units better)
    double lowTempFactor;
    if (_heatPumpType == 'standard') {
      if (_designTemp >= 30) {
        lowTempFactor = 0.85;
      } else if (_designTemp >= 17) {
        lowTempFactor = 0.70;
      } else if (_designTemp >= 0) {
        lowTempFactor = 0.50;
      } else {
        lowTempFactor = 0.35;
      }
    } else { // cold climate
      if (_designTemp >= 30) {
        lowTempFactor = 0.90;
      } else if (_designTemp >= 17) {
        lowTempFactor = 0.80;
      } else if (_designTemp >= 0) {
        lowTempFactor = 0.65;
      } else {
        lowTempFactor = 0.50;
      }
    }

    // Size based on cooling load (avoid oversizing for humidity)
    final nominalCapacity = coolingTons * 12000;

    // Heating capacity at different temps
    final heating47 = nominalCapacity * 1.0;
    final heatingDesign = nominalCapacity * lowTempFactor;

    // Auxiliary heat needed
    final auxNeeded = _heatingLoad - heatingDesign;

    // Recommended size
    String recommendedSize;
    if (coolingTons <= 1.75) {
      recommendedSize = '1.5 Ton Heat Pump';
    } else if (coolingTons <= 2.25) {
      recommendedSize = '2 Ton Heat Pump';
    } else if (coolingTons <= 2.75) {
      recommendedSize = '2.5 Ton Heat Pump';
    } else if (coolingTons <= 3.25) {
      recommendedSize = '3 Ton Heat Pump';
    } else if (coolingTons <= 3.75) {
      recommendedSize = '3.5 Ton Heat Pump';
    } else if (coolingTons <= 4.25) {
      recommendedSize = '4 Ton Heat Pump';
    } else {
      recommendedSize = '5 Ton Heat Pump';
    }

    String recommendation;
    if (auxNeeded > 0 && _hasAuxHeat) {
      recommendation = 'Auxiliary heat of ${(auxNeeded / 1000).toStringAsFixed(0)}k BTU needed. Electric strips or gas backup.';
    } else if (auxNeeded > 0 && !_hasAuxHeat) {
      recommendation = 'Heat pump undersized for heating. Consider cold climate model or add backup heat.';
    } else {
      recommendation = 'Heat pump covers full heating load at design temp. Aux heat optional for emergencies.';
    }

    if (_heatPumpType == 'coldclimate') {
      recommendation += ' Cold climate models maintain capacity better below 17°F.';
    }

    setState(() {
      _coolingTons = coolingTons;
      _heatingCapacity47 = heating47;
      _heatingCapacity17 = heatingDesign;
      _auxHeatNeeded = auxNeeded > 0 ? auxNeeded : 0;
      _recommendedSize = recommendedSize;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coolingLoad = 36000;
      _heatingLoad = 48000;
      _designTemp = 20;
      _heatPumpType = 'standard';
      _hasAuxHeat = true;
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
        title: Text('Heat Pump Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Cooling Load', value: _coolingLoad, min: 12000, max: 100000, unit: ' BTU', onChanged: (v) { setState(() => _coolingLoad = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heating Load', value: _heatingLoad, min: 12000, max: 120000, unit: ' BTU', onChanged: (v) { setState(() => _heatingLoad = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DESIGN CONDITIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor Design Temp', value: _designTemp.toDouble(), min: -20, max: 40, unit: '\u00B0F', isInt: true, onChanged: (v) { setState(() => _designTemp = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Heat Pump Type', options: const ['Standard', 'Cold Climate'], selectedIndex: _heatPumpType == 'standard' ? 0 : 1, onChanged: (i) { setState(() => _heatPumpType = i == 0 ? 'standard' : 'coldclimate'); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, label: 'Include Auxiliary Heat', value: _hasAuxHeat, onChanged: (v) { setState(() => _hasAuxHeat = v ?? true); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'HEAT PUMP SIZING'),
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
        Expanded(child: Text('Size for cooling load, verify heating capacity. Heat pump capacity drops in cold weather - may need aux heat.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, required ValueChanged<double> onChanged}) {
    final displayValue = unit == ' BTU' ? '${(value / 1000).toStringAsFixed(0)}k$unit' : (isInt ? '${value.round()}$unit' : '${value.toStringAsFixed(0)}$unit');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(displayValue, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                  ),
                ),
              );
            }).toList(),
          ),
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
    if (_coolingTons == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_recommendedSize ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          Text('(${_coolingTons?.toStringAsFixed(1)} tons nominal)', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.snowflake, color: Colors.blue, size: 20),
                  const SizedBox(height: 4),
                  Text('Cooling', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  Text('${(_coolingLoad / 1000).toStringAsFixed(0)}k BTU', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.flame, color: Colors.orange, size: 20),
                  const SizedBox(height: 4),
                  Text('@ 47\u00B0F', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  Text('${(_heatingCapacity47! / 1000).toStringAsFixed(0)}k BTU', style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.thermometerSnowflake, color: Colors.red, size: 20),
                  const SizedBox(height: 4),
                  Text('@ ${_designTemp}\u00B0F', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  Text('${(_heatingCapacity17! / 1000).toStringAsFixed(0)}k BTU', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          if (_auxHeatNeeded! > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(LucideIcons.zap, color: colors.accentWarning, size: 18),
                const SizedBox(width: 8),
                Text('Aux Heat: ${(_auxHeatNeeded! / 1000).toStringAsFixed(0)}k BTU', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
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
}
