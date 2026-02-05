import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shock Treatment Calculator
class ShockTreatmentScreen extends ConsumerStatefulWidget {
  const ShockTreatmentScreen({super.key});
  @override
  ConsumerState<ShockTreatmentScreen> createState() => _ShockTreatmentScreenState();
}

class _ShockTreatmentScreenState extends ConsumerState<ShockTreatmentScreen> {
  final _volumeController = TextEditingController();
  final _ccController = TextEditingController();
  String _shockType = 'Cal-Hypo (65%)';
  String _situation = 'Routine';

  double? _shockOz;
  double? _shockLbs;
  String? _targetFc;

  // Shock multiplier by situation
  static const Map<String, double> _situations = {
    'Routine': 10.0, // Target 10 ppm FC
    'Algae (Green)': 20.0, // Target 20 ppm FC
    'Algae (Yellow)': 30.0, // Target 30 ppm FC
    'Algae (Black)': 40.0, // Target 40 ppm FC
  };

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final cc = double.tryParse(_ccController.text) ?? 0;

    if (volume == null || volume <= 0) {
      setState(() { _shockOz = null; });
      return;
    }

    // Breakpoint chlorination = CC × 10 + target FC
    final targetFc = _situations[_situation] ?? 10.0;
    final breakpointTarget = (cc * 10) + targetFc;

    // Per 10,000 gallons, to raise FC by 1 ppm:
    // Cal-Hypo (65%): 2 oz
    // Dichlor (56%): 2.4 oz
    // Liquid (12.5%): 10 oz
    double ozPer10kPerPpm;
    switch (_shockType) {
      case 'Cal-Hypo (65%)':
        ozPer10kPerPpm = 2.0;
        break;
      case 'Dichlor (56%)':
        ozPer10kPerPpm = 2.4;
        break;
      case 'Liquid (12.5%)':
        ozPer10kPerPpm = 10.0;
        break;
      default:
        ozPer10kPerPpm = 2.0;
    }

    final oz = breakpointTarget * (volume / 10000) * ozPer10kPerPpm;
    final lbs = oz / 16;

    setState(() {
      _shockOz = oz;
      _shockLbs = lbs;
      _targetFc = breakpointTarget.toStringAsFixed(0);
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _ccController.clear();
    setState(() { _shockOz = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _ccController.dispose();
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
        title: Text('Shock Treatment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('SHOCK TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildShockTypeSelector(colors),
            const SizedBox(height: 16),
            Text('SITUATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildSituationSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Combined Chlorine', unit: 'ppm', hint: 'CC from test (optional)', controller: _ccController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_shockOz != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildShockTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Cal-Hypo (65%)', 'Dichlor (56%)', 'Liquid (12.5%)'].map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _shockType == type,
        onSelected: (_) => setState(() { _shockType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildSituationSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _situations.keys.map((sit) => ChoiceChip(
        label: Text(sit, style: const TextStyle(fontSize: 11)),
        selected: _situation == sit,
        onSelected: (_) => setState(() { _situation = sit; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Breakpoint = CC × 10 + Target', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Shock at dusk for best results', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Shock Needed', '${_shockOz!.toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pounds', '${_shockLbs!.toStringAsFixed(2)} lbs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Target FC', '$_targetFc ppm'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Add at dusk with pump running. Do not swim until FC drops below 5 ppm.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
