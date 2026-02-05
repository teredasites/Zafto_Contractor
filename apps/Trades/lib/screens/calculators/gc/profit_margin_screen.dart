import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Profit Margin Calculator - Job profitability analysis
class ProfitMarginScreen extends ConsumerStatefulWidget {
  const ProfitMarginScreen({super.key});
  @override
  ConsumerState<ProfitMarginScreen> createState() => _ProfitMarginScreenState();
}

class _ProfitMarginScreenState extends ConsumerState<ProfitMarginScreen> {
  final _revenueController = TextEditingController(text: '100000');
  final _laborController = TextEditingController(text: '35000');
  final _materialController = TextEditingController(text: '30000');
  final _overheadController = TextEditingController(text: '15000');

  double? _grossProfit;
  double? _netProfit;
  double? _grossMargin;
  double? _netMargin;

  @override
  void dispose() { _revenueController.dispose(); _laborController.dispose(); _materialController.dispose(); _overheadController.dispose(); super.dispose(); }

  void _calculate() {
    final revenue = double.tryParse(_revenueController.text);
    final labor = double.tryParse(_laborController.text) ?? 0;
    final material = double.tryParse(_materialController.text) ?? 0;
    final overhead = double.tryParse(_overheadController.text) ?? 0;

    if (revenue == null || revenue == 0) {
      setState(() { _grossProfit = null; _netProfit = null; _grossMargin = null; _netMargin = null; });
      return;
    }

    final directCost = labor + material;
    final grossProfit = revenue - directCost;
    final netProfit = grossProfit - overhead;

    final grossMargin = (grossProfit / revenue) * 100;
    final netMargin = (netProfit / revenue) * 100;

    setState(() { _grossProfit = grossProfit; _netProfit = netProfit; _grossMargin = grossMargin; _netMargin = netMargin; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _revenueController.text = '100000'; _laborController.text = '35000'; _materialController.text = '30000'; _overheadController.text = '15000'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Profit Margin', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Contract Revenue', unit: '\$', controller: _revenueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Labor Cost', unit: '\$', controller: _laborController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Material Cost', unit: '\$', controller: _materialController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Overhead', unit: '\$', controller: _overheadController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_netProfit != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('NET PROFIT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_netProfit!.toStringAsFixed(2)}', style: TextStyle(color: _netProfit! >= 0 ? colors.accentSuccess : colors.accentError, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gross Profit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_grossProfit!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gross Margin', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_grossMargin!.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Net Margin', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_netMargin!.toStringAsFixed(1)}%', style: TextStyle(color: _netMargin! >= 10 ? colors.accentSuccess : colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Target: 35-50% gross margin, 10-20% net margin for healthy business.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMarginGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMarginGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INDUSTRY BENCHMARKS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Remodeling', '35-50% gross'),
        _buildTableRow(colors, 'New construction', '20-30% gross'),
        _buildTableRow(colors, 'Specialty trades', '40-60% gross'),
        _buildTableRow(colors, 'Healthy net margin', '10-20%'),
        _buildTableRow(colors, 'Break-even danger', '<5% net'),
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
