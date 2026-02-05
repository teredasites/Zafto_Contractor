import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Economizer Calculator - Design System v2.6
/// Airside economizer operation and setpoints
class EconomizerScreen extends ConsumerStatefulWidget {
  const EconomizerScreen({super.key});
  @override
  ConsumerState<EconomizerScreen> createState() => _EconomizerScreenState();
}

class _EconomizerScreenState extends ConsumerState<EconomizerScreen> {
  double _outdoorTemp = 55;
  double _outdoorRh = 50;
  double _returnTemp = 75;
  double _supplySetpoint = 55;
  double _highLimitTemp = 70;
  double _highLimitEnthalpy = 28;
  String _controlType = 'dry_bulb';
  String _economizerType = 'integrated';

  double? _outdoorEnthalpy;
  double? _returnEnthalpy;
  bool? _economizerEnabled;
  double? _mixedAirTemp;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Calculate outdoor enthalpy (simplified)
    // h = 0.24T + W(1061 + 0.444T) where W is humidity ratio
    // Simplified: h ≈ 0.24T + 0.01RH × (50 + 0.1T)
    final outdoorEnthalpy = 0.24 * _outdoorTemp + 0.01 * _outdoorRh * (50 + 0.1 * _outdoorTemp);
    final returnEnthalpy = 0.24 * _returnTemp + 0.01 * 50 * (50 + 0.1 * _returnTemp); // Assume 50% RH return

    // Check economizer enable conditions
    bool economizerEnabled;
    String reason;

    if (_controlType == 'dry_bulb') {
      economizerEnabled = _outdoorTemp < _highLimitTemp && _outdoorTemp < _returnTemp;
      reason = economizerEnabled
          ? 'OA temp (${_outdoorTemp.toStringAsFixed(0)}°F) below high limit (${_highLimitTemp.toStringAsFixed(0)}°F)'
          : 'OA temp (${_outdoorTemp.toStringAsFixed(0)}°F) above high limit or return temp';
    } else if (_controlType == 'enthalpy') {
      economizerEnabled = outdoorEnthalpy < _highLimitEnthalpy && outdoorEnthalpy < returnEnthalpy;
      reason = economizerEnabled
          ? 'OA enthalpy (${outdoorEnthalpy.toStringAsFixed(1)} BTU/lb) below limits'
          : 'OA enthalpy (${outdoorEnthalpy.toStringAsFixed(1)} BTU/lb) above limits';
    } else { // differential enthalpy
      economizerEnabled = outdoorEnthalpy < returnEnthalpy - 2;
      reason = economizerEnabled
          ? 'OA enthalpy lower than return air by ${(returnEnthalpy - outdoorEnthalpy).toStringAsFixed(1)} BTU/lb'
          : 'OA enthalpy not sufficiently lower than return air';
    }

    // Calculate mixed air temp when economizer is enabled
    double mixedAirTemp;
    if (economizerEnabled) {
      // Assume 100% OA when enabled and OA can meet setpoint
      if (_outdoorTemp <= _supplySetpoint) {
        mixedAirTemp = _outdoorTemp;
      } else {
        // Calculate mix ratio to achieve setpoint
        mixedAirTemp = _supplySetpoint;
      }
    } else {
      mixedAirTemp = _returnTemp; // Minimum OA only
    }

    String status = economizerEnabled ? 'ENABLED' : 'DISABLED';

    String recommendation;
    recommendation = reason + '. ';

    if (economizerEnabled) {
      if (_economizerType == 'integrated') {
        recommendation += 'Integrated economizer: Can operate with mechanical cooling for additional capacity.';
      } else {
        recommendation += 'Non-integrated: Economizer must be fully open or closed. No mixing with mechanical.';
      }

      if (_outdoorTemp < _supplySetpoint - 5) {
        recommendation += ' Full economizer mode - no mechanical cooling needed.';
      } else {
        recommendation += ' Partial economizer - may need supplemental cooling.';
      }
    } else {
      recommendation += 'Minimum outdoor air only. Mechanical cooling providing full capacity.';
    }

    switch (_controlType) {
      case 'dry_bulb':
        recommendation += ' Dry bulb control: Simple but doesn\'t account for humidity. Good for dry climates.';
        break;
      case 'enthalpy':
        recommendation += ' Enthalpy control: Accounts for humidity. Better for humid climates.';
        break;
      case 'differential':
        recommendation += ' Differential enthalpy: Compares OA to RA. Most efficient but complex.';
        break;
    }

    setState(() {
      _outdoorEnthalpy = outdoorEnthalpy;
      _returnEnthalpy = returnEnthalpy;
      _economizerEnabled = economizerEnabled;
      _mixedAirTemp = mixedAirTemp;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _outdoorTemp = 55;
      _outdoorRh = 50;
      _returnTemp = 75;
      _supplySetpoint = 55;
      _highLimitTemp = 70;
      _highLimitEnthalpy = 28;
      _controlType = 'dry_bulb';
      _economizerType = 'integrated';
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
        title: Text('Economizer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONTROL TYPE'),
              const SizedBox(height: 12),
              _buildControlTypeSelector(colors),
              const SizedBox(height: 12),
              _buildEconomizerTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SETPOINTS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'High Limit T', _highLimitTemp, 55, 80, '°F', (v) { setState(() => _highLimitTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'High Limit h', _highLimitEnthalpy, 20, 35, ' BTU/lb', (v) { setState(() => _highLimitEnthalpy = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Supply Setpoint', value: _supplySetpoint, min: 50, max: 65, unit: '°F', onChanged: (v) { setState(() => _supplySetpoint = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'OA Temp', _outdoorTemp, 30, 95, '°F', (v) { setState(() => _outdoorTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'OA RH', _outdoorRh, 20, 90, '%', (v) { setState(() => _outdoorRh = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Return Air Temp', value: _returnTemp, min: 70, max: 85, unit: '°F', onChanged: (v) { setState(() => _returnTemp = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'ECONOMIZER STATUS'),
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
        Expanded(child: Text('Economizer uses outdoor air for free cooling when conditions permit. Title 24 requires 75°F or lower high limit.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildControlTypeSelector(ZaftoColors colors) {
    final types = [('dry_bulb', 'Dry Bulb'), ('enthalpy', 'Enthalpy'), ('differential', 'Differential')];
    return Row(
      children: types.map((t) {
        final selected = _controlType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _controlType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEconomizerTypeSelector(ZaftoColors colors) {
    final types = [('integrated', 'Integrated'), ('nonintegrated', 'Non-Integrated')];
    return Row(
      children: types.map((t) {
        final selected = _economizerType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _economizerType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
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
    final enabled = _economizerEnabled ?? false;
    final statusColor = enabled ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Icon(enabled ? LucideIcons.wind : LucideIcons.snowflake, color: statusColor, size: 48),
          const SizedBox(height: 8),
          Text(_status ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
          Text(enabled ? 'Free Cooling Active' : 'Mechanical Cooling', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('${_outdoorEnthalpy?.toStringAsFixed(1)}', style: TextStyle(color: Colors.blue.shade700, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('OA Enthalpy', style: TextStyle(color: Colors.blue.shade600, fontSize: 10)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('${_returnEnthalpy?.toStringAsFixed(1)}', style: TextStyle(color: Colors.cyan.shade700, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('RA Enthalpy', style: TextStyle(color: Colors.cyan.shade600, fontSize: 10)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'OA Temp', '${_outdoorTemp.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Mixed Air', '${_mixedAirTemp?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Control', _controlType.replaceAll('_', ' '))),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(enabled ? LucideIcons.checkCircle : LucideIcons.info, color: enabled ? Colors.green : colors.textSecondary, size: 16),
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
