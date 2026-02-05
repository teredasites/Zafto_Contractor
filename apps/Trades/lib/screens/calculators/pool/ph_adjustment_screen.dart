import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// pH Adjustment Calculator
class PhAdjustmentScreen extends ConsumerStatefulWidget {
  const PhAdjustmentScreen({super.key});
  @override
  ConsumerState<PhAdjustmentScreen> createState() => _PhAdjustmentScreenState();
}

class _PhAdjustmentScreenState extends ConsumerState<PhAdjustmentScreen> {
  final _volumeController = TextEditingController();
  final _currentPhController = TextEditingController();
  final _targetPhController = TextEditingController(text: '7.4');

  double? _acidOz;
  double? _sodaAshOz;
  String? _direction;
  String? _chemical;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final currentPh = double.tryParse(_currentPhController.text);
    final targetPh = double.tryParse(_targetPhController.text);

    if (volume == null || currentPh == null || targetPh == null || volume <= 0) {
      setState(() { _acidOz = null; });
      return;
    }

    final phDiff = currentPh - targetPh;

    if (phDiff.abs() < 0.1) {
      setState(() {
        _acidOz = 0;
        _sodaAshOz = 0;
        _direction = 'balanced';
        _chemical = 'No adjustment needed';
      });
      return;
    }

    // Per 10,000 gallons:
    // To lower pH by 0.2: ~6 oz muriatic acid (31.45%)
    // To raise pH by 0.2: ~6 oz soda ash
    final adjustmentFactor = (volume / 10000) * (phDiff.abs() / 0.2) * 6;

    if (phDiff > 0) {
      // pH too high - need acid
      setState(() {
        _acidOz = adjustmentFactor;
        _sodaAshOz = null;
        _direction = 'lower';
        _chemical = 'Muriatic Acid';
      });
    } else {
      // pH too low - need soda ash
      setState(() {
        _acidOz = null;
        _sodaAshOz = adjustmentFactor;
        _direction = 'raise';
        _chemical = 'Soda Ash';
      });
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentPhController.clear();
    _targetPhController.text = '7.4';
    setState(() { _acidOz = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _currentPhController.dispose();
    _targetPhController.dispose();
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
        title: Text('pH Adjustment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Current pH', unit: '', hint: 'Test result', controller: _currentPhController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target pH', unit: '', hint: '7.2-7.6 ideal', controller: _targetPhController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_acidOz != null || _sodaAshOz != null) _buildResultsCard(colors),
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
        Text('Ideal pH: 7.2 - 7.6', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Acid lowers pH, Soda Ash raises pH', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final amount = _acidOz ?? _sodaAshOz ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        if (_direction == 'balanced')
          Text('pH is balanced!', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700))
        else ...[
          _buildResultRow(colors, 'Direction', 'Need to $_direction pH'),
          const SizedBox(height: 12),
          _buildResultRow(colors, _chemical!, '${amount.toStringAsFixed(1)} oz', isPrimary: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _direction == 'lower'
                ? 'Add acid to deep end with pump running. Wait 4 hours before retesting.'
                : 'Dissolve soda ash in bucket first. Add slowly with pump running.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ),
        ],
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
