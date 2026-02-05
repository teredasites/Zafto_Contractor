import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Cover Savings Calculator
class CoverSavingsScreen extends ConsumerStatefulWidget {
  const CoverSavingsScreen({super.key});
  @override
  ConsumerState<CoverSavingsScreen> createState() => _CoverSavingsScreenState();
}

class _CoverSavingsScreenState extends ConsumerState<CoverSavingsScreen> {
  final _surfaceAreaController = TextEditingController();
  final _heatingCostController = TextEditingController(text: '200');
  final _monthsController = TextEditingController(text: '6');
  String _coverType = 'Solar Blanket';

  double? _heatSavings;
  double? _waterSavings;
  double? _chemicalSavings;
  double? _totalSavings;

  // Savings percentages by cover type
  static const Map<String, Map<String, double>> _coverSavings = {
    'Solar Blanket': {'heat': 0.70, 'water': 0.95, 'chemical': 0.50},
    'Thermal Cover': {'heat': 0.80, 'water': 0.97, 'chemical': 0.60},
    'Safety Cover': {'heat': 0.60, 'water': 0.90, 'chemical': 0.40},
  };

  void _calculate() {
    final surfaceArea = double.tryParse(_surfaceAreaController.text);
    final heatingCost = double.tryParse(_heatingCostController.text);
    final months = double.tryParse(_monthsController.text);

    if (surfaceArea == null || heatingCost == null || months == null ||
        surfaceArea <= 0 || heatingCost <= 0 || months <= 0) {
      setState(() { _heatSavings = null; });
      return;
    }

    final savings = _coverSavings[_coverType]!;
    final heatSavings = heatingCost * months * savings['heat']!;

    // Water savings: ~1/4" evaporation per day = ~$50/month for average pool
    final waterSavings = 50 * months * savings['water']!;

    // Chemical savings: ~$30/month average
    final chemicalSavings = 30 * months * savings['chemical']!;

    final totalSavings = heatSavings + waterSavings + chemicalSavings;

    setState(() {
      _heatSavings = heatSavings;
      _waterSavings = waterSavings;
      _chemicalSavings = chemicalSavings;
      _totalSavings = totalSavings;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _surfaceAreaController.clear();
    _heatingCostController.text = '200';
    _monthsController.text = '6';
    setState(() { _heatSavings = null; });
  }

  @override
  void dispose() {
    _surfaceAreaController.dispose();
    _heatingCostController.dispose();
    _monthsController.dispose();
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
        title: Text('Cover Savings', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('COVER TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Surface Area', unit: 'sq ft', hint: 'Pool surface', controller: _surfaceAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Monthly Heating Cost', unit: '\$', hint: 'Without cover', controller: _heatingCostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Swim Season', unit: 'months', hint: 'Months of use', controller: _monthsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_heatSavings != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _coverSavings.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _coverType == type,
        onSelected: (_) => setState(() { _coverType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Covers reduce costs 50-90%', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Heat, water, and chemical savings', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Heat Savings', '\$${_heatSavings!.toStringAsFixed(0)}'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Water Savings', '\$${_waterSavings!.toStringAsFixed(0)}'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Chemical Savings', '\$${_chemicalSavings!.toStringAsFixed(0)}'),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Season Savings', '\$${_totalSavings!.toStringAsFixed(0)}', isPrimary: true),
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
