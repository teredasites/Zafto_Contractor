import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// EV Charging Cost Calculator - Cost per charge
class ChargingCostScreen extends ConsumerStatefulWidget {
  const ChargingCostScreen({super.key});
  @override
  ConsumerState<ChargingCostScreen> createState() => _ChargingCostScreenState();
}

class _ChargingCostScreenState extends ConsumerState<ChargingCostScreen> {
  final _energyController = TextEditingController();
  final _rateController = TextEditingController(text: '0.12');
  final _rangeController = TextEditingController();

  double? _chargingCost;
  double? _costPerMile;

  void _calculate() {
    final energy = double.tryParse(_energyController.text);
    final rate = double.tryParse(_rateController.text) ?? 0.12;
    final range = double.tryParse(_rangeController.text);

    if (energy == null) {
      setState(() { _chargingCost = null; });
      return;
    }

    final cost = energy * rate;
    double? costPerMile;
    if (range != null && range > 0) {
      costPerMile = cost / range;
    }

    setState(() {
      _chargingCost = cost;
      _costPerMile = costPerMile;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _energyController.clear();
    _rateController.text = '0.12';
    _rangeController.clear();
    setState(() { _chargingCost = null; });
  }

  @override
  void dispose() {
    _energyController.dispose();
    _rateController.dispose();
    _rangeController.dispose();
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
        title: Text('Charging Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Energy to Charge', unit: 'kWh', hint: 'Amount needed', controller: _energyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Electricity Rate', unit: '\$/kWh', hint: 'Avg ~\$0.12', controller: _rateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Range Added', unit: 'miles', hint: 'For cost/mile (optional)', controller: _rangeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_chargingCost != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildComparisonCard(colors),
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
        Text('Cost = kWh × Rate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate EV charging expenses', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('CHARGING COST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('\$${_chargingCost!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        if (_costPerMile != null) ...[
          const SizedBox(height: 16),
          _buildResultRow(colors, 'Cost Per Mile', '\$${_costPerMile!.toStringAsFixed(3)}'),
          Text('${(_costPerMile! * 100).toStringAsFixed(1)} cents/mile', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ],
      ]),
    );
  }

  Widget _buildComparisonCard(ZaftoColors colors) {
    final rate = double.tryParse(_rateController.text) ?? 0.12;
    // Compare to gas at $3.50/gal, 30 MPG = $0.117/mile
    // EV at 3.5 mi/kWh = rate/3.5 per mile
    final evCostPerMile = rate / 3.5;
    final gasCostPerMile = 3.50 / 30;
    final savings = gasCostPerMile - evCostPerMile;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EV vs GAS COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildCompareRow(colors, 'EV (3.5 mi/kWh)', '\$${evCostPerMile.toStringAsFixed(3)}/mi'),
        _buildCompareRow(colors, 'Gas (30 MPG @ \$3.50)', '\$${gasCostPerMile.toStringAsFixed(3)}/mi'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: savings > 0 ? colors.accentSuccess.withValues(alpha: 0.1) : colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(savings > 0 ? 'EV saves \$${(savings * 12000).toStringAsFixed(0)}/year (12k miles)' : 'Gas is cheaper at current rates', style: TextStyle(color: savings > 0 ? colors.accentSuccess : colors.warning, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildCompareRow(ZaftoColors colors, String vehicle, String cost) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(vehicle, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(cost, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
