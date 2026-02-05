import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Torque Multiplication Calculator - Torque at wheels
class TorqueMultiplicationScreen extends ConsumerStatefulWidget {
  const TorqueMultiplicationScreen({super.key});
  @override
  ConsumerState<TorqueMultiplicationScreen> createState() => _TorqueMultiplicationScreenState();
}

class _TorqueMultiplicationScreenState extends ConsumerState<TorqueMultiplicationScreen> {
  final _engineTorqueController = TextEditingController();
  final _transRatioController = TextEditingController();
  final _diffRatioController = TextEditingController();
  final _tireDiameterController = TextEditingController();

  double? _axleTorque;
  double? _wheelForce;

  void _calculate() {
    final engineTorque = double.tryParse(_engineTorqueController.text);
    final transRatio = double.tryParse(_transRatioController.text);
    final diffRatio = double.tryParse(_diffRatioController.text);
    final tireDiameter = double.tryParse(_tireDiameterController.text);

    if (engineTorque == null || transRatio == null || diffRatio == null) {
      setState(() { _axleTorque = null; });
      return;
    }

    final axle = engineTorque * transRatio * diffRatio;
    double? force;
    if (tireDiameter != null && tireDiameter > 0) {
      // Force = Torque / (Tire radius in feet)
      final radiusFt = (tireDiameter / 2) / 12;
      force = axle / radiusFt;
    }

    setState(() {
      _axleTorque = axle;
      _wheelForce = force;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _engineTorqueController.clear();
    _transRatioController.clear();
    _diffRatioController.clear();
    _tireDiameterController.clear();
    setState(() { _axleTorque = null; });
  }

  @override
  void dispose() {
    _engineTorqueController.dispose();
    _transRatioController.dispose();
    _diffRatioController.dispose();
    _tireDiameterController.dispose();
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
        title: Text('Torque Multiplication', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Torque', unit: 'lb-ft', hint: 'At crankshaft', controller: _engineTorqueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Transmission Ratio', unit: ':1', hint: 'Current gear', controller: _transRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Differential Ratio', unit: ':1', hint: 'Final drive', controller: _diffRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tire Diameter (Optional)', unit: 'in', hint: 'For force calculation', controller: _tireDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_axleTorque != null) _buildResultsCard(colors),
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
        Text('Axle Tq = Engine × Trans × Diff', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Torque multiplied through drivetrain to wheels', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Axle Torque', '${_axleTorque!.toStringAsFixed(0)} lb-ft', isPrimary: true),
        if (_wheelForce != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Tractive Force', '${_wheelForce!.toStringAsFixed(0)} lbs'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('This is theoretical maximum - actual is limited by traction and drivetrain losses.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
