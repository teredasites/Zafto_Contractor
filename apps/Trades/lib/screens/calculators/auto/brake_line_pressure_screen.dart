import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Brake Line Pressure Calculator - Hydraulic system pressure
class BrakeLinePressureScreen extends ConsumerStatefulWidget {
  const BrakeLinePressureScreen({super.key});
  @override
  ConsumerState<BrakeLinePressureScreen> createState() => _BrakeLinePressureScreenState();
}

class _BrakeLinePressureScreenState extends ConsumerState<BrakeLinePressureScreen> {
  final _pedalForceController = TextEditingController(text: '100');
  final _pedalRatioController = TextEditingController(text: '6');
  final _boostRatioController = TextEditingController(text: '3');
  final _mcBoreController = TextEditingController(text: '1.0');

  double? _linePressure;
  double? _mcArea;

  void _calculate() {
    final pedalForce = double.tryParse(_pedalForceController.text);
    final pedalRatio = double.tryParse(_pedalRatioController.text);
    final boostRatio = double.tryParse(_boostRatioController.text) ?? 1;
    final mcBore = double.tryParse(_mcBoreController.text);

    if (pedalForce == null || pedalRatio == null || mcBore == null || mcBore <= 0) {
      setState(() { _linePressure = null; });
      return;
    }

    final mcArea = math.pi * math.pow(mcBore / 2, 2);
    final totalForce = pedalForce * pedalRatio * boostRatio;
    final pressure = totalForce / mcArea;

    setState(() {
      _mcArea = mcArea;
      _linePressure = pressure;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pedalForceController.text = '100';
    _pedalRatioController.text = '6';
    _boostRatioController.text = '3';
    _mcBoreController.text = '1.0';
    setState(() { _linePressure = null; });
  }

  @override
  void dispose() {
    _pedalForceController.dispose();
    _pedalRatioController.dispose();
    _boostRatioController.dispose();
    _mcBoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Brake Line Pressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pedal Force', unit: 'lbs', hint: 'Foot pressure', controller: _pedalForceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pedal Ratio', unit: ':1', hint: 'Mechanical advantage', controller: _pedalRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Boost Ratio', unit: ':1', hint: '1 if manual brakes', controller: _boostRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'MC Bore', unit: 'in', hint: 'Master cylinder bore', controller: _mcBoreController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_linePressure != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('PSI = (Pedal × Ratio × Boost) / Area', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Hydraulic pressure in brake lines', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Line Pressure', '${_linePressure!.toStringAsFixed(0)} PSI', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'MC Area', '${_mcArea!.toStringAsFixed(3)} sq in'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Typical max line pressure: 800-1200 PSI street, 1200-1800 PSI race', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
