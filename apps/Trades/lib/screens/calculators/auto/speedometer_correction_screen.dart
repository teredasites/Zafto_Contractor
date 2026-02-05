import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Speedometer Correction Calculator - Compensate for tire size changes
class SpeedometerCorrectionScreen extends ConsumerStatefulWidget {
  const SpeedometerCorrectionScreen({super.key});
  @override
  ConsumerState<SpeedometerCorrectionScreen> createState() => _SpeedometerCorrectionScreenState();
}

class _SpeedometerCorrectionScreenState extends ConsumerState<SpeedometerCorrectionScreen> {
  final _origDiameterController = TextEditingController();
  final _newDiameterController = TextEditingController();
  final _speedoReadingController = TextEditingController(text: '60');

  double? _actualSpeed;
  double? _errorPercent;

  void _calculate() {
    final origDiameter = double.tryParse(_origDiameterController.text);
    final newDiameter = double.tryParse(_newDiameterController.text);
    final speedoReading = double.tryParse(_speedoReadingController.text);

    if (origDiameter == null || newDiameter == null || speedoReading == null || origDiameter <= 0) {
      setState(() { _actualSpeed = null; });
      return;
    }

    // Actual speed = Speedo reading × (New diameter / Original diameter)
    final actual = speedoReading * (newDiameter / origDiameter);
    final error = ((newDiameter - origDiameter) / origDiameter) * 100;

    setState(() {
      _actualSpeed = actual;
      _errorPercent = error;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _origDiameterController.clear();
    _newDiameterController.clear();
    _speedoReadingController.text = '60';
    setState(() { _actualSpeed = null; });
  }

  @override
  void dispose() {
    _origDiameterController.dispose();
    _newDiameterController.dispose();
    _speedoReadingController.dispose();
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
        title: Text('Speedometer Correction', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Original Tire Diameter', unit: 'in', hint: 'Stock tire height', controller: _origDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'New Tire Diameter', unit: 'in', hint: 'Current tire height', controller: _newDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Speedometer Shows', unit: 'mph', hint: 'Displayed speed', controller: _speedoReadingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_actualSpeed != null) _buildResultsCard(colors),
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
        Text('Actual = Speedo × (New / Original)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate true speed with different tire sizes', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final faster = _errorPercent! > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Actual Speed', '${_actualSpeed!.toStringAsFixed(1)} mph', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Speedometer Error', '${_errorPercent!.abs().toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(
            faster
                ? 'Speedo reads slow - actual speed is HIGHER than displayed'
                : 'Speedo reads fast - actual speed is LOWER than displayed',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
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
