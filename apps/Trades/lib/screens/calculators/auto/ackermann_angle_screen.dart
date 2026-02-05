import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ackermann Angle Calculator - Ackermann steering geometry calculation
class AckermannAngleScreen extends ConsumerStatefulWidget {
  const AckermannAngleScreen({super.key});
  @override
  ConsumerState<AckermannAngleScreen> createState() => _AckermannAngleScreenState();
}

class _AckermannAngleScreenState extends ConsumerState<AckermannAngleScreen> {
  final _wheelbaseController = TextEditingController();
  final _trackWidthController = TextEditingController();
  final _innerAngleController = TextEditingController();

  double? _outerAngle;
  double? _turningRadius;
  double? _ackermannPercent;

  void _calculate() {
    final wheelbase = double.tryParse(_wheelbaseController.text);
    final trackWidth = double.tryParse(_trackWidthController.text);
    final innerAngle = double.tryParse(_innerAngleController.text);

    if (wheelbase == null || trackWidth == null || innerAngle == null ||
        wheelbase <= 0 || trackWidth <= 0 || innerAngle <= 0 || innerAngle >= 90) {
      setState(() { _outerAngle = null; });
      return;
    }

    // Convert inner angle to radians
    final innerRad = innerAngle * math.pi / 180;

    // Ackermann geometry: cot(outer) = cot(inner) + (track / wheelbase)
    // cot = 1/tan
    final cotInner = 1 / math.tan(innerRad);
    final cotOuter = cotInner + (trackWidth / wheelbase);
    final outerRad = math.atan(1 / cotOuter);
    final outerAngle = outerRad * 180 / math.pi;

    // Turning radius (to center of rear axle)
    final turningRadius = wheelbase / math.tan(innerRad);

    // Ackermann percentage (100% = perfect Ackermann, <100% = parallel steer)
    final idealOuter = outerAngle;
    final parallelOuter = innerAngle;
    final ackermannPercent = ((innerAngle - parallelOuter) / (idealOuter - parallelOuter + 0.001)) * 100;

    setState(() {
      _outerAngle = outerAngle;
      _turningRadius = turningRadius;
      _ackermannPercent = ackermannPercent.clamp(0, 150);
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _wheelbaseController.clear();
    _trackWidthController.clear();
    _innerAngleController.clear();
    setState(() { _outerAngle = null; });
  }

  @override
  void dispose() {
    _wheelbaseController.dispose();
    _trackWidthController.dispose();
    _innerAngleController.dispose();
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
        title: Text('Ackermann Geometry', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Wheelbase', unit: 'in', hint: 'Front to rear axle distance', controller: _wheelbaseController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Track Width', unit: 'in', hint: 'Distance between wheel centers', controller: _trackWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Inner Wheel Angle', unit: 'deg', hint: 'Inside wheel steer angle', controller: _innerAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_outerAngle != null) _buildResultsCard(colors),
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
        Text('cot(outer) = cot(inner) + T/W', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Ensures all wheels follow concentric arcs in turns', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Outer Wheel Angle', '${_outerAngle!.toStringAsFixed(2)}°', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Turning Radius', '${_turningRadius!.toStringAsFixed(1)} in'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Turning Radius', '${(_turningRadius! / 12).toStringAsFixed(1)} ft'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Angle Difference', '${(double.tryParse(_innerAngleController.text)! - _outerAngle!).toStringAsFixed(2)}°'),
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
