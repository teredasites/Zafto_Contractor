import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Steering Column Angle Calculator - Column and U-joint angle calculations
class SteeringColumnAngleScreen extends ConsumerStatefulWidget {
  const SteeringColumnAngleScreen({super.key});
  @override
  ConsumerState<SteeringColumnAngleScreen> createState() => _SteeringColumnAngleScreenState();
}

class _SteeringColumnAngleScreenState extends ConsumerState<SteeringColumnAngleScreen> {
  final _columnAngle1Controller = TextEditingController();
  final _columnAngle2Controller = TextEditingController();
  final _inputSpeedController = TextEditingController(text: '360');

  double? _phaseError;
  double? _speedVariation;
  double? _totalAngle;
  String? _recommendation;

  void _calculate() {
    final angle1 = double.tryParse(_columnAngle1Controller.text);
    final angle2 = double.tryParse(_columnAngle2Controller.text);
    final inputSpeed = double.tryParse(_inputSpeedController.text);

    if (angle1 == null || inputSpeed == null) {
      setState(() { _phaseError = null; });
      return;
    }

    final ang1Rad = angle1 * math.pi / 180;
    final ang2Rad = (angle2 ?? 0) * math.pi / 180;

    // Single U-joint speed variation
    // Output speed varies by: cos(angle) to 1/cos(angle)
    final speedVar1 = (1 / math.cos(ang1Rad) - math.cos(ang1Rad)) * 100;

    // For double cardan (two U-joints), angles should be equal and phased
    // Phase error when angles don't cancel
    double phaseError;
    double totalSpeedVar;

    if (angle2 != null && angle2 > 0) {
      // Two U-joints - calculate net effect
      // If properly phased and equal angles, variation cancels
      final angleDiff = (angle1 - angle2).abs();
      phaseError = angleDiff;
      totalSpeedVar = speedVar1 * (angleDiff / angle1).clamp(0, 1);
    } else {
      phaseError = angle1;
      totalSpeedVar = speedVar1;
    }

    final totalAngle = angle1 + (angle2 ?? 0);

    String recommendation;
    if (totalAngle <= 3) {
      recommendation = 'Excellent - Minimal vibration';
    } else if (totalAngle <= 7) {
      recommendation = 'Good - Normal street use';
    } else if (totalAngle <= 15) {
      recommendation = 'Acceptable with double-cardan';
    } else if (totalAngle <= 25) {
      recommendation = 'Use CV joint recommended';
    } else {
      recommendation = 'Excessive - Redesign needed';
    }

    setState(() {
      _phaseError = phaseError;
      _speedVariation = totalSpeedVar;
      _totalAngle = totalAngle;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _columnAngle1Controller.clear();
    _columnAngle2Controller.clear();
    _inputSpeedController.text = '360';
    setState(() { _phaseError = null; });
  }

  @override
  void dispose() {
    _columnAngle1Controller.dispose();
    _columnAngle2Controller.dispose();
    _inputSpeedController.dispose();
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
        title: Text('Steering Column Angle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Upper U-Joint Angle', unit: 'deg', hint: 'First joint angle', controller: _columnAngle1Controller, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Lower U-Joint Angle', unit: 'deg', hint: 'Second joint (optional)', controller: _columnAngle2Controller, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Input Speed', unit: 'deg/s', hint: 'Steering wheel rotation', controller: _inputSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_phaseError != null) _buildResultsCard(colors),
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
        Text('Speed Var = 1/cos(a) - cos(a)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Double-cardan cancels when angles equal & phased', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Angle', '${_totalAngle!.toStringAsFixed(1)}°', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Phase Error', '${_phaseError!.toStringAsFixed(1)}°'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Speed Variation', '${_speedVariation!.toStringAsFixed(2)}%'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Status', _recommendation!),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.end)),
    ]);
  }
}
