import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Flywheel Weight Calculator - Flywheel mass effect on performance
class FlywheelWeightScreen extends ConsumerStatefulWidget {
  const FlywheelWeightScreen({super.key});
  @override
  ConsumerState<FlywheelWeightScreen> createState() => _FlywheelWeightScreenState();
}

class _FlywheelWeightScreenState extends ConsumerState<FlywheelWeightScreen> {
  final _stockWeightController = TextEditingController();
  final _newWeightController = TextEditingController();
  final _diameterController = TextEditingController();
  final _hpController = TextEditingController();
  final _redlineController = TextEditingController(text: '6500');

  double? _weightReduction;
  double? _inertiaReduction;
  double? _revGain;
  String? _recommendation;

  void _calculate() {
    final stockWeight = double.tryParse(_stockWeightController.text);
    final newWeight = double.tryParse(_newWeightController.text);
    final diameter = double.tryParse(_diameterController.text);
    final hp = double.tryParse(_hpController.text);
    final redline = double.tryParse(_redlineController.text);

    if (stockWeight == null || newWeight == null) {
      setState(() { _weightReduction = null; });
      return;
    }

    final weightDiff = stockWeight - newWeight;
    final weightPercent = (weightDiff / stockWeight) * 100;

    // Moment of inertia approximation: I = 0.5 × m × r²
    // Inertia reduction proportional to weight reduction for same diameter
    double inertiaPercent = weightPercent;

    // Rev improvement estimate (lighter flywheel = faster revs)
    // Roughly 5-10% quicker rev response per 30% weight reduction
    double revImprovement = weightPercent * 0.25;

    String recommendation;
    if (weightPercent < 15) {
      recommendation = 'Mild reduction - improved throttle response';
    } else if (weightPercent < 30) {
      recommendation = 'Moderate reduction - good street/track balance';
    } else if (weightPercent < 45) {
      recommendation = 'Significant reduction - may need rev matching';
    } else {
      recommendation = 'Extreme reduction - race use only, difficult daily driving';
    }

    setState(() {
      _weightReduction = weightPercent;
      _inertiaReduction = inertiaPercent;
      _revGain = revImprovement;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _stockWeightController.clear();
    _newWeightController.clear();
    _diameterController.clear();
    _hpController.clear();
    _redlineController.text = '6500';
    setState(() { _weightReduction = null; });
  }

  @override
  void dispose() {
    _stockWeightController.dispose();
    _newWeightController.dispose();
    _diameterController.dispose();
    _hpController.dispose();
    _redlineController.dispose();
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
        title: Text('Flywheel Weight', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Stock Flywheel Weight', unit: 'lbs', hint: 'e.g. 22', controller: _stockWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'New Flywheel Weight', unit: 'lbs', hint: 'e.g. 12', controller: _newWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Flywheel Diameter', unit: 'in', hint: 'Optional', controller: _diameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine HP', unit: 'HP', hint: 'Optional', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Redline', unit: 'RPM', hint: 'e.g. 6500', controller: _redlineController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_weightReduction != null) _buildResultsCard(colors),
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
        Text('Inertia = 0.5 x Mass x Radius²', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Lower inertia = faster rev response', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Weight Reduction', '${_weightReduction!.toStringAsFixed(1)}%', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Inertia Reduction', '~${_inertiaReduction!.toStringAsFixed(1)}%'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Rev Response Gain', '~${_revGain!.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Note: Lighter flywheels reduce engine braking and may cause idle issues', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
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
