import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Transmission Gear Spread Calculator - Analyze gear spacing
class TransGearSpreadScreen extends ConsumerStatefulWidget {
  const TransGearSpreadScreen({super.key});
  @override
  ConsumerState<TransGearSpreadScreen> createState() => _TransGearSpreadScreenState();
}

class _TransGearSpreadScreenState extends ConsumerState<TransGearSpreadScreen> {
  final _gear1Controller = TextEditingController();
  final _gear2Controller = TextEditingController();
  final _gear3Controller = TextEditingController();
  final _gear4Controller = TextEditingController();
  final _gear5Controller = TextEditingController();
  final _gear6Controller = TextEditingController();

  double? _totalSpread;
  List<double> _stepPercentages = [];

  void _calculate() {
    final gears = <double>[];
    for (final controller in [_gear1Controller, _gear2Controller, _gear3Controller, _gear4Controller, _gear5Controller, _gear6Controller]) {
      final value = double.tryParse(controller.text);
      if (value != null && value > 0) gears.add(value);
    }

    if (gears.length < 2) {
      setState(() { _totalSpread = null; _stepPercentages = []; });
      return;
    }

    final spread = gears.first / gears.last;
    final steps = <double>[];
    for (int i = 0; i < gears.length - 1; i++) {
      final step = ((gears[i] - gears[i + 1]) / gears[i]) * 100;
      steps.add(step);
    }

    setState(() {
      _totalSpread = spread;
      _stepPercentages = steps;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    for (final controller in [_gear1Controller, _gear2Controller, _gear3Controller, _gear4Controller, _gear5Controller, _gear6Controller]) {
      controller.clear();
    }
    setState(() { _totalSpread = null; _stepPercentages = []; });
  }

  @override
  void dispose() {
    _gear1Controller.dispose();
    _gear2Controller.dispose();
    _gear3Controller.dispose();
    _gear4Controller.dispose();
    _gear5Controller.dispose();
    _gear6Controller.dispose();
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
        title: Text('Gear Spread', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ZaftoInputField(label: '1st', unit: '', hint: 'Ratio', controller: _gear1Controller, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: '2nd', unit: '', hint: 'Ratio', controller: _gear2Controller, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: '3rd', unit: '', hint: 'Ratio', controller: _gear3Controller, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: '4th', unit: '', hint: 'Ratio', controller: _gear4Controller, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: '5th', unit: '', hint: 'Ratio', controller: _gear5Controller, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: '6th', unit: '', hint: 'Optional', controller: _gear6Controller, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalSpread != null) _buildResultsCard(colors),
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
        Text('Spread = 1st Gear / Top Gear', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Analyze transmission gear spacing', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Spread', '${_totalSpread!.toStringAsFixed(2)}:1', isPrimary: true),
        const SizedBox(height: 16),
        Text('GEAR STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ..._stepPercentages.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${i + 1}st to ${i + 2}nd', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text('${step.toStringAsFixed(1)}% drop', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Ideal step: 15-20% between gears keeps engine in powerband.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
