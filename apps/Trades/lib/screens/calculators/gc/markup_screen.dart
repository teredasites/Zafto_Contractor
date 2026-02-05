import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Markup Calculator - Contractor pricing and profit
class MarkupScreen extends ConsumerStatefulWidget {
  const MarkupScreen({super.key});
  @override
  ConsumerState<MarkupScreen> createState() => _MarkupScreenState();
}

class _MarkupScreenState extends ConsumerState<MarkupScreen> {
  final _costController = TextEditingController(text: '10000');
  final _markupController = TextEditingController(text: '20');
  final _overheadController = TextEditingController(text: '15');

  double? _sellPrice;
  double? _grossProfit;
  double? _netProfit;
  double? _profitMargin;

  @override
  void dispose() { _costController.dispose(); _markupController.dispose(); _overheadController.dispose(); super.dispose(); }

  void _calculate() {
    final cost = double.tryParse(_costController.text);
    final markupPct = double.tryParse(_markupController.text);
    final overheadPct = double.tryParse(_overheadController.text);

    if (cost == null || markupPct == null || overheadPct == null) {
      setState(() { _sellPrice = null; _grossProfit = null; _netProfit = null; _profitMargin = null; });
      return;
    }

    // Calculate sell price with markup
    final sellPrice = cost * (1 + markupPct / 100);

    // Gross profit
    final grossProfit = sellPrice - cost;

    // Overhead costs
    final overheadCost = sellPrice * (overheadPct / 100);

    // Net profit after overhead
    final netProfit = grossProfit - overheadCost;

    // Net profit margin
    final profitMargin = (netProfit / sellPrice) * 100;

    setState(() { _sellPrice = sellPrice; _grossProfit = grossProfit; _netProfit = netProfit; _profitMargin = profitMargin; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _costController.text = '10000'; _markupController.text = '20'; _overheadController.text = '15'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Markup Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Job Cost', unit: '\$', controller: _costController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Markup', unit: '%', controller: _markupController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Overhead', unit: '%', controller: _overheadController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_sellPrice != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SELL PRICE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_sellPrice!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gross Profit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_grossProfit!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Net Profit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_netProfit!.toStringAsFixed(2)}', style: TextStyle(color: _netProfit! >= 0 ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Profit Margin', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_profitMargin!.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Margin = Profit/Price. Markup = Profit/Cost. A 20% markup = 16.7% margin.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMarkupTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMarkupTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MARKUP TO MARGIN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '10% markup', '9.1% margin'),
        _buildTableRow(colors, '15% markup', '13.0% margin'),
        _buildTableRow(colors, '20% markup', '16.7% margin'),
        _buildTableRow(colors, '25% markup', '20.0% margin'),
        _buildTableRow(colors, '30% markup', '23.1% margin'),
        _buildTableRow(colors, '50% markup', '33.3% margin'),
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
