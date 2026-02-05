import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Driveshaft Angle Calculator - Calculate working angle between U-joints
class DriveshaftAngleScreen extends ConsumerStatefulWidget {
  const DriveshaftAngleScreen({super.key});
  @override
  ConsumerState<DriveshaftAngleScreen> createState() => _DriveshaftAngleScreenState();
}

class _DriveshaftAngleScreenState extends ConsumerState<DriveshaftAngleScreen> {
  final _transAngleController = TextEditingController();
  final _pinAngleController = TextEditingController();
  final _driveshaftAngleController = TextEditingController();

  double? _frontWorkingAngle;
  double? _rearWorkingAngle;
  double? _difference;
  String? _status;

  void _calculate() {
    final transAngle = double.tryParse(_transAngleController.text);
    final pinAngle = double.tryParse(_pinAngleController.text);
    final driveshaftAngle = double.tryParse(_driveshaftAngleController.text);

    if (transAngle == null || pinAngle == null || driveshaftAngle == null) {
      setState(() { _frontWorkingAngle = null; });
      return;
    }

    // Front working angle = transmission angle - driveshaft angle
    final frontAngle = (transAngle - driveshaftAngle).abs();
    // Rear working angle = driveshaft angle - pinion angle
    final rearAngle = (driveshaftAngle - pinAngle).abs();
    final diff = (frontAngle - rearAngle).abs();

    String status;
    if (diff <= 0.5) {
      status = 'Excellent - Perfect phasing';
    } else if (diff <= 1.0) {
      status = 'Good - Within spec';
    } else if (diff <= 2.0) {
      status = 'Acceptable - Minor vibration possible';
    } else {
      status = 'Poor - Vibration likely, adjust pinion';
    }

    setState(() {
      _frontWorkingAngle = frontAngle;
      _rearWorkingAngle = rearAngle;
      _difference = diff;
      _status = status;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _transAngleController.clear();
    _pinAngleController.clear();
    _driveshaftAngleController.clear();
    setState(() { _frontWorkingAngle = null; });
  }

  @override
  void dispose() {
    _transAngleController.dispose();
    _pinAngleController.dispose();
    _driveshaftAngleController.dispose();
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
        title: Text('Driveshaft Angle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Transmission Output Angle', unit: 'deg', hint: 'Down from horizontal', controller: _transAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Driveshaft Angle', unit: 'deg', hint: 'Centerline angle', controller: _driveshaftAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pinion Angle', unit: 'deg', hint: 'Up from horizontal', controller: _pinAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_frontWorkingAngle != null) _buildResultsCard(colors),
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
        Text('Working Angle = |Input - Output|', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('U-joint angles should be equal and opposite', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _difference! <= 1.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Front Working Angle', '${_frontWorkingAngle!.toStringAsFixed(1)}°', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Rear Working Angle', '${_rearWorkingAngle!.toStringAsFixed(1)}°', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Angle Difference', '${_difference!.toStringAsFixed(2)}°'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isGood ? colors.accentSuccess.withValues(alpha: 0.1) : colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isGood ? colors.accentSuccess : colors.warning, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_status!, style: TextStyle(color: isGood ? colors.accentSuccess : colors.warning, fontSize: 13, fontWeight: FontWeight.w500))),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Ideal: Working angles within 1° of each other. Max operating angle: 3° continuous, 7° intermittent.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
