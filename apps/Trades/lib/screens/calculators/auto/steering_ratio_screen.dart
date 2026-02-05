import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Steering Ratio Calculator - Steering gear ratio calculation
class SteeringRatioScreen extends ConsumerStatefulWidget {
  const SteeringRatioScreen({super.key});
  @override
  ConsumerState<SteeringRatioScreen> createState() => _SteeringRatioScreenState();
}

class _SteeringRatioScreenState extends ConsumerState<SteeringRatioScreen> {
  final _steeringWheelTurnsController = TextEditingController();
  final _wheelTurnAngleController = TextEditingController();

  double? _steeringRatio;
  double? _lockToLockTurns;
  String? _category;

  void _calculate() {
    final steeringTurns = double.tryParse(_steeringWheelTurnsController.text);
    final wheelAngle = double.tryParse(_wheelTurnAngleController.text);

    if (steeringTurns == null || wheelAngle == null || wheelAngle <= 0) {
      setState(() { _steeringRatio = null; });
      return;
    }

    // Steering Ratio = (Steering wheel degrees) / (Wheel turn angle)
    // Steering wheel turns × 360 = total degrees
    final steeringDegrees = steeringTurns * 360;
    final ratio = steeringDegrees / wheelAngle;

    // Full lock-to-lock (typical wheel angle is 30-45 degrees each side)
    final lockToLock = steeringTurns * 2;

    String category;
    if (ratio < 14) {
      category = 'Quick (Sports/Racing)';
    } else if (ratio <= 18) {
      category = 'Standard (Street)';
    } else {
      category = 'Slow (Trucks/Heavy)';
    }

    setState(() {
      _steeringRatio = ratio;
      _lockToLockTurns = lockToLock;
      _category = category;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _steeringWheelTurnsController.clear();
    _wheelTurnAngleController.clear();
    setState(() { _steeringRatio = null; });
  }

  @override
  void dispose() {
    _steeringWheelTurnsController.dispose();
    _wheelTurnAngleController.dispose();
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
        title: Text('Steering Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Steering Wheel Turns', unit: 'turns', hint: 'Center to full lock', controller: _steeringWheelTurnsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Turn Angle', unit: 'deg', hint: 'Front wheel angle at lock', controller: _wheelTurnAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_steeringRatio != null) _buildResultsCard(colors),
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
        Text('Ratio = (Turns x 360) / Wheel Angle', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('12-14:1 sports, 15-18:1 standard, 20+:1 trucks', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Steering Ratio', '${_steeringRatio!.toStringAsFixed(1)}:1', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Lock-to-Lock', '${_lockToLockTurns!.toStringAsFixed(1)} turns'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Category', _category!),
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
