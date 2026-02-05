import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Change Order Calculator - CO pricing
class ChangeOrderScreen extends ConsumerStatefulWidget {
  const ChangeOrderScreen({super.key});
  @override
  ConsumerState<ChangeOrderScreen> createState() => _ChangeOrderScreenState();
}

class _ChangeOrderScreenState extends ConsumerState<ChangeOrderScreen> {
  final _laborController = TextEditingController(text: '800');
  final _materialController = TextEditingController(text: '400');
  final _markupController = TextEditingController(text: '20');
  final _overheadController = TextEditingController(text: '10');

  double? _directCost;
  double? _totalCO;
  double? _profit;

  @override
  void dispose() { _laborController.dispose(); _materialController.dispose(); _markupController.dispose(); _overheadController.dispose(); super.dispose(); }

  void _calculate() {
    final labor = double.tryParse(_laborController.text) ?? 0;
    final material = double.tryParse(_materialController.text) ?? 0;
    final markupPct = double.tryParse(_markupController.text) ?? 20;
    final overheadPct = double.tryParse(_overheadController.text) ?? 10;

    final directCost = labor + material;

    // Apply overhead
    final withOverhead = directCost * (1 + overheadPct / 100);

    // Apply markup/profit
    final totalCO = withOverhead * (1 + markupPct / 100);

    final profit = totalCO - directCost;

    setState(() { _directCost = directCost; _totalCO = totalCO; _profit = profit; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _laborController.text = '800'; _materialController.text = '400'; _markupController.text = '20'; _overheadController.text = '10'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Change Order', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Labor Cost', unit: '\$', controller: _laborController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Material Cost', unit: '\$', controller: _materialController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Overhead', unit: '%', controller: _overheadController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Markup', unit: '%', controller: _markupController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalCO != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CHANGE ORDER', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_totalCO!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Direct Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_directCost!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Your Profit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_profit!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Get written approval before starting CO work. Track hours and materials separately.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCOChecklist(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCOChecklist(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CHANGE ORDER ESSENTIALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildCheckItem(colors, 'Written description of work'),
        _buildCheckItem(colors, 'Schedule impact noted'),
        _buildCheckItem(colors, 'Signed by owner/architect'),
        _buildCheckItem(colors, 'Reference original contract'),
        _buildCheckItem(colors, 'Include payment terms'),
      ]),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(LucideIcons.checkCircle, size: 14, color: colors.accentSuccess),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
