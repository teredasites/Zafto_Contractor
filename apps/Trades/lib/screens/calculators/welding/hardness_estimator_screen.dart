import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Hardness Estimator Calculator - HAZ hardness prediction
class HardnessEstimatorScreen extends ConsumerStatefulWidget {
  const HardnessEstimatorScreen({super.key});
  @override
  ConsumerState<HardnessEstimatorScreen> createState() => _HardnessEstimatorScreenState();
}

class _HardnessEstimatorScreenState extends ConsumerState<HardnessEstimatorScreen> {
  final _carbonController = TextEditingController();
  final _coolingRateController = TextEditingController(text: '20');
  final _ceController = TextEditingController();

  double? _maxHardness;
  double? _hazHardness;
  String? _assessment;

  void _calculate() {
    final carbon = double.tryParse(_carbonController.text);
    final coolingRate = double.tryParse(_coolingRateController.text) ?? 20;
    final ce = double.tryParse(_ceController.text);

    if (carbon == null && ce == null) {
      setState(() { _maxHardness = null; });
      return;
    }

    // Use CE if provided, otherwise estimate from carbon
    final effectiveCE = ce ?? (carbon! + 0.15);

    // Maximum hardness formula (Duren): HVmax = 90 + 1050C + 47Si + 75Mn + 30Ni + 31Cr
    // Simplified: HVmax ≈ 90 + 1050 * CE
    final maxHardness = 90 + (1050 * effectiveCE);

    // HAZ hardness depends on cooling rate
    // Fast cooling (>30°F/s) approaches max hardness
    // Slow cooling (<10°F/s) approaches base metal hardness
    double hazFactor;
    if (coolingRate > 50) {
      hazFactor = 0.95;
    } else if (coolingRate > 30) {
      hazFactor = 0.85;
    } else if (coolingRate > 15) {
      hazFactor = 0.70;
    } else if (coolingRate > 5) {
      hazFactor = 0.55;
    } else {
      hazFactor = 0.40;
    }

    final hazHardness = maxHardness * hazFactor;

    String assessment;
    if (hazHardness > 400) {
      assessment = 'Very high hardness - high cracking risk. Increase preheat/heat input';
    } else if (hazHardness > 350) {
      assessment = 'High hardness - cracking possible. Use low hydrogen, control cooling';
    } else if (hazHardness > 300) {
      assessment = 'Moderate hardness - typical for structural steel';
    } else {
      assessment = 'Acceptable hardness - good ductility expected';
    }

    setState(() {
      _maxHardness = maxHardness;
      _hazHardness = hazHardness;
      _assessment = assessment;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _carbonController.clear();
    _coolingRateController.text = '20';
    _ceController.clear();
    setState(() { _maxHardness = null; });
  }

  @override
  void dispose() {
    _carbonController.dispose();
    _coolingRateController.dispose();
    _ceController.dispose();
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
        title: Text('Hardness Estimator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Carbon Content', unit: '%', hint: 'Or enter CE below', controller: _carbonController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Carbon Equivalent', unit: 'CE', hint: 'Optional - overrides C', controller: _ceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Cooling Rate', unit: '\u00B0F/s', hint: '20 typical', controller: _coolingRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_maxHardness != null) _buildResultsCard(colors),
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
        Text('HAZ Hardness Prediction', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate peak hardness in heat-affected zone', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'HAZ Hardness', '${_hazHardness!.toStringAsFixed(0)} HV', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Max Possible', '${_maxHardness!.toStringAsFixed(0)} HV'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Rockwell C (est)', '${((_hazHardness! - 76) / 8.7).toStringAsFixed(0)} HRC'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_assessment!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
