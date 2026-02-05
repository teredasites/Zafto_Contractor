import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Job Estimate Calculator - Total repair cost estimation
class JobEstimateScreen extends ConsumerStatefulWidget {
  const JobEstimateScreen({super.key});
  @override
  ConsumerState<JobEstimateScreen> createState() => _JobEstimateScreenState();
}

class _JobEstimateScreenState extends ConsumerState<JobEstimateScreen> {
  final _laborHoursController = TextEditingController();
  final _laborRateController = TextEditingController(text: '125');
  final _partsCostController = TextEditingController();
  final _partsMarkupController = TextEditingController(text: '40');
  final _shopSuppliesController = TextEditingController(text: '5');
  final _taxRateController = TextEditingController(text: '7');

  double? _laborTotal;
  double? _partsTotal;
  double? _shopSupplies;
  double? _taxAmount;
  double? _grandTotal;

  void _calculate() {
    final laborHours = double.tryParse(_laborHoursController.text) ?? 0;
    final laborRate = double.tryParse(_laborRateController.text) ?? 125;
    final partsCost = double.tryParse(_partsCostController.text) ?? 0;
    final partsMarkup = double.tryParse(_partsMarkupController.text) ?? 40;
    final shopSuppliesPercent = double.tryParse(_shopSuppliesController.text) ?? 5;
    final taxRate = double.tryParse(_taxRateController.text) ?? 7;

    final laborTotal = laborHours * laborRate;
    final partsRetail = partsCost * (1 + partsMarkup / 100);
    final shopSupplies = laborTotal * (shopSuppliesPercent / 100);
    final subtotal = laborTotal + partsRetail + shopSupplies;
    final taxAmount = partsRetail * (taxRate / 100); // Tax on parts only typically
    final grandTotal = subtotal + taxAmount;

    setState(() {
      _laborTotal = laborTotal;
      _partsTotal = partsRetail;
      _shopSupplies = shopSupplies;
      _taxAmount = taxAmount;
      _grandTotal = grandTotal;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _laborHoursController.clear();
    _laborRateController.text = '125';
    _partsCostController.clear();
    _partsMarkupController.text = '40';
    _shopSuppliesController.text = '5';
    _taxRateController.text = '7';
    setState(() { _grandTotal = null; });
  }

  @override
  void dispose() {
    _laborHoursController.dispose();
    _laborRateController.dispose();
    _partsCostController.dispose();
    _partsMarkupController.dispose();
    _shopSuppliesController.dispose();
    _taxRateController.dispose();
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
        title: Text('Job Estimate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Labor', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Hours', unit: 'hrs', hint: '', controller: _laborHoursController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Rate', unit: '\$/hr', hint: '', controller: _laborRateController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Text('Parts', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Cost', unit: '\$', hint: '', controller: _partsCostController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Markup', unit: '%', hint: '', controller: _partsMarkupController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Text('Other', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Shop Supplies', unit: '%', hint: '', controller: _shopSuppliesController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tax Rate', unit: '%', hint: '', controller: _taxRateController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_grandTotal != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('ESTIMATE BREAKDOWN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildLineItem(colors, 'Labor', _laborTotal!),
        _buildLineItem(colors, 'Parts (retail)', _partsTotal!),
        _buildLineItem(colors, 'Shop Supplies', _shopSupplies!),
        _buildLineItem(colors, 'Tax', _taxAmount!),
        const Divider(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('TOTAL', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          Text('\$${_grandTotal!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _buildLineItem(ZaftoColors colors, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      ]),
    );
  }
}
