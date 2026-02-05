import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Welding Time Calculator - Estimate total job time
class WeldingTimeScreen extends ConsumerStatefulWidget {
  const WeldingTimeScreen({super.key});
  @override
  ConsumerState<WeldingTimeScreen> createState() => _WeldingTimeScreenState();
}

class _WeldingTimeScreenState extends ConsumerState<WeldingTimeScreen> {
  final _weldLengthController = TextEditingController();
  final _travelSpeedController = TextEditingController(text: '10');
  final _operatorFactorController = TextEditingController(text: '30');
  final _numberOfPassesController = TextEditingController(text: '1');

  double? _arcTime;
  double? _totalTime;
  double? _jobHours;

  void _calculate() {
    final weldLength = double.tryParse(_weldLengthController.text);
    final travelSpeed = double.tryParse(_travelSpeedController.text) ?? 10;
    final operatorFactor = double.tryParse(_operatorFactorController.text) ?? 30;
    final numberOfPasses = double.tryParse(_numberOfPassesController.text) ?? 1;

    if (weldLength == null || travelSpeed <= 0) {
      setState(() { _arcTime = null; });
      return;
    }

    // Arc time in minutes = (length in inches × passes) / travel speed (IPM)
    final lengthInches = weldLength * 12; // Convert feet to inches
    final arcTimeMinutes = (lengthInches * numberOfPasses) / travelSpeed;

    // Total time = arc time / operator factor
    final totalTimeMinutes = arcTimeMinutes / (operatorFactor / 100);
    final jobHours = totalTimeMinutes / 60;

    setState(() {
      _arcTime = arcTimeMinutes;
      _totalTime = totalTimeMinutes;
      _jobHours = jobHours;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldLengthController.clear();
    _travelSpeedController.text = '10';
    _operatorFactorController.text = '30';
    _numberOfPassesController.text = '1';
    setState(() { _arcTime = null; });
  }

  @override
  void dispose() {
    _weldLengthController.dispose();
    _travelSpeedController.dispose();
    _operatorFactorController.dispose();
    _numberOfPassesController.dispose();
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
        title: Text('Welding Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Weld Length', unit: 'ft', hint: 'Linear feet', controller: _weldLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Travel Speed', unit: 'IPM', hint: '10 IPM typical', controller: _travelSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Passes', unit: '#', hint: '1 for single pass', controller: _numberOfPassesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Operator Factor', unit: '%', hint: '30% typical arc-on', controller: _operatorFactorController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildOperatorFactorGuide(colors),
            const SizedBox(height: 32),
            if (_arcTime != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildOperatorFactorGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Typical Operator Factors:', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Manual SMAW: 20-30%', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          Text('Semi-auto MIG: 25-40%', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          Text('Robotic: 60-85%', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Time = Length / Speed / OpFactor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate total welding job time', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Time', '${_jobHours!.toStringAsFixed(2)} hrs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Minutes', '${_totalTime!.toStringAsFixed(0)} min'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Arc Time Only', '${_arcTime!.toStringAsFixed(0)} min'),
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
