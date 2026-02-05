import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Heating Gas Cost Calculator
class GasCostScreen extends ConsumerStatefulWidget {
  const GasCostScreen({super.key});
  @override
  ConsumerState<GasCostScreen> createState() => _GasCostScreenState();
}

class _GasCostScreenState extends ConsumerState<GasCostScreen> {
  final _heaterBtuController = TextEditingController();
  final _hoursController = TextEditingController(text: '4');
  final _gasPriceController = TextEditingController(text: '1.50');
  String _gasType = 'Natural Gas';

  double? _thermsUsed;
  double? _dailyCost;
  double? _monthlyCost;

  void _calculate() {
    final heaterBtu = double.tryParse(_heaterBtuController.text);
    final hours = double.tryParse(_hoursController.text);
    final gasPrice = double.tryParse(_gasPriceController.text);

    if (heaterBtu == null || hours == null || gasPrice == null ||
        heaterBtu <= 0 || hours <= 0 || gasPrice <= 0) {
      setState(() { _thermsUsed = null; });
      return;
    }

    // 1 therm = 100,000 BTU for natural gas
    // Propane: 1 gallon = 91,500 BTU
    double thermsPerHour;
    if (_gasType == 'Natural Gas') {
      thermsPerHour = heaterBtu / 100000;
    } else {
      // Convert propane gallons to equivalent therms
      thermsPerHour = heaterBtu / 91500;
    }

    // Account for 80% heater efficiency
    final actualTherms = thermsPerHour / 0.80;
    final dailyTherms = actualTherms * hours;
    final dailyCost = dailyTherms * gasPrice;
    final monthlyCost = dailyCost * 30;

    setState(() {
      _thermsUsed = dailyTherms;
      _dailyCost = dailyCost;
      _monthlyCost = monthlyCost;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _heaterBtuController.clear();
    _hoursController.text = '4';
    _gasPriceController.text = '1.50';
    setState(() { _thermsUsed = null; });
  }

  @override
  void dispose() {
    _heaterBtuController.dispose();
    _hoursController.dispose();
    _gasPriceController.dispose();
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
        title: Text('Heating Gas Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('GAS TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Heater Size', unit: 'BTU/hr', hint: 'e.g. 400000', controller: _heaterBtuController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Hours per Day', unit: 'hrs', hint: 'Average runtime', controller: _hoursController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Gas Price', unit: _gasType == 'Natural Gas' ? '\$/therm' : '\$/gal', hint: 'Local rate', controller: _gasPriceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_thermsUsed != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Natural Gas'), selected: _gasType == 'Natural Gas', onSelected: (_) => setState(() { _gasType = 'Natural Gas'; _gasPriceController.text = '1.50'; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Propane'), selected: _gasType == 'Propane', onSelected: (_) => setState(() { _gasType = 'Propane'; _gasPriceController.text = '3.00'; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Cost = (BTU / 100K) × Hours × Rate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Assumes 80% heater efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final unit = _gasType == 'Natural Gas' ? 'therms' : 'gallons';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Daily Usage', '${_thermsUsed!.toStringAsFixed(1)} $unit'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Daily Cost', '\$${_dailyCost!.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Monthly Cost', '\$${_monthlyCost!.toStringAsFixed(0)}', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Use a cover to reduce heating costs by 50-70%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
