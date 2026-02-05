import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shop Rate Calculator - Calculate and compare shop labor rates
class ShopRateScreen extends ConsumerStatefulWidget {
  const ShopRateScreen({super.key});
  @override
  ConsumerState<ShopRateScreen> createState() => _ShopRateScreenState();
}

class _ShopRateScreenState extends ConsumerState<ShopRateScreen> {
  final _laborHoursController = TextEditingController();
  final _shopRateController = TextEditingController();
  final _partsController = TextEditingController();
  final _markupController = TextEditingController();

  double? _laborCost;
  double? _partsTotal;
  double? _totalEstimate;

  void _calculate() {
    final laborHours = double.tryParse(_laborHoursController.text);
    final shopRate = double.tryParse(_shopRateController.text);
    final parts = double.tryParse(_partsController.text) ?? 0;
    final markup = double.tryParse(_markupController.text) ?? 0;

    if (laborHours == null || shopRate == null) {
      setState(() { _laborCost = null; });
      return;
    }

    final laborCost = laborHours * shopRate;
    final partsTotal = parts * (1 + markup / 100);
    final totalEstimate = laborCost + partsTotal;

    setState(() {
      _laborCost = laborCost;
      _partsTotal = partsTotal;
      _totalEstimate = totalEstimate;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _laborHoursController.clear();
    _shopRateController.clear();
    _partsController.clear();
    _markupController.clear();
    setState(() { _laborCost = null; });
  }

  @override
  void dispose() {
    _laborHoursController.dispose();
    _shopRateController.dispose();
    _partsController.dispose();
    _markupController.dispose();
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
        title: Text('Shop Rate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Labor Hours', unit: 'hrs', hint: 'Book time', controller: _laborHoursController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Shop Rate', unit: '\$/hr', hint: 'e.g., 125', controller: _shopRateController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Parts Cost', unit: '\$', hint: 'At cost', controller: _partsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Parts Markup', unit: '%', hint: '30-50', controller: _markupController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_laborCost != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildRateReference(colors),
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
        Text('Total = (Labor × Rate) + (Parts × Markup)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Calculate repair estimates with labor and parts', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('REPAIR ESTIMATE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildCostRow(colors, 'Labor', '\$${_laborCost!.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _buildCostRow(colors, 'Parts (w/markup)', '\$${_partsTotal!.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('TOTAL', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          Text('\$${_totalEstimate!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _buildCostRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildRateReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL SHOP RATES (2024)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRateRow(colors, 'Independent Shop', '\$80-120/hr'),
        _buildRateRow(colors, 'Chain/Franchise', '\$100-140/hr'),
        _buildRateRow(colors, 'Dealership (domestic)', '\$125-165/hr'),
        _buildRateRow(colors, 'Dealership (import)', '\$150-200/hr'),
        _buildRateRow(colors, 'Dealership (luxury)', '\$175-250/hr'),
        _buildRateRow(colors, 'Specialty/Performance', '\$150-300/hr'),
        const SizedBox(height: 12),
        Text('Rates vary significantly by region and market', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildRateRow(ZaftoColors colors, String shop, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(shop, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(rate, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
