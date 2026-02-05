import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Battery Load Test Calculator
class BatteryLoadTestScreen extends ConsumerStatefulWidget {
  const BatteryLoadTestScreen({super.key});
  @override
  ConsumerState<BatteryLoadTestScreen> createState() => _BatteryLoadTestScreenState();
}

class _BatteryLoadTestScreenState extends ConsumerState<BatteryLoadTestScreen> {
  final _ccaController = TextEditingController();
  final _voltageBeforeController = TextEditingController(text: '12.6');
  final _voltageUnderLoadController = TextEditingController();
  final _tempController = TextEditingController(text: '70');

  double? _loadAmps;
  double? _minVoltage;
  String? _result;
  String? _recommendation;

  void _calculate() {
    final cca = double.tryParse(_ccaController.text);
    final voltageBefore = double.tryParse(_voltageBeforeController.text);
    final voltageUnderLoad = double.tryParse(_voltageUnderLoadController.text);
    final temp = double.tryParse(_tempController.text) ?? 70;

    if (cca == null || voltageBefore == null || cca <= 0) {
      setState(() { _loadAmps = null; });
      return;
    }

    // Load test at 50% of CCA for 15 seconds
    final loadAmps = cca * 0.5;

    // Minimum voltage depends on temperature
    // At 70F: 9.6V minimum
    // Adjusts ~0.1V per 10 degrees from 70F
    final tempAdjust = (70 - temp) / 10 * 0.1;
    final minVoltage = 9.6 - tempAdjust;

    String result;
    String recommendation;

    if (voltageBefore < 12.4) {
      result = 'Battery undercharged - Charge before testing';
      recommendation = 'Charge battery to 12.6V+ before load test';
    } else if (voltageUnderLoad == null) {
      result = 'Enter voltage under load to see results';
      recommendation = 'Apply ${loadAmps.toStringAsFixed(0)}A load for 15 seconds';
    } else if (voltageUnderLoad >= minVoltage) {
      result = 'PASS - Battery is good';
      recommendation = 'Battery has adequate capacity. Retest in 6 months.';
    } else if (voltageUnderLoad >= minVoltage - 0.5) {
      result = 'MARGINAL - Monitor closely';
      recommendation = 'Battery is weak. Consider replacement before winter.';
    } else {
      result = 'FAIL - Replace battery';
      recommendation = 'Battery cannot deliver adequate current. Replace.';
    }

    setState(() {
      _loadAmps = loadAmps;
      _minVoltage = minVoltage;
      _result = result;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ccaController.clear();
    _voltageBeforeController.text = '12.6';
    _voltageUnderLoadController.clear();
    _tempController.text = '70';
    setState(() { _loadAmps = null; });
  }

  @override
  void dispose() {
    _ccaController.dispose();
    _voltageBeforeController.dispose();
    _voltageUnderLoadController.dispose();
    _tempController.dispose();
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
        title: Text('Battery Load Test', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Battery CCA', unit: 'A', hint: 'Cold cranking amps', controller: _ccaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Voltage Before', unit: 'V', hint: 'Open circuit', controller: _voltageBeforeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Voltage Under Load', unit: 'V', hint: 'After 15 sec', controller: _voltageUnderLoadController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Temperature', unit: 'F', hint: 'Ambient temp', controller: _tempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_loadAmps != null) _buildResultsCard(colors),
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
        Text('Load = CCA × 50% for 15 sec', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Minimum 9.6V at 70F under load', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isFail = _result?.contains('FAIL') ?? false;
    final isPass = _result?.contains('PASS') ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isFail ? Colors.red.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Test Load', '${_loadAmps!.toStringAsFixed(0)} A'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min Voltage', '${_minVoltage!.toStringAsFixed(1)} V'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isFail ? Colors.red.withValues(alpha: 0.1) : (isPass ? Colors.green.withValues(alpha: 0.1) : colors.bgBase), borderRadius: BorderRadius.circular(8)),
          child: Text(_result!, style: TextStyle(color: isFail ? Colors.red : (isPass ? Colors.green : colors.textPrimary), fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
