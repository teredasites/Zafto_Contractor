import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Energy Recovery Ventilator Calculator - Design System v2.6
/// ERV/HRV sizing and energy savings
class EnergyRecoveryScreen extends ConsumerStatefulWidget {
  const EnergyRecoveryScreen({super.key});
  @override
  ConsumerState<EnergyRecoveryScreen> createState() => _EnergyRecoveryScreenState();
}

class _EnergyRecoveryScreenState extends ConsumerState<EnergyRecoveryScreen> {
  double _cfm = 200;
  double _outdoorTemp = 20;
  double _indoorTemp = 70;
  double _outdoorRh = 30;
  double _indoorRh = 40;
  double _sensibleEfficiency = 75;
  String _unitType = 'erv';
  String _climate = 'cold';

  double? _heatingBtuSaved;
  double? _coolingBtuSaved;
  double? _supplyTemp;
  double? _annualSavings;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Temperature difference
    final deltaT = _indoorTemp - _outdoorTemp;

    // Sensible heat recovery
    // BTU/h = 1.08 × CFM × ΔT × Efficiency
    final sensibleRecovery = 1.08 * _cfm * deltaT.abs() * (_sensibleEfficiency / 100);

    // Supply air temperature after recovery
    double supplyTemp;
    if (_outdoorTemp < _indoorTemp) {
      // Heating mode
      supplyTemp = _outdoorTemp + (deltaT * _sensibleEfficiency / 100);
    } else {
      // Cooling mode
      supplyTemp = _outdoorTemp - (deltaT.abs() * _sensibleEfficiency / 100);
    }

    // ERV also recovers latent energy (moisture)
    double latentRecovery = 0;
    if (_unitType == 'erv') {
      // Simplified latent recovery estimate
      final rhDiff = (_indoorRh - _outdoorRh).abs();
      latentRecovery = 0.68 * _cfm * rhDiff * 0.5; // ~50% latent efficiency typical
    }

    final heatingBtuSaved = deltaT > 0 ? sensibleRecovery + latentRecovery : 0.0;
    final coolingBtuSaved = deltaT < 0 ? sensibleRecovery + latentRecovery : 0.0;

    // Annual savings estimate (3000 heating hrs, 1500 cooling hrs)
    double annualSavings;
    if (_climate == 'cold') {
      annualSavings = (heatingBtuSaved * 3000 / 100000) * 1.2; // ~$1.20/therm
    } else if (_climate == 'hot') {
      annualSavings = (coolingBtuSaved * 1500 / 12000) * 0.12 * 1.0; // ~$0.12/kWh × 1 kW/ton
    } else {
      annualSavings = (heatingBtuSaved * 2000 / 100000) * 1.2 + (coolingBtuSaved * 1000 / 12000) * 0.12;
    }

    String recommendation;
    recommendation = '${_sensibleEfficiency.toStringAsFixed(0)}% sensible efficiency. ';

    if (_unitType == 'erv') {
      recommendation += 'ERV: Transfers heat AND moisture. Best for humid climates or when indoor humidity control important.';
    } else {
      recommendation += 'HRV: Heat recovery only, no moisture transfer. Best for very cold/dry climates.';
    }

    if (_climate == 'cold') {
      recommendation += ' Cold climate: Focus on heating recovery. ${_unitType == 'hrv' ? 'HRV' : 'ERV'} should have frost protection.';
    } else if (_climate == 'hot') {
      recommendation += ' Hot climate: ERV preferred to reduce latent cooling load.';
    } else {
      recommendation += ' Mixed climate: ERV provides year-round benefits.';
    }

    if (sensibleRecovery > 50000) {
      recommendation += ' High energy recovery - good ROI expected.';
    }

    recommendation += ' Supply air: ${supplyTemp.toStringAsFixed(0)}°F after recovery (was ${_outdoorTemp.toStringAsFixed(0)}°F).';

    setState(() {
      _heatingBtuSaved = heatingBtuSaved;
      _coolingBtuSaved = coolingBtuSaved;
      _supplyTemp = supplyTemp;
      _annualSavings = annualSavings;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _cfm = 200;
      _outdoorTemp = 20;
      _indoorTemp = 70;
      _outdoorRh = 30;
      _indoorRh = 40;
      _sensibleEfficiency = 75;
      _unitType = 'erv';
      _climate = 'cold';
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
        title: Text('Energy Recovery', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'UNIT TYPE'),
              const SizedBox(height: 12),
              _buildUnitTypeSelector(colors),
              const SizedBox(height: 12),
              _buildClimateSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW & EFFICIENCY'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'CFM', _cfm, 50, 1000, '', (v) { setState(() => _cfm = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Efficiency', _sensibleEfficiency, 50, 95, '%', (v) { setState(() => _sensibleEfficiency = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Outdoor', _outdoorTemp, -20, 100, '°F', (v) { setState(() => _outdoorTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Indoor', _indoorTemp, 65, 80, '°F', (v) { setState(() => _indoorTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'ENERGY RECOVERY'),
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
        Expanded(child: Text('ERV/HRV preconditions outdoor air using exhaust energy. 60-80% sensible efficiency typical. Reduces heating/cooling load.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildUnitTypeSelector(ZaftoColors colors) {
    final types = [('erv', 'ERV (Heat + Moisture)'), ('hrv', 'HRV (Heat Only)')];
    return Row(
      children: types.map((t) {
        final selected = _unitType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _unitType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildClimateSelector(ZaftoColors colors) {
    final climates = [('cold', 'Cold'), ('mixed', 'Mixed'), ('hot', 'Hot/Humid')];
    return Row(
      children: climates.map((c) {
        final selected = _climate == c.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _climate = c.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: c != climates.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(c.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_supplyTemp == null) return const SizedBox.shrink();

    final isHeating = _outdoorTemp < _indoorTemp;
    final btuSaved = isHeating ? _heatingBtuSaved : _coolingBtuSaved;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Column(children: [
                Text('${_outdoorTemp.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textPrimary.withValues(alpha: 0.5), fontSize: 24)),
                Icon(LucideIcons.arrowRight, color: colors.accentPrimary),
                Text('${_supplyTemp?.toStringAsFixed(0)}°F', style: TextStyle(color: colors.accentPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
                Text('Supply After Recovery', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ]),
            ),
            Container(width: 1, height: 80, color: colors.borderDefault),
            Expanded(
              child: Column(children: [
                Text('${(btuSaved! / 1000).toStringAsFixed(1)}k', style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
                Text('BTU/h Recovered', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isHeating ? Colors.orange.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(
              isHeating ? 'HEATING MODE' : 'COOLING MODE',
              style: TextStyle(color: isHeating ? Colors.orange.shade700 : Colors.blue.shade700, fontSize: 14, fontWeight: FontWeight.w600),
            )),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Annual Savings', '\$${_annualSavings?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'CFM', '${_cfm.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Efficiency', '${_sensibleEfficiency.toStringAsFixed(0)}%')),
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
