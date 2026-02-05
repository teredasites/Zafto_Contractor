import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Heat Pump Balance Point Calculator - Design System v2.6
/// Determine when auxiliary heat is needed
class HeatPumpBalancePointScreen extends ConsumerStatefulWidget {
  const HeatPumpBalancePointScreen({super.key});
  @override
  ConsumerState<HeatPumpBalancePointScreen> createState() => _HeatPumpBalancePointScreenState();
}

class _HeatPumpBalancePointScreenState extends ConsumerState<HeatPumpBalancePointScreen> {
  double _heatLoss = 60000; // BTU/h at design temp
  double _designTemp = 5; // Design outdoor temp
  double _indoorTemp = 70;
  double _heatPumpCapacity47 = 48000; // Capacity at 47°F
  double _heatPumpCapacity17 = 28000; // Capacity at 17°F
  double _auxHeatCapacity = 15000; // Per strip kW * 3412
  int _auxStrips = 2;

  double? _balancePoint;
  double? _economicBalancePoint;
  double? _capacityAtBalance;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Heat pump capacity varies linearly with outdoor temp
    // Interpolate between 47°F and 17°F ratings
    // Capacity = C47 + (C17 - C47) * (47 - T) / (47 - 17)

    // Building heat loss is linear with temp difference
    // Q = UA * (Tin - Tout) = HeatLoss * (Tin - Tout) / (Tin - Tdesign)

    // Balance point is where heat pump capacity = building load
    // Solve iteratively
    double balancePoint = 35; // Initial guess

    for (int i = 0; i < 20; i++) {
      // Heat loss at current temp
      final heatLoss = _heatLoss * (_indoorTemp - balancePoint) / (_indoorTemp - _designTemp);

      // Heat pump capacity at current temp
      double hpCapacity;
      if (balancePoint >= 47) {
        hpCapacity = _heatPumpCapacity47;
      } else if (balancePoint <= 17) {
        hpCapacity = _heatPumpCapacity17;
      } else {
        hpCapacity = _heatPumpCapacity47 + (_heatPumpCapacity17 - _heatPumpCapacity47) * (47 - balancePoint) / 30;
      }

      // Newton-Raphson-ish approach
      if (hpCapacity > heatLoss) {
        balancePoint -= 2;
      } else if (hpCapacity < heatLoss) {
        balancePoint += 2;
      } else {
        break;
      }
    }

    // Refine
    double heatLossAtBalance = _heatLoss * (_indoorTemp - balancePoint) / (_indoorTemp - _designTemp);
    double capacityAtBalance;
    if (balancePoint >= 47) {
      capacityAtBalance = _heatPumpCapacity47;
    } else if (balancePoint <= 17) {
      capacityAtBalance = _heatPumpCapacity17;
    } else {
      capacityAtBalance = _heatPumpCapacity47 + (_heatPumpCapacity17 - _heatPumpCapacity47) * (47 - balancePoint) / 30;
    }

    // Economic balance point (where heat pump + aux is cheaper than aux alone)
    // Simplified: typically 5-10°F below thermal balance point
    final economicBalancePoint = balancePoint - 8;

    // Total aux capacity
    final totalAuxCapacity = _auxHeatCapacity * _auxStrips;

    String recommendation;
    if (balancePoint > 35) {
      recommendation = 'High balance point (${balancePoint.toStringAsFixed(0)}°F). Heat pump may be undersized or building is leaky.';
    } else if (balancePoint < 25) {
      recommendation = 'Low balance point indicates well-insulated building or properly sized heat pump.';
    } else {
      recommendation = 'Balance point in typical range. System should perform well in moderate climates.';
    }

    // Aux heat staging
    if (_designTemp < balancePoint) {
      final loadAtDesign = _heatLoss;
      final hpAtDesign = _heatPumpCapacity17 * 0.7; // Derate below 17°F
      final auxNeeded = loadAtDesign - hpAtDesign;

      if (auxNeeded > totalAuxCapacity) {
        recommendation += ' WARNING: Aux heat (${(totalAuxCapacity / 1000).toStringAsFixed(0)}k BTU) may be insufficient at design temp.';
      } else {
        recommendation += ' Aux heat adequate. ${_auxStrips} strips provide ${(totalAuxCapacity / 1000).toStringAsFixed(0)}k BTU backup.';
      }
    }

    recommendation += ' Set emergency heat lockout 5°F above balance point to maximize efficiency.';

    setState(() {
      _balancePoint = balancePoint;
      _economicBalancePoint = economicBalancePoint;
      _capacityAtBalance = capacityAtBalance;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _heatLoss = 60000;
      _designTemp = 5;
      _indoorTemp = 70;
      _heatPumpCapacity47 = 48000;
      _heatPumpCapacity17 = 28000;
      _auxHeatCapacity = 15000;
      _auxStrips = 2;
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
        title: Text('HP Balance Point', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heat Loss at Design', value: _heatLoss / 1000, min: 20, max: 150, unit: 'k BTU/h', onChanged: (v) { setState(() => _heatLoss = v * 1000); _calculate(); }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Design Temp', _designTemp, -20, 30, '°F', (v) { setState(() => _designTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Indoor Temp', _indoorTemp, 65, 75, '°F', (v) { setState(() => _indoorTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HEAT PUMP'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Cap @ 47°F', _heatPumpCapacity47 / 1000, 18, 120, 'k', (v) { setState(() => _heatPumpCapacity47 = v * 1000); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Cap @ 17°F', _heatPumpCapacity17 / 1000, 10, 80, 'k', (v) { setState(() => _heatPumpCapacity17 = v * 1000); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AUXILIARY HEAT'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Per Strip', _auxHeatCapacity / 1000, 5, 20, 'k BTU', (v) { setState(() => _auxHeatCapacity = v * 1000); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, '# Strips', _auxStrips.toDouble(), 1, 5, '', (v) { setState(() => _auxStrips = v.round()); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'BALANCE POINT'),
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
        Icon(LucideIcons.scale, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Balance point = outdoor temp where heat pump capacity equals building heat loss. Below this, aux heat kicks in.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
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
    if (_balancePoint == null) return const SizedBox.shrink();

    final totalAux = _auxHeatCapacity * _auxStrips;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_balancePoint?.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Thermal Balance Point', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('Economic: ${_economicBalancePoint?.toStringAsFixed(0)}°F (aux cheaper below)', style: TextStyle(color: Colors.blue.shade700, fontSize: 12))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'HP @ Balance', '${(_capacityAtBalance! / 1000).toStringAsFixed(0)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total Aux', '${(totalAux / 1000).toStringAsFixed(0)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Design Load', '${(_heatLoss / 1000).toStringAsFixed(0)}k BTU')),
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
