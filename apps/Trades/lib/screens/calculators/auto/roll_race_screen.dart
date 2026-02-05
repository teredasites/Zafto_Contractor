import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Roll Race Calculator - Calculate roll race times and acceleration
class RollRaceScreen extends ConsumerStatefulWidget {
  const RollRaceScreen({super.key});
  @override
  ConsumerState<RollRaceScreen> createState() => _RollRaceScreenState();
}

class _RollRaceScreenState extends ConsumerState<RollRaceScreen> {
  final _startSpeedController = TextEditingController();
  final _endSpeedController = TextEditingController();
  final _timeController = TextEditingController();
  final _weightController = TextEditingController();

  double? _acceleration;
  double? _gForce;
  double? _estimatedHp;

  void _calculate() {
    final startSpeed = double.tryParse(_startSpeedController.text);
    final endSpeed = double.tryParse(_endSpeedController.text);
    final time = double.tryParse(_timeController.text);
    final weight = double.tryParse(_weightController.text);

    if (startSpeed == null || endSpeed == null || time == null || time <= 0) {
      setState(() { _acceleration = null; });
      return;
    }

    // Convert mph to ft/s (1 mph = 1.467 ft/s)
    final startFps = startSpeed * 1.467;
    final endFps = endSpeed * 1.467;

    // Acceleration in ft/s²
    final acceleration = (endFps - startFps) / time;

    // G-force (1g = 32.174 ft/s²)
    final gForce = acceleration / 32.174;

    // Estimate HP if weight provided
    // Power = Force × Velocity = mass × acceleration × velocity
    // Average velocity and estimated HP at WOT
    double? hp;
    if (weight != null && weight > 0) {
      final avgVelocity = (startFps + endFps) / 2;
      // P = m × a × v, convert to HP (1 HP = 550 ft-lb/s)
      final mass = weight / 32.174; // weight to mass in slugs
      hp = (mass * acceleration * avgVelocity) / 550;
    }

    setState(() {
      _acceleration = acceleration;
      _gForce = gForce;
      _estimatedHp = hp;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _startSpeedController.clear();
    _endSpeedController.clear();
    _timeController.clear();
    _weightController.clear();
    setState(() { _acceleration = null; });
  }

  @override
  void dispose() {
    _startSpeedController.dispose();
    _endSpeedController.dispose();
    _timeController.dispose();
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
        title: Text('Roll Race', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Start Speed', unit: 'mph', hint: 'e.g., 30', controller: _startSpeedController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'End Speed', unit: 'mph', hint: 'e.g., 130', controller: _endSpeedController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Time', unit: 'sec', hint: 'Measured', controller: _timeController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Weight (opt)', unit: 'lbs', hint: 'For HP est.', controller: _weightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_acceleration != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildCommonRolls(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Roll Race Calculator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Analyze acceleration from a rolling start. Common rolls: 30-130, 40-140, 60-130 mph.', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('PERFORMANCE ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox(colors, 'Acceleration', '${_acceleration!.toStringAsFixed(1)} ft/s²')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(colors, 'G-Force', '${_gForce!.toStringAsFixed(2)} G')),
        ]),
        if (_estimatedHp != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Estimated Average Power', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              Text('${_estimatedHp!.toStringAsFixed(0)} WHP', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        Text('G-force represents sustained acceleration feel', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildStatBox(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildCommonRolls(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON ROLL RACES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRollRow(colors, '30-130 mph', 'Most common, 100 mph pull'),
        _buildRollRow(colors, '40-140 mph', 'Highway performance'),
        _buildRollRow(colors, '60-130 mph', 'In-gear pull test'),
        _buildRollRow(colors, '50-150 mph', 'High power cars'),
        const SizedBox(height: 12),
        Text('Roll races remove launch variables - pure acceleration test', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildRollRow(ZaftoColors colors, String range, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(range, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
