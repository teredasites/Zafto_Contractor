import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Boiler Efficiency Calculator - Design System v2.6
/// Combustion efficiency and heat loss analysis
class BoilerEfficiencyScreen extends ConsumerStatefulWidget {
  const BoilerEfficiencyScreen({super.key});
  @override
  ConsumerState<BoilerEfficiencyScreen> createState() => _BoilerEfficiencyScreenState();
}

class _BoilerEfficiencyScreenState extends ConsumerState<BoilerEfficiencyScreen> {
  double _stackTemp = 350;
  double _ambientTemp = 70;
  double _o2Percent = 5.0;
  double _co2Percent = 10.0;
  String _fuelType = 'natural_gas';
  double _ratedInput = 100000;

  double? _combustionEfficiency;
  double? _netStackTemp;
  double? _excessAir;
  double? _heatLoss;
  double? _annualSavings;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Net stack temperature
    final netStackTemp = _stackTemp - _ambientTemp;

    // Excess air calculation from O2
    // Excess Air % = O2 / (21 - O2) * 100
    final excessAir = (_o2Percent / (21 - _o2Percent)) * 100;

    // Fuel-specific constants
    double k1; // Stack loss coefficient
    double k2; // Radiation loss factor
    double fuelCost; // $ per therm equivalent

    switch (_fuelType) {
      case 'natural_gas':
        k1 = 0.38;
        k2 = 1.5;
        fuelCost = 1.20;
        break;
      case 'propane':
        k1 = 0.35;
        k2 = 1.5;
        fuelCost = 2.50;
        break;
      case 'oil':
        k1 = 0.40;
        k2 = 2.0;
        fuelCost = 3.00;
        break;
      default:
        k1 = 0.38;
        k2 = 1.5;
        fuelCost = 1.20;
    }

    // Stack heat loss percentage
    // Loss % = (Stack Temp - Ambient) / (CO2% * K1)
    final stackLoss = netStackTemp / (_co2Percent * k1);

    // Radiation and convection losses (estimated)
    final radiationLoss = k2 + (100000 / _ratedInput) * 0.5;

    // Total heat loss
    final heatLoss = stackLoss + radiationLoss;

    // Combustion efficiency
    final combustionEfficiency = 100 - heatLoss;

    // Annual savings potential (assuming 10% improvement possible)
    final currentAnnualFuel = _ratedInput * 2000 / 100000 * fuelCost; // 2000 hrs/yr
    final potentialImprovement = combustionEfficiency < 85 ? (85 - combustionEfficiency) / 100 : 0.0;
    final annualSavings = currentAnnualFuel * potentialImprovement;

    String recommendation;
    if (combustionEfficiency >= 85) {
      recommendation = 'Efficiency is good (${combustionEfficiency.toStringAsFixed(1)}%). Maintain current tune-up schedule.';
    } else if (combustionEfficiency >= 80) {
      recommendation = 'Fair efficiency. Check burner adjustment and heat exchanger cleanliness.';
    } else {
      recommendation = 'Poor efficiency. Needs tune-up: clean heat exchanger, adjust air/fuel ratio, check for air leaks.';
    }

    if (excessAir > 50) {
      recommendation += ' HIGH EXCESS AIR (${excessAir.toStringAsFixed(0)}%). Reduce combustion air - target 15-30%.';
    } else if (excessAir < 10) {
      recommendation += ' Low excess air may cause incomplete combustion and CO. Increase air slightly.';
    }

    if (netStackTemp > 400) {
      recommendation += ' High stack temp indicates heat exchanger fouling or oversized boiler.';
    }

    if (_fuelType == 'oil') {
      recommendation += ' Oil boiler: Check nozzle, filter, and electrode spacing.';
    }

    setState(() {
      _combustionEfficiency = combustionEfficiency;
      _netStackTemp = netStackTemp;
      _excessAir = excessAir;
      _heatLoss = heatLoss;
      _annualSavings = annualSavings;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _stackTemp = 350;
      _ambientTemp = 70;
      _o2Percent = 5.0;
      _co2Percent = 10.0;
      _fuelType = 'natural_gas';
      _ratedInput = 100000;
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
        title: Text('Boiler Efficiency', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'FUEL'),
              const SizedBox(height: 12),
              _buildFuelSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Rated Input', value: _ratedInput / 1000, min: 50, max: 1000, unit: 'k BTU/h', onChanged: (v) { setState(() => _ratedInput = v * 1000); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FLUE GAS ANALYSIS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Stack Temp', _stackTemp, 200, 600, '°F', (v) { setState(() => _stackTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Ambient', _ambientTemp, 50, 90, '°F', (v) { setState(() => _ambientTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'O2 %', _o2Percent, 1, 12, '%', (v) { setState(() => _o2Percent = v); _calculate(); }, decimals: 1)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'CO2 %', _co2Percent, 5, 14, '%', (v) { setState(() => _co2Percent = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EFFICIENCY ANALYSIS'),
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
        Icon(LucideIcons.flame, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Use flue gas analyzer readings. Target 80-85% efficiency. Excess air 15-30%, stack temp <350°F.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFuelSelector(ZaftoColors colors) {
    final fuels = [('natural_gas', 'Natural Gas'), ('propane', 'Propane'), ('oil', 'Oil')];
    return Row(
      children: fuels.map((f) {
        final selected = _fuelType == f.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _fuelType = f.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: f != fuels.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(f.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
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
            child: Text('${value.toStringAsFixed(0)} $unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_combustionEfficiency == null) return const SizedBox.shrink();

    final isGood = (_combustionEfficiency ?? 0) >= 80;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_combustionEfficiency?.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Combustion Efficiency', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: isGood ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(isGood ? 'GOOD' : 'NEEDS TUNE-UP', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Stack Rise', '${_netStackTemp?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Excess Air', '${_excessAir?.toStringAsFixed(0)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Heat Loss', '${_heatLoss?.toStringAsFixed(1)}%')),
          ]),
          if ((_annualSavings ?? 0) > 50) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text('Potential annual savings: \$${_annualSavings?.toStringAsFixed(0)}', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
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
