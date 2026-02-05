import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Filter Backwash Calculator
class BackwashCalculatorScreen extends ConsumerStatefulWidget {
  const BackwashCalculatorScreen({super.key});
  @override
  ConsumerState<BackwashCalculatorScreen> createState() => _BackwashCalculatorScreenState();
}

class _BackwashCalculatorScreenState extends ConsumerState<BackwashCalculatorScreen> {
  final _filterSqFtController = TextEditingController();
  final _flowRateController = TextEditingController(text: '40');
  final _backwashMinutesController = TextEditingController(text: '3');
  String _filterType = 'Sand';

  double? _backwashGallons;
  double? _monthlyWater;
  String? _recommendation;

  // Backwash frequency by filter type (times per month)
  static const Map<String, int> _backwashFrequency = {
    'Sand': 2,
    'DE': 4,
    'Cartridge': 0, // No backwash, just clean
  };

  void _calculate() {
    final filterSqFt = double.tryParse(_filterSqFtController.text);
    final flowRate = double.tryParse(_flowRateController.text);
    final minutes = double.tryParse(_backwashMinutesController.text);

    if (filterSqFt == null || flowRate == null || minutes == null ||
        filterSqFt <= 0 || flowRate <= 0 || minutes <= 0) {
      setState(() { _backwashGallons = null; });
      return;
    }

    // Backwash water = flow rate × time
    final backwashGallons = flowRate * minutes;
    final frequency = _backwashFrequency[_filterType]!;
    final monthlyWater = backwashGallons * frequency;

    String recommendation;
    if (_filterType == 'Cartridge') {
      recommendation = 'Cartridge filters don\'t backwash - clean every 2-4 weeks';
    } else if (_filterType == 'DE') {
      recommendation = 'Add DE powder after each backwash (1 lb per 10 sq ft)';
    } else {
      recommendation = 'Backwash when pressure rises 8-10 PSI above clean';
    }

    setState(() {
      _backwashGallons = backwashGallons;
      _monthlyWater = monthlyWater;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _filterSqFtController.clear();
    _flowRateController.text = '40';
    _backwashMinutesController.text = '3';
    setState(() { _backwashGallons = null; });
  }

  @override
  void dispose() {
    _filterSqFtController.dispose();
    _flowRateController.dispose();
    _backwashMinutesController.dispose();
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
        title: Text('Backwash Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Filter Size', unit: 'sq ft', hint: 'Filter area', controller: _filterSqFtController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Flow Rate', unit: 'GPM', hint: 'Pump flow', controller: _flowRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Backwash Time', unit: 'min', hint: 'Duration', controller: _backwashMinutesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_backwashGallons != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _backwashFrequency.keys.map((type) => ChoiceChip(
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
        Text('Water = Flow Rate × Time', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Backwash when pressure rises 8-10 PSI', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Per Backwash', '${_backwashGallons!.toStringAsFixed(0)} gal', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Monthly Usage', '${_monthlyWater!.toStringAsFixed(0)} gal'),
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
