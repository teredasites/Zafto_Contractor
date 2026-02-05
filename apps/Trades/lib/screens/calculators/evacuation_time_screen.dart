import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Evacuation Time Calculator - Design System v2.6
/// Vacuum pump evacuation time estimation
class EvacuationTimeScreen extends ConsumerStatefulWidget {
  const EvacuationTimeScreen({super.key});
  @override
  ConsumerState<EvacuationTimeScreen> createState() => _EvacuationTimeScreenState();
}

class _EvacuationTimeScreenState extends ConsumerState<EvacuationTimeScreen> {
  double _systemVolume = 5; // cubic feet
  double _pumpCfm = 4;
  double _targetMicrons = 500;
  double _startPressure = 760000; // microns (1 atm)
  String _systemType = 'residential';
  bool _hasOilContamination = false;

  double? _pumpdownTime;
  double? _deepVacuumTime;
  double? _totalTime;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Evacuation time formula (simplified)
    // Time = (Volume / CFM) × ln(P1/P2) × correction factors

    // Initial pumpdown to ~1000 microns
    final pumpdownRatio = _startPressure / 1000;
    final pumpdownTime = (_systemVolume / _pumpCfm) * _ln(pumpdownRatio);

    // Deep vacuum from 1000 to target
    // Much slower as pump efficiency drops at deep vacuum
    final deepVacuumRatio = 1000 / _targetMicrons;
    final efficiencyFactor = _targetMicrons < 500 ? 2.5 : 1.5;
    final deepVacuumTime = (_systemVolume / _pumpCfm) * _ln(deepVacuumRatio) * efficiencyFactor;

    // Contamination factor
    double contaminationFactor = 1.0;
    if (_hasOilContamination) {
      contaminationFactor = 2.0;
    }

    // System type factor
    double systemFactor;
    switch (_systemType) {
      case 'residential':
        systemFactor = 1.0;
        break;
      case 'commercial':
        systemFactor = 1.2;
        break;
      case 'chiller':
        systemFactor = 1.5;
        break;
      default:
        systemFactor = 1.0;
    }

    final totalTime = (pumpdownTime + deepVacuumTime) * contaminationFactor * systemFactor;

    String recommendation;
    if (_targetMicrons <= 250) {
      recommendation = 'Deep vacuum (${_targetMicrons.toStringAsFixed(0)} microns) for R-410A. Triple evacuate for moisture contamination.';
    } else if (_targetMicrons <= 500) {
      recommendation = 'Standard vacuum (${_targetMicrons.toStringAsFixed(0)} microns). Acceptable for most systems.';
    } else {
      recommendation = 'Shallow vacuum. Consider deeper evacuation for optimal performance.';
    }

    if (_hasOilContamination) {
      recommendation += ' OIL CONTAMINATION: Use filter/drier in vacuum line. May require multiple evacuations and nitrogen breaks.';
    }

    if (totalTime > 60) {
      recommendation += ' Long evacuation time: Check for leaks, use larger pump, or pre-evacuate with nitrogen.';
    }

    recommendation += ' Hold vacuum 15+ minutes to verify no leaks. Rise of >250 microns indicates moisture or leak.';

    if (_pumpCfm < 2) {
      recommendation += ' Small pump: Consider upgrading to 4+ CFM for faster evacuation.';
    }

    setState(() {
      _pumpdownTime = pumpdownTime;
      _deepVacuumTime = deepVacuumTime * contaminationFactor;
      _totalTime = totalTime;
      _recommendation = recommendation;
    });
  }

  double _ln(double x) {
    if (x <= 0) return 0;
    double result = 0;
    double term = (x - 1) / (x + 1);
    double power = term;
    for (int i = 1; i < 30; i += 2) {
      result += power / i;
      power *= term * term;
    }
    return 2 * result;
  }

  void _reset() {
    setState(() {
      _systemVolume = 5;
      _pumpCfm = 4;
      _targetMicrons = 500;
      _startPressure = 760000;
      _systemType = 'residential';
      _hasOilContamination = false;
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
        title: Text('Evacuation Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSystemTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System Volume', value: _systemVolume, min: 1, max: 50, unit: ' cu ft', onChanged: (v) { setState(() => _systemVolume = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'VACUUM PUMP'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Pump CFM', _pumpCfm, 1, 12, ' CFM', (v) { setState(() => _pumpCfm = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Target', _targetMicrons, 200, 1000, ' µ', (v) { setState(() => _targetMicrons = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Oil/moisture contamination present', _hasOilContamination, (v) { setState(() => _hasOilContamination = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EVACUATION TIME'),
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
        Expanded(child: Text('Target 500 microns minimum, 250 microns for R-410A. Hold 15+ min to verify no rise.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    final types = [('residential', 'Residential'), ('commercial', 'Commercial'), ('chiller', 'Chiller')];
    return Row(
      children: types.map((t) {
        final selected = _systemType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _systemType = t.$1); _calculate(); },
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

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
      ),
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
    if (_totalTime == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_totalTime?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Minutes Total', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('${_pumpdownTime?.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                  Text('Initial Pumpdown', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('${_deepVacuumTime?.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                  Text('Deep Vacuum', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Volume', '${_systemVolume.toStringAsFixed(0)} cu ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Pump', '${_pumpCfm.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Target', '${_targetMicrons.toStringAsFixed(0)} µ')),
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
