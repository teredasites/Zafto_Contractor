import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Refrigerant P-T Chart Calculator - Design System v2.6
/// Pressure-Temperature relationship for common refrigerants
class RefrigerantPtChartScreen extends ConsumerStatefulWidget {
  const RefrigerantPtChartScreen({super.key});
  @override
  ConsumerState<RefrigerantPtChartScreen> createState() => _RefrigerantPtChartScreenState();
}

class _RefrigerantPtChartScreenState extends ConsumerState<RefrigerantPtChartScreen> {
  String _inputMode = 'pressure';
  double _pressure = 118; // psig
  double _temperature = 40; // °F
  String _refrigerant = 'r410a';

  double? _calculatedValue;
  String? _units;
  String? _recommendation;

  // P-T data (simplified linear interpolation points)
  final Map<String, List<List<double>>> _ptData = {
    'r410a': [
      [-20, 25.6], [0, 49.0], [10, 62.5], [20, 78.2], [30, 96.1], [40, 116.3],
      [50, 139.1], [60, 164.6], [70, 193.2], [80, 224.9], [90, 260.0], [100, 298.8],
      [110, 341.5], [120, 388.3], [130, 439.5],
    ],
    'r22': [
      [-20, 0.6], [0, 24.0], [10, 33.1], [20, 43.0], [30, 54.9], [40, 68.5],
      [50, 84.0], [60, 101.6], [70, 121.4], [80, 143.6], [90, 168.4], [100, 195.9],
      [110, 226.4], [120, 260.0], [130, 297.0],
    ],
    'r134a': [
      [-20, -4.9], [0, 6.5], [10, 12.0], [20, 18.4], [30, 26.1], [40, 34.9],
      [50, 45.0], [60, 56.5], [70, 69.7], [80, 84.8], [90, 101.8], [100, 121.0],
      [110, 142.5], [120, 166.6], [130, 193.4],
    ],
    'r404a': [
      [-20, 8.2], [0, 31.8], [10, 42.8], [20, 55.6], [30, 70.3], [40, 87.1],
      [50, 106.2], [60, 127.7], [70, 151.9], [80, 178.9], [90, 209.0], [100, 242.3],
      [110, 279.2], [120, 319.8], [130, 364.5],
    ],
    'r407c': [
      [-20, 3.5], [0, 26.5], [10, 37.0], [20, 49.3], [30, 63.6], [40, 80.0],
      [50, 98.7], [60, 120.0], [70, 144.0], [80, 171.0], [90, 201.0], [100, 234.5],
      [110, 271.8], [120, 313.0], [130, 358.5],
    ],
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final data = _ptData[_refrigerant] ?? _ptData['r410a']!;

    double calculatedValue;
    String units;

    if (_inputMode == 'pressure') {
      // Find temperature from pressure
      calculatedValue = _interpolate(data, _pressure, false);
      units = '°F at ${_pressure.toStringAsFixed(1)} psig';
    } else {
      // Find pressure from temperature
      calculatedValue = _interpolate(data, _temperature, true);
      units = 'psig at ${_temperature.toStringAsFixed(0)}°F';
    }

    String recommendation;
    if (_refrigerant == 'r410a') {
      recommendation = 'R-410A: Higher pressure than R-22. Requires rated components. Purple/Rose cylinder color.';
    } else if (_refrigerant == 'r22') {
      recommendation = 'R-22 PHASEOUT: No longer manufactured. Recovery and reclaim only. Green cylinder.';
    } else if (_refrigerant == 'r134a') {
      recommendation = 'R-134a: Auto A/C and medium temp refrigeration. POE oil required. Light blue cylinder.';
    } else if (_refrigerant == 'r404a') {
      recommendation = 'R-404A: Commercial refrigeration. GWP phaseout pending. Orange cylinder.';
    } else {
      recommendation = 'R-407C: R-22 retrofit option. Zeotropic blend - liquid charge only.';
    }

    if (_inputMode == 'pressure') {
      if (calculatedValue < 32) {
        recommendation += ' Low temp operation: Check for freeze-up and oil return.';
      } else if (calculatedValue > 100) {
        recommendation += ' High condensing temp: Check condenser and ambient conditions.';
      }
    } else {
      if (_refrigerant == 'r410a' && calculatedValue > 400) {
        recommendation += ' Very high pressure: Verify gauge rating and safety.';
      }
    }

    setState(() {
      _calculatedValue = calculatedValue;
      _units = units;
      _recommendation = recommendation;
    });
  }

  double _interpolate(List<List<double>> data, double value, bool tempToPress) {
    int idx = tempToPress ? 0 : 1;
    int resultIdx = tempToPress ? 1 : 0;

    // Find bracketing points
    for (int i = 0; i < data.length - 1; i++) {
      if (value >= data[i][idx] && value <= data[i + 1][idx]) {
        double ratio = (value - data[i][idx]) / (data[i + 1][idx] - data[i][idx]);
        return data[i][resultIdx] + ratio * (data[i + 1][resultIdx] - data[i][resultIdx]);
      }
    }

    // Extrapolate if outside range
    if (value < data.first[idx]) {
      return data.first[resultIdx];
    }
    return data.last[resultIdx];
  }

  void _reset() {
    setState(() {
      _inputMode = 'pressure';
      _pressure = 118;
      _temperature = 40;
      _refrigerant = 'r410a';
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
        title: Text('P-T Chart', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'REFRIGERANT'),
              const SizedBox(height: 12),
              _buildRefrigerantSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INPUT MODE'),
              const SizedBox(height: 12),
              _buildModeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, _inputMode == 'pressure' ? 'ENTER PRESSURE' : 'ENTER TEMPERATURE'),
              const SizedBox(height: 12),
              if (_inputMode == 'pressure')
                _buildSliderRow(colors, label: 'Pressure', value: _pressure, min: 0, max: _refrigerant == 'r410a' ? 450 : 300, unit: ' psig', onChanged: (v) { setState(() => _pressure = v); _calculate(); })
              else
                _buildSliderRow(colors, label: 'Temperature', value: _temperature, min: -20, max: 130, unit: '°F', onChanged: (v) { setState(() => _temperature = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'RESULT'),
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
        Expanded(child: Text('Saturated pressure-temperature relationship. For superheat/subcooling, compare actual temp to this saturation value.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildRefrigerantSelector(ZaftoColors colors) {
    final refs = [('r410a', 'R-410A'), ('r22', 'R-22'), ('r134a', 'R-134a'), ('r404a', 'R-404A'), ('r407c', 'R-407C')];
    return Row(
      children: refs.map((r) {
        final selected = _refrigerant == r.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _refrigerant = r.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: r != refs.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeSelector(ZaftoColors colors) {
    final modes = [('pressure', 'Pressure → Temp'), ('temperature', 'Temp → Pressure')];
    return Row(
      children: modes.map((m) {
        final selected = _inputMode == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _inputMode = m.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: m != modes.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
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
    if (_calculatedValue == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(
            _inputMode == 'pressure'
                ? '${_calculatedValue?.toStringAsFixed(1)}°F'
                : '${_calculatedValue?.toStringAsFixed(1)} psig',
            style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700),
          ),
          Text(_units ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _refrigerant == 'r410a' ? Colors.pink.withValues(alpha: 0.2)
                  : _refrigerant == 'r22' ? Colors.green.withValues(alpha: 0.2)
                  : _refrigerant == 'r134a' ? Colors.lightBlue.withValues(alpha: 0.2)
                  : _refrigerant == 'r404a' ? Colors.orange.withValues(alpha: 0.2)
                  : Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(_refrigerant.toUpperCase(), style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
          ),
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
