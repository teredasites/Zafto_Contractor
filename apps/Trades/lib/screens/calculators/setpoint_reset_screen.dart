import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Setpoint Reset Calculator - Design System v2.6
/// Energy-saving supply air and water temperature reset
class SetpointResetScreen extends ConsumerStatefulWidget {
  const SetpointResetScreen({super.key});
  @override
  ConsumerState<SetpointResetScreen> createState() => _SetpointResetScreenState();
}

class _SetpointResetScreenState extends ConsumerState<SetpointResetScreen> {
  double _outdoorTemp = 75; // degrees F
  double _minSetpoint = 55; // degrees F (cooling design)
  double _maxSetpoint = 65; // degrees F (minimum cooling)
  double _startResetTemp = 65; // outdoor temp to start reset
  double _endResetTemp = 55; // outdoor temp at full reset
  String _resetType = 'sat';
  String _resetSchedule = 'outdoor';

  double? _currentSetpoint;
  double? _energySavings;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Linear reset calculation
    // Setpoint = Min + (Max - Min) × (OAT - EndTemp) / (StartTemp - EndTemp)
    double currentSetpoint;

    if (_outdoorTemp >= _startResetTemp) {
      // Above start temp - use minimum setpoint (max cooling)
      currentSetpoint = _minSetpoint;
    } else if (_outdoorTemp <= _endResetTemp) {
      // Below end temp - use maximum setpoint (min cooling)
      currentSetpoint = _maxSetpoint;
    } else {
      // In reset range - linear interpolation
      final resetRange = _startResetTemp - _endResetTemp;
      final tempAboveEnd = _outdoorTemp - _endResetTemp;
      final resetFraction = tempAboveEnd / resetRange;
      currentSetpoint = _maxSetpoint - ((_maxSetpoint - _minSetpoint) * resetFraction);
    }

    // Energy savings estimate
    // Approximately 2% savings per degree of reset
    final resetAmount = currentSetpoint - _minSetpoint;
    final energySavings = resetAmount * 2;

    String recommendation;
    recommendation = 'Current setpoint: ${currentSetpoint.toStringAsFixed(1)}°F at ${_outdoorTemp.toStringAsFixed(0)}°F outdoor. ';

    if (_outdoorTemp >= _startResetTemp) {
      recommendation += 'Full cooling mode. No reset active.';
    } else if (_outdoorTemp <= _endResetTemp) {
      recommendation += 'Maximum reset. ${resetAmount.toStringAsFixed(1)}°F warmer than design.';
    } else {
      recommendation += 'Partial reset active. Saving approximately ${energySavings.toStringAsFixed(0)}% energy.';
    }

    switch (_resetType) {
      case 'sat':
        recommendation += ' Supply air reset: 55°F design, reset to 60-65°F in mild weather. Verify humidity control.';
        break;
      case 'chws':
        recommendation += ' Chilled water reset: 44°F design, reset to 48-55°F. Monitor coil performance.';
        break;
      case 'hws':
        recommendation += ' Hot water reset: 180°F design, reset down to 120°F. Verify heat output adequate.';
        break;
      case 'condenser':
        recommendation += ' Condenser water reset: Lower limit by wet bulb + approach. Check chiller limits.';
        break;
    }

    switch (_resetSchedule) {
      case 'outdoor':
        recommendation += ' OA reset: Simple, predictable. May not reflect actual load.';
        break;
      case 'demand':
        recommendation += ' Demand-based: Uses valve/damper position. Better efficiency but needs tuning.';
        break;
      case 'zone':
        recommendation += ' Zone-based: Reset based on worst zone. Best for VAV systems.';
        break;
    }

    recommendation += ' Typical savings 10-20% on fan/pump energy with proper reset.';

    setState(() {
      _currentSetpoint = currentSetpoint;
      _energySavings = energySavings;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _outdoorTemp = 75;
      _minSetpoint = 55;
      _maxSetpoint = 65;
      _startResetTemp = 65;
      _endResetTemp = 55;
      _resetType = 'sat';
      _resetSchedule = 'outdoor';
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
        title: Text('Setpoint Reset', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'RESET TYPE'),
              const SizedBox(height: 12),
              _buildResetTypeSelector(colors),
              const SizedBox(height: 12),
              _buildScheduleSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SETPOINT RANGE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Min (Design)', _minSetpoint, 40, 60, '°F', (v) { setState(() => _minSetpoint = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Max (Reset)', _maxSetpoint, 55, 75, '°F', (v) { setState(() => _maxSetpoint = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RESET SCHEDULE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Start OAT', _startResetTemp, 50, 80, '°F', (v) { setState(() => _startResetTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'End OAT', _endResetTemp, 40, 70, '°F', (v) { setState(() => _endResetTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CURRENT CONDITIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor Temperature', value: _outdoorTemp, min: 30, max: 100, unit: '°F', onChanged: (v) { setState(() => _outdoorTemp = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'RESET OUTPUT'),
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
        Icon(LucideIcons.thermometerSun, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Setpoint reset saves 10-20% energy. Reset supply air/water temp when load is low. Monitor humidity and comfort.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildResetTypeSelector(ZaftoColors colors) {
    final types = [('sat', 'Supply Air'), ('chws', 'CHW Supply'), ('hws', 'HW Supply'), ('condenser', 'Cond Water')];
    return Row(
      children: types.map((t) {
        final selected = _resetType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _resetType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleSelector(ZaftoColors colors) {
    final schedules = [('outdoor', 'OA Temp'), ('demand', 'Demand'), ('zone', 'Zone Request')];
    return Row(
      children: schedules.map((s) {
        final selected = _resetSchedule == s.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _resetSchedule = s.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: s != schedules.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
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
    if (_currentSetpoint == null) return const SizedBox.shrink();

    final isReset = _currentSetpoint! > _minSetpoint;
    final resetAmount = _currentSetpoint! - _minSetpoint;
    final statusColor = isReset ? Colors.green : colors.accentPrimary;
    final status = isReset ? 'RESET ACTIVE' : 'DESIGN SETPOINT';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_currentSetpoint?.toStringAsFixed(1)}°F', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Current Setpoint', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('$status ${isReset ? "(+${resetAmount.toStringAsFixed(1)}°F)" : ""}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          if (isReset)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text('~${_energySavings?.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.w600)),
                Text('Estimated Energy Savings', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Outdoor', '${_outdoorTemp.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Min SP', '${_minSetpoint.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Max SP', '${_maxSetpoint.toStringAsFixed(0)}°F')),
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
