import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rotor Minimum Thickness Calculator - Check if rotor is serviceable
class RotorMinThicknessScreen extends ConsumerStatefulWidget {
  const RotorMinThicknessScreen({super.key});
  @override
  ConsumerState<RotorMinThicknessScreen> createState() => _RotorMinThicknessScreenState();
}

class _RotorMinThicknessScreenState extends ConsumerState<RotorMinThicknessScreen> {
  final _currentThicknessController = TextEditingController();
  final _minThicknessController = TextEditingController();
  final _machineRemovalController = TextEditingController(text: '0.015');

  double? _afterMachine;
  bool? _canMachine;

  void _calculate() {
    final current = double.tryParse(_currentThicknessController.text);
    final minimum = double.tryParse(_minThicknessController.text);
    final removal = double.tryParse(_machineRemovalController.text) ?? 0.015;

    if (current == null || minimum == null) {
      setState(() { _afterMachine = null; });
      return;
    }

    // Remove material from both sides
    final afterMachine = current - (removal * 2);
    final canMachine = afterMachine >= minimum;

    setState(() {
      _afterMachine = afterMachine;
      _canMachine = canMachine;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentThicknessController.clear();
    _minThicknessController.clear();
    _machineRemovalController.text = '0.015';
    setState(() { _afterMachine = null; });
  }

  @override
  void dispose() {
    _currentThicknessController.dispose();
    _minThicknessController.dispose();
    _machineRemovalController.dispose();
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
        title: Text('Rotor Min Thickness', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Thickness', unit: 'in', hint: 'Measured rotor', controller: _currentThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Minimum Spec', unit: 'in', hint: 'From rotor or manual', controller: _minThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Machine Per Side', unit: 'in', hint: 'Typical: 0.010-0.020', controller: _machineRemovalController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_afterMachine != null) _buildResultsCard(colors),
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
        Text('After = Current - (Removal × 2)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Check if rotor can be machined or needs replacement', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _canMachine! ? colors.accentSuccess : colors.error;
    final minimum = double.tryParse(_minThicknessController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'After Machining', '${_afterMachine!.toStringAsFixed(3)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Minimum Required', '${minimum.toStringAsFixed(3)}"'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(_canMachine! ? 'CAN BE MACHINED' : 'REPLACE ROTOR', style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_canMachine! ? 'Rotor has sufficient material' : 'Below minimum after machining', style: TextStyle(color: statusColor.withValues(alpha: 0.8), fontSize: 12)),
          ]),
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
