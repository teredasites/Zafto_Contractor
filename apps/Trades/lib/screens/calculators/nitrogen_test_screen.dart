import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Nitrogen Pressure Test Calculator - Design System v2.6
/// Standing pressure test for refrigerant systems
class NitrogenTestScreen extends ConsumerStatefulWidget {
  const NitrogenTestScreen({super.key});
  @override
  ConsumerState<NitrogenTestScreen> createState() => _NitrogenTestScreenState();
}

class _NitrogenTestScreenState extends ConsumerState<NitrogenTestScreen> {
  double _testPressure = 500;
  double _initialReading = 500;
  double _finalReading = 498;
  double _testDuration = 24; // hours
  double _ambientTempStart = 70;
  double _ambientTempEnd = 68;
  String _refrigerantType = 'r410a';
  String _systemType = 'mini_split';

  double? _pressureChange;
  double? _tempCorrection;
  double? _adjustedChange;
  bool? _passesTest;
  String? _testStandard;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Raw pressure change
    final pressureChange = _initialReading - _finalReading;

    // Temperature correction using ideal gas law approximation
    // P1/T1 = P2/T2 -> corrected = P2 * (T1/T2)
    final t1Abs = _ambientTempStart + 460; // Rankine
    final t2Abs = _ambientTempEnd + 460;
    final tempCorrectedFinal = _finalReading * (t1Abs / t2Abs);
    final tempCorrection = tempCorrectedFinal - _finalReading;

    // Adjusted pressure change accounting for temperature
    final adjustedChange = _initialReading - tempCorrectedFinal;

    // Determine test standard based on refrigerant
    String testStandard;
    double allowableChange;
    double minTestPressure;

    switch (_refrigerantType) {
      case 'r410a':
        minTestPressure = 500;
        allowableChange = 5; // psi over 24 hours
        testStandard = 'R-410A: Min 500 psi, max 5 psi drop in 24 hrs';
        break;
      case 'r22':
        minTestPressure = 300;
        allowableChange = 3;
        testStandard = 'R-22: Min 300 psi, max 3 psi drop in 24 hrs';
        break;
      case 'r134a':
        minTestPressure = 150;
        allowableChange = 3;
        testStandard = 'R-134a: Min 150 psi, max 3 psi drop in 24 hrs';
        break;
      default:
        minTestPressure = 400;
        allowableChange = 5;
        testStandard = 'Standard: Max 5 psi drop in 24 hrs';
    }

    // Scale allowable change for test duration
    final scaledAllowable = allowableChange * (_testDuration / 24);

    // Pass/fail determination
    final passesTest = adjustedChange <= scaledAllowable && _testPressure >= minTestPressure;

    String recommendation;
    if (passesTest) {
      recommendation = 'PASS: System holds pressure. Safe to proceed with evacuation and charging.';
    } else if (adjustedChange > scaledAllowable) {
      recommendation = 'FAIL: Pressure drop exceeds allowable. Check all joints, service valves, and fittings for leaks.';
    } else {
      recommendation = 'FAIL: Test pressure too low. Increase to minimum ${minTestPressure.toStringAsFixed(0)} psi.';
    }

    if ((tempCorrection).abs() > 5) {
      recommendation += ' Significant temp change: ${tempCorrection.toStringAsFixed(1)} psi correction applied.';
    }

    if (_systemType == 'mini_split') {
      recommendation += ' Mini-split: Check flare connections with soap bubbles at high pressure.';
    } else if (_systemType == 'chiller') {
      recommendation += ' Chiller: Extended test (48-72 hrs) recommended for large volume.';
    }

    recommendation += ' Always use dry nitrogen with trace gas for leak detection.';

    setState(() {
      _pressureChange = pressureChange;
      _tempCorrection = tempCorrection;
      _adjustedChange = adjustedChange;
      _passesTest = passesTest;
      _testStandard = testStandard;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _testPressure = 500;
      _initialReading = 500;
      _finalReading = 498;
      _testDuration = 24;
      _ambientTempStart = 70;
      _ambientTempEnd = 68;
      _refrigerantType = 'r410a';
      _systemType = 'mini_split';
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
        title: Text('Nitrogen Test', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildRefrigerantSelector(colors),
              const SizedBox(height: 12),
              _buildSystemTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEST READINGS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Test Pressure', value: _testPressure, min: 100, max: 650, unit: ' psi', onChanged: (v) { setState(() { _testPressure = v; _initialReading = v; }); _calculate(); }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Initial', _initialReading, 100, 650, ' psi', (v) { setState(() => _initialReading = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Final', _finalReading, 100, 650, ' psi', (v) { setState(() => _finalReading = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Test Duration', value: _testDuration, min: 1, max: 72, unit: ' hrs', onChanged: (v) { setState(() => _testDuration = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AMBIENT TEMPS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Start', _ambientTempStart, 40, 100, '°F', (v) { setState(() => _ambientTempStart = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'End', _ambientTempEnd, 40, 100, '°F', (v) { setState(() => _ambientTempEnd = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TEST RESULTS'),
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
        Expanded(child: Text('Standing pressure test: 24 hrs minimum. Account for ambient temp changes. Max 5 psi drop typical.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildRefrigerantSelector(ZaftoColors colors) {
    final refs = [('r410a', 'R-410A'), ('r22', 'R-22'), ('r134a', 'R-134a')];
    return Row(
      children: refs.map((r) {
        final selected = _refrigerantType == r.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _refrigerantType = r.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: r != refs.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    final types = [('mini_split', 'Mini-Split'), ('split', 'Split System'), ('chiller', 'Chiller')];
    return Row(
      children: types.map((t) {
        final selected = _systemType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _systemType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
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
    if (_passesTest == null) return const SizedBox.shrink();

    final passed = _passesTest ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: passed ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(passed ? 'PASS' : 'FAIL', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Text(_testStandard ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Raw Drop', '${_pressureChange?.toStringAsFixed(1)} psi')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Temp Corr.', '${_tempCorrection?.toStringAsFixed(1)} psi')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Adjusted', '${_adjustedChange?.toStringAsFixed(1)} psi')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: passed ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(passed ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: passed ? Colors.green : Colors.red, size: 16),
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
