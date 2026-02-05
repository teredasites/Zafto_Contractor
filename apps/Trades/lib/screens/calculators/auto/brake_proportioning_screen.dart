import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Brake Proportioning Valve Calculator - Adjust front/rear bias
class BrakeProportioningScreen extends ConsumerStatefulWidget {
  const BrakeProportioningScreen({super.key});
  @override
  ConsumerState<BrakeProportioningScreen> createState() => _BrakeProportioningScreenState();
}

class _BrakeProportioningScreenState extends ConsumerState<BrakeProportioningScreen> {
  final _inputPressureController = TextEditingController(text: '1000');
  final _kneePointController = TextEditingController(text: '400');
  final _slopeController = TextEditingController(text: '0.57');

  double? _outputPressure;
  double? _reduction;

  void _calculate() {
    final inputPressure = double.tryParse(_inputPressureController.text);
    final kneePoint = double.tryParse(_kneePointController.text) ?? 400;
    final slope = double.tryParse(_slopeController.text) ?? 0.57;

    if (inputPressure == null) {
      setState(() { _outputPressure = null; });
      return;
    }

    double output;
    if (inputPressure <= kneePoint) {
      output = inputPressure;
    } else {
      output = kneePoint + ((inputPressure - kneePoint) * slope);
    }

    final reduction = ((inputPressure - output) / inputPressure) * 100;

    setState(() {
      _outputPressure = output;
      _reduction = reduction;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _inputPressureController.text = '1000';
    _kneePointController.text = '400';
    _slopeController.text = '0.57';
    setState(() { _outputPressure = null; });
  }

  @override
  void dispose() {
    _inputPressureController.dispose();
    _kneePointController.dispose();
    _slopeController.dispose();
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
        title: Text('Brake Proportioning', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Line Pressure (Input)', unit: 'PSI', hint: 'From master cylinder', controller: _inputPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Knee Point', unit: 'PSI', hint: 'When reduction starts', controller: _kneePointController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Slope (Ratio)', unit: '', hint: '0-1, lower = more reduction', controller: _slopeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_outputPressure != null) _buildResultsCard(colors),
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
        Text('Output = Knee + (Input - Knee) × Slope', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Reduces rear brake pressure to prevent lockup', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Rear Pressure', '${_outputPressure!.toStringAsFixed(0)} PSI', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pressure Reduction', '${_reduction!.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Typical Settings:', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Street: Knee 300-450 PSI, Slope 0.50-0.65\nTrack: Adjust to achieve balanced braking', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
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
