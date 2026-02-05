import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Boost Pressure Effects Calculator
class BoostCalculatorScreen extends ConsumerStatefulWidget {
  const BoostCalculatorScreen({super.key});
  @override
  ConsumerState<BoostCalculatorScreen> createState() => _BoostCalculatorScreenState();
}

class _BoostCalculatorScreenState extends ConsumerState<BoostCalculatorScreen> {
  final _baseHpController = TextEditingController();
  final _currentBoostController = TextEditingController();
  final _targetBoostController = TextEditingController();
  final _efficiencyController = TextEditingController(text: '80');

  double? _currentPr;
  double? _targetPr;
  double? _currentBoostedHp;
  double? _targetBoostedHp;
  double? _hpGain;
  String? _fuelAdvice;

  void _calculate() {
    final baseHp = double.tryParse(_baseHpController.text);
    final currentBoost = double.tryParse(_currentBoostController.text);
    final targetBoost = double.tryParse(_targetBoostController.text);
    final efficiency = double.tryParse(_efficiencyController.text) ?? 80;

    if (baseHp == null || currentBoost == null || targetBoost == null) {
      setState(() { _currentPr = null; });
      return;
    }

    const atmosphericPsi = 14.7;
    final efficiencyFactor = efficiency / 100;

    // Pressure ratios
    final currentPr = (currentBoost + atmosphericPsi) / atmosphericPsi;
    final targetPr = (targetBoost + atmosphericPsi) / atmosphericPsi;

    // HP calculations using pressure ratio
    // HP gain is roughly proportional to pressure ratio with efficiency factor
    final currentBoostedHp = baseHp * currentPr * efficiencyFactor;
    final targetBoostedHp = baseHp * targetPr * efficiencyFactor;
    final hpGain = targetBoostedHp - currentBoostedHp;

    // Fuel system advice
    String fuelAdvice;
    if (targetBoost > 25) {
      fuelAdvice = 'High boost: Consider E85, larger injectors, and fuel pump upgrade. '
                   'May need forged internals.';
    } else if (targetBoost > 18) {
      fuelAdvice = 'Moderate-high boost: Verify fuel system capacity. '
                   'Consider 93+ octane or E85 blend.';
    } else if (targetBoost > 12) {
      fuelAdvice = 'Moderate boost: Stock fuel system may work with tune. '
                   'Use 91+ octane.';
    } else {
      fuelAdvice = 'Low boost: Most stock fuel systems sufficient. '
                   'Recommend 91 octane minimum.';
    }

    setState(() {
      _currentPr = currentPr;
      _targetPr = targetPr;
      _currentBoostedHp = currentBoostedHp;
      _targetBoostedHp = targetBoostedHp;
      _hpGain = hpGain;
      _fuelAdvice = fuelAdvice;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _baseHpController.clear();
    _currentBoostController.clear();
    _targetBoostController.clear();
    _efficiencyController.text = '80';
    setState(() { _currentPr = null; });
  }

  @override
  void dispose() {
    _baseHpController.dispose();
    _currentBoostController.dispose();
    _targetBoostController.dispose();
    _efficiencyController.dispose();
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
        title: Text('Boost Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Base N/A Horsepower', unit: 'HP', hint: 'Without boost', controller: _baseHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Boost', unit: 'PSI', hint: 'Current setting', controller: _currentBoostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Boost', unit: 'PSI', hint: 'Desired boost', controller: _targetBoostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Efficiency', unit: '%', hint: 'Turbo/SC efficiency', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_currentPr != null) _buildResultsCard(colors),
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
        Text('PR = (Boost + 14.7) / 14.7', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Estimate HP gains from boost increase', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'HP Gain', '+${_hpGain!.toStringAsFixed(0)} HP', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Current PR', '${_currentPr!.toStringAsFixed(2)}:1'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Target PR', '${_targetPr!.toStringAsFixed(2)}:1'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Current HP', '${_currentBoostedHp!.toStringAsFixed(0)} HP'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Target HP', '${_targetBoostedHp!.toStringAsFixed(0)} HP'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_fuelAdvice!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
