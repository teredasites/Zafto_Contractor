import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Electrode Calculator - Lbs of rod for weld length
class ElectrodeScreen extends ConsumerStatefulWidget {
  const ElectrodeScreen({super.key});
  @override
  ConsumerState<ElectrodeScreen> createState() => _ElectrodeScreenState();
}

class _ElectrodeScreenState extends ConsumerState<ElectrodeScreen> {
  final _weldLengthController = TextEditingController();
  final _legSizeController = TextEditingController(text: '0.25');
  String _rodSize = '3/32';

  double? _lbsRequired;
  double? _rodsNeeded;

  // Approximate deposition rate (lbs per foot of weld for 1/4" fillet)
  static const Map<String, double> _depositionRates = {
    '3/32': 0.012,
    '1/8': 0.027,
    '5/32': 0.040,
    '3/16': 0.055,
  };

  void _calculate() {
    final length = double.tryParse(_weldLengthController.text);
    final leg = double.tryParse(_legSizeController.text);

    if (length == null || leg == null || leg <= 0) {
      setState(() { _lbsRequired = null; });
      return;
    }

    final baseRate = _depositionRates[_rodSize] ?? 0.027;
    // Adjust for leg size (compared to standard 1/4")
    final adjustedRate = baseRate * (leg / 0.25) * (leg / 0.25);
    final lbs = length * adjustedRate * 1.15; // 15% waste factor
    // Approximate rods (14" rod = ~0.1 lbs for 1/8")
    final rodsPerLb = _rodSize == '1/8' ? 10 : (_rodSize == '3/32' ? 16 : 8);
    final rods = lbs * rodsPerLb;

    setState(() {
      _lbsRequired = lbs;
      _rodsNeeded = rods;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldLengthController.clear();
    _legSizeController.text = '0.25';
    setState(() { _lbsRequired = null; });
  }

  @override
  void dispose() {
    _weldLengthController.dispose();
    _legSizeController.dispose();
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
        title: Text('Electrode Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildRodSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Length', unit: 'ft', hint: 'Total linear feet', controller: _weldLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fillet Leg Size', unit: 'in', hint: 'e.g. 0.25 for 1/4"', controller: _legSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lbsRequired != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildRodSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _depositionRates.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _rodSize == size,
        onSelected: (_) => setState(() { _rodSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Stick Electrode Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Includes 15% waste factor for stub loss', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Electrode Weight', '${_lbsRequired!.toStringAsFixed(2)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Approx. Rods', '${_rodsNeeded!.toStringAsFixed(0)} rods'),
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
