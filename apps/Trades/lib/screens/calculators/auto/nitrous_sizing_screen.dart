import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Nitrous Jet Sizing Calculator
class NitrousSizingScreen extends ConsumerStatefulWidget {
  const NitrousSizingScreen({super.key});
  @override
  ConsumerState<NitrousSizingScreen> createState() => _NitrousSizingScreenState();
}

class _NitrousSizingScreenState extends ConsumerState<NitrousSizingScreen> {
  final _targetHpController = TextEditingController();
  final _bottlePressureController = TextEditingController(text: '950');
  final _fuelPressureController = TextEditingController(text: '45');

  double? _nitrousJetSize;
  double? _fuelJetSize;
  double? _nitrousFlow;
  double? _fuelFlow;
  String? _systemAdvice;

  void _calculate() {
    final targetHp = double.tryParse(_targetHpController.text);
    final bottlePressure = double.tryParse(_bottlePressureController.text) ?? 950;
    final fuelPressure = double.tryParse(_fuelPressureController.text) ?? 45;

    if (targetHp == null || targetHp <= 0) {
      setState(() { _nitrousJetSize = null; });
      return;
    }

    // Nitrous jet sizing (approximate)
    // Each 10 HP requires roughly 0.5 lb/min of nitrous
    // Jet size (thousandths) = sqrt(flow / K) where K depends on pressure
    final nitrousFlowLbMin = targetHp * 0.05; // ~0.5 lb/min per 10 HP

    // Pressure correction for nitrous (reference 900 PSI)
    final pressureCorrection = math.sqrt(bottlePressure / 900);

    // Jet sizing formula (simplified)
    // Using typical flow coefficients for nitrous jets
    final nitrousJet = math.sqrt((nitrousFlowLbMin * 1000) / pressureCorrection) * 2.5;

    // Fuel jet sizing
    // Nitrous needs roughly 6:1 nitrous:fuel ratio by weight for gasoline
    // For E85, closer to 4.5:1
    final fuelFlowLbMin = nitrousFlowLbMin / 6.0;

    // Fuel jet size based on pressure
    final fuelPressureCorrection = math.sqrt(fuelPressure / 45);
    final fuelJet = math.sqrt((fuelFlowLbMin * 1000) / fuelPressureCorrection) * 3.5;

    // System advice
    String advice;
    if (targetHp <= 75) {
      advice = 'Small shot: Safe for most stock engines. Single fogger or dry kit suitable.';
    } else if (targetHp <= 150) {
      advice = 'Medium shot: Verify fuel system capacity. Consider progressive controller.';
    } else if (targetHp <= 250) {
      advice = 'Large shot: Forged internals recommended. Use window switch and progressive.';
    } else {
      advice = 'Extreme shot: Race-only. Requires built engine, roll cage, and safety equipment.';
    }

    setState(() {
      _nitrousJetSize = nitrousJet;
      _fuelJetSize = fuelJet;
      _nitrousFlow = nitrousFlowLbMin;
      _fuelFlow = fuelFlowLbMin;
      _systemAdvice = advice;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _targetHpController.clear();
    _bottlePressureController.text = '950';
    _fuelPressureController.text = '45';
    setState(() { _nitrousJetSize = null; });
  }

  @override
  void dispose() {
    _targetHpController.dispose();
    _bottlePressureController.dispose();
    _fuelPressureController.dispose();
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
        title: Text('Nitrous Jet Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target HP Gain', unit: 'HP', hint: 'Desired shot size', controller: _targetHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Bottle Pressure', unit: 'PSI', hint: '900-1050 typical', controller: _bottlePressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fuel Pressure', unit: 'PSI', hint: 'Base fuel pressure', controller: _fuelPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_nitrousJetSize != null) _buildResultsCard(colors),
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
        Text('Jet Size = f(HP, Pressure, Flow)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Size nitrous and fuel jets for target HP', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Nitrous Jet', '${_nitrousJetSize!.toStringAsFixed(0)} thou', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Fuel Jet', '${_fuelJetSize!.toStringAsFixed(0)} thou'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'N2O Flow', '${_nitrousFlow!.toStringAsFixed(2)} lb/min'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Fuel Flow', '${_fuelFlow!.toStringAsFixed(2)} lb/min'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_systemAdvice!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Always verify with manufacturer jet charts. Values are estimates.',
            style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
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
