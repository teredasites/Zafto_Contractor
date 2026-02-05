import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Enthalpy Calculator - Design System v2.6
/// Calculate air enthalpy for economizer and load calculations
class EnthalpyScreen extends ConsumerStatefulWidget {
  const EnthalpyScreen({super.key});
  @override
  ConsumerState<EnthalpyScreen> createState() => _EnthalpyScreenState();
}

class _EnthalpyScreenState extends ConsumerState<EnthalpyScreen> {
  double _dryBulbTemp = 75;
  double _relativeHumidity = 50;
  double _elevation = 0;
  String _mode = 'single';

  // For comparison mode
  double _outdoorDb = 85;
  double _outdoorRh = 60;

  double? _enthalpy;
  double? _wetBulbTemp;
  double? _dewPoint;
  double? _humidityRatio;
  double? _outdoorEnthalpy;
  String? _economizerDecision;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Calculate saturation pressure using Magnus formula
    double satPressure(double t) {
      return 0.61078 * math.exp((17.27 * t) / (t + 237.3));
    }

    // Atmospheric pressure at elevation
    final atmPressure = 101.325 * math.pow(1 - 0.0000225577 * _elevation * 0.3048, 5.2559);

    // Partial pressure of water vapor
    final pws = satPressure((_dryBulbTemp - 32) * 5 / 9) * 10; // Convert to kPa
    final pw = pws * (_relativeHumidity / 100);

    // Humidity ratio (lb water / lb dry air)
    final humidityRatio = 0.622 * pw / (atmPressure - pw);

    // Enthalpy (BTU/lb dry air)
    // h = 0.24 * T + W * (1061 + 0.444 * T)
    final enthalpy = 0.24 * _dryBulbTemp + humidityRatio * (1061 + 0.444 * _dryBulbTemp);

    // Wet bulb approximation
    final wetBulb = _dryBulbTemp * math.atan(0.151977 * math.sqrt(_relativeHumidity + 8.313659)) +
        math.atan(_dryBulbTemp + _relativeHumidity) -
        math.atan(_relativeHumidity - 1.676331) +
        0.00391838 * math.pow(_relativeHumidity, 1.5) * math.atan(0.023101 * _relativeHumidity) -
        4.686035;

    // Dew point approximation
    final a = 17.27;
    final b = 237.7;
    final tC = (_dryBulbTemp - 32) * 5 / 9;
    final gamma = math.log(_relativeHumidity / 100) + (a * tC) / (b + tC);
    final dewPointC = (b * gamma) / (a - gamma);
    final dewPoint = dewPointC * 9 / 5 + 32;

    // Economizer comparison
    double? outdoorEnthalpy;
    String economizerDecision = '';

    if (_mode == 'economizer') {
      final pwsOut = satPressure((_outdoorDb - 32) * 5 / 9) * 10;
      final pwOut = pwsOut * (_outdoorRh / 100);
      final wOut = 0.622 * pwOut / (atmPressure - pwOut);
      outdoorEnthalpy = 0.24 * _outdoorDb + wOut * (1061 + 0.444 * _outdoorDb);

      if (outdoorEnthalpy < enthalpy) {
        economizerDecision = 'USE OUTDOOR AIR - Lower enthalpy = free cooling';
      } else {
        economizerDecision = 'USE RETURN AIR - Outdoor enthalpy too high';
      }
    }

    String recommendation;
    if (_mode == 'economizer') {
      final enthalpyDiff = (enthalpy - (outdoorEnthalpy ?? enthalpy)).abs();
      recommendation = 'Enthalpy difference: ${enthalpyDiff.toStringAsFixed(1)} BTU/lb. ';
      if (outdoorEnthalpy != null && outdoorEnthalpy < enthalpy) {
        recommendation += 'Outdoor air provides ${((1 - outdoorEnthalpy / enthalpy) * 100).toStringAsFixed(0)}% energy savings vs mechanical cooling.';
      } else {
        recommendation += 'Outdoor air would increase cooling load. Keep dampers at minimum.';
      }
    } else {
      recommendation = 'Enthalpy represents total heat content. Use for coil load calculations: Q = 4.5 × CFM × Δh.';
    }

    if (dewPoint > 55) {
      recommendation += ' High dew point (${dewPoint.toStringAsFixed(0)}°F) indicates muggy conditions.';
    }

    setState(() {
      _enthalpy = enthalpy;
      _wetBulbTemp = wetBulb;
      _dewPoint = dewPoint;
      _humidityRatio = humidityRatio * 7000; // Convert to grains
      _outdoorEnthalpy = outdoorEnthalpy;
      _economizerDecision = economizerDecision;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _dryBulbTemp = 75;
      _relativeHumidity = 50;
      _elevation = 0;
      _mode = 'single';
      _outdoorDb = 85;
      _outdoorRh = 60;
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
        title: Text('Enthalpy', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODE'),
              const SizedBox(height: 12),
              _buildModeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, _mode == 'economizer' ? 'INDOOR/RETURN AIR' : 'AIR CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Dry Bulb', _dryBulbTemp, 40, 100, '°F', (v) { setState(() => _dryBulbTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'RH', _relativeHumidity, 10, 100, '%', (v) { setState(() => _relativeHumidity = v); _calculate(); })),
              ]),
              if (_mode == 'economizer') ...[
                const SizedBox(height: 24),
                _buildSectionHeader(colors, 'OUTDOOR AIR'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildCompactSlider(colors, 'Outdoor DB', _outdoorDb, 40, 110, '°F', (v) { setState(() => _outdoorDb = v); _calculate(); })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCompactSlider(colors, 'Outdoor RH', _outdoorRh, 10, 100, '%', (v) { setState(() => _outdoorRh = v); _calculate(); })),
                ]),
              ],
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Elevation', value: _elevation, min: 0, max: 10000, unit: ' ft', onChanged: (v) { setState(() => _elevation = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'RESULTS'),
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
        Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Enthalpy = total heat content (sensible + latent). Critical for economizer control and coil sizing.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildModeSelector(ZaftoColors colors) {
    final modes = [('single', 'Single Point'), ('economizer', 'Economizer Compare')];
    return Row(
      children: modes.map((m) {
        final selected = _mode == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _mode = m.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: m != modes.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
    if (_enthalpy == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_enthalpy?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('BTU/lb dry air', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          if (_mode == 'economizer' && _economizerDecision != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _economizerDecision!.contains('USE OUTDOOR') ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(_economizerDecision ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _buildResultItem(colors, 'Indoor h', '${_enthalpy?.toStringAsFixed(1)}')),
              Container(width: 1, height: 40, color: colors.borderDefault),
              Expanded(child: _buildResultItem(colors, 'Outdoor h', '${_outdoorEnthalpy?.toStringAsFixed(1)}')),
            ]),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Wet Bulb', '${_wetBulbTemp?.toStringAsFixed(1)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Dew Point', '${_dewPoint?.toStringAsFixed(1)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Grains', '${_humidityRatio?.toStringAsFixed(0)}')),
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
