import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Automotive A/C Refrigerant Charge Calculator
class RefrigerantChargeScreen extends ConsumerStatefulWidget {
  const RefrigerantChargeScreen({super.key});
  @override
  ConsumerState<RefrigerantChargeScreen> createState() => _RefrigerantChargeScreenState();
}

class _RefrigerantChargeScreenState extends ConsumerState<RefrigerantChargeScreen> {
  final _specChargeController = TextEditingController();
  final _currentChargeController = TextEditingController();
  String _refrigerantType = 'R134a';
  bool _rearAC = false;

  double? _amountNeeded;
  String? _recommendation;

  void _calculate() {
    final specCharge = double.tryParse(_specChargeController.text);
    final currentCharge = double.tryParse(_currentChargeController.text) ?? 0;

    if (specCharge == null || specCharge <= 0) {
      setState(() { _amountNeeded = null; });
      return;
    }

    // Rear A/C typically adds 6-10 oz to system
    final rearAdjust = _rearAC ? 8.0 : 0.0;
    final totalSpec = specCharge + rearAdjust;

    final amountNeeded = totalSpec - currentCharge;

    String recommendation;
    if (amountNeeded < 0) {
      recommendation = 'System may be overcharged. Recover and recharge to spec.';
    } else if (amountNeeded > specCharge * 0.5) {
      recommendation = 'Large deficit: Evacuate system, leak test, then charge';
    } else if (_refrigerantType == 'R1234yf') {
      recommendation = 'R1234yf: Use certified recovery/recharge machine only';
    } else {
      recommendation = 'Charge slowly. Check pressures at operating temp.';
    }

    setState(() {
      _amountNeeded = amountNeeded;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _specChargeController.clear();
    _currentChargeController.clear();
    _rearAC = false;
    setState(() { _amountNeeded = null; });
  }

  @override
  void dispose() {
    _specChargeController.dispose();
    _currentChargeController.dispose();
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
        title: Text('A/C Refrigerant', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('REFRIGERANT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Spec Charge', unit: 'oz', hint: 'On underhood label', controller: _specChargeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Charge', unit: 'oz', hint: '0 if empty', controller: _currentChargeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildRearACToggle(colors),
            const SizedBox(height: 32),
            if (_amountNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['R134a', 'R1234yf', 'R12 (Classic)'].map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _refrigerantType == type,
        onSelected: (_) => setState(() { _refrigerantType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildRearACToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Front Only'), selected: !_rearAC, onSelected: (_) => setState(() { _rearAC = false; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('With Rear A/C'), selected: _rearAC, onSelected: (_) => setState(() { _rearAC = true; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Needed = Spec - Current', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Check underhood label for spec charge', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isOvercharged = _amountNeeded! < 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isOvercharged ? Colors.orange.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, isOvercharged ? 'Overcharged By' : 'Amount Needed', '${_amountNeeded!.abs().toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Grams', '${(_amountNeeded!.abs() * 28.35).toStringAsFixed(0)} g'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
