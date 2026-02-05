import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Landscape Estimate Calculator - Quick job pricing
class LandscapeEstimateScreen extends ConsumerStatefulWidget {
  const LandscapeEstimateScreen({super.key});
  @override
  ConsumerState<LandscapeEstimateScreen> createState() => _LandscapeEstimateScreenState();
}

class _LandscapeEstimateScreenState extends ConsumerState<LandscapeEstimateScreen> {
  final _laborHoursController = TextEditingController(text: '8');
  final _laborRateController = TextEditingController(text: '50');
  final _materialsController = TextEditingController(text: '500');
  final _rentalController = TextEditingController(text: '150');

  double _markupPercent = 20;
  double _contingency = 10;

  double? _laborCost;
  double? _subtotal;
  double? _markup;
  double? _totalPrice;

  @override
  void dispose() { _laborHoursController.dispose(); _laborRateController.dispose(); _materialsController.dispose(); _rentalController.dispose(); super.dispose(); }

  void _calculate() {
    final laborHours = double.tryParse(_laborHoursController.text) ?? 8;
    final laborRate = double.tryParse(_laborRateController.text) ?? 50;
    final materials = double.tryParse(_materialsController.text) ?? 500;
    final rental = double.tryParse(_rentalController.text) ?? 150;

    final laborCost = laborHours * laborRate;
    final subtotal = laborCost + materials + rental;
    final markup = subtotal * (_markupPercent / 100);
    final contingencyAmount = subtotal * (_contingency / 100);
    final totalPrice = subtotal + markup + contingencyAmount;

    setState(() {
      _laborCost = laborCost;
      _subtotal = subtotal;
      _markup = markup;
      _totalPrice = totalPrice;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _laborHoursController.text = '8'; _laborRateController.text = '50'; _materialsController.text = '500'; _rentalController.text = '150'; setState(() { _markupPercent = 20; _contingency = 10; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Landscape Estimate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('LABOR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Hours', unit: 'hrs', controller: _laborHoursController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Rate', unit: '\$/hr', controller: _laborRateController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 20),
            Text('COSTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Materials', unit: '\$', controller: _materialsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Equipment/Rental', unit: '\$', controller: _rentalController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Text('Markup:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _markupPercent, min: 0, max: 50, divisions: 10, label: '${_markupPercent.toInt()}%', onChanged: (v) { setState(() => _markupPercent = v); _calculate(); })),
              Text('${_markupPercent.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            Row(children: [
              Text('Contingency:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _contingency, min: 0, max: 20, divisions: 4, label: '${_contingency.toInt()}%', onChanged: (v) { setState(() => _contingency = v); _calculate(); })),
              Text('${_contingency.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_totalPrice != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('QUOTE PRICE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_totalPrice!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                _buildLineItem(colors, 'Labor', '\$${_laborCost!.toStringAsFixed(0)}'),
                _buildLineItem(colors, 'Materials', '\$${_materialsController.text}'),
                _buildLineItem(colors, 'Equipment', '\$${_rentalController.text}'),
                const SizedBox(height: 8), Divider(color: colors.borderSubtle), const SizedBox(height: 8),
                _buildLineItem(colors, 'Subtotal', '\$${_subtotal!.toStringAsFixed(0)}'),
                _buildLineItem(colors, 'Markup (${_markupPercent.toInt()}%)', '\$${_markup!.toStringAsFixed(0)}'),
                _buildLineItem(colors, 'Contingency (${_contingency.toInt()}%)', '\$${(_subtotal! * _contingency / 100).toStringAsFixed(0)}'),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPricingTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildLineItem(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildPricingTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRICING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Small job minimum', '\$150-250'),
        _buildTableRow(colors, 'Material markup', '15-25%'),
        _buildTableRow(colors, 'Labor burden', '+20-30% on rate'),
        _buildTableRow(colors, 'Contingency', '5-15%'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
