import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Building Pressure Calculator - Design System v2.6
/// Building pressurization and infiltration analysis
class BuildingPressureScreen extends ConsumerStatefulWidget {
  const BuildingPressureScreen({super.key});
  @override
  ConsumerState<BuildingPressureScreen> createState() => _BuildingPressureScreenState();
}

class _BuildingPressureScreenState extends ConsumerState<BuildingPressureScreen> {
  double _supplyCfm = 5000;
  double _returnCfm = 4500;
  double _exhaustCfm = 300;
  double _buildingHeight = 40; // feet
  double _outdoorTemp = 20; // degrees F
  double _indoorTemp = 72; // degrees F
  String _buildingType = 'office';

  double? _netPressure;
  double? _stackEffect;
  double? _windPressure;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Net airflow = Supply - Return - Exhaust
    final netCfm = _supplyCfm - _returnCfm - _exhaustCfm;

    // Positive pressure (simplified): depends on leakage area
    // Roughly 0.05" WC per 1% outdoor air differential
    final oaPercent = (netCfm / _supplyCfm) * 100;
    final netPressure = oaPercent * 0.005; // Very simplified

    // Stack effect pressure
    // ΔP = 0.52 × h × (1/To - 1/Ti) where temps in Rankine
    final toRankine = _outdoorTemp + 460;
    final tiRankine = _indoorTemp + 460;
    final stackEffect = 0.52 * _buildingHeight * ((1 / toRankine) - (1 / tiRankine)) * 10000;

    // Wind pressure estimate (simplified)
    // At 15 mph wind, roughly 0.03" WC on windward side
    final windPressure = 0.03;

    String recommendation;
    if (netPressure > 0.02 && netPressure < 0.05) {
      recommendation = 'Good positive pressure (${(netPressure * 100).toStringAsFixed(1)} hundredths " WC). Prevents infiltration.';
    } else if (netPressure > 0.05) {
      recommendation = 'High positive pressure. May cause door opening issues. Increase return or add relief.';
    } else if (netPressure < 0) {
      recommendation = 'NEGATIVE pressure. Building draws in unconditioned air. Increase supply or reduce exhaust.';
    } else {
      recommendation = 'Low positive pressure. May not prevent infiltration at all doors.';
    }

    recommendation += ' Net airflow: ${netCfm.toStringAsFixed(0)} CFM (${oaPercent.toStringAsFixed(1)}% of supply). ';

    // Stack effect analysis
    if (stackEffect.abs() > 0.03) {
      recommendation += 'Significant stack effect (${stackEffect.toStringAsFixed(3)}" WC). ';
      if (_outdoorTemp < _indoorTemp) {
        recommendation += 'Winter: Air enters low, exits high. Pressurize lower floors more.';
      } else {
        recommendation += 'Summer: Reverse stack. Air enters high, exits low.';
      }
    }

    switch (_buildingType) {
      case 'office':
        recommendation += ' Office: Target +0.03" to +0.05" WC. Balance for vestibule airlocks.';
        break;
      case 'hospital':
        recommendation += ' Hospital: Critical pressure relationships. Isolation rooms negative, OR positive.';
        break;
      case 'lab':
        recommendation += ' Laboratory: Typically negative to prevent contaminant escape. 100% exhaust.';
        break;
      case 'cleanroom':
        recommendation += ' Clean room: Positive cascade from cleanest to less clean. +0.03" to +0.05" between zones.';
        break;
    }

    recommendation += ' Monitor with differential pressure sensors. Doors should open with <30 lbs force.';

    setState(() {
      _netPressure = netPressure;
      _stackEffect = stackEffect;
      _windPressure = windPressure;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _supplyCfm = 5000;
      _returnCfm = 4500;
      _exhaustCfm = 300;
      _buildingHeight = 40;
      _outdoorTemp = 20;
      _indoorTemp = 72;
      _buildingType = 'office';
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
        title: Text('Building Pressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING TYPE'),
              const SizedBox(height: 12),
              _buildBuildingTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW BALANCE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Supply', _supplyCfm, 1000, 20000, ' CFM', (v) { setState(() => _supplyCfm = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Return', _returnCfm, 1000, 20000, ' CFM', (v) { setState(() => _returnCfm = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Exhaust', _exhaustCfm, 0, 2000, ' CFM', (v) { setState(() => _exhaustCfm = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'STACK EFFECT'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Height', _buildingHeight, 10, 200, ' ft', (v) { setState(() => _buildingHeight = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Outdoor', _outdoorTemp, -20, 100, '°F', (v) { setState(() => _outdoorTemp = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Indoor', _indoorTemp, 60, 80, '°F', (v) { setState(() => _indoorTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PRESSURE ANALYSIS'),
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
        Icon(LucideIcons.building2, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Positive pressure (+0.03" to +0.05" WC) prevents infiltration. Stack effect causes vertical pressure differences in tall buildings.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildBuildingTypeSelector(ZaftoColors colors) {
    final types = [('office', 'Office'), ('hospital', 'Hospital'), ('lab', 'Laboratory'), ('cleanroom', 'Clean Room')];
    return Row(
      children: types.map((t) {
        final selected = _buildingType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _buildingType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_netPressure == null) return const SizedBox.shrink();

    final isPositive = _netPressure! > 0;
    final isGood = _netPressure! > 0.02 && _netPressure! < 0.06;
    final statusColor = isGood ? Colors.green : (isPositive ? Colors.orange : Colors.red);
    final status = isGood ? 'GOOD PRESSURE' : (isPositive ? 'CHECK PRESSURE' : 'NEGATIVE PRESSURE');

    final netCfm = _supplyCfm - _returnCfm - _exhaustCfm;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${(_netPressure! * 100).toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Hundredths Inches WC', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Net Flow', '${netCfm.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Stack Effect', '${(_stackEffect! * 100).toStringAsFixed(1)} h"WC')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Wind Est', '${(_windPressure! * 100).toStringAsFixed(0)} h"WC')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
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
