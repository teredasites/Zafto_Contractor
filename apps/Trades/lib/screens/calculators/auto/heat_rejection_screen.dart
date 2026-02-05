import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Heat Rejection Calculator - Engine cooling capacity
class HeatRejectionScreen extends ConsumerStatefulWidget {
  const HeatRejectionScreen({super.key});
  @override
  ConsumerState<HeatRejectionScreen> createState() => _HeatRejectionScreenState();
}

class _HeatRejectionScreenState extends ConsumerState<HeatRejectionScreen> {
  final _horsepowerController = TextEditingController();
  final _efficiencyController = TextEditingController(text: '25');

  double? _totalHeat;
  double? _coolantHeat;
  double? _exhaustHeat;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);
    final efficiency = double.tryParse(_efficiencyController.text) ?? 25;

    if (horsepower == null || efficiency <= 0) {
      setState(() { _totalHeat = null; });
      return;
    }

    // Total fuel energy = HP / efficiency
    final fuelEnergy = horsepower / (efficiency / 100);
    final totalHeatBtu = fuelEnergy * 2545; // Convert HP to BTU/hr

    // Heat distribution (approximate):
    // Mechanical work: efficiency%
    // Coolant: ~33%
    // Exhaust: ~33%
    // Friction/misc: remaining
    final coolantHeat = totalHeatBtu * 0.33;
    final exhaustHeat = totalHeatBtu * 0.33;

    setState(() {
      _totalHeat = totalHeatBtu;
      _coolantHeat = coolantHeat;
      _exhaustHeat = exhaustHeat;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    _efficiencyController.text = '25';
    setState(() { _totalHeat = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
    _efficiencyController.dispose();
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
        title: Text('Heat Rejection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Thermal Efficiency', unit: '%', hint: 'Typical 20-30%', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalHeat != null) _buildResultsCard(colors),
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
        Text('~33% of fuel energy to coolant', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Size cooling system for heat load', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('HEAT DISTRIBUTION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildHeatBar(colors, 'To Coolant', _coolantHeat!, colors.accentPrimary),
        const SizedBox(height: 8),
        _buildHeatBar(colors, 'To Exhaust', _exhaustHeat!, colors.warning),
        const SizedBox(height: 8),
        _buildHeatBar(colors, 'Mechanical Work', double.parse(_horsepowerController.text) * 2545, colors.accentSuccess),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            _buildResultRow(colors, 'Total Fuel Energy', '${(_totalHeat! / 1000).toStringAsFixed(0)}k BTU/hr'),
            const SizedBox(height: 4),
            _buildResultRow(colors, 'Cooling System Load', '${(_coolantHeat! / 1000).toStringAsFixed(0)}k BTU/hr'),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeatBar(ZaftoColors colors, String label, double value, Color barColor) {
    final percentage = (value / _totalHeat! * 100);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
      const SizedBox(height: 4),
      Container(
        height: 8,
        decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4)),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: percentage / 100,
          child: Container(decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(4))),
        ),
      ),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}
