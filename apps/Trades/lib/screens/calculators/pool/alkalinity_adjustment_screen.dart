import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Alkalinity Adjustment Calculator
class AlkalinityAdjustmentScreen extends ConsumerStatefulWidget {
  const AlkalinityAdjustmentScreen({super.key});
  @override
  ConsumerState<AlkalinityAdjustmentScreen> createState() => _AlkalinityAdjustmentScreenState();
}

class _AlkalinityAdjustmentScreenState extends ConsumerState<AlkalinityAdjustmentScreen> {
  final _volumeController = TextEditingController();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController(text: '100');

  double? _bicarbOz;
  double? _acidOz;
  String? _direction;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final current = double.tryParse(_currentController.text);
    final target = double.tryParse(_targetController.text);

    if (volume == null || current == null || target == null || volume <= 0) {
      setState(() { _bicarbOz = null; });
      return;
    }

    final diff = target - current;

    if (diff.abs() < 5) {
      setState(() {
        _bicarbOz = 0;
        _acidOz = 0;
        _direction = 'balanced';
      });
      return;
    }

    // Per 10,000 gallons:
    // To raise TA by 10 ppm: 1.4 lbs sodium bicarbonate
    // To lower TA by 10 ppm: 26 oz muriatic acid (then aerate)
    if (diff > 0) {
      // Need to raise TA
      final lbs = (diff / 10) * (volume / 10000) * 1.4;
      final oz = lbs * 16;
      setState(() {
        _bicarbOz = oz;
        _acidOz = null;
        _direction = 'raise';
      });
    } else {
      // Need to lower TA
      final oz = (diff.abs() / 10) * (volume / 10000) * 26;
      setState(() {
        _bicarbOz = null;
        _acidOz = oz;
        _direction = 'lower';
      });
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentController.clear();
    _targetController.text = '100';
    setState(() { _bicarbOz = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _currentController.dispose();
    _targetController.dispose();
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
        title: Text('Alkalinity Adjustment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current TA', unit: 'ppm', hint: 'Test result', controller: _currentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target TA', unit: 'ppm', hint: '80-120 ppm ideal', controller: _targetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bicarbOz != null || _acidOz != null || _direction == 'balanced') _buildResultsCard(colors),
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
        Text('Ideal TA: 80-120 ppm', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Baking soda raises, acid + aeration lowers', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    if (_direction == 'balanced') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
        child: Text('Alkalinity is balanced!', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      );
    }

    final amount = _direction == 'raise' ? _bicarbOz! : _acidOz!;
    final chemical = _direction == 'raise' ? 'Sodium Bicarbonate' : 'Muriatic Acid';
    final tip = _direction == 'raise'
        ? 'Dissolve in bucket first. Add slowly with pump running.'
        : 'Add acid, then run pump and aerate (waterfall/jets) to drive off CO2 without lowering pH.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Direction', 'Need to $_direction TA'),
        const SizedBox(height: 12),
        _buildResultRow(colors, chemical, '${amount.toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(tip, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
