import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Filler Metal Cost Calculator - Cost per foot of weld
class FillerMetalCostScreen extends ConsumerStatefulWidget {
  const FillerMetalCostScreen({super.key});
  @override
  ConsumerState<FillerMetalCostScreen> createState() => _FillerMetalCostScreenState();
}

class _FillerMetalCostScreenState extends ConsumerState<FillerMetalCostScreen> {
  final _weldLengthController = TextEditingController();
  final _legSizeController = TextEditingController(text: '0.25');
  final _pricePerLbController = TextEditingController(text: '3.50');
  final _laborRateController = TextEditingController(text: '75');
  String _process = 'GMAW';

  double? _fillerCost;
  double? _laborCost;
  double? _totalCost;
  double? _costPerFoot;

  // Deposition rates (lbs/hr at typical settings)
  static const Map<String, double> _depositionRates = {
    'SMAW': 2.5,
    'GMAW': 6.0,
    'FCAW': 8.0,
    'SAW': 15.0,
  };

  // Deposition efficiency
  static const Map<String, double> _efficiency = {
    'SMAW': 0.60,
    'GMAW': 0.95,
    'FCAW': 0.85,
    'SAW': 0.98,
  };

  void _calculate() {
    final length = double.tryParse(_weldLengthController.text);
    final leg = double.tryParse(_legSizeController.text);
    final pricePerLb = double.tryParse(_pricePerLbController.text) ?? 3.50;
    final laborRate = double.tryParse(_laborRateController.text) ?? 75;

    if (length == null || leg == null || leg <= 0) {
      setState(() { _fillerCost = null; });
      return;
    }

    // Calculate weld metal needed
    final areaPerFoot = (leg * leg / 2) * 12;
    final totalVolume = areaPerFoot * length;
    final weldMetalWeight = totalVolume * 0.284;

    final efficiency = _efficiency[_process] ?? 0.85;
    final depositionRate = _depositionRates[_process] ?? 6.0;

    final fillerNeeded = weldMetalWeight / efficiency;
    final fillerCost = fillerNeeded * pricePerLb;

    // Calculate labor time (operator factor ~30% for arc-on time)
    final arcHours = weldMetalWeight / depositionRate;
    final totalHours = arcHours / 0.30; // 30% arc-on time typical
    final laborCost = totalHours * laborRate;

    final totalCost = fillerCost + laborCost;
    final costPerFoot = totalCost / length;

    setState(() {
      _fillerCost = fillerCost;
      _laborCost = laborCost;
      _totalCost = totalCost;
      _costPerFoot = costPerFoot;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldLengthController.clear();
    _legSizeController.text = '0.25';
    _pricePerLbController.text = '3.50';
    _laborRateController.text = '75';
    setState(() { _fillerCost = null; });
  }

  @override
  void dispose() {
    _weldLengthController.dispose();
    _legSizeController.dispose();
    _pricePerLbController.dispose();
    _laborRateController.dispose();
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
        title: Text('Filler Metal Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Length', unit: 'ft', hint: 'Total linear feet', controller: _weldLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fillet Leg Size', unit: 'in', hint: 'e.g. 0.25', controller: _legSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Filler Price', unit: '\$/lb', hint: 'Cost per pound', controller: _pricePerLbController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Labor Rate', unit: '\$/hr', hint: 'Loaded labor rate', controller: _laborRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_fillerCost != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _depositionRates.keys.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Welding Cost Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Includes filler metal and labor costs', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Cost', '\$${_totalCost!.toStringAsFixed(2)}', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cost per Foot', '\$${_costPerFoot!.toStringAsFixed(2)}/ft'),
        const Divider(height: 24),
        _buildResultRow(colors, 'Filler Metal', '\$${_fillerCost!.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Labor', '\$${_laborCost!.toStringAsFixed(2)}'),
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
