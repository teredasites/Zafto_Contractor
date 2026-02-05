import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Break Even Mileage Calculator - Calculate EV vs gas break-even point
class BreakEvenMileageScreen extends ConsumerStatefulWidget {
  const BreakEvenMileageScreen({super.key});
  @override
  ConsumerState<BreakEvenMileageScreen> createState() => _BreakEvenMileageScreenState();
}

class _BreakEvenMileageScreenState extends ConsumerState<BreakEvenMileageScreen> {
  final _evPriceController = TextEditingController();
  final _gasPriceController = TextEditingController();
  final _evEfficiencyController = TextEditingController();
  final _gasMpgController = TextEditingController();
  final _electricityController = TextEditingController();
  final _gasCostController = TextEditingController();

  double? _breakEvenMiles;
  double? _annualSavings;
  double? _breakEvenYears;

  void _calculate() {
    final evPrice = double.tryParse(_evPriceController.text);
    final gasPrice = double.tryParse(_gasPriceController.text);
    final evEfficiency = double.tryParse(_evEfficiencyController.text);
    final gasMpg = double.tryParse(_gasMpgController.text);
    final electricityCost = double.tryParse(_electricityController.text);
    final gasCost = double.tryParse(_gasCostController.text);

    if (evPrice == null || gasPrice == null || evEfficiency == null ||
        gasMpg == null || electricityCost == null || gasCost == null ||
        evEfficiency <= 0 || gasMpg <= 0) {
      setState(() { _breakEvenMiles = null; });
      return;
    }

    // Cost per mile calculations
    // EV: kWh/mile × $/kWh = $/mile
    final evCostPerMile = (1 / evEfficiency) * electricityCost;

    // Gas: gal/mile × $/gal = $/mile
    final gasCostPerMile = (1 / gasMpg) * gasCost;

    // Savings per mile
    final savingsPerMile = gasCostPerMile - evCostPerMile;

    if (savingsPerMile <= 0) {
      setState(() { _breakEvenMiles = null; });
      return;
    }

    // Price difference
    final priceDiff = evPrice - gasPrice;

    // Break-even mileage
    final breakEvenMiles = priceDiff / savingsPerMile;

    // Annual savings assuming 12,000 miles/year
    final annualSavings = savingsPerMile * 12000;

    // Break-even years
    final breakEvenYears = breakEvenMiles / 12000;

    setState(() {
      _breakEvenMiles = breakEvenMiles;
      _annualSavings = annualSavings;
      _breakEvenYears = breakEvenYears;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _evPriceController.clear();
    _gasPriceController.clear();
    _evEfficiencyController.clear();
    _gasMpgController.clear();
    _electricityController.clear();
    _gasCostController.clear();
    setState(() { _breakEvenMiles = null; });
  }

  @override
  void dispose() {
    _evPriceController.dispose();
    _gasPriceController.dispose();
    _evEfficiencyController.dispose();
    _gasMpgController.dispose();
    _electricityController.dispose();
    _gasCostController.dispose();
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
        title: Text('Break-Even Mileage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            Text('Vehicle Prices', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'EV Price', unit: '\$', hint: 'e.g., 45000', controller: _evPriceController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Gas Price', unit: '\$', hint: 'e.g., 35000', controller: _gasPriceController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Text('Efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'EV Efficiency', unit: 'mi/kWh', hint: '3.5', controller: _evEfficiencyController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Gas MPG', unit: 'mpg', hint: '30', controller: _gasMpgController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Text('Energy Costs', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Electricity', unit: '\$/kWh', hint: '0.13', controller: _electricityController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Gas', unit: '\$/gal', hint: '3.50', controller: _gasCostController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_breakEvenMiles != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.zap, color: colors.accentSuccess, size: 24),
          const SizedBox(width: 8),
          Text('vs', style: TextStyle(color: colors.textTertiary, fontSize: 16)),
          const SizedBox(width: 8),
          Icon(LucideIcons.fuel, color: colors.warning, size: 24),
        ]),
        const SizedBox(height: 8),
        Text('Compare EV vs Gas vehicle total cost of ownership', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isReasonable = _breakEvenYears! <= 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BREAK-EVEN ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text('${_breakEvenMiles!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} miles', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        Text('to break even on price difference', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox(colors, 'Break-Even', '${_breakEvenYears!.toStringAsFixed(1)} years')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(colors, 'Annual Savings', '\$${_annualSavings!.toStringAsFixed(0)}')),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isReasonable ? colors.accentSuccess.withValues(alpha: 0.1) : colors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isReasonable
                ? 'EV pays off within typical ownership period!'
                : 'Long break-even period - consider other EV benefits (environment, convenience, maintenance)',
            style: TextStyle(color: isReasonable ? colors.accentSuccess : colors.warning, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    );
  }

  Widget _buildStatBox(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.accentSuccess, fontSize: 18, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
