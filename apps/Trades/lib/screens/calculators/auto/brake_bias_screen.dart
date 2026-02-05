import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Brake Bias Calculator - Front/rear brake force distribution
class BrakeBiasScreen extends ConsumerStatefulWidget {
  const BrakeBiasScreen({super.key});
  @override
  ConsumerState<BrakeBiasScreen> createState() => _BrakeBiasScreenState();
}

class _BrakeBiasScreenState extends ConsumerState<BrakeBiasScreen> {
  final _frontPistonController = TextEditingController();
  final _frontRotorController = TextEditingController();
  final _rearPistonController = TextEditingController();
  final _rearRotorController = TextEditingController();

  double? _frontBias;
  double? _rearBias;

  void _calculate() {
    final frontPiston = double.tryParse(_frontPistonController.text);
    final frontRotor = double.tryParse(_frontRotorController.text);
    final rearPiston = double.tryParse(_rearPistonController.text);
    final rearRotor = double.tryParse(_rearRotorController.text);

    if (frontPiston == null || frontRotor == null || rearPiston == null || rearRotor == null) {
      setState(() { _frontBias = null; });
      return;
    }

    // Effective radius is typically rotor radius minus pad center offset
    final frontArea = math.pi * math.pow(frontPiston / 2, 2);
    final rearArea = math.pi * math.pow(rearPiston / 2, 2);

    // Torque = Area × Pressure × Effective Radius (simplified)
    final frontTorque = frontArea * (frontRotor / 2);
    final rearTorque = rearArea * (rearRotor / 2);
    final totalTorque = frontTorque + rearTorque;

    setState(() {
      _frontBias = (frontTorque / totalTorque) * 100;
      _rearBias = (rearTorque / totalTorque) * 100;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _frontPistonController.clear();
    _frontRotorController.clear();
    _rearPistonController.clear();
    _rearRotorController.clear();
    setState(() { _frontBias = null; });
  }

  @override
  void dispose() {
    _frontPistonController.dispose();
    _frontRotorController.dispose();
    _rearPistonController.dispose();
    _rearRotorController.dispose();
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
        title: Text('Brake Bias', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'FRONT BRAKES'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Piston Dia', unit: 'in', hint: 'Caliper', controller: _frontPistonController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Rotor Dia', unit: 'in', hint: 'Rotor', controller: _frontRotorController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, 'REAR BRAKES'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Piston Dia', unit: 'in', hint: 'Caliper', controller: _rearPistonController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Rotor Dia', unit: 'in', hint: 'Rotor', controller: _rearRotorController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_frontBias != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Bias = (Piston Area × Rotor Radius)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Front/rear braking force distribution', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_frontBias! > 70) {
      analysis = 'Heavy front bias - good for street, may understeer under braking';
    } else if (_frontBias! > 60) {
      analysis = 'Balanced bias - typical for performance use';
    } else {
      analysis = 'More rear bias - requires careful setup to avoid lockup';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(children: [
            Text('FRONT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${_frontBias!.toStringAsFixed(1)}%', style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
          ])),
          Container(width: 1, height: 50, color: colors.borderSubtle),
          Expanded(child: Column(children: [
            Text('REAR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${_rearBias!.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }
}
