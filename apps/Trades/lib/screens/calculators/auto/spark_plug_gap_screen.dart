import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Spark Plug Gap Calculator
class SparkPlugGapScreen extends ConsumerStatefulWidget {
  const SparkPlugGapScreen({super.key});
  @override
  ConsumerState<SparkPlugGapScreen> createState() => _SparkPlugGapScreenState();
}

class _SparkPlugGapScreenState extends ConsumerState<SparkPlugGapScreen> {
  final _boostPsiController = TextEditingController(text: '0');
  String _ignitionType = 'Coil-on-Plug';
  String _plugType = 'Iridium';

  double? _recommendedGap;
  String? _gapInches;
  String? _recommendation;

  void _calculate() {
    final boostPsi = double.tryParse(_boostPsiController.text) ?? 0;

    // Base gap by ignition type (mm)
    double baseGap;
    if (_ignitionType == 'Coil-on-Plug') {
      baseGap = 1.1; // Modern COP systems
    } else if (_ignitionType == 'Coil Pack') {
      baseGap = 1.0;
    } else {
      baseGap = 0.9; // Distributor
    }

    // Adjust for plug type
    if (_plugType == 'Copper') {
      baseGap -= 0.1;
    } else if (_plugType == 'Platinum') {
      // Standard gap
    } else if (_plugType == 'Iridium') {
      baseGap += 0.05; // Fine electrode allows slightly larger gap
    }

    // Reduce gap for boost (rule: -0.004" per 10 PSI boost)
    final boostReduction = (boostPsi / 10) * 0.1; // ~0.1mm per 10 PSI
    final adjustedGap = (baseGap - boostReduction).clamp(0.5, 1.3);

    final gapInches = adjustedGap / 25.4;

    String recommendation;
    if (boostPsi > 20) {
      recommendation = 'High boost: Consider colder heat range plugs';
    } else if (_plugType == 'Copper') {
      recommendation = 'Copper plugs: Replace every 20-30K miles';
    } else {
      recommendation = 'Iridium/Platinum: 60-100K mile service life';
    }

    setState(() {
      _recommendedGap = adjustedGap;
      _gapInches = gapInches.toStringAsFixed(3);
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _boostPsiController.text = '0';
    setState(() { _recommendedGap = null; });
  }

  @override
  void dispose() {
    _boostPsiController.dispose();
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
        title: Text('Spark Plug Gap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('IGNITION TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildIgnitionSelector(colors),
            const SizedBox(height: 16),
            Text('PLUG TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildPlugSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Boost Pressure', unit: 'PSI', hint: '0 for N/A', controller: _boostPsiController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedGap != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildIgnitionSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Coil-on-Plug', 'Coil Pack', 'Distributor'].map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _ignitionType == type,
        onSelected: (_) => setState(() { _ignitionType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildPlugSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Copper', 'Platinum', 'Iridium'].map((type) => ChoiceChip(
        label: Text(type),
        selected: _plugType == type,
        onSelected: (_) => setState(() { _plugType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Gap = Base - (Boost × 0.004"/10PSI)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Reduce gap for forced induction', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Gap (mm)', '${_recommendedGap!.toStringAsFixed(2)} mm', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Gap (inches)', '$_gapInches"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
