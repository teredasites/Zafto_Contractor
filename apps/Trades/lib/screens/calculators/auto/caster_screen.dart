import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Caster Calculator - Steering axis inclination
class CasterScreen extends ConsumerStatefulWidget {
  const CasterScreen({super.key});
  @override
  ConsumerState<CasterScreen> createState() => _CasterScreenState();
}

class _CasterScreenState extends ConsumerState<CasterScreen> {
  final _camberTurnedInController = TextEditingController();
  final _camberTurnedOutController = TextEditingController();
  final _turnAngleController = TextEditingController(text: '20');

  double? _casterAngle;

  void _calculate() {
    final camberIn = double.tryParse(_camberTurnedInController.text);
    final camberOut = double.tryParse(_camberTurnedOutController.text);
    final turnAngle = double.tryParse(_turnAngleController.text);

    if (camberIn == null || camberOut == null || turnAngle == null || turnAngle <= 0) {
      setState(() { _casterAngle = null; });
      return;
    }

    // Caster = (Camber turned in - Camber turned out) / (2 × sin(turn angle))
    // Simplified formula: Caster ≈ (Camber diff) × 1.5 for 20° turns
    final camberDiff = camberIn - camberOut;
    final sinTurn = 0.342; // sin(20°), common turn-plate setting
    final caster = camberDiff / (2 * sinTurn);

    setState(() {
      _casterAngle = caster;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _camberTurnedInController.clear();
    _camberTurnedOutController.clear();
    _turnAngleController.text = '20';
    setState(() { _casterAngle = null; });
  }

  @override
  void dispose() {
    _camberTurnedInController.dispose();
    _camberTurnedOutController.dispose();
    _turnAngleController.dispose();
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
        title: Text('Caster', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Camber Turned In', unit: '°', hint: 'Wheel turned toward car', controller: _camberTurnedInController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Camber Turned Out', unit: '°', hint: 'Wheel turned away', controller: _camberTurnedOutController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Turn Angle', unit: '°', hint: 'Usually 20°', controller: _turnAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_casterAngle != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildInfoCard(colors),
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
        Text('Caster = Camber Diff / (2 × sin θ)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Steering axis angle from vertical (side view)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_casterAngle! < 2) {
      analysis = 'Low caster - light steering, less self-centering';
    } else if (_casterAngle! < 5) {
      analysis = 'Street spec - good balance of effort and stability';
    } else if (_casterAngle! < 8) {
      analysis = 'Performance - excellent high-speed stability';
    } else {
      analysis = 'Very high caster - heavy steering, maximum stability';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Caster Angle', '+${_casterAngle!.toStringAsFixed(2)}°', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CASTER EFFECTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('More Caster (+):\n- Better straight-line stability\n- Stronger self-centering\n- Heavier steering effort\n- More camber gain in turns\n\nCross-caster (split):\n- Can compensate for road crown\n- 0.5° more on left is common', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
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
