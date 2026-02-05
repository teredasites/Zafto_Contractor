import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Latent Load Calculator - Design System v2.6
/// Moisture removal cooling load calculation
class LatentLoadScreen extends ConsumerStatefulWidget {
  const LatentLoadScreen({super.key});
  @override
  ConsumerState<LatentLoadScreen> createState() => _LatentLoadScreenState();
}

class _LatentLoadScreenState extends ConsumerState<LatentLoadScreen> {
  double _cfm = 400;
  double _outdoorRh = 70;
  double _indoorRh = 50;
  int _outdoorTemp = 95;
  int _indoorTemp = 75;
  int _occupants = 4;
  String _activityLevel = 'light';

  double? _outdoorGrains;
  double? _indoorGrains;
  double? _infiltrationLatent;
  double? _occupantLatent;
  double? _totalLatent;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Simplified grains per pound calculation from temp and RH
    // Saturation grains at temperature (approximate)
    double satGrains(int tempF) {
      return 0.000156 * tempF * tempF * tempF - 0.0156 * tempF * tempF + 0.97 * tempF - 3.2;
    }

    final satGrainsOut = satGrains(_outdoorTemp) + 50; // Rough approximation
    final satGrainsIn = satGrains(_indoorTemp) + 50;

    final outdoorGr = satGrainsOut * (_outdoorRh / 100);
    final indoorGr = satGrainsIn * (_indoorRh / 100);
    final deltaGrains = outdoorGr - indoorGr;

    // Infiltration latent: Q = 0.68 × CFM × Δgr
    final infiltrationLatent = 0.68 * _cfm * deltaGrains;

    // Occupant latent load (BTU/hr per person)
    double latentPerPerson;
    switch (_activityLevel) {
      case 'sedentary': latentPerPerson = 155; break;
      case 'light': latentPerPerson = 200; break;
      case 'moderate': latentPerPerson = 300; break;
      case 'active': latentPerPerson = 450; break;
      default: latentPerPerson = 200;
    }
    final occupantLatent = _occupants * latentPerPerson;

    final totalLatent = infiltrationLatent + occupantLatent;

    String recommendation;
    if (_outdoorRh > 60) {
      recommendation = 'High outdoor humidity. System SHR may need adjustment for adequate dehumidification.';
    } else {
      recommendation = 'Moderate humidity. Standard equipment should provide adequate moisture removal.';
    }

    if (totalLatent > 10000) {
      recommendation += ' Consider dedicated dehumidification for comfort.';
    }

    setState(() {
      _outdoorGrains = outdoorGr;
      _indoorGrains = indoorGr;
      _infiltrationLatent = infiltrationLatent;
      _occupantLatent = occupantLatent;
      _totalLatent = totalLatent;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _cfm = 400;
      _outdoorRh = 70;
      _indoorRh = 50;
      _outdoorTemp = 95;
      _indoorTemp = 75;
      _occupants = 4;
      _activityLevel = 'light';
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
        title: Text('Latent Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'OUTDOOR CONDITIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor Temperature', value: _outdoorTemp.toDouble(), min: 70, max: 105, unit: '\u00B0F', isInt: true, onChanged: (v) { setState(() => _outdoorTemp = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor RH', value: _outdoorRh, min: 30, max: 100, unit: '%', onChanged: (v) { setState(() => _outdoorRh = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INDOOR CONDITIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Indoor Temperature', value: _indoorTemp.toDouble(), min: 68, max: 80, unit: '\u00B0F', isInt: true, onChanged: (v) { setState(() => _indoorTemp = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Indoor RH Target', value: _indoorRh, min: 40, max: 60, unit: '%', onChanged: (v) { setState(() => _indoorRh = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'VENTILATION & OCCUPANTS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ventilation CFM', value: _cfm, min: 50, max: 1000, unit: ' CFM', onChanged: (v) { setState(() => _cfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Occupants', value: _occupants.toDouble(), min: 1, max: 12, unit: '', isInt: true, onChanged: (v) { setState(() => _occupants = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Activity Level', options: const ['Sedentary', 'Light', 'Moderate', 'Active'], selectedIndex: ['sedentary', 'light', 'moderate', 'active'].indexOf(_activityLevel), onChanged: (i) { setState(() => _activityLevel = ['sedentary', 'light', 'moderate', 'active'][i]); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'LATENT LOAD'),
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
        Expanded(child: Text('Calculate moisture removal load. Latent load affects equipment SHR selection and dehumidification needs.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 10))),
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
    if (_totalLatent == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${(_totalLatent! / 1000).toStringAsFixed(1)}k', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('BTU/hr Total Latent', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Outdoor', '${_outdoorGrains?.toStringAsFixed(0)} gr/lb')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Indoor', '${_indoorGrains?.toStringAsFixed(0)} gr/lb')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Infiltration', '${(_infiltrationLatent! / 1000).toStringAsFixed(1)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Occupant', '${(_occupantLatent! / 1000).toStringAsFixed(1)}k BTU')),
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
