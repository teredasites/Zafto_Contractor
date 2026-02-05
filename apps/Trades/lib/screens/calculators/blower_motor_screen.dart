import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Blower Motor Calculator - Design System v2.6
/// CFM and motor selection for air handlers
class BlowerMotorScreen extends ConsumerStatefulWidget {
  const BlowerMotorScreen({super.key});
  @override
  ConsumerState<BlowerMotorScreen> createState() => _BlowerMotorScreenState();
}

class _BlowerMotorScreenState extends ConsumerState<BlowerMotorScreen> {
  double _systemTons = 3;
  double _staticPressure = 0.5;
  String _motorType = 'psc';
  String _application = 'residential';
  double _customCfm = 0;
  bool _useCustomCfm = false;

  double? _requiredCfm;
  double? _motorHp;
  double? _rpm;
  String? _motorSelection;
  double? _efficiency;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // CFM requirement: typically 400 CFM per ton for cooling
    double cfm;
    if (_useCustomCfm && _customCfm > 0) {
      cfm = _customCfm;
    } else {
      cfm = _systemTons * 400;
    }

    // Motor HP calculation
    // HP = (CFM × SP) / (6356 × efficiency)
    // Typical blower efficiency 50-65%
    double motorEfficiency;
    if (_motorType == 'ecm') {
      motorEfficiency = 0.80;
    } else if (_motorType == 'x13') {
      motorEfficiency = 0.70;
    } else {
      motorEfficiency = 0.55; // PSC
    }

    final calculatedHp = (cfm * _staticPressure) / (6356 * motorEfficiency);

    // Round up to standard motor sizes
    double motorHp;
    String motorSelection;
    if (calculatedHp <= 0.125) {
      motorHp = 0.125;
      motorSelection = '1/8 HP';
    } else if (calculatedHp <= 0.167) {
      motorHp = 0.167;
      motorSelection = '1/6 HP';
    } else if (calculatedHp <= 0.25) {
      motorHp = 0.25;
      motorSelection = '1/4 HP';
    } else if (calculatedHp <= 0.33) {
      motorHp = 0.33;
      motorSelection = '1/3 HP';
    } else if (calculatedHp <= 0.5) {
      motorHp = 0.5;
      motorSelection = '1/2 HP';
    } else if (calculatedHp <= 0.75) {
      motorHp = 0.75;
      motorSelection = '3/4 HP';
    } else {
      motorHp = 1.0;
      motorSelection = '1 HP';
    }

    // RPM selection based on application
    double rpm;
    if (_application == 'residential') {
      rpm = 1075; // Standard
    } else {
      rpm = 1140; // Commercial
    }

    // Efficiency rating
    double efficiency;
    switch (_motorType) {
      case 'ecm': efficiency = 80; break;
      case 'x13': efficiency = 70; break;
      default: efficiency = 55;
    }

    String recommendation;
    if (_motorType == 'ecm') {
      recommendation = 'ECM motor: Variable speed, highest efficiency. Maintains CFM across static pressure range. Best for zoning.';
    } else if (_motorType == 'x13') {
      recommendation = 'X13 motor: Constant torque, moderate efficiency. Good upgrade from PSC, maintains CFM better than PSC.';
    } else {
      recommendation = 'PSC motor: Fixed speed, lowest cost. CFM drops significantly with increased static pressure.';
    }

    if (_staticPressure > 0.7) {
      recommendation += ' High static pressure - verify ductwork is properly sized.';
    }

    if (cfm / _systemTons < 350) {
      recommendation += ' Low CFM/ton ratio - may cause low suction pressure or coil freezing.';
    } else if (cfm / _systemTons > 450) {
      recommendation += ' High CFM/ton ratio - good for humid climates, may reduce dehumidification.';
    }

    setState(() {
      _requiredCfm = cfm;
      _motorHp = motorHp;
      _rpm = rpm;
      _motorSelection = motorSelection;
      _efficiency = efficiency;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemTons = 3;
      _staticPressure = 0.5;
      _motorType = 'psc';
      _application = 'residential';
      _customCfm = 0;
      _useCustomCfm = false;
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
        title: Text('Blower Motor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System Capacity', value: _systemTons, min: 1, max: 10, unit: ' tons', decimals: 1, onChanged: (v) { setState(() => _systemTons = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Static Pressure', value: _staticPressure, min: 0.2, max: 1.2, unit: '" WC', decimals: 2, onChanged: (v) { setState(() => _staticPressure = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Use Custom CFM', _useCustomCfm, (v) { setState(() => _useCustomCfm = v); _calculate(); }),
              if (_useCustomCfm) ...[
                const SizedBox(height: 8),
                _buildSliderRow(colors, label: 'Custom CFM', value: _customCfm > 0 ? _customCfm : _systemTons * 400, min: 400, max: 4000, unit: ' CFM', onChanged: (v) { setState(() => _customCfm = v); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MOTOR TYPE'),
              const SizedBox(height: 12),
              _buildMotorTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Application', options: const ['Residential', 'Commercial'], selectedIndex: _application == 'residential' ? 0 : 1, onChanged: (i) { setState(() => _application = i == 0 ? 'residential' : 'commercial'); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'MOTOR SELECTION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildMotorComparison(colors),
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
        Icon(LucideIcons.fan, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size blower motor by CFM and static pressure. ECM motors maintain CFM; PSC motors drop CFM as pressure rises.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMotorTypeSelector(ZaftoColors colors) {
    final types = [
      ('psc', 'PSC', 'Fixed speed'),
      ('x13', 'X13', 'Constant torque'),
      ('ecm', 'ECM', 'Variable speed'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _motorType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _motorType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 10)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderDefault, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_motorHp == null) return const SizedBox.shrink();

    Color efficiencyColor;
    if (_efficiency! >= 75) {
      efficiencyColor = Colors.green;
    } else if (_efficiency! >= 65) {
      efficiencyColor = colors.accentPrimary;
    } else {
      efficiencyColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_motorSelection ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('${_motorType.toUpperCase()} Motor', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'CFM', '${_requiredCfm?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'RPM', '${_rpm?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItemColored(colors, 'Efficiency', '${_efficiency?.toStringAsFixed(0)}%', efficiencyColor)),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CFM/TON RATIO', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${(_requiredCfm! / _systemTons).toStringAsFixed(0)} CFM/ton (target: 400)', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorComparison(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MOTOR TYPE COMPARISON', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildComparisonRow(colors, 'PSC', 'Fixed speed, 55% eff', '\$50-100'),
          _buildComparisonRow(colors, 'X13', 'Const. torque, 70% eff', '\$150-250'),
          _buildComparisonRow(colors, 'ECM', 'Variable, 80% eff', '\$300-500'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(ZaftoColors colors, String type, String desc, String cost) {
    final selected = _motorType == type.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: selected ? colors.accentPrimary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        SizedBox(width: 40, child: Text(type, style: TextStyle(color: selected ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(cost, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }

  Widget _buildResultItemColored(ZaftoColors colors, String label, String value, Color valueColor) {
    return Column(children: [
      Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
