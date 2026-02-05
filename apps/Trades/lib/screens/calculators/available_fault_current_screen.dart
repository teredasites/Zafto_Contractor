import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Available Fault Current Calculator - Design System v2.6
/// Point-to-point method for fault current at any point
class AvailableFaultCurrentScreen extends ConsumerStatefulWidget {
  const AvailableFaultCurrentScreen({super.key});
  @override
  ConsumerState<AvailableFaultCurrentScreen> createState() => _AvailableFaultCurrentScreenState();
}

class _AvailableFaultCurrentScreenState extends ConsumerState<AvailableFaultCurrentScreen> {
  double _utilityFault = 50000;
  double _transformerKva = 75;
  double _transformerZ = 5.75;
  int _voltage = 208;
  double _conductorLength = 50;
  String _conductorSize = '4';
  String _conductorType = 'copper';

  double? _transformerFault;
  double? _conductorImpedance;
  double? _pointFaultCurrent;
  String? _aicRating;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Available Fault', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SOURCE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Utility Fault Current', value: _utilityFault, min: 10000, max: 100000, unit: ' A', onChanged: (v) { setState(() => _utilityFault = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TRANSFORMER'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'kVA', value: _transformerKva, min: 15, max: 1000, unit: ' kVA', onChanged: (v) { setState(() => _transformerKva = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Impedance (%Z)', value: _transformerZ, min: 2, max: 8, unit: '%', isDecimal: true, onChanged: (v) { setState(() => _transformerZ = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Secondary Voltage', options: const ['208V', '240V', '480V'], selectedIndex: _voltage == 208 ? 0 : _voltage == 240 ? 1 : 2, onChanged: (i) { setState(() => _voltage = [208, 240, 480][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDUCTOR'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Length (one-way)', value: _conductorLength, min: 10, max: 500, unit: ' ft', onChanged: (v) { setState(() => _conductorLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildConductorSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FAULT CURRENT AT POINT'),
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
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('Point-to-point method per IEEE 141 (Red Book)', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isDecimal = false, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${isDecimal ? value.toStringAsFixed(2) : value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: isDecimal ? ((max - min) * 10).round() : (max - min).round() ~/ 5, onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: List.generate(options.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(i); },
            child: Container(
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: selectedIndex == i ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: selectedIndex == i ? colors.accentPrimary : colors.borderSubtle)),
              alignment: Alignment.center,
              child: Text(options[i], style: TextStyle(color: selectedIndex == i ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildConductorSelector(ZaftoColors colors) {
    final sizes = ['14', '12', '10', '8', '6', '4', '3', '2', '1', '1/0', '2/0', '3/0', '4/0', '250', '350', '500'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _conductorSize,
              dropdownColor: colors.bgElevated,
              underline: const SizedBox(),
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
              items: sizes.map((s) => DropdownMenuItem(value: s, child: Text('#$s'))).toList(),
              onChanged: (v) { setState(() => _conductorSize = v!); _calculate(); },
            ),
          ])),
          const SizedBox(width: 24),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              _buildMaterialChip(colors, 'Cu', 'copper'),
              const SizedBox(width: 8),
              _buildMaterialChip(colors, 'Al', 'aluminum'),
            ]),
          ])),
        ]),
      ]),
    );
  }

  Widget _buildMaterialChip(ZaftoColors colors, String label, String value) {
    return GestureDetector(
      onTap: () { setState(() => _conductorType = value); _calculate(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: _conductorType == value ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: _conductorType == value ? colors.accentPrimary : colors.borderSubtle)),
        child: Text(label, style: TextStyle(color: _conductorType == value ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${((_pointFaultCurrent ?? 0) / 1000).toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('kA available fault current', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Min AIC: $_aicRating', style: TextStyle(color: colors.warning, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Utility available', '${(_utilityFault / 1000).toStringAsFixed(1)} kA'),
        _buildCalcRow(colors, 'At transformer secondary', '${((_transformerFault ?? 0) / 1000).toStringAsFixed(1)} kA'),
        _buildCalcRow(colors, 'Conductor impedance factor', '${_conductorImpedance?.toStringAsFixed(4) ?? '0'} Ω'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'At end of ${_conductorLength.toStringAsFixed(0)} ft', '${((_pointFaultCurrent ?? 0) / 1000).toStringAsFixed(2)} kA', highlight: true),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13))),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    // Step 1: Transformer secondary fault current (assuming infinite utility)
    // I = kVA × 1000 / (V × √3 × %Z/100)
    final xfmrFla = (_transformerKva * 1000) / (_voltage * 1.732);
    final xfmrFault = xfmrFla / (_transformerZ / 100);

    // Actual transformer fault considers utility impedance
    // Using simplified method: 1/Itotal = 1/Iutility + 1/Ixfmr
    final actualXfmrFault = 1 / ((1 / _utilityFault) + (1 / xfmrFault));

    // Step 2: Conductor impedance
    // Z = R × L × 2 / 1000 (ohms for round trip)
    final resistance = _getResistance(_conductorSize, _conductorType);
    final reactance = _getReactance(_conductorSize);
    final impedance = ((resistance + reactance) * _conductorLength * 2) / 1000;

    // Step 3: Fault current at point
    // Using point-to-point: Ipoint = V / (√3 × Z)
    final lineVoltage = _voltage.toDouble();
    final totalZ = (lineVoltage / (1.732 * actualXfmrFault)) + impedance;
    final pointFault = lineVoltage / (1.732 * totalZ);

    // Determine AIC rating needed
    String aic;
    if (pointFault <= 10000) aic = '10 kAIC';
    else if (pointFault <= 14000) aic = '14 kAIC';
    else if (pointFault <= 18000) aic = '18 kAIC';
    else if (pointFault <= 22000) aic = '22 kAIC';
    else if (pointFault <= 25000) aic = '25 kAIC';
    else if (pointFault <= 35000) aic = '35 kAIC';
    else if (pointFault <= 42000) aic = '42 kAIC';
    else if (pointFault <= 65000) aic = '65 kAIC';
    else aic = '100 kAIC+';

    setState(() {
      _transformerFault = actualXfmrFault;
      _conductorImpedance = impedance;
      _pointFaultCurrent = pointFault;
      _aicRating = aic;
    });
  }

  double _getResistance(String size, String material) {
    // Ohms per 1000 ft at 75°C
    const copperR = {
      '14': 3.14, '12': 1.98, '10': 1.24, '8': 0.778, '6': 0.491,
      '4': 0.308, '3': 0.245, '2': 0.194, '1': 0.154, '1/0': 0.122,
      '2/0': 0.0967, '3/0': 0.0766, '4/0': 0.0608, '250': 0.0515, '350': 0.0367, '500': 0.0258,
    };
    const aluminumR = {
      '14': 5.17, '12': 3.25, '10': 2.04, '8': 1.28, '6': 0.808,
      '4': 0.508, '3': 0.403, '2': 0.319, '1': 0.253, '1/0': 0.201,
      '2/0': 0.159, '3/0': 0.126, '4/0': 0.100, '250': 0.0847, '350': 0.0605, '500': 0.0424,
    };
    final table = material == 'copper' ? copperR : aluminumR;
    return table[size] ?? 0.308;
  }

  double _getReactance(String size) {
    // Approximate reactance (Ohms per 1000 ft) - varies by conduit type
    const reactance = {
      '14': 0.058, '12': 0.054, '10': 0.050, '8': 0.052, '6': 0.051,
      '4': 0.048, '3': 0.047, '2': 0.045, '1': 0.046, '1/0': 0.044,
      '2/0': 0.043, '3/0': 0.042, '4/0': 0.041, '250': 0.041, '350': 0.039, '500': 0.038,
    };
    return reactance[size] ?? 0.048;
  }

  void _reset() {
    setState(() {
      _utilityFault = 50000;
      _transformerKva = 75;
      _transformerZ = 5.75;
      _voltage = 208;
      _conductorLength = 50;
      _conductorSize = '4';
      _conductorType = 'copper';
    });
    _calculate();
  }
}
