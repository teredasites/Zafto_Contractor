import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Job Profit Calculator - Job costing and margins
class JobProfitScreen extends ConsumerStatefulWidget {
  const JobProfitScreen({super.key});
  @override
  ConsumerState<JobProfitScreen> createState() => _JobProfitScreenState();
}

class _JobProfitScreenState extends ConsumerState<JobProfitScreen> {
  final _revenueController = TextEditingController(text: '5000');
  final _materialsController = TextEditingController(text: '1500');
  final _laborHoursController = TextEditingController(text: '24');
  final _laborRateController = TextEditingController(text: '25');
  final _equipmentController = TextEditingController(text: '200');
  final _overheadController = TextEditingController(text: '15');

  double? _totalCost;
  double? _grossProfit;
  double? _netProfit;
  double? _profitMargin;

  @override
  void dispose() { _revenueController.dispose(); _materialsController.dispose(); _laborHoursController.dispose(); _laborRateController.dispose(); _equipmentController.dispose(); _overheadController.dispose(); super.dispose(); }

  void _calculate() {
    final revenue = double.tryParse(_revenueController.text) ?? 5000;
    final materials = double.tryParse(_materialsController.text) ?? 1500;
    final laborHours = double.tryParse(_laborHoursController.text) ?? 24;
    final laborRate = double.tryParse(_laborRateController.text) ?? 25;
    final equipment = double.tryParse(_equipmentController.text) ?? 200;
    final overheadPct = double.tryParse(_overheadController.text) ?? 15;

    final laborCost = laborHours * laborRate;
    final directCost = materials + laborCost + equipment;
    final grossProfit = revenue - directCost;

    final overheadCost = revenue * (overheadPct / 100);
    final netProfit = grossProfit - overheadCost;
    final margin = (netProfit / revenue) * 100;

    setState(() {
      _totalCost = directCost + overheadCost;
      _grossProfit = grossProfit;
      _netProfit = netProfit;
      _profitMargin = margin;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _revenueController.text = '5000'; _materialsController.text = '1500'; _laborHoursController.text = '24'; _laborRateController.text = '25'; _equipmentController.text = '200'; _overheadController.text = '15'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final isHealthy = (_profitMargin ?? 0) >= 20;
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Job Profit', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Job Revenue', unit: '\$', controller: _revenueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Materials Cost', unit: '\$', controller: _materialsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Labor Hours', unit: 'hrs', controller: _laborHoursController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Labor Rate', unit: '\$/hr', controller: _laborRateController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Equipment', unit: '\$', controller: _equipmentController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Overhead', unit: '%', controller: _overheadController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_netProfit != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('NET PROFIT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_netProfit!.toStringAsFixed(0)}', style: TextStyle(color: isHealthy ? colors.accentSuccess : colors.accentError, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Profit margin', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_profitMargin!.toStringAsFixed(1)}%', style: TextStyle(color: isHealthy ? colors.accentSuccess : colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gross profit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_grossProfit!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_totalCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildProfitGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProfitGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HEALTHY MARGINS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Maintenance', '25-35%'),
        _buildTableRow(colors, 'Installs', '20-30%'),
        _buildTableRow(colors, 'Hardscape', '15-25%'),
        _buildTableRow(colors, 'Design/build', '30-40%'),
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
