import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Fault Current Calculator - Design System v2.6
class FaultCurrentScreen extends ConsumerStatefulWidget {
  const FaultCurrentScreen({super.key});
  @override
  ConsumerState<FaultCurrentScreen> createState() => _FaultCurrentScreenState();
}

class _FaultCurrentScreenState extends ConsumerState<FaultCurrentScreen> {
  bool _isThreePhase = true;
  final _kvaController = TextEditingController(text: '75');
  final _impedanceController = TextEditingController(text: '2.5');
  final _voltageController = TextEditingController(text: '480');
  final _lengthController = TextEditingController();
  String _conductorSize = '4/0 AWG';
  String _conduitType = 'Steel';
  Map<String, dynamic>? _results;

  static const Map<String, Map<String, double>> _conductorZ = {
    '14 AWG': {'Steel': 3.14, 'PVC': 3.10}, '12 AWG': {'Steel': 1.98, 'PVC': 1.96}, '10 AWG': {'Steel': 1.24, 'PVC': 1.23},
    '8 AWG': {'Steel': 0.78, 'PVC': 0.78}, '6 AWG': {'Steel': 0.49, 'PVC': 0.49}, '4 AWG': {'Steel': 0.31, 'PVC': 0.31},
    '3 AWG': {'Steel': 0.25, 'PVC': 0.25}, '2 AWG': {'Steel': 0.19, 'PVC': 0.19}, '1 AWG': {'Steel': 0.16, 'PVC': 0.15},
    '1/0 AWG': {'Steel': 0.13, 'PVC': 0.12}, '2/0 AWG': {'Steel': 0.10, 'PVC': 0.10}, '3/0 AWG': {'Steel': 0.082, 'PVC': 0.077},
    '4/0 AWG': {'Steel': 0.067, 'PVC': 0.062}, '250 kcmil': {'Steel': 0.057, 'PVC': 0.052}, '300 kcmil': {'Steel': 0.049, 'PVC': 0.044},
    '350 kcmil': {'Steel': 0.043, 'PVC': 0.038}, '400 kcmil': {'Steel': 0.038, 'PVC': 0.033}, '500 kcmil': {'Steel': 0.032, 'PVC': 0.027},
  };

  @override
  void dispose() { _kvaController.dispose(); _impedanceController.dispose(); _voltageController.dispose(); _lengthController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fault Current', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildMethodCard(colors),
            const SizedBox(height: 24),
            _buildPhaseSelector(colors),
            const SizedBox(height: 24),
            Text('TRANSFORMER DATA', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'kVA Rating', unit: 'kVA', controller: _kvaController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Impedance', unit: '%Z', controller: _impedanceController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Secondary Voltage', unit: 'V', controller: _voltageController),
            const SizedBox(height: 24),
            Text('CONDUCTOR DATA (Optional)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'One-Way Length', unit: 'ft', hint: 'Leave blank for xfmr only', controller: _lengthController),
            const SizedBox(height: 12),
            ZaftoInputFieldDropdown<String>(label: 'Conductor Size', value: _conductorSize, items: _conductorZ.keys.toList(), itemLabel: (s) => s, onChanged: (v) => setState(() => _conductorSize = v)),
            const SizedBox(height: 12),
            ZaftoInputFieldDropdown<String>(label: 'Conduit Type', value: _conduitType, items: const ['Steel', 'PVC'], itemLabel: (s) => s, onChanged: (v) => setState(() => _conduitType = v)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
            const SizedBox(height: 24),
            if (_results != null) _buildResults(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMethodCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Point-to-Point Method', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          Text('IEEE 141 / NEC 110.24', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildPhaseSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [false, true].map((v) {
        final sel = v == _isThreePhase;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _isThreePhase = v); },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: sel ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(v ? '3-PHASE' : '1-PHASE', textAlign: TextAlign.center, style: TextStyle(color: sel ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600))),
        ));
      }).toList()),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentError.withValues(alpha: 0.3))),
      child: Column(children: [
        Icon(LucideIcons.zap, color: colors.accentError, size: 32),
        const SizedBox(height: 12),
        Text('${(_results!['faultCurrent'] as double).toStringAsFixed(0)}', style: TextStyle(color: colors.accentError, fontSize: 48, fontWeight: FontWeight.w700)),
        Text('AMPS RMS', style: TextStyle(color: colors.textTertiary, letterSpacing: 1)),
        const SizedBox(height: 20),
        _buildResultRow(colors, 'At Transformer', '${(_results!['transformerFC'] as double).toStringAsFixed(0)} A'),
        if (_results!['conductorFC'] != null) ...[const SizedBox(height: 8), _buildResultRow(colors, 'At Load (after conductor)', '${(_results!['conductorFC'] as double).toStringAsFixed(0)} A')],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3))),
          child: Row(children: [Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20), const SizedBox(width: 8), Expanded(child: Text('Verify OCPD and equipment AIC ratings exceed this value', style: TextStyle(color: colors.accentWarning, fontSize: 12)))]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _calculate() {
    final colors = ref.read(zaftoColorsProvider);
    final kva = double.tryParse(_kvaController.text);
    final impedance = double.tryParse(_impedanceController.text);
    final voltage = double.tryParse(_voltageController.text);
    if (kva == null || impedance == null || voltage == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter all transformer data'), backgroundColor: colors.accentError)); return; }
    final fla = _isThreePhase ? (kva * 1000) / (voltage * math.sqrt(3)) : (kva * 1000) / voltage;
    final transformerFC = fla * (100 / impedance);
    final length = double.tryParse(_lengthController.text);
    double? conductorFC;
    if (length != null && length > 0) {
      final zPerFt = (_conductorZ[_conductorSize]?[_conduitType] ?? 0.05) / 1000;
      final totalZ = _isThreePhase ? zPerFt * length * 1.732 : zPerFt * length * 2;
      final transformerZ = voltage / transformerFC;
      conductorFC = voltage / (transformerZ + totalZ);
    }
    setState(() { _results = {'transformerFC': transformerFC, 'conductorFC': conductorFC, 'faultCurrent': conductorFC ?? transformerFC}; });
  }

  void _reset() { _kvaController.text = '75'; _impedanceController.text = '2.5'; _voltageController.text = '480'; _lengthController.clear(); setState(() { _isThreePhase = true; _conductorSize = '4/0 AWG'; _conduitType = 'Steel'; _results = null; }); }
}
