import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Brake Rotor Specification Calculator
class BrakeRotorSpecScreen extends ConsumerStatefulWidget {
  const BrakeRotorSpecScreen({super.key});
  @override
  ConsumerState<BrakeRotorSpecScreen> createState() => _BrakeRotorSpecScreenState();
}

class _BrakeRotorSpecScreenState extends ConsumerState<BrakeRotorSpecScreen> {
  final _nominalThicknessController = TextEditingController();
  final _currentThicknessController = TextEditingController();
  final _minThicknessController = TextEditingController();
  final _runoutController = TextEditingController(text: '0.002');

  double? _wearRemaining;
  double? _wearPercent;
  String? _condition;
  String? _recommendation;

  void _calculate() {
    final nominal = double.tryParse(_nominalThicknessController.text);
    final current = double.tryParse(_currentThicknessController.text);
    final minimum = double.tryParse(_minThicknessController.text);
    final runout = double.tryParse(_runoutController.text) ?? 0;

    if (nominal == null || current == null || minimum == null ||
        nominal <= 0 || current <= 0 || minimum <= 0) {
      setState(() { _wearRemaining = null; });
      return;
    }

    final totalWearAllowed = nominal - minimum;
    final wearUsed = nominal - current;
    final wearRemaining = current - minimum;
    final wearPercent = totalWearAllowed > 0 ? (wearUsed / totalWearAllowed * 100) : 100;

    String condition;
    String recommendation;

    if (current < minimum) {
      condition = 'BELOW MINIMUM - Replace immediately!';
      recommendation = 'Rotor is unsafe. Replace before driving.';
    } else if (wearRemaining < 0.5) {
      condition = 'Near minimum - Replace soon';
      recommendation = 'Schedule replacement at next brake service';
    } else if (runout > 0.003) {
      condition = 'Excessive runout - May need machining';
      recommendation = 'Runout >0.003" causes pedal pulsation. Machine or replace.';
    } else if (wearPercent > 75) {
      condition = 'Worn - Monitor closely';
      recommendation = 'Plan for replacement at next pad change';
    } else {
      condition = 'Good condition';
      recommendation = 'Continue to monitor at each brake service';
    }

    setState(() {
      _wearRemaining = wearRemaining;
      _wearPercent = wearPercent.toDouble();
      _condition = condition;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _nominalThicknessController.clear();
    _currentThicknessController.clear();
    _minThicknessController.clear();
    _runoutController.text = '0.002';
    setState(() { _wearRemaining = null; });
  }

  @override
  void dispose() {
    _nominalThicknessController.dispose();
    _currentThicknessController.dispose();
    _minThicknessController.dispose();
    _runoutController.dispose();
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
        title: Text('Brake Rotor Spec', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Nominal Thickness', unit: 'mm', hint: 'New rotor spec', controller: _nominalThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Thickness', unit: 'mm', hint: 'Measured', controller: _currentThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Minimum Thickness', unit: 'mm', hint: 'Discard spec', controller: _minThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Lateral Runout', unit: 'in', hint: 'Dial indicator', controller: _runoutController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_wearRemaining != null) _buildResultsCard(colors),
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
        Text('Wear = Nominal - Current', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Never machine below minimum thickness', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isBad = _wearRemaining! < 0.5 || _wearPercent! > 90;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isBad ? Colors.red.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Remaining', '${_wearRemaining!.toStringAsFixed(2)} mm', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Wear Used', '${_wearPercent!.toStringAsFixed(0)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isBad ? Colors.red.withValues(alpha: 0.1) : colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_condition!, style: TextStyle(color: isBad ? Colors.red : colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
