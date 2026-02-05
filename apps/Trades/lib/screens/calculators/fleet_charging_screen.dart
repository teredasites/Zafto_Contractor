import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Fleet Charging Calculator - Design System v2.6
/// Commercial EV depot infrastructure sizing
class FleetChargingScreen extends ConsumerStatefulWidget {
  const FleetChargingScreen({super.key});
  @override
  ConsumerState<FleetChargingScreen> createState() => _FleetChargingScreenState();
}

class _FleetChargingScreenState extends ConsumerState<FleetChargingScreen> {
  int _fleetSize = 10;
  double _avgBatteryKwh = 60;
  double _dailyMiles = 100;
  double _efficiency = 3.5; // miles per kWh
  double _chargeWindowHours = 8;
  String _chargerType = 'level2';
  double _simultaneousFactor = 0.5;

  double? _dailyEnergyPerVehicle;
  double? _totalDailyEnergy;
  double? _minChargerKw;
  int? _recommendedChargers;
  double? _peakDemandKw;
  double? _annualEnergy;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Daily energy per vehicle
    final dailyEnergy = _dailyMiles / _efficiency;

    // Total fleet daily energy
    final totalDaily = dailyEnergy * _fleetSize;

    // Minimum charger power to complete in window
    final minChargerKw = dailyEnergy / _chargeWindowHours;

    // Charger power based on type
    double chargerKw;
    if (_chargerType == 'level2') {
      chargerKw = 19.2; // High-power L2
    } else if (_chargerType == 'dcfc50') {
      chargerKw = 50;
    } else {
      chargerKw = 150;
    }

    // Vehicles per charger (how many can share one charger in window)
    final vehiclesPerCharger = (chargerKw * _chargeWindowHours) / dailyEnergy;
    final minChargers = (_fleetSize / vehiclesPerCharger).ceil();

    // Recommended chargers with some buffer
    final recommendedChargers = (minChargers * 1.2).ceil();

    // Peak demand (simultaneous charging)
    final peakDemand = recommendedChargers * chargerKw * _simultaneousFactor;

    // Annual energy
    final annualEnergy = totalDaily * 365;

    String recommendation;
    if (_chargerType == 'level2') {
      if (_chargeWindowHours >= 8) {
        recommendation = 'Level 2 suitable for overnight depot charging. Consider TOU rates for cost savings.';
      } else {
        recommendation = 'Short charge window - consider DC fast charging for guaranteed readiness.';
      }
    } else {
      recommendation = 'DC fast charging provides quick turnaround. Higher demand charges may apply.';
    }

    if (peakDemand > 200) {
      recommendation += ' Peak demand over 200kW - utility coordination required. Consider on-site storage.';
    }

    setState(() {
      _dailyEnergyPerVehicle = dailyEnergy;
      _totalDailyEnergy = totalDaily;
      _minChargerKw = minChargerKw;
      _recommendedChargers = recommendedChargers;
      _peakDemandKw = peakDemand;
      _annualEnergy = annualEnergy;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _fleetSize = 10;
      _avgBatteryKwh = 60;
      _dailyMiles = 100;
      _efficiency = 3.5;
      _chargeWindowHours = 8;
      _chargerType = 'level2';
      _simultaneousFactor = 0.5;
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
        title: Text('Fleet Charging', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'FLEET PARAMETERS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Fleet Size', value: _fleetSize.toDouble(), min: 2, max: 100, unit: ' vehicles', isInt: true, onChanged: (v) { setState(() => _fleetSize = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Avg Battery Size', value: _avgBatteryKwh, min: 30, max: 200, unit: ' kWh', onChanged: (v) { setState(() => _avgBatteryKwh = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Daily Miles', value: _dailyMiles, min: 20, max: 300, unit: ' mi', onChanged: (v) { setState(() => _dailyMiles = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Efficiency', value: _efficiency, min: 2, max: 5, unit: ' mi/kWh', decimals: 1, onChanged: (v) { setState(() => _efficiency = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CHARGING SETUP'),
              const SizedBox(height: 12),
              _buildChargerTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Charge Window', value: _chargeWindowHours, min: 2, max: 12, unit: ' hours', onChanged: (v) { setState(() => _chargeWindowHours = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Simultaneous Factor', value: _simultaneousFactor, min: 0.3, max: 1.0, unit: '', decimals: 1, onChanged: (v) { setState(() => _simultaneousFactor = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'INFRASTRUCTURE SIZING'),
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
        Icon(LucideIcons.truck, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size depot charging infrastructure. Balance charger count, charge window, and peak demand for cost optimization.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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

  Widget _buildChargerTypeSelector(ZaftoColors colors) {
    final options = [
      ('level2', 'Level 2', '19.2 kW'),
      ('dcfc50', 'DC 50kW', 'Fast'),
      ('dcfc150', 'DC 150kW', 'Ultra-Fast'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Charger Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: options.map((o) {
            final selected = _chargerType == o.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _chargerType = o.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: o != options.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Column(children: [
                    Text(o.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(o.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 11)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_recommendedChargers == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('$_recommendedChargers', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Recommended Chargers', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Daily/Vehicle', '${_dailyEnergyPerVehicle?.toStringAsFixed(1)} kWh')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total Daily', '${_totalDailyEnergy?.toStringAsFixed(0)} kWh')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Peak Demand', '${_peakDemandKw?.toStringAsFixed(0)} kW')),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Min Charger kW', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('${_minChargerKw?.toStringAsFixed(1)} kW', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Annual Energy', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('${((_annualEnergy ?? 0) / 1000).toStringAsFixed(0)} MWh', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
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
