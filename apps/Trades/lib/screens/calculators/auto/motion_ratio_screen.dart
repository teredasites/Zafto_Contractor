import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Motion Ratio Calculator - Wheel rate from spring rate
class MotionRatioScreen extends ConsumerStatefulWidget {
  const MotionRatioScreen({super.key});
  @override
  ConsumerState<MotionRatioScreen> createState() => _MotionRatioScreenState();
}

class _MotionRatioScreenState extends ConsumerState<MotionRatioScreen> {
  final _springRateController = TextEditingController();
  final _motionRatioController = TextEditingController(text: '0.75');

  double? _wheelRate;
  double? _effectiveRate;

  void _calculate() {
    final springRate = double.tryParse(_springRateController.text);
    final motionRatio = double.tryParse(_motionRatioController.text);

    if (springRate == null || motionRatio == null || motionRatio <= 0) {
      setState(() { _wheelRate = null; });
      return;
    }

    // Wheel Rate = Spring Rate × Motion Ratio²
    final wheelRate = springRate * motionRatio * motionRatio;

    setState(() {
      _wheelRate = wheelRate;
      _effectiveRate = wheelRate;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _springRateController.clear();
    _motionRatioController.text = '0.75';
    setState(() { _wheelRate = null; });
  }

  @override
  void dispose() {
    _springRateController.dispose();
    _motionRatioController.dispose();
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
        title: Text('Motion Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Spring Rate', unit: 'lb/in', hint: 'Coilover spring rate', controller: _springRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Motion Ratio', unit: '', hint: '0.5-1.0 typical', controller: _motionRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_wheelRate != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildInfoCard(colors),
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
        Text('Wheel Rate = Spring × MR²', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Effective spring rate at the wheel', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Wheel Rate', '${_wheelRate!.toStringAsFixed(1)} lb/in', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Motion ratio < 1.0 means the spring moves less than the wheel. This reduces effective wheel rate.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEASURING MOTION RATIO', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('MR = Spring Movement / Wheel Movement\n\n1. Measure distance from spring seat to fixed point\n2. Measure wheel movement (e.g., 1")\n3. Measure spring movement\n4. Divide spring by wheel movement', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 12),
        Text('Typical values:\n- MacPherson strut: 0.90-1.0\n- Double wishbone: 0.65-0.85\n- Multi-link: 0.70-0.90', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
