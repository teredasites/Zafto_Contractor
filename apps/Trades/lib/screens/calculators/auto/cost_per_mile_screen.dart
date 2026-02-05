import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cost Per Mile Calculator - Fuel cost analysis
class CostPerMileScreen extends ConsumerStatefulWidget {
  const CostPerMileScreen({super.key});
  @override
  ConsumerState<CostPerMileScreen> createState() => _CostPerMileScreenState();
}

class _CostPerMileScreenState extends ConsumerState<CostPerMileScreen> {
  final _mpgController = TextEditingController();
  final _fuelPriceController = TextEditingController();
  final _annualMilesController = TextEditingController(text: '12000');

  double? _costPerMile;
  double? _annualFuelCost;

  void _calculate() {
    final mpg = double.tryParse(_mpgController.text);
    final fuelPrice = double.tryParse(_fuelPriceController.text);
    final annualMiles = double.tryParse(_annualMilesController.text);

    if (mpg == null || fuelPrice == null || mpg <= 0) {
      setState(() { _costPerMile = null; });
      return;
    }

    final costPerMile = fuelPrice / mpg;
    double? annualCost;
    if (annualMiles != null) {
      annualCost = costPerMile * annualMiles;
    }

    setState(() {
      _costPerMile = costPerMile;
      _annualFuelCost = annualCost;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _mpgController.clear();
    _fuelPriceController.clear();
    _annualMilesController.text = '12000';
    setState(() { _costPerMile = null; });
  }

  @override
  void dispose() {
    _mpgController.dispose();
    _fuelPriceController.dispose();
    _annualMilesController.dispose();
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
        title: Text('Cost Per Mile', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Fuel Economy', unit: 'mpg', hint: 'Your MPG', controller: _mpgController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fuel Price', unit: '\$/gal', hint: 'Current price', controller: _fuelPriceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Annual Miles', unit: 'miles', hint: 'Average 12,000', controller: _annualMilesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_costPerMile != null) _buildResultsCard(colors),
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
        Text('Cost/Mile = Fuel Price / MPG', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate your actual fuel cost per mile', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('COST PER MILE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('\$${_costPerMile!.toStringAsFixed(3)}', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${(_costPerMile! * 100).toStringAsFixed(1)} cents/mile', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        if (_annualFuelCost != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Annual Fuel Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              Text('\$${_annualFuelCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Monthly: \$${(_annualFuelCost! / 12).toStringAsFixed(0)}', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ]),
    );
  }
}
