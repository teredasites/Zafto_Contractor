import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stabilizer (Cyanuric Acid) Calculator
class StabilizerCyaScreen extends ConsumerStatefulWidget {
  const StabilizerCyaScreen({super.key});
  @override
  ConsumerState<StabilizerCyaScreen> createState() => _StabilizerCyaScreenState();
}

class _StabilizerCyaScreenState extends ConsumerState<StabilizerCyaScreen> {
  final _volumeController = TextEditingController();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController(text: '40');

  double? _cyaOz;
  double? _cyaLbs;
  String? _direction;
  String? _note;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final current = double.tryParse(_currentController.text) ?? 0;
    final target = double.tryParse(_targetController.text);

    if (volume == null || target == null || volume <= 0) {
      setState(() { _cyaOz = null; });
      return;
    }

    final diff = target - current;

    if (diff <= 0) {
      // CYA too high - only way to lower is dilution
      final percentDrain = (current - target) / current * 100;
      setState(() {
        _cyaOz = percentDrain;
        _cyaLbs = null;
        _direction = 'lower';
        _note = 'CYA cannot be removed chemically. Drain ${percentDrain.toStringAsFixed(0)}% and refill with fresh water.';
      });
      return;
    }

    // Need to raise CYA
    // 13 oz of CYA per 10,000 gallons raises CYA by 10 ppm
    final oz = (diff / 10) * (volume / 10000) * 13;
    final lbs = oz / 16;

    setState(() {
      _cyaOz = oz;
      _cyaLbs = lbs;
      _direction = 'raise';
      _note = 'Add CYA to skimmer sock or dissolve slowly. Takes 2-3 days to fully dissolve.';
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentController.clear();
    _targetController.text = '40';
    setState(() { _cyaOz = null; });
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
        title: Text('Stabilizer (CYA)', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Current CYA', unit: 'ppm', hint: 'Test result', controller: _currentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target CYA', unit: 'ppm', hint: '30-50 ppm ideal', controller: _targetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cyaOz != null) _buildResultsCard(colors),
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
        Text('Ideal CYA: 30-50 ppm', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Protects chlorine from UV degradation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        if (_direction == 'raise') ...[
          _buildResultRow(colors, 'CYA Needed', '${_cyaOz!.toStringAsFixed(1)} oz', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Pounds', '${_cyaLbs!.toStringAsFixed(2)} lbs'),
        ] else ...[
          _buildResultRow(colors, 'Direction', 'Need to lower CYA'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Drain Amount', '${_cyaOz!.toStringAsFixed(0)}%', isPrimary: true),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_note!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
