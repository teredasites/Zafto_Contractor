import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Plaster Calculator
class PlasterCalculatorScreen extends ConsumerStatefulWidget {
  const PlasterCalculatorScreen({super.key});
  @override
  ConsumerState<PlasterCalculatorScreen> createState() => _PlasterCalculatorScreenState();
}

class _PlasterCalculatorScreenState extends ConsumerState<PlasterCalculatorScreen> {
  final _surfaceAreaController = TextEditingController();
  String _finishType = 'Standard Plaster';

  double? _bags80lb;
  double? _estimatedCost;
  String? _coverage;

  // Coverage per 80lb bag varies by finish type
  static const Map<String, double> _coveragePerBag = {
    'Standard Plaster': 25, // sq ft per bag
    'Pebble Tec': 18,
    'QuartzScapes': 20,
    'Glass Bead': 15,
  };

  static const Map<String, double> _costPerSqFt = {
    'Standard Plaster': 8,
    'Pebble Tec': 15,
    'QuartzScapes': 12,
    'Glass Bead': 18,
  };

  void _calculate() {
    final surfaceArea = double.tryParse(_surfaceAreaController.text);

    if (surfaceArea == null || surfaceArea <= 0) {
      setState(() { _bags80lb = null; });
      return;
    }

    final coverage = _coveragePerBag[_finishType] ?? 25;
    final costPerSqFt = _costPerSqFt[_finishType] ?? 8;

    final bags = surfaceArea / coverage;
    final cost = surfaceArea * costPerSqFt;

    setState(() {
      _bags80lb = bags;
      _estimatedCost = cost;
      _coverage = '${coverage.toStringAsFixed(0)} sq ft/bag';
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _surfaceAreaController.clear();
    setState(() { _bags80lb = null; });
  }

  @override
  void dispose() {
    _surfaceAreaController.dispose();
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
        title: Text('Pool Plaster', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('FINISH TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Surface Area', unit: 'sq ft', hint: 'Total pool surface', controller: _surfaceAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bags80lb != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _coveragePerBag.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _finishType == type,
        onSelected: (_) => setState(() { _finishType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Bags = Surface Area / Coverage', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Plaster thickness: 3/8" to 1/2"', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, '80-lb Bags', '${_bags80lb!.toStringAsFixed(0)} bags', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Coverage', _coverage!),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Cost', '\$${_estimatedCost!.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Add 10% for waste. Acid wash and prep adds to labor.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
