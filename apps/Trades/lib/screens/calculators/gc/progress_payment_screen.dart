import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Progress Payment Calculator - Draw schedule and billing
class ProgressPaymentScreen extends ConsumerStatefulWidget {
  const ProgressPaymentScreen({super.key});
  @override
  ConsumerState<ProgressPaymentScreen> createState() => _ProgressPaymentScreenState();
}

class _ProgressPaymentScreenState extends ConsumerState<ProgressPaymentScreen> {
  final _contractController = TextEditingController(text: '150000');
  final _completedController = TextEditingController(text: '45');
  final _retainageController = TextEditingController(text: '10');
  final _previousController = TextEditingController(text: '50000');

  double? _earnedToDate;
  double? _retainageHeld;
  double? _netPayable;
  double? _thisApplication;

  @override
  void dispose() { _contractController.dispose(); _completedController.dispose(); _retainageController.dispose(); _previousController.dispose(); super.dispose(); }

  void _calculate() {
    final contract = double.tryParse(_contractController.text);
    final completedPct = double.tryParse(_completedController.text);
    final retainagePct = double.tryParse(_retainageController.text);
    final previous = double.tryParse(_previousController.text) ?? 0;

    if (contract == null || completedPct == null || retainagePct == null) {
      setState(() { _earnedToDate = null; _retainageHeld = null; _netPayable = null; _thisApplication = null; });
      return;
    }

    final earnedToDate = contract * (completedPct / 100);
    final retainageHeld = earnedToDate * (retainagePct / 100);
    final netPayable = earnedToDate - retainageHeld;
    final thisApplication = netPayable - previous;

    setState(() { _earnedToDate = earnedToDate; _retainageHeld = retainageHeld; _netPayable = netPayable; _thisApplication = thisApplication; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _contractController.text = '150000'; _completedController.text = '45'; _retainageController.text = '10'; _previousController.text = '50000'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Progress Payment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Contract Amount', unit: '\$', controller: _contractController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Completed', unit: '%', controller: _completedController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Retainage', unit: '%', controller: _retainageController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Previous Payments', unit: '\$', controller: _previousController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_thisApplication != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('THIS DRAW', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_thisApplication!.toStringAsFixed(2)}', style: TextStyle(color: _thisApplication! >= 0 ? colors.accentPrimary : colors.accentError, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Earned to Date', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_earnedToDate!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Retainage Held', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('-\$${_retainageHeld!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Net Payable', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_netPayable!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Retainage released at substantial/final completion per contract terms.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDrawSchedule(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildDrawSchedule(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL DRAW SCHEDULE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Foundation complete', '15%'),
        _buildTableRow(colors, 'Framing complete', '25%'),
        _buildTableRow(colors, 'Rough-ins complete', '20%'),
        _buildTableRow(colors, 'Drywall complete', '15%'),
        _buildTableRow(colors, 'Trim/finishes', '15%'),
        _buildTableRow(colors, 'Final completion', '10%'),
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
