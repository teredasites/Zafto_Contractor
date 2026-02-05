import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Regen Braking Calculator - Calculate regenerative braking energy recovery
class RegenBrakingScreen extends ConsumerStatefulWidget {
  const RegenBrakingScreen({super.key});
  @override
  ConsumerState<RegenBrakingScreen> createState() => _RegenBrakingScreenState();
}

class _RegenBrakingScreenState extends ConsumerState<RegenBrakingScreen> {
  final _weightController = TextEditingController();
  final _startSpeedController = TextEditingController();
  final _endSpeedController = TextEditingController();
  final _efficiencyController = TextEditingController();

  double? _kineticEnergy;
  double? _recoveredEnergy;
  double? _rangeRecovered;

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    final startSpeed = double.tryParse(_startSpeedController.text);
    final endSpeed = double.tryParse(_endSpeedController.text) ?? 0;
    final efficiency = double.tryParse(_efficiencyController.text) ?? 70;

    if (weight == null || startSpeed == null) {
      setState(() { _kineticEnergy = null; });
      return;
    }

    // Convert lbs to kg, mph to m/s
    final massKg = weight * 0.453592;
    final v1 = startSpeed * 0.44704;
    final v2 = endSpeed * 0.44704;

    // Kinetic energy change: KE = 0.5 * m * (v1² - v2²) in Joules
    final keJoules = 0.5 * massKg * (v1 * v1 - v2 * v2);

    // Convert to kWh (1 kWh = 3,600,000 J)
    final keKwh = keJoules / 3600000;

    // Apply regen efficiency
    final recoveredKwh = keKwh * (efficiency / 100);

    // Estimate range recovered (assuming 3.5 mi/kWh average efficiency)
    final rangeRecovered = recoveredKwh * 3.5;

    setState(() {
      _kineticEnergy = keKwh;
      _recoveredEnergy = recoveredKwh;
      _rangeRecovered = rangeRecovered;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weightController.clear();
    _startSpeedController.clear();
    _endSpeedController.clear();
    _efficiencyController.clear();
    setState(() { _kineticEnergy = null; });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _startSpeedController.dispose();
    _endSpeedController.dispose();
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
        title: Text('Regen Braking', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'Including passengers', controller: _weightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Start Speed', unit: 'mph', hint: 'Before braking', controller: _startSpeedController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'End Speed', unit: 'mph', hint: '0 for full stop', controller: _endSpeedController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Regen Efficiency', unit: '%', hint: 'Default 70%', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_kineticEnergy != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildRegenInfo(colors),
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
        Text('KE = ½mv² (Kinetic Energy)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate energy recovered during regenerative braking', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('ENERGY RECOVERY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox(colors, 'Kinetic Energy', '${(_kineticEnergy! * 1000).toStringAsFixed(0)} Wh')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(colors, 'Recovered', '${(_recoveredEnergy! * 1000).toStringAsFixed(0)} Wh')),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('Range Recovered', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            Text('~${(_rangeRecovered! * 5280).toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentSuccess, fontSize: 24, fontWeight: FontWeight.w700)),
            Text('(${_rangeRecovered!.toStringAsFixed(2)} miles)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
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

  Widget _buildRegenInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REGEN EFFICIENCY FACTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Motor/generator efficiency: 85-95%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Battery charging efficiency: 90-95%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Power electronics: 95-98%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Combined typical: 60-80%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Text('Higher speeds = more energy to recover\nCity driving benefits most from regen', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
