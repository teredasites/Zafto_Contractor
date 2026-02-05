import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// CO2 Demand Ventilation Calculator - Design System v2.6
/// CO2-based outdoor air calculation per ASHRAE 62.1
class Co2VentilationScreen extends ConsumerStatefulWidget {
  const Co2VentilationScreen({super.key});
  @override
  ConsumerState<Co2VentilationScreen> createState() => _Co2VentilationScreenState();
}

class _Co2VentilationScreenState extends ConsumerState<Co2VentilationScreen> {
  double _occupancy = 50;
  double _outdoorCo2 = 400;
  double _indoorCo2 = 1000;
  double _targetCo2 = 800;
  double _cfmPerPerson = 15;
  String _spaceType = 'office';
  String _activityLevel = 'sedentary';

  double? _requiredCfm;
  double? _co2Generation;
  String? _status;
  String? _recommendation;

  // CO2 generation rates (cfh per person) by activity
  final Map<String, double> _co2Rates = {
    'sedentary': 0.31, // Office work
    'light': 0.43, // Standing, light work
    'moderate': 0.69, // Walking, moderate work
    'heavy': 1.08, // Heavy physical work
    'athletic': 2.16, // Gym, sports
  };

  // ASHRAE 62.1 ventilation rates
  final Map<String, List<double>> _ashrae621 = {
    'office': [5, 0.06], // CFM/person, CFM/sq ft
    'conference': [5, 0.06],
    'classroom': [10, 0.12],
    'retail': [7.5, 0.12],
    'restaurant': [7.5, 0.18],
    'gym': [20, 0.18],
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // CO2 generation rate
    final co2Rate = _co2Rates[_activityLevel] ?? 0.31;
    final totalCo2Generation = co2Rate * _occupancy; // cfh CO2

    // Required outdoor air from CO2 balance equation
    // Vo = N / (Ci - Co) where:
    // Vo = outdoor air cfm
    // N = CO2 generation (cfh)
    // Ci = indoor CO2 (ppm)
    // Co = outdoor CO2 (ppm)

    final co2Diff = _targetCo2 - _outdoorCo2;
    double requiredCfm;
    if (co2Diff > 0) {
      // Convert: cfh CO2 / (ppm difference) × 10^6 (ppm to fraction) / 60 min
      requiredCfm = (totalCo2Generation * 1000000) / (co2Diff * 60);
    } else {
      requiredCfm = _occupancy * 20; // Fallback
    }

    // Compare to ASHRAE minimum
    final ashraeRates = _ashrae621[_spaceType] ?? [5.0, 0.06];
    final ashraeMinCfm = _occupancy * ashraeRates[0];

    String status;
    if (_indoorCo2 <= 800) {
      status = 'EXCELLENT';
    } else if (_indoorCo2 <= 1000) {
      status = 'GOOD';
    } else if (_indoorCo2 <= 1500) {
      status = 'MARGINAL';
    } else {
      status = 'POOR';
    }

    String recommendation;
    recommendation = 'Current ${_indoorCo2.toStringAsFixed(0)} ppm. ';

    if (_indoorCo2 > 1000) {
      recommendation += 'CO2 above 1000 ppm indicates inadequate ventilation. Increase outdoor air or reduce occupancy.';
    } else if (_indoorCo2 > 800) {
      recommendation += 'CO2 acceptable but could improve. Consider increasing outdoor air during peak occupancy.';
    } else {
      recommendation += 'Excellent IAQ. CO2 levels indicate good ventilation.';
    }

    recommendation += ' ASHRAE min for ${ _spaceType}: ${ashraeMinCfm.toStringAsFixed(0)} CFM (${ashraeRates[0]} CFM/person).';

    if (requiredCfm > ashraeMinCfm * 1.5) {
      recommendation += ' CO2-based rate higher than ASHRAE minimum - use larger value.';
    }

    switch (_activityLevel) {
      case 'sedentary':
        recommendation += ' Sedentary activity: 0.31 cfh CO2/person.';
        break;
      case 'athletic':
        recommendation += ' High activity: 2+ cfh CO2/person. May need 3-4× normal ventilation.';
        break;
    }

    if (_outdoorCo2 > 450) {
      recommendation += ' Outdoor CO2 elevated - check for nearby exhaust or traffic.';
    }

    setState(() {
      _requiredCfm = requiredCfm;
      _co2Generation = totalCo2Generation;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _occupancy = 50;
      _outdoorCo2 = 400;
      _indoorCo2 = 1000;
      _targetCo2 = 800;
      _cfmPerPerson = 15;
      _spaceType = 'office';
      _activityLevel = 'sedentary';
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
        title: Text('CO2 Ventilation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 12),
              _buildActivitySelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'OCCUPANCY'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Number of People', value: _occupancy, min: 5, max: 500, unit: '', onChanged: (v) { setState(() => _occupancy = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CO2 LEVELS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Indoor', _indoorCo2, 400, 2000, ' ppm', (v) { setState(() => _indoorCo2 = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Outdoor', _outdoorCo2, 350, 500, ' ppm', (v) { setState(() => _outdoorCo2 = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Target Indoor CO2', value: _targetCo2, min: 600, max: 1200, unit: ' ppm', onChanged: (v) { setState(() => _targetCo2 = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'VENTILATION REQUIRED'),
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
        Icon(LucideIcons.activity, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('CO2 indicates ventilation adequacy. Target <1000 ppm. Outdoor ~400 ppm. >1500 ppm indicates poor IAQ.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSpaceTypeSelector(ZaftoColors colors) {
    final types = [('office', 'Office'), ('conference', 'Conference'), ('classroom', 'Classroom'), ('retail', 'Retail'), ('restaurant', 'Restaurant'), ('gym', 'Gym')];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.map((t) {
        final selected = _spaceType == t.$1;
        return GestureDetector(
          onTap: () { setState(() => _spaceType = t.$1); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitySelector(ZaftoColors colors) {
    final activities = [('sedentary', 'Sedentary'), ('light', 'Light'), ('moderate', 'Moderate'), ('heavy', 'Heavy'), ('athletic', 'Athletic')];
    return Row(
      children: activities.map((a) {
        final selected = _activityLevel == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _activityLevel = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != activities.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600))),
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
    if (_requiredCfm == null) return const SizedBox.shrink();

    final statusColor = _status == 'EXCELLENT' ? Colors.green
        : _status == 'GOOD' ? Colors.blue
        : _status == 'MARGINAL' ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_requiredCfm?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('CFM Outdoor Air Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${_status ?? ''} - ${_indoorCo2.toStringAsFixed(0)} ppm', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'CFM/Person', '${(_requiredCfm! / _occupancy).toStringAsFixed(1)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'CO2 Gen', '${_co2Generation?.toStringAsFixed(1)} cfh')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Occupancy', '${_occupancy.toStringAsFixed(0)}')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_indoorCo2 <= 1000 ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: _indoorCo2 <= 1000 ? Colors.green : Colors.orange, size: 16),
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
