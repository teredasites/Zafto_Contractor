import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Brake Pedal Ratio Calculator - Mechanical advantage calculation
class PedalRatioScreen extends ConsumerStatefulWidget {
  const PedalRatioScreen({super.key});
  @override
  ConsumerState<PedalRatioScreen> createState() => _PedalRatioScreenState();
}

class _PedalRatioScreenState extends ConsumerState<PedalRatioScreen> {
  final _pivotToPadController = TextEditingController();
  final _pivotToPushrodController = TextEditingController();

  double? _pedalRatio;
  double? _outputForce;

  void _calculate() {
    final pivotToPad = double.tryParse(_pivotToPadController.text);
    final pivotToPushrod = double.tryParse(_pivotToPushrodController.text);

    if (pivotToPad == null || pivotToPushrod == null || pivotToPushrod <= 0) {
      setState(() { _pedalRatio = null; });
      return;
    }

    final ratio = pivotToPad / pivotToPushrod;
    // Assuming 100 lb input force
    final output = 100 * ratio;

    setState(() {
      _pedalRatio = ratio;
      _outputForce = output;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pivotToPadController.clear();
    _pivotToPushrodController.clear();
    setState(() { _pedalRatio = null; });
  }

  @override
  void dispose() {
    _pivotToPadController.dispose();
    _pivotToPushrodController.dispose();
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
        title: Text('Pedal Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pivot to Pedal Pad', unit: 'in', hint: 'Distance A', controller: _pivotToPadController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pivot to Pushrod', unit: 'in', hint: 'Distance B', controller: _pivotToPushrodController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pedalRatio != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildDiagramCard(colors),
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
        Text('Ratio = Pivot-to-Pad / Pivot-to-Pushrod', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Mechanical advantage multiplies pedal force', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_pedalRatio! < 4) {
      analysis = 'Low ratio - requires higher pedal effort, but short travel';
    } else if (_pedalRatio! < 6) {
      analysis = 'Typical ratio for power-assisted brakes';
    } else if (_pedalRatio! < 8) {
      analysis = 'Good ratio for manual brakes - balanced feel';
    } else {
      analysis = 'High ratio - light pedal but increased travel';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Pedal Ratio', '${_pedalRatio!.toStringAsFixed(2)}:1', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Output @ 100 lb input', '${_outputForce!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildDiagramCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEASUREMENT GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('Pivot to Pad: Measure from pedal pivot point to center of foot pad.\n\nPivot to Pushrod: Measure from pivot to master cylinder pushrod attachment.', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 12),
        Text('Typical ranges:\n- Power brakes: 4:1 to 5:1\n- Manual brakes: 5:1 to 7:1', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
