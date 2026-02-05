import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Fan Laws Calculator - Design System v2.6
/// Fan affinity laws for speed, flow, pressure, power
class FanLawScreen extends ConsumerStatefulWidget {
  const FanLawScreen({super.key});
  @override
  ConsumerState<FanLawScreen> createState() => _FanLawScreenState();
}

class _FanLawScreenState extends ConsumerState<FanLawScreen> {
  double _originalRpm = 1200;
  double _originalCfm = 5000;
  double _originalSp = 1.5; // inches WC
  double _originalBhp = 3.5;
  double _newRpm = 1000;
  String _solveFor = 'new_values'; // or 'rpm_for_cfm'
  double _targetCfm = 4000;

  double? _newCfm;
  double? _newSp;
  double? _newBhp;
  double? _rpmRatio;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    double newCfm, newSp, newBhp, rpmRatio;

    if (_solveFor == 'new_values') {
      // Calculate new values from new RPM
      rpmRatio = _newRpm / _originalRpm;

      // Fan Law 1: CFM varies directly with speed
      newCfm = _originalCfm * rpmRatio;

      // Fan Law 2: Pressure varies with speed squared
      newSp = _originalSp * math.pow(rpmRatio, 2);

      // Fan Law 3: Power varies with speed cubed
      newBhp = _originalBhp * math.pow(rpmRatio, 3);
    } else {
      // Calculate RPM needed for target CFM
      rpmRatio = _targetCfm / _originalCfm;
      _newRpm = _originalRpm * rpmRatio;
      newCfm = _targetCfm;
      newSp = _originalSp * math.pow(rpmRatio, 2);
      newBhp = _originalBhp * math.pow(rpmRatio, 3);
    }

    String recommendation;
    recommendation = 'Speed ratio: ${rpmRatio.toStringAsFixed(2)}. ';
    recommendation += 'CFM changes 1:1 with speed. ';
    recommendation += 'Pressure changes with speed². ';
    recommendation += 'Power changes with speed³. ';

    if (rpmRatio > 1.2) {
      recommendation += 'WARNING: Increasing speed >20% significantly increases power (${((math.pow(rpmRatio, 3) - 1) * 100).toStringAsFixed(0)}% more BHP). ';
    }

    if (rpmRatio < 1) {
      final powerSavings = (1 - math.pow(rpmRatio, 3)) * 100;
      recommendation += 'SAVINGS: ${powerSavings.toStringAsFixed(0)}% power reduction at reduced speed. VFD recommended. ';
    }

    if (newBhp > _originalBhp * 1.5) {
      recommendation += 'Check motor sizing - may need larger motor. ';
    }

    recommendation += 'VFDs use fan laws to save energy. ';
    recommendation += 'Measure actual performance after sheave changes.';

    setState(() {
      _newCfm = newCfm;
      _newSp = newSp;
      _newBhp = newBhp;
      _rpmRatio = rpmRatio;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _originalRpm = 1200;
      _originalCfm = 5000;
      _originalSp = 1.5;
      _originalBhp = 3.5;
      _newRpm = 1000;
      _solveFor = 'new_values';
      _targetCfm = 4000;
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
        title: Text('Fan Laws', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SOLVE FOR'),
              const SizedBox(height: 12),
              _buildSolveForSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ORIGINAL CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'RPM', _originalRpm, 200, 3600, '', (v) { setState(() => _originalRpm = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'CFM', _originalCfm, 500, 50000, '', (v) { setState(() => _originalCfm = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Static', _originalSp, 0.1, 10, '" WC', (v) { setState(() => _originalSp = v); _calculate(); }, decimals: 2)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'BHP', _originalBhp, 0.5, 50, '', (v) { setState(() => _originalBhp = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, _solveFor == 'new_values' ? 'NEW SPEED' : 'TARGET CFM'),
              const SizedBox(height: 12),
              if (_solveFor == 'new_values')
                _buildCompactSlider(colors, 'New RPM', _newRpm, 200, 3600, '', (v) { setState(() => _newRpm = v); _calculate(); })
              else
                _buildCompactSlider(colors, 'Target CFM', _targetCfm, 500, 50000, '', (v) { setState(() => _targetCfm = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'NEW CONDITIONS'),
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
        Icon(LucideIcons.fan, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Fan Laws: CFM ∝ RPM, Pressure ∝ RPM², Power ∝ RPM³. Small speed changes = big power changes.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSolveForSelector(ZaftoColors colors) {
    final options = [('new_values', 'Calculate from RPM'), ('rpm_for_cfm', 'Find RPM for CFM')];
    return Row(
      children: options.map((o) {
        final selected = _solveFor == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _solveFor = o.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: o != options.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(o.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
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
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_newCfm == null) return const SizedBox.shrink();

    final powerChange = ((_newBhp! / _originalBhp) - 1) * 100;
    final isReduction = powerChange < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Column(children: [
              Text('${_originalRpm.toStringAsFixed(0)}', style: TextStyle(color: colors.textSecondary, fontSize: 24, fontWeight: FontWeight.w600)),
              Text('Original RPM', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
            ]),
            Icon(LucideIcons.arrowRight, color: colors.textSecondary),
            Column(children: [
              Text('${_newRpm.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
              Text('New RPM', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: isReduction ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${powerChange.toStringAsFixed(0)}% ${isReduction ? "POWER SAVINGS" : "MORE POWER"}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildComparisonItem(colors, 'CFM', _originalCfm, _newCfm!)),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildComparisonItem(colors, 'SP (" WC)', _originalSp, _newSp!)),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildComparisonItem(colors, 'BHP', _originalBhp, _newBhp!)),
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

  Widget _buildComparisonItem(ZaftoColors colors, String label, double original, double newValue) {
    return Column(children: [
      Text('${newValue.toStringAsFixed(newValue < 10 ? 2 : 0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      Text('from ${original.toStringAsFixed(original < 10 ? 2 : 0)}', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 9)),
    ]);
  }
}
