import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Electrode Efficiency Calculator - Compare consumable efficiency
class ElectrodeEfficiencyScreen extends ConsumerStatefulWidget {
  const ElectrodeEfficiencyScreen({super.key});
  @override
  ConsumerState<ElectrodeEfficiencyScreen> createState() => _ElectrodeEfficiencyScreenState();
}

class _ElectrodeEfficiencyScreenState extends ConsumerState<ElectrodeEfficiencyScreen> {
  final _depositedController = TextEditingController();
  final _consumedController = TextEditingController();

  double? _efficiency;
  String? _processComparison;
  String? _analysis;

  // Typical efficiency ranges by process
  static const Map<String, List<double>> _typicalEfficiency = {
    'SMAW': [55, 65],
    'GMAW': [93, 98],
    'FCAW-G': [82, 88],
    'FCAW-S': [75, 82],
    'SAW': [95, 99],
    'GTAW': [95, 100],
  };

  void _calculate() {
    final deposited = double.tryParse(_depositedController.text);
    final consumed = double.tryParse(_consumedController.text);

    if (deposited == null || consumed == null || consumed <= 0) {
      setState(() { _efficiency = null; });
      return;
    }

    final efficiency = (deposited / consumed) * 100;

    String? matchedProcess;
    for (final entry in _typicalEfficiency.entries) {
      if (efficiency >= entry.value[0] && efficiency <= entry.value[1]) {
        matchedProcess = entry.key;
        break;
      }
    }

    String analysis;
    if (efficiency < 60) {
      analysis = 'Low efficiency - significant spatter/stub loss';
    } else if (efficiency < 80) {
      analysis = 'Moderate efficiency - typical for stick welding';
    } else if (efficiency < 95) {
      analysis = 'Good efficiency - typical for flux-cored';
    } else {
      analysis = 'Excellent efficiency - minimal waste';
    }

    setState(() {
      _efficiency = efficiency;
      _processComparison = matchedProcess != null
          ? 'Consistent with $matchedProcess process'
          : 'Check parameters - outside typical ranges';
      _analysis = analysis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _depositedController.clear();
    _consumedController.clear();
    setState(() { _efficiency = null; });
  }

  @override
  void dispose() {
    _depositedController.dispose();
    _consumedController.dispose();
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
        title: Text('Electrode Efficiency', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Weld Metal Deposited', unit: 'lbs', hint: 'Actual weld weight', controller: _depositedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Electrode Consumed', unit: 'lbs', hint: 'Total electrode used', controller: _consumedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 24),
            _buildTypicalRanges(colors),
            const SizedBox(height: 32),
            if (_efficiency != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypicalRanges(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Typical Ranges:', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: _typicalEfficiency.entries.map((e) =>
              Text('${e.key}: ${e.value[0].toInt()}-${e.value[1].toInt()}%',
                style: TextStyle(color: colors.textTertiary, fontSize: 11))
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Eff = (Deposited / Consumed) x 100', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Measure actual vs theoretical deposition', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Efficiency', '${_efficiency!.toStringAsFixed(1)}%', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Waste', '${(100 - _efficiency!).toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Text(_processComparison!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_analysis!, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            ],
          ),
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
