import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Injector Duty Cycle Calculator - Check if injectors are maxed out
class InjectorDutyScreen extends ConsumerStatefulWidget {
  const InjectorDutyScreen({super.key});
  @override
  ConsumerState<InjectorDutyScreen> createState() => _InjectorDutyScreenState();
}

class _InjectorDutyScreenState extends ConsumerState<InjectorDutyScreen> {
  final _injectorSizeController = TextEditingController();
  final _injectorCountController = TextEditingController(text: '4');
  final _targetHpController = TextEditingController();
  final _bsfcController = TextEditingController(text: '0.55');
  final _fuelPressureController = TextEditingController(text: '43.5');
  final _basePressureController = TextEditingController(text: '43.5');

  double? _dutyCycle;
  double? _requiredFlow;

  void _calculate() {
    final injectorSize = double.tryParse(_injectorSizeController.text);
    final injectorCount = int.tryParse(_injectorCountController.text) ?? 4;
    final targetHp = double.tryParse(_targetHpController.text);
    final bsfc = double.tryParse(_bsfcController.text) ?? 0.55;
    final fuelPressure = double.tryParse(_fuelPressureController.text) ?? 43.5;
    final basePressure = double.tryParse(_basePressureController.text) ?? 43.5;

    if (injectorSize == null || targetHp == null) {
      setState(() { _dutyCycle = null; });
      return;
    }

    // Adjust injector flow for pressure difference
    final pressureRatio = fuelPressure / basePressure;
    final adjustedFlow = injectorSize * (pressureRatio > 0 ? (pressureRatio).abs() : 1);

    // Required flow = HP × BSFC / Number of injectors
    final requiredFlow = (targetHp * bsfc) / injectorCount;

    // Duty cycle = Required flow / Adjusted injector flow × 100
    final duty = (requiredFlow / adjustedFlow) * 100;

    setState(() {
      _dutyCycle = duty;
      _requiredFlow = requiredFlow;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _injectorSizeController.clear();
    _injectorCountController.text = '4';
    _targetHpController.clear();
    _bsfcController.text = '0.55';
    _fuelPressureController.text = '43.5';
    _basePressureController.text = '43.5';
    setState(() { _dutyCycle = null; });
  }

  @override
  void dispose() {
    _injectorSizeController.dispose();
    _injectorCountController.dispose();
    _targetHpController.dispose();
    _bsfcController.dispose();
    _fuelPressureController.dispose();
    _basePressureController.dispose();
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
        title: Text('Injector Duty Cycle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Injector Size', unit: 'cc/min', hint: 'Flow rating', controller: _injectorSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Injectors', unit: '', hint: '4, 6, 8', controller: _injectorCountController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Horsepower', unit: 'hp', hint: 'Wheel HP', controller: _targetHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'BSFC', unit: 'lb/hp/hr', hint: 'NA: 0.45-0.50, FI: 0.55-0.65', controller: _bsfcController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_dutyCycle != null) _buildResultsCard(colors),
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
        Text('IDC% = (HP × BSFC) / (Inj × Count) × 100', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Keep duty cycle under 80-85% for safety', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    String status;
    if (_dutyCycle! <= 80) {
      statusColor = colors.accentSuccess;
      status = 'Safe - headroom available';
    } else if (_dutyCycle! <= 85) {
      statusColor = colors.warning;
      status = 'Marginal - consider upgrading';
    } else {
      statusColor = colors.error;
      status = 'Maxed out - upgrade injectors';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Duty Cycle', '${_dutyCycle!.toStringAsFixed(1)}%', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Required per Injector', '${_requiredFlow!.toStringAsFixed(1)} cc/min'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
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
