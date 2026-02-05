import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Salt Calculator for Saltwater Pools
class SaltCalculatorScreen extends ConsumerStatefulWidget {
  const SaltCalculatorScreen({super.key});
  @override
  ConsumerState<SaltCalculatorScreen> createState() => _SaltCalculatorScreenState();
}

class _SaltCalculatorScreenState extends ConsumerState<SaltCalculatorScreen> {
  final _volumeController = TextEditingController();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController(text: '3200');

  double? _lbsNeeded;
  double? _bagsNeeded;
  double? _ppmIncrease;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final current = double.tryParse(_currentController.text) ?? 0;
    final target = double.tryParse(_targetController.text);

    if (volume == null || target == null || volume <= 0 || target <= current) {
      setState(() { _lbsNeeded = null; });
      return;
    }

    final ppmNeeded = target - current;
    // Rule: 0.85 lbs of salt per 100 gallons raises salt by 100 ppm
    final lbs = (ppmNeeded / 100) * (volume / 100) * 0.85;
    // Standard pool salt bags are 40 lbs
    final bags = lbs / 40;

    setState(() {
      _lbsNeeded = lbs;
      _bagsNeeded = bags;
      _ppmIncrease = ppmNeeded;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentController.clear();
    _targetController.text = '3200';
    setState(() { _lbsNeeded = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _currentController.dispose();
    _targetController.dispose();
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
        title: Text('Salt Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Salt', unit: 'ppm', hint: 'Test result', controller: _currentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Salt', unit: 'ppm', hint: '2700-3400 typical', controller: _targetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lbsNeeded != null) _buildResultsCard(colors),
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
        Text('0.85 lbs / 100 gal = 100 ppm', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Ideal: 2700-3400 ppm (check generator specs)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Salt Needed', '${_lbsNeeded!.toStringAsFixed(1)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, '40-lb Bags', '${_bagsNeeded!.toStringAsFixed(1)} bags'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'PPM Increase', '${_ppmIncrease!.toStringAsFixed(0)} ppm'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Use pool-grade salt only. Broadcast around perimeter with pump running. Wait 24 hrs before retesting.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
