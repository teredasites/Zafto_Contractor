import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Filter Size Calculator
class FilterSizeScreen extends ConsumerStatefulWidget {
  const FilterSizeScreen({super.key});
  @override
  ConsumerState<FilterSizeScreen> createState() => _FilterSizeScreenState();
}

class _FilterSizeScreenState extends ConsumerState<FilterSizeScreen> {
  final _volumeController = TextEditingController();
  final _turnoverController = TextEditingController(text: '8');
  String _filterType = 'Cartridge';

  double? _gpmRequired;
  double? _filterSqFt;
  String? _recommendation;

  // Filter flow rates per sq ft
  static const Map<String, double> _flowRates = {
    'Sand': 20.0, // 15-20 GPM per sq ft
    'Cartridge': 0.375, // 0.375 GPM per sq ft
    'DE': 2.0, // 1-2 GPM per sq ft
  };

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final turnover = double.tryParse(_turnoverController.text);

    if (volume == null || turnover == null || volume <= 0 || turnover <= 0) {
      setState(() { _gpmRequired = null; });
      return;
    }

    final gpm = volume / (turnover * 60);
    final flowRate = _flowRates[_filterType] ?? 0.375;
    final sqFt = gpm / flowRate;

    String recommendation;
    if (_filterType == 'Cartridge') {
      if (sqFt <= 100) recommendation = '100 sq ft cartridge filter';
      else if (sqFt <= 200) recommendation = '200 sq ft cartridge filter';
      else if (sqFt <= 300) recommendation = '300 sq ft cartridge filter';
      else if (sqFt <= 425) recommendation = '425 sq ft cartridge filter';
      else recommendation = '500+ sq ft or multiple filters';
    } else if (_filterType == 'Sand') {
      if (sqFt <= 2.6) recommendation = '19\" sand filter (2.6 sq ft)';
      else if (sqFt <= 3.1) recommendation = '22\" sand filter (3.1 sq ft)';
      else if (sqFt <= 4.9) recommendation = '26\" sand filter (4.9 sq ft)';
      else recommendation = '30\"+ sand filter';
    } else {
      if (sqFt <= 36) recommendation = '36 sq ft DE filter';
      else if (sqFt <= 48) recommendation = '48 sq ft DE filter';
      else if (sqFt <= 60) recommendation = '60 sq ft DE filter';
      else recommendation = '72+ sq ft DE filter';
    }

    setState(() {
      _gpmRequired = gpm;
      _filterSqFt = sqFt;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _turnoverController.text = '8';
    setState(() { _gpmRequired = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _turnoverController.dispose();
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
        title: Text('Filter Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('FILTER TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Turnover Time', unit: 'hrs', hint: '8 hrs typical', controller: _turnoverController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gpmRequired != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: ['Sand', 'Cartridge', 'DE'].map((type) => ChoiceChip(
        label: Text(type),
        selected: _filterType == type,
        onSelected: (_) => setState(() { _filterType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Filter Area = GPM / Flow Rate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Cartridge: 0.375, DE: 2.0, Sand: 20 GPM/sq ft', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Flow Required', '${_gpmRequired!.toStringAsFixed(1)} GPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Filter Size', '${_filterSqFt!.toStringAsFixed(1)} sq ft'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
