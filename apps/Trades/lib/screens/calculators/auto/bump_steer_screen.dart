import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bump Steer Calculator - Measure and diagnose bump steer
class BumpSteerScreen extends ConsumerStatefulWidget {
  const BumpSteerScreen({super.key});
  @override
  ConsumerState<BumpSteerScreen> createState() => _BumpSteerScreenState();
}

class _BumpSteerScreenState extends ConsumerState<BumpSteerScreen> {
  final _toeAtRideController = TextEditingController(text: '0');
  final _toeAtBumpController = TextEditingController();
  final _toeAtDroopController = TextEditingController();
  final _wheelTravelController = TextEditingController(text: '2');

  double? _bumpSteerBump;
  double? _bumpSteerDroop;

  void _calculate() {
    final toeAtRide = double.tryParse(_toeAtRideController.text) ?? 0;
    final toeAtBump = double.tryParse(_toeAtBumpController.text);
    final toeAtDroop = double.tryParse(_toeAtDroopController.text);
    final wheelTravel = double.tryParse(_wheelTravelController.text) ?? 2;

    if (toeAtBump == null && toeAtDroop == null) {
      setState(() { _bumpSteerBump = null; });
      return;
    }

    setState(() {
      _bumpSteerBump = toeAtBump != null ? (toeAtBump - toeAtRide) / wheelTravel : null;
      _bumpSteerDroop = toeAtDroop != null ? (toeAtDroop - toeAtRide) / wheelTravel : null;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _toeAtRideController.text = '0';
    _toeAtBumpController.clear();
    _toeAtDroopController.clear();
    _wheelTravelController.text = '2';
    setState(() { _bumpSteerBump = null; });
  }

  @override
  void dispose() {
    _toeAtRideController.dispose();
    _toeAtBumpController.dispose();
    _toeAtDroopController.dispose();
    _wheelTravelController.dispose();
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
        title: Text('Bump Steer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Toe at Ride Height', unit: 'in', hint: 'Baseline measurement', controller: _toeAtRideController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Toe at Full Bump', unit: 'in', hint: 'Suspension compressed', controller: _toeAtBumpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Toe at Full Droop', unit: 'in', hint: 'Suspension extended', controller: _toeAtDroopController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Travel', unit: 'in', hint: 'From ride to bump/droop', controller: _wheelTravelController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bumpSteerBump != null || _bumpSteerDroop != null) _buildResultsCard(colors),
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
        Text('Bump Steer = Toe Change / Travel', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Toe change per inch of suspension travel', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        if (_bumpSteerBump != null)
          _buildResultRow(colors, 'In Bump', '${_bumpSteerBump! >= 0 ? '+' : ''}${_bumpSteerBump!.toStringAsFixed(3)}"/in', isPrimary: true),
        if (_bumpSteerBump != null && _bumpSteerDroop != null)
          const SizedBox(height: 12),
        if (_bumpSteerDroop != null)
          _buildResultRow(colors, 'In Droop', '${_bumpSteerDroop! >= 0 ? '+' : ''}${_bumpSteerDroop!.toStringAsFixed(3)}"/in'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Target: Less than 0.030"/inch. Zero bump steer means tie rod moves in same arc as control arm.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CORRECTING BUMP STEER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('- Raise/lower tie rod end with spacers\n- Adjustable tie rod ends (Heim joints)\n- Bump steer spacer kits\n- Relocate steering rack height\n- Check for bent steering components', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
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
