import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Permit Cost Calculator - Building permit fee estimation
class PermitCostScreen extends ConsumerStatefulWidget {
  const PermitCostScreen({super.key});
  @override
  ConsumerState<PermitCostScreen> createState() => _PermitCostScreenState();
}

class _PermitCostScreenState extends ConsumerState<PermitCostScreen> {
  final _valuationController = TextEditingController(text: '250000');

  String _permitType = 'new_const';

  double? _permitFee;
  double? _planCheck;
  double? _totalFees;

  @override
  void dispose() { _valuationController.dispose(); super.dispose(); }

  void _calculate() {
    final valuation = double.tryParse(_valuationController.text);

    if (valuation == null) {
      setState(() { _permitFee = null; _planCheck = null; _totalFees = null; });
      return;
    }

    // Typical sliding scale fee calculation
    // Base + rate per thousand (varies widely by jurisdiction)
    double permitFee;
    double baseFee;
    double ratePerThousand;

    switch (_permitType) {
      case 'new_const':
        baseFee = 500;
        ratePerThousand = 8.50;
        break;
      case 'addition':
        baseFee = 300;
        ratePerThousand = 7.00;
        break;
      case 'remodel':
        baseFee = 200;
        ratePerThousand = 5.50;
        break;
      case 'mechanical':
        baseFee = 100;
        ratePerThousand = 3.00;
        break;
      case 'electrical':
        baseFee = 75;
        ratePerThousand = 2.50;
        break;
      case 'plumbing':
        baseFee = 75;
        ratePerThousand = 2.50;
        break;
      default:
        baseFee = 500;
        ratePerThousand = 8.50;
    }

    permitFee = baseFee + (valuation / 1000 * ratePerThousand);

    // Plan check typically 50-65% of permit fee
    final planCheck = permitFee * 0.65;

    final totalFees = permitFee + planCheck;

    setState(() { _permitFee = permitFee; _planCheck = planCheck; _totalFees = totalFees; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _valuationController.text = '250000'; setState(() => _permitType = 'new_const'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Permit Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Project Valuation', unit: '\$', controller: _valuationController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalFees != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL FEES', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_totalFees!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Permit Fee', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_permitFee!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Plan Check (65%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_planCheck!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Estimate only. Actual fees vary by jurisdiction. Contact local building dept.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPermitTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['new_const', 'addition', 'remodel'];
    final labels = {'new_const': 'New Const', 'addition': 'Addition', 'remodel': 'Remodel'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PERMIT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _permitType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _permitType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
      const SizedBox(height: 8),
      Row(children: ['mechanical', 'electrical', 'plumbing'].map((o) {
        final isSelected = _permitType == o;
        final labels2 = {'mechanical': 'Mechanical', 'electrical': 'Electrical', 'plumbing': 'Plumbing'};
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _permitType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != 'plumbing' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels2[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildPermitTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ADDITIONAL FEES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Impact fees', 'Varies'),
        _buildTableRow(colors, 'School fees', '\$2-5/sqft'),
        _buildTableRow(colors, 'Fire sprinkler', '\$100-300'),
        _buildTableRow(colors, 'Sewer connection', '\$500-5000'),
        _buildTableRow(colors, 'Re-inspection', '\$50-100'),
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
