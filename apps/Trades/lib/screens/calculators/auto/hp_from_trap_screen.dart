import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// HP From Trap Speed Calculator - Estimate HP from quarter mile trap speed
class HpFromTrapScreen extends ConsumerStatefulWidget {
  const HpFromTrapScreen({super.key});
  @override
  ConsumerState<HpFromTrapScreen> createState() => _HpFromTrapScreenState();
}

class _HpFromTrapScreenState extends ConsumerState<HpFromTrapScreen> {
  final _trapSpeedController = TextEditingController();
  final _weightController = TextEditingController();

  double? _estimatedHp;
  double? _powerToWeight;

  void _calculate() {
    final trapSpeed = double.tryParse(_trapSpeedController.text);
    final weight = double.tryParse(_weightController.text);

    if (trapSpeed == null || weight == null || weight <= 0) {
      setState(() { _estimatedHp = null; });
      return;
    }

    // Using the trap speed formula: HP = (Weight / 234) * (Speed / 5.825)^3
    // Rearranged from ET/Speed formula
    final hp = weight * math.pow(trapSpeed / 234, 3);

    setState(() {
      _estimatedHp = hp;
      _powerToWeight = weight / hp;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _trapSpeedController.clear();
    _weightController.clear();
    setState(() { _estimatedHp = null; });
  }

  @override
  void dispose() {
    _trapSpeedController.dispose();
    _weightController.dispose();
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
        title: Text('HP from Trap Speed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Trap Speed', unit: 'mph', hint: 'Quarter mile', controller: _trapSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'With driver', controller: _weightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_estimatedHp != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildSpeedReference(colors),
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
        Text('HP = Weight × (Speed / 234)³', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Estimate wheel horsepower from trap speed', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('ESTIMATED POWER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_estimatedHp!.toStringAsFixed(0)} WHP', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Wheel Horsepower', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox(colors, 'Power/Weight', '${_powerToWeight!.toStringAsFixed(1)} lbs/hp')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(colors, 'Crank HP Est.', '${(_estimatedHp! * 1.15).toStringAsFixed(0)} HP')),
        ]),
        const SizedBox(height: 12),
        Text('Crank HP estimated with 15% drivetrain loss', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildStatBox(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildSpeedReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRAP SPEED REFERENCE (3,400 lb)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRefRow(colors, '95 mph', '~200 HP'),
        _buildRefRow(colors, '105 mph', '~280 HP'),
        _buildRefRow(colors, '115 mph', '~370 HP'),
        _buildRefRow(colors, '125 mph', '~480 HP'),
        _buildRefRow(colors, '135 mph', '~600 HP'),
        _buildRefRow(colors, '150 mph', '~830 HP'),
        const SizedBox(height: 8),
        Text('Actual results vary with traction, altitude, and conditions', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildRefRow(ZaftoColors colors, String speed, String hp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(speed, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(hp, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
