import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Power to Weight Ratio Calculator
class PowerToWeightScreen extends ConsumerStatefulWidget {
  const PowerToWeightScreen({super.key});
  @override
  ConsumerState<PowerToWeightScreen> createState() => _PowerToWeightScreenState();
}

class _PowerToWeightScreenState extends ConsumerState<PowerToWeightScreen> {
  final _horsepowerController = TextEditingController();
  final _weightController = TextEditingController();
  final _torqueController = TextEditingController();

  double? _hpPerLb;
  double? _lbPerHp;
  double? _hpPerTon;
  double? _predictedEt;
  String? _performanceClass;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);
    final weight = double.tryParse(_weightController.text);
    final torque = double.tryParse(_torqueController.text);

    if (horsepower == null || weight == null || horsepower <= 0 || weight <= 0) {
      setState(() { _hpPerLb = null; });
      return;
    }

    // Calculate ratios
    final hpPerLb = horsepower / weight;
    final lbPerHp = weight / horsepower;
    final hpPerTon = (horsepower / weight) * 2000;

    // Predict 1/4 mile ET
    final predictedEt = 5.825 * math.pow(weight / horsepower, 1/3);

    // Performance classification
    String perfClass;
    if (lbPerHp < 4) {
      perfClass = 'Hypercar territory (sub-10 sec 1/4)';
    } else if (lbPerHp < 6) {
      perfClass = 'Supercar level (10-11 sec 1/4)';
    } else if (lbPerHp < 8) {
      perfClass = 'High performance (11-12 sec 1/4)';
    } else if (lbPerHp < 12) {
      perfClass = 'Sport/muscle car (12-14 sec 1/4)';
    } else if (lbPerHp < 18) {
      perfClass = 'Average performance (14-16 sec)';
    } else {
      perfClass = 'Economy class (16+ sec 1/4)';
    }

    setState(() {
      _hpPerLb = hpPerLb;
      _lbPerHp = lbPerHp;
      _hpPerTon = hpPerTon;
      _predictedEt = predictedEt;
      _performanceClass = perfClass;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    _weightController.clear();
    _torqueController.clear();
    setState(() { _hpPerLb = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
    _weightController.dispose();
    _torqueController.dispose();
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
        title: Text('Power to Weight', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Horsepower', unit: 'HP', hint: 'Wheel or crank', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'With driver', controller: _weightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Torque', unit: 'lb-ft', hint: 'Optional', controller: _torqueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_hpPerLb != null) _buildResultsCard(colors),
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
        Text('Ratio = HP / Weight (or Weight / HP)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Lower lb/HP = faster acceleration', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Pounds per HP', '${_lbPerHp!.toStringAsFixed(2)} lb/HP', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'HP per Pound', '${_hpPerLb!.toStringAsFixed(4)} HP/lb'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'HP per Ton', '${_hpPerTon!.toStringAsFixed(0)} HP/ton'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Predicted 1/4 Mile', '${_predictedEt!.toStringAsFixed(2)} sec'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_performanceClass!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
