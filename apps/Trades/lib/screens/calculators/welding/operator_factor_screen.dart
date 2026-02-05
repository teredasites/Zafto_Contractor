import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Operator Factor Calculator - Arc-on time percentage
class OperatorFactorScreen extends ConsumerStatefulWidget {
  const OperatorFactorScreen({super.key});
  @override
  ConsumerState<OperatorFactorScreen> createState() => _OperatorFactorScreenState();
}

class _OperatorFactorScreenState extends ConsumerState<OperatorFactorScreen> {
  final _arcTimeController = TextEditingController();
  final _totalTimeController = TextEditingController();
  String _environment = 'Shop';
  String _process = 'SMAW';

  double? _operatorFactor;
  double? _nonArcTime;
  String? _benchmark;

  // Typical operator factors
  static const Map<String, Map<String, double>> _typicalFactors = {
    'SMAW': {'Shop': 25, 'Field': 20, 'Robotic': 0},
    'GMAW': {'Shop': 35, 'Field': 25, 'Robotic': 70},
    'FCAW': {'Shop': 35, 'Field': 30, 'Robotic': 70},
    'SAW': {'Shop': 50, 'Field': 40, 'Robotic': 80},
    'GTAW': {'Shop': 20, 'Field': 15, 'Robotic': 50},
  };

  void _calculate() {
    final arcTime = double.tryParse(_arcTimeController.text);
    final totalTime = double.tryParse(_totalTimeController.text);

    double operatorFactor;
    if (arcTime != null && totalTime != null && totalTime > 0) {
      operatorFactor = (arcTime / totalTime) * 100;
    } else {
      // Use typical value
      operatorFactor = _typicalFactors[_process]?[_environment] ?? 30;
    }

    final nonArcTime = 100 - operatorFactor;
    final typicalValue = _typicalFactors[_process]?[_environment] ?? 30;

    String benchmark;
    if (operatorFactor > typicalValue * 1.2) {
      benchmark = 'Above average - excellent efficiency';
    } else if (operatorFactor > typicalValue * 0.8) {
      benchmark = 'Average for $_process in $_environment environment';
    } else {
      benchmark = 'Below average - review workflow for improvements';
    }

    setState(() {
      _operatorFactor = operatorFactor;
      _nonArcTime = nonArcTime;
      _benchmark = benchmark;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _arcTimeController.clear();
    _totalTimeController.clear();
    setState(() { _operatorFactor = null; });
  }

  @override
  void dispose() {
    _arcTimeController.dispose();
    _totalTimeController.dispose();
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
        title: Text('Operator Factor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Process', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            Text('Environment', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildEnvironmentSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Arc Time', unit: 'min', hint: 'Optional - to calculate', controller: _arcTimeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Total Time', unit: 'min', hint: 'Optional - to calculate', controller: _totalTimeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_operatorFactor != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _typicalFactors.keys.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildEnvironmentSelector(ZaftoColors colors) {
    final environments = ['Shop', 'Field', 'Robotic'];
    return Wrap(
      spacing: 8,
      children: environments.map((e) => ChoiceChip(
        label: Text(e),
        selected: _environment == e,
        onSelected: (_) => setState(() { _environment = e; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Op Factor = Arc Time / Total Time', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Percentage of time the arc is on', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Operator Factor', '${_operatorFactor!.toStringAsFixed(0)}%', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Non-Arc Time', '${_nonArcTime!.toStringAsFixed(0)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_benchmark!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
