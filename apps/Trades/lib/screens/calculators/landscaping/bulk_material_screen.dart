import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bulk Material Calculator - Bags vs bulk pricing
class BulkMaterialScreen extends ConsumerStatefulWidget {
  const BulkMaterialScreen({super.key});
  @override
  ConsumerState<BulkMaterialScreen> createState() => _BulkMaterialScreenState();
}

class _BulkMaterialScreenState extends ConsumerState<BulkMaterialScreen> {
  final _cuYdController = TextEditingController(text: '5');
  final _bagPriceController = TextEditingController(text: '5');
  final _bagSizeController = TextEditingController(text: '2');
  final _bulkPriceController = TextEditingController(text: '45');
  final _deliveryController = TextEditingController(text: '75');

  double? _bagsNeeded;
  double? _bagTotal;
  double? _bulkTotal;
  double? _savings;
  String? _recommendation;

  @override
  void dispose() { _cuYdController.dispose(); _bagPriceController.dispose(); _bagSizeController.dispose(); _bulkPriceController.dispose(); _deliveryController.dispose(); super.dispose(); }

  void _calculate() {
    final cuYd = double.tryParse(_cuYdController.text) ?? 5;
    final bagPrice = double.tryParse(_bagPriceController.text) ?? 5;
    final bagSizeCuFt = double.tryParse(_bagSizeController.text) ?? 2;
    final bulkPricePerYd = double.tryParse(_bulkPriceController.text) ?? 45;
    final deliveryFee = double.tryParse(_deliveryController.text) ?? 75;

    // Convert to cu ft
    final cuFt = cuYd * 27;
    final bagsNeeded = (cuFt / bagSizeCuFt).ceil();
    final bagTotal = bagsNeeded * bagPrice;

    final bulkTotal = (cuYd * bulkPricePerYd) + deliveryFee;

    final savings = bagTotal - bulkTotal;

    String recommendation;
    if (savings > 50) {
      recommendation = 'Bulk saves \$${savings.abs().toStringAsFixed(0)}';
    } else if (savings < -50) {
      recommendation = 'Bags save \$${savings.abs().toStringAsFixed(0)}';
    } else {
      recommendation = 'Similar cost - consider convenience';
    }

    setState(() {
      _bagsNeeded = bagsNeeded.toDouble();
      _bagTotal = bagTotal;
      _bulkTotal = bulkTotal;
      _savings = savings;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _cuYdController.text = '5'; _bagPriceController.text = '5'; _bagSizeController.text = '2'; _bulkPriceController.text = '45'; _deliveryController.text = '75'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Bags vs Bulk', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Amount Needed', unit: 'cu yd', controller: _cuYdController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Text('BAGGED MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bag Price', unit: '\$', controller: _bagPriceController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Bag Size', unit: 'cu ft', controller: _bagSizeController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Text('BULK MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Price/Yard', unit: '\$', controller: _bulkPriceController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Delivery', unit: '\$', controller: _deliveryController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_bagTotal != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: (_savings ?? 0) > 0 ? colors.accentSuccess.withValues(alpha: 0.1) : colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon((_savings ?? 0) > 0 ? LucideIcons.truck : LucideIcons.package, color: (_savings ?? 0) > 0 ? colors.accentSuccess : colors.accentWarning, size: 18),
                    const SizedBox(width: 8),
                    Text(_recommendation ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(children: [
                    Text('BAGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('\$${_bagTotal!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('${_bagsNeeded!.toInt()} bags', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ])),
                  Container(width: 1, height: 60, color: colors.borderSubtle),
                  Expanded(child: Column(children: [
                    Text('BULK', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('\$${_bulkTotal!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('delivered', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ])),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONSIDERATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Bulk threshold', '2-3 cu yd usually'),
        _buildTableRow(colors, 'Bags', 'No delivery, store at will'),
        _buildTableRow(colors, 'Bulk', 'Needs staging area, shovel'),
        _buildTableRow(colors, '1 cu yd', '~13.5 bags (2 cu ft)'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
