import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fuel Pump Sizing Calculator - Required fuel pump flow
class FuelPumpScreen extends ConsumerStatefulWidget {
  const FuelPumpScreen({super.key});
  @override
  ConsumerState<FuelPumpScreen> createState() => _FuelPumpScreenState();
}

class _FuelPumpScreenState extends ConsumerState<FuelPumpScreen> {
  final _targetHpController = TextEditingController();
  final _bsfcController = TextEditingController(text: '0.55');
  final _fuelPressureController = TextEditingController(text: '43.5');
  final _safetyMarginController = TextEditingController(text: '20');

  double? _requiredFlow;
  double? _requiredFlowLph;

  void _calculate() {
    final targetHp = double.tryParse(_targetHpController.text);
    final bsfc = double.tryParse(_bsfcController.text) ?? 0.55;
    final safetyMargin = double.tryParse(_safetyMarginController.text) ?? 20;

    if (targetHp == null) {
      setState(() { _requiredFlow = null; });
      return;
    }

    // Required flow = HP × BSFC / 6 (gasoline density) + safety margin
    // Result in lbs/hr, convert to gallons/hr
    final lbsPerHour = targetHp * bsfc;
    final gph = lbsPerHour / 6.0; // Gasoline ~6 lbs/gallon
    final gphWithMargin = gph * (1 + safetyMargin / 100);
    final lph = gphWithMargin * 3.785;

    setState(() {
      _requiredFlow = gphWithMargin;
      _requiredFlowLph = lph;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _targetHpController.clear();
    _bsfcController.text = '0.55';
    _fuelPressureController.text = '43.5';
    _safetyMarginController.text = '20';
    setState(() { _requiredFlow = null; });
  }

  @override
  void dispose() {
    _targetHpController.dispose();
    _bsfcController.dispose();
    _fuelPressureController.dispose();
    _safetyMarginController.dispose();
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
        title: Text('Fuel Pump Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Horsepower', unit: 'hp', hint: 'At crank', controller: _targetHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'BSFC', unit: 'lb/hp/hr', hint: 'NA: 0.45-0.50, FI: 0.55-0.65', controller: _bsfcController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fuel Pressure', unit: 'psi', hint: 'Operating pressure', controller: _fuelPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Safety Margin', unit: '%', hint: 'Typical 20%', controller: _safetyMarginController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_requiredFlow != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildPumpReferenceCard(colors),
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
        Text('GPH = (HP × BSFC / 6) × 1.2', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Fuel pump flow decreases with pressure', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('MINIMUM PUMP FLOW', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(children: [
            Text('${_requiredFlow!.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
            Text('GPH', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
          Container(width: 1, height: 40, color: colors.borderSubtle),
          Column(children: [
            Text('${_requiredFlowLph!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
            Text('LPH', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Pump ratings are at free-flow. Actual flow at pressure is lower. Check pump flow curve.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildPumpReferenceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON PUMP RATINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildPumpRow(colors, 'Stock in-tank', '~80-120 LPH', '~250-350 HP'),
        _buildPumpRow(colors, 'Walbro 255', '255 LPH', '~500 HP'),
        _buildPumpRow(colors, 'AEM 340', '340 LPH', '~650 HP'),
        _buildPumpRow(colors, 'DW400', '415 LPH', '~800 HP'),
        _buildPumpRow(colors, 'Dual pump', '500+ LPH', '1000+ HP'),
      ]),
    );
  }

  Widget _buildPumpRow(ZaftoColors colors, String pump, String flow, String hp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(flex: 2, child: Text(pump, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        Expanded(child: Text(flow, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Expanded(child: Text(hp, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }
}
