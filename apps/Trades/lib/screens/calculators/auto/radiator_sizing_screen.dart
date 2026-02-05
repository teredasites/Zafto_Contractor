import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Radiator Sizing Calculator - Heat rejection requirements
class RadiatorSizingScreen extends ConsumerStatefulWidget {
  const RadiatorSizingScreen({super.key});
  @override
  ConsumerState<RadiatorSizingScreen> createState() => _RadiatorSizingScreenState();
}

class _RadiatorSizingScreenState extends ConsumerState<RadiatorSizingScreen> {
  final _horsepowerController = TextEditingController();
  final _engineEfficiencyController = TextEditingController(text: '25');

  double? _heatRejection;
  double? _minRadiatorSize;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);
    final efficiency = double.tryParse(_engineEfficiencyController.text) ?? 25;

    if (horsepower == null) {
      setState(() { _heatRejection = null; });
      return;
    }

    // Engine typically converts 25-30% of fuel energy to mechanical power
    // Remaining goes to heat (exhaust, cooling, friction)
    // Cooling system handles roughly 30-35% of fuel energy
    final fuelEnergy = horsepower / (efficiency / 100);
    final heatToRadiator = fuelEnergy * 0.33; // ~33% to coolant
    final btuPerHour = heatToRadiator * 2545; // HP to BTU/hr

    // Radiator capacity rough estimate: 100 BTU/hr per square inch
    final minRadiatorSize = btuPerHour / 100;

    setState(() {
      _heatRejection = btuPerHour;
      _minRadiatorSize = minRadiatorSize;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    _engineEfficiencyController.text = '25';
    setState(() { _heatRejection = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
    _engineEfficiencyController.dispose();
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
        title: Text('Radiator Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Horsepower', unit: 'hp', hint: 'Peak output', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine Efficiency', unit: '%', hint: 'Typical 25-30%', controller: _engineEfficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_heatRejection != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildRadiatorGuide(colors),
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
        Text('~33% of fuel energy goes to coolant', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Size radiator for heat rejection needs', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('COOLING REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Heat Rejection', '${(_heatRejection! / 1000).toStringAsFixed(0)}k BTU/hr'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Min Radiator Area', '${_minRadiatorSize!.toStringAsFixed(0)} sq in'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('APPROXIMATE DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${(_minRadiatorSize! / 24).toStringAsFixed(0)}" × 24" or equivalent', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRadiatorGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RADIATOR SELECTION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Add 20-30% capacity for hot climates', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Add 30-50% for track/racing use', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Aluminum: lighter, better heat transfer', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Copper/brass: more durable, repairable', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Dual-pass: better cooling efficiency', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Match to fan CFM for optimal cooling', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
