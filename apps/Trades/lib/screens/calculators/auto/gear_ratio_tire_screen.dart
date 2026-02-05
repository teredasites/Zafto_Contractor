import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gear Ratio for Tire Size Calculator - Compensate for larger/smaller tires
class GearRatioTireScreen extends ConsumerStatefulWidget {
  const GearRatioTireScreen({super.key});
  @override
  ConsumerState<GearRatioTireScreen> createState() => _GearRatioTireScreenState();
}

class _GearRatioTireScreenState extends ConsumerState<GearRatioTireScreen> {
  final _stockTireController = TextEditingController();
  final _newTireController = TextEditingController();
  final _stockRatioController = TextEditingController();

  double? _newRatio;
  double? _effectiveRatio;

  void _calculate() {
    final stockTire = double.tryParse(_stockTireController.text);
    final newTire = double.tryParse(_newTireController.text);
    final stockRatio = double.tryParse(_stockRatioController.text);

    if (stockTire == null || newTire == null || stockRatio == null || stockTire <= 0) {
      setState(() { _newRatio = null; });
      return;
    }

    // New ratio = Stock ratio × (New tire / Stock tire)
    final newRatio = stockRatio * (newTire / stockTire);
    // Effective ratio with new tires but stock gears
    final effectiveRatio = stockRatio * (stockTire / newTire);

    setState(() {
      _newRatio = newRatio;
      _effectiveRatio = effectiveRatio;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _stockTireController.clear();
    _newTireController.clear();
    _stockRatioController.clear();
    setState(() { _newRatio = null; });
  }

  @override
  void dispose() {
    _stockTireController.dispose();
    _newTireController.dispose();
    _stockRatioController.dispose();
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
        title: Text('Gear Ratio for Tires', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Stock Tire Diameter', unit: 'in', hint: 'Original tires', controller: _stockTireController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'New Tire Diameter', unit: 'in', hint: 'Current/planned tires', controller: _newTireController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Stock Gear Ratio', unit: ':1', hint: 'Original diff ratio', controller: _stockRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_newRatio != null) _buildResultsCard(colors),
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
        Text('New Ratio = Stock × (New / Stock tire)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Maintain performance feel with different tire sizes', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final stockTire = double.tryParse(_stockTireController.text) ?? 1;
    final newTire = double.tryParse(_newTireController.text) ?? 1;
    final tireDiff = ((newTire - stockTire) / stockTire * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Recommended Ratio', '${_newRatio!.toStringAsFixed(2)}:1', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Current Effective Ratio', '${_effectiveRatio!.toStringAsFixed(2)}:1'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Tire Size Change', '${tireDiff >= 0 ? '+' : ''}${tireDiff.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(
            tireDiff > 0
                ? 'Larger tires reduce effective gearing. Numerically higher ratio restores performance.'
                : 'Smaller tires increase effective gearing. Lower ratio prevents over-revving.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
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
