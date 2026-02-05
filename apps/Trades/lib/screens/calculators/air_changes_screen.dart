import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Air Changes Calculator - Design System v2.6
/// ACH calculation and ventilation rate analysis
class AirChangesScreen extends ConsumerStatefulWidget {
  const AirChangesScreen({super.key});
  @override
  ConsumerState<AirChangesScreen> createState() => _AirChangesScreenState();
}

class _AirChangesScreenState extends ConsumerState<AirChangesScreen> {
  double _roomLength = 20;
  double _roomWidth = 15;
  double _ceilingHeight = 8;
  double _cfm = 200;
  String _spaceType = 'office';
  String _inputMode = 'cfm_to_ach';

  double? _ach;
  double? _roomVolume;
  double? _requiredCfm;
  String? _recommendation;

  // Recommended ACH by space type
  final Map<String, List<double>> _achRequirements = {
    'office': [4, 6],
    'retail': [6, 10],
    'restaurant': [8, 12],
    'hospital': [6, 12],
    'cleanroom': [15, 400],
    'warehouse': [2, 4],
    'residential': [4, 8],
    'gymnasium': [6, 10],
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final roomVolume = _roomLength * _roomWidth * _ceilingHeight;

    double ach;
    double requiredCfm;

    if (_inputMode == 'cfm_to_ach') {
      // Calculate ACH from CFM
      ach = (_cfm * 60) / roomVolume;
      final minAch = _achRequirements[_spaceType]?[0] ?? 4;
      requiredCfm = (minAch * roomVolume) / 60;
    } else {
      // Calculate CFM from target ACH
      final targetAch = _achRequirements[_spaceType]?[0] ?? 4;
      ach = targetAch;
      requiredCfm = (ach * roomVolume) / 60;
    }

    final minAch = _achRequirements[_spaceType]?[0] ?? 4;
    final maxAch = _achRequirements[_spaceType]?[1] ?? 8;

    String recommendation;
    if (ach < minAch) {
      recommendation = 'Below minimum ($minAch ACH). Increase ventilation to ${requiredCfm.toStringAsFixed(0)} CFM for this space type.';
    } else if (ach > maxAch) {
      recommendation = 'Above typical range ($minAch-$maxAch ACH). May be oversized - check energy costs.';
    } else {
      recommendation = 'Within recommended range ($minAch-$maxAch ACH) for ${_spaceType.replaceAll('_', ' ')}.';
    }

    switch (_spaceType) {
      case 'office':
        recommendation += ' Office: ASHRAE 62.1 requires 5-20 CFM/person plus 0.06 CFM/sq ft.';
        break;
      case 'restaurant':
        recommendation += ' Restaurant: High exhaust for cooking. Make-up air critical.';
        break;
      case 'hospital':
        recommendation += ' Healthcare: Pressure relationships critical. HEPA filtration for isolation.';
        break;
      case 'cleanroom':
        recommendation += ' Cleanroom: Class determines ACH. ISO 5 needs 240-600 ACH.';
        break;
      case 'warehouse':
        recommendation += ' Warehouse: Lower rates acceptable. Focus on exhaust ventilation.';
        break;
    }

    setState(() {
      _ach = ach;
      _roomVolume = roomVolume;
      _requiredCfm = requiredCfm;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _roomLength = 20;
      _roomWidth = 15;
      _ceilingHeight = 8;
      _cfm = 200;
      _spaceType = 'office';
      _inputMode = 'cfm_to_ach';
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
        title: Text('Air Changes', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SPACE TYPE'),
              const SizedBox(height: 12),
              _buildSpaceTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOM DIMENSIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Length', _roomLength, 10, 100, ' ft', (v) { setState(() => _roomLength = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Width', _roomWidth, 10, 100, ' ft', (v) { setState(() => _roomWidth = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Height', _ceilingHeight, 8, 30, ' ft', (v) { setState(() => _ceilingHeight = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Supply CFM', value: _cfm, min: 50, max: 5000, unit: ' CFM', onChanged: (v) { setState(() => _cfm = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'AIR CHANGES PER HOUR'),
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
        Expanded(child: Text('ACH = (CFM × 60) / Room Volume. Higher ACH means faster air turnover. Balance IAQ needs with energy costs.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSpaceTypeSelector(ZaftoColors colors) {
    final types = [('office', 'Office'), ('retail', 'Retail'), ('restaurant', 'Restaurant'), ('hospital', 'Hospital')];
    return Column(children: [
      Row(
        children: types.map((t) {
          final selected = _spaceType == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _spaceType = t.$1); _calculate(); },
              child: Container(
                margin: EdgeInsets.only(right: t != types.last ? 6 : 0),
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
      ),
      const SizedBox(height: 8),
      Row(
        children: [('cleanroom', 'Cleanroom'), ('warehouse', 'Warehouse'), ('residential', 'Residential'), ('gymnasium', 'Gym')].map((t) {
          final selected = _spaceType == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _spaceType = t.$1); _calculate(); },
              child: Container(
                margin: EdgeInsets.only(right: t.$1 != 'gymnasium' ? 6 : 0),
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
      ),
    ]);
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
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
    if (_ach == null) return const SizedBox.shrink();

    final minAch = _achRequirements[_spaceType]?[0] ?? 4;
    final maxAch = _achRequirements[_spaceType]?[1] ?? 8;
    final isLow = _ach! < minAch;
    final isHigh = _ach! > maxAch;
    final isGood = !isLow && !isHigh;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_ach?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Air Changes per Hour', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isGood ? Colors.green : (isLow ? Colors.orange : Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(isGood ? 'WITHIN RANGE' : (isLow ? 'BELOW MINIMUM' : 'ABOVE TYPICAL'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Volume', '${_roomVolume?.toStringAsFixed(0)} cu ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Required', '${_requiredCfm?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Range', '$minAch-$maxAch ACH')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isGood ? Colors.green : Colors.orange, size: 16),
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
