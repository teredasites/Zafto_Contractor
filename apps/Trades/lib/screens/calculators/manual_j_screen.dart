import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Manual J Residential Calculator - Design System v2.6
/// ACCA Manual J heating and cooling load calculation
class ManualJScreen extends ConsumerStatefulWidget {
  const ManualJScreen({super.key});
  @override
  ConsumerState<ManualJScreen> createState() => _ManualJScreenState();
}

class _ManualJScreenState extends ConsumerState<ManualJScreen> {
  double _squareFeet = 2000;
  double _ceilingHeight = 9;
  int _outdoorDesignHeat = 10;
  int _outdoorDesignCool = 95;
  int _indoorTemp = 70;
  String _climateZone = 'zone4';
  String _insulation = 'average';
  int _windows = 12;
  int _occupants = 4;

  double? _heatingLoad;
  double? _coolingLoad;
  double? _heatingTons;
  double? _coolingTons;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final volume = _squareFeet * _ceilingHeight;

    // Insulation factor
    double insulationFactor;
    if (_insulation == 'poor') {
      insulationFactor = 1.4;
    } else if (_insulation == 'average') {
      insulationFactor = 1.0;
    } else {
      insulationFactor = 0.7;
    }

    // Climate zone factor
    double climateFactor;
    switch (_climateZone) {
      case 'zone1': climateFactor = 0.7; break;
      case 'zone2': climateFactor = 0.8; break;
      case 'zone3': climateFactor = 0.9; break;
      case 'zone4': climateFactor = 1.0; break;
      case 'zone5': climateFactor = 1.1; break;
      case 'zone6': climateFactor = 1.2; break;
      case 'zone7': climateFactor = 1.3; break;
      default: climateFactor = 1.0;
    }

    // Heating load (simplified Manual J)
    final heatingDeltaT = _indoorTemp - _outdoorDesignHeat;
    final baseHeatingBtu = volume * 0.133 * heatingDeltaT;
    final windowHeatLoss = _windows * 150 * heatingDeltaT / 50;
    final infiltrationHeat = volume * 0.018 * heatingDeltaT;
    final totalHeating = (baseHeatingBtu + windowHeatLoss + infiltrationHeat) * insulationFactor * climateFactor;

    // Cooling load (simplified Manual J)
    final coolingDeltaT = _outdoorDesignCool - _indoorTemp;
    final baseCoolingBtu = volume * 0.133 * coolingDeltaT;
    final solarGain = _windows * 200; // BTU per window
    final internalGain = _occupants * 400 + (_squareFeet * 1); // people + equipment
    final infiltrationCool = volume * 0.018 * coolingDeltaT;
    final totalCooling = (baseCoolingBtu + solarGain + internalGain + infiltrationCool) * insulationFactor;

    final heatingTons = totalHeating / 12000;
    final coolingTons = totalCooling / 12000;

    String recommendation;
    if (coolingTons < heatingTons) {
      recommendation = 'Heating dominant climate. Consider heat pump with auxiliary heat or gas furnace with A/C.';
    } else {
      recommendation = 'Cooling dominant climate. Standard A/C or heat pump will work well.';
    }

    if (coolingTons > 5) {
      recommendation += ' System over 5 tons - consider zoning or multiple systems.';
    }

    setState(() {
      _heatingLoad = totalHeating;
      _coolingLoad = totalCooling;
      _heatingTons = heatingTons;
      _coolingTons = coolingTons;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _squareFeet = 2000;
      _ceilingHeight = 9;
      _outdoorDesignHeat = 10;
      _outdoorDesignCool = 95;
      _indoorTemp = 70;
      _climateZone = 'zone4';
      _insulation = 'average';
      _windows = 12;
      _occupants = 4;
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
        title: Text('Manual J Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING ENVELOPE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Square Footage', value: _squareFeet, min: 500, max: 6000, unit: ' sq ft', onChanged: (v) { setState(() => _squareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 8, max: 14, unit: ' ft', decimals: 1, onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Windows', value: _windows.toDouble(), min: 4, max: 30, unit: '', isInt: true, onChanged: (v) { setState(() => _windows = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Insulation Quality', options: const ['Poor', 'Average', 'Good'], selectedIndex: ['poor', 'average', 'good'].indexOf(_insulation), onChanged: (i) { setState(() => _insulation = ['poor', 'average', 'good'][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DESIGN CONDITIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor Design Heat', value: _outdoorDesignHeat.toDouble(), min: -20, max: 40, unit: '\u00B0F', isInt: true, onChanged: (v) { setState(() => _outdoorDesignHeat = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor Design Cool', value: _outdoorDesignCool.toDouble(), min: 80, max: 115, unit: '\u00B0F', isInt: true, onChanged: (v) { setState(() => _outdoorDesignCool = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Occupants', value: _occupants.toDouble(), min: 1, max: 10, unit: '', isInt: true, onChanged: (v) { setState(() => _occupants = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'LOAD CALCULATION'),
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
        Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('ACCA Manual J simplified load calculation. For permit work, use full Manual J software.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_heatingLoad == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Column(children: [
                Icon(LucideIcons.flame, color: Colors.orange, size: 24),
                const SizedBox(height: 8),
                Text('${(_heatingLoad! / 1000).toStringAsFixed(0)}k', style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
                Text('BTU Heating', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Text('${_heatingTons?.toStringAsFixed(1)} tons', style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(width: 1, height: 100, color: colors.borderDefault),
            Expanded(
              child: Column(children: [
                Icon(LucideIcons.snowflake, color: Colors.blue, size: 24),
                const SizedBox(height: 8),
                Text('${(_coolingLoad! / 1000).toStringAsFixed(0)}k', style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
                Text('BTU Cooling', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Text('${_coolingTons?.toStringAsFixed(1)} tons', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
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
}
