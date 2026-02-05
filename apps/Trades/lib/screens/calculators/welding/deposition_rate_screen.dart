import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Deposition Rate Calculator - lbs/hr weld metal deposited
class DepositionRateScreen extends ConsumerStatefulWidget {
  const DepositionRateScreen({super.key});
  @override
  ConsumerState<DepositionRateScreen> createState() => _DepositionRateScreenState();
}

class _DepositionRateScreenState extends ConsumerState<DepositionRateScreen> {
  final _wireSpeedController = TextEditingController();
  final _efficiencyController = TextEditingController(text: '95');
  String _wireSize = '0.035';
  String _process = 'GMAW';

  double? _depositionRate;
  double? _lbsPerHour;
  String? _analysis;

  // Wire weight per foot (lbs/ft)
  static const Map<String, double> _wireWeightPerFt = {
    '0.023': 0.00040,
    '0.030': 0.00068,
    '0.035': 0.00093,
    '0.045': 0.00153,
    '0.052': 0.00205,
    '1/16': 0.00295,
  };

  void _calculate() {
    final wireSpeed = double.tryParse(_wireSpeedController.text);
    final efficiency = double.tryParse(_efficiencyController.text) ?? 95;

    if (wireSpeed == null || wireSpeed <= 0) {
      setState(() { _depositionRate = null; });
      return;
    }

    final weightPerFt = _wireWeightPerFt[_wireSize] ?? 0.00093;
    // Wire speed in IPM, convert to feet per hour
    final feetPerHour = wireSpeed * 60 / 12;
    final lbsPerHour = feetPerHour * weightPerFt * (efficiency / 100);

    String analysis;
    if (lbsPerHour < 3) {
      analysis = 'Low deposition - suitable for thin materials or detail work';
    } else if (lbsPerHour < 8) {
      analysis = 'Moderate deposition - good for general fabrication';
    } else if (lbsPerHour < 15) {
      analysis = 'High deposition - production welding rates';
    } else {
      analysis = 'Very high deposition - heavy fabrication rates';
    }

    setState(() {
      _depositionRate = lbsPerHour;
      _lbsPerHour = lbsPerHour;
      _analysis = analysis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _wireSpeedController.clear();
    _efficiencyController.text = '95';
    setState(() { _depositionRate = null; });
  }

  @override
  void dispose() {
    _wireSpeedController.dispose();
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
        title: Text('Deposition Rate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildProcessSelector(colors),
            const SizedBox(height: 12),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Wire Feed Speed', unit: 'IPM', hint: 'Inches per minute', controller: _wireSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Deposition Efficiency', unit: '%', hint: '95% typical for MIG', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_depositionRate != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['GMAW', 'FCAW-G', 'FCAW-S', 'SAW'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _wireWeightPerFt.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _wireSize == size,
        onSelected: (_) => setState(() { _wireSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('DR = WFS x Wire Weight x Eff', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Pounds of weld metal deposited per hour', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Deposition Rate', '${_lbsPerHour!.toStringAsFixed(2)} lbs/hr', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Per 8-hr Shift', '${(_lbsPerHour! * 8 * 0.3).toStringAsFixed(1)} lbs'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_analysis!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
