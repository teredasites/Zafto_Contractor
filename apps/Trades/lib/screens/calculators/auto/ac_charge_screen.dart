import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// A/C Refrigerant Charge Calculator
/// Calculates refrigerant charge based on system specs and conditions
class AcChargeScreen extends ConsumerStatefulWidget {
  const AcChargeScreen({super.key});
  @override
  ConsumerState<AcChargeScreen> createState() => _AcChargeScreenState();
}

class _AcChargeScreenState extends ConsumerState<AcChargeScreen> {
  final _specChargeController = TextEditingController();
  final _lineAddedController = TextEditingController(text: '0');
  final _ambientTempController = TextEditingController();

  double? _totalCharge;
  double? _lineAdjustment;
  double? _tempAdjustment;
  String? _chargeStatus;

  void _calculate() {
    final specCharge = double.tryParse(_specChargeController.text);
    final lineAdded = double.tryParse(_lineAddedController.text) ?? 0;
    final ambientTemp = double.tryParse(_ambientTempController.text);

    if (specCharge == null) {
      setState(() { _totalCharge = null; });
      return;
    }

    // Line length adjustment: ~0.5 oz per foot of added line
    final lineAdj = lineAdded * 0.5;

    // Temperature adjustment: high ambient may need slight reduction
    double tempAdj = 0;
    String status = 'Normal';
    if (ambientTemp != null) {
      if (ambientTemp > 100) {
        tempAdj = -1.0; // Reduce slightly in extreme heat
        status = 'High Ambient - Reduce Charge';
      } else if (ambientTemp < 60) {
        status = 'Low Ambient - Charge May Read Low';
      }
    }

    final total = specCharge + lineAdj + tempAdj;

    setState(() {
      _totalCharge = total;
      _lineAdjustment = lineAdj;
      _tempAdjustment = tempAdj;
      _chargeStatus = status;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _specChargeController.clear();
    _lineAddedController.text = '0';
    _ambientTempController.clear();
    setState(() { _totalCharge = null; });
  }

  @override
  void dispose() {
    _specChargeController.dispose();
    _lineAddedController.dispose();
    _ambientTempController.dispose();
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
        title: Text('A/C Charge', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Spec Charge', unit: 'oz', hint: 'OEM specified refrigerant amount', controller: _specChargeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Line Added', unit: 'ft', hint: 'Additional line length beyond OEM', controller: _lineAddedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ambient Temp', unit: 'F', hint: 'Current outdoor temperature', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalCharge != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Total = Spec + Line Adj + Temp Adj', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Add ~0.5 oz per foot of added refrigerant line', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Charge', '${_totalCharge!.toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Line Adjustment', '+${_lineAdjustment!.toStringAsFixed(1)} oz'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Temp Adjustment', '${_tempAdjustment!.toStringAsFixed(1)} oz'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Status', _chargeStatus!),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
