import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// U-Joint Phasing Calculator - Check and correct u-joint phasing
class UJointPhasingScreen extends ConsumerStatefulWidget {
  const UJointPhasingScreen({super.key});
  @override
  ConsumerState<UJointPhasingScreen> createState() => _UJointPhasingScreenState();
}

class _UJointPhasingScreenState extends ConsumerState<UJointPhasingScreen> {
  final _frontAngleController = TextEditingController();
  final _rearAngleController = TextEditingController();
  final _rpmController = TextEditingController();
  String _phasing = 'in_phase';

  double? _speedVariation;
  double? _vibrationFreq;
  String? _status;
  bool? _isCorrect;

  void _calculate() {
    final frontAngle = double.tryParse(_frontAngleController.text);
    final rearAngle = double.tryParse(_rearAngleController.text);
    final rpm = double.tryParse(_rpmController.text);

    if (frontAngle == null || rearAngle == null) {
      setState(() { _speedVariation = null; });
      return;
    }

    // Convert to radians
    final frontRad = frontAngle * math.pi / 180;
    final rearRad = rearAngle * math.pi / 180;

    // Speed variation through a single u-joint = cos(angle) to 1/cos(angle)
    // For in-phase joints with equal angles, variations cancel
    // For out-of-phase or unequal angles, variations compound

    bool correctPhasing;
    double variation;
    String statusMsg;

    final angleDiff = (frontAngle - rearAngle).abs();

    if (_phasing == 'in_phase') {
      // In-phase: yokes parallel, angles should be equal to cancel
      if (angleDiff <= 1.0) {
        // Near-equal angles with in-phase = vibrations cancel
        variation = 0;
        correctPhasing = true;
        statusMsg = 'Correct phasing - Vibrations cancel out';
      } else {
        // Unequal angles cause residual vibration
        variation = angleDiff * 0.5; // Simplified % speed variation
        correctPhasing = false;
        statusMsg = 'Angle mismatch - Speed variation present';
      }
    } else {
      // Out-of-phase (90° offset): vibrations compound
      final maxAngle = math.max(frontAngle, rearAngle);
      variation = (1 / math.cos(maxAngle * math.pi / 180) - 1) * 100;
      correctPhasing = false;
      statusMsg = 'Out of phase - Vibrations compound (rotate shaft 90°)';
    }

    double? vibFreq;
    if (rpm != null) {
      // U-joint vibration occurs at 2x shaft speed
      vibFreq = (rpm / 60) * 2;
    }

    setState(() {
      _speedVariation = variation;
      _vibrationFreq = vibFreq;
      _status = statusMsg;
      _isCorrect = correctPhasing;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _frontAngleController.clear();
    _rearAngleController.clear();
    _rpmController.clear();
    setState(() { _speedVariation = null; _phasing = 'in_phase'; });
  }

  @override
  void dispose() {
    _frontAngleController.dispose();
    _rearAngleController.dispose();
    _rpmController.dispose();
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
        title: Text('U-Joint Phasing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildPhasingSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Front U-Joint Angle', unit: 'deg', hint: 'Working angle', controller: _frontAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Rear U-Joint Angle', unit: 'deg', hint: 'Working angle', controller: _rearAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Driveshaft RPM', unit: 'rpm', hint: 'For vibration frequency', controller: _rpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_speedVariation != null) _buildResultsCard(colors),
            const SizedBox(height: 20),
            _buildPhasingDiagram(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPhasingSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('YOKE ORIENTATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Row(children: [
        _buildOption(colors, 'In Phase', 'in_phase', 'Parallel'),
        const SizedBox(width: 8),
        _buildOption(colors, 'Out of Phase', 'out_phase', '90° offset'),
      ]),
    ]);
  }

  Widget _buildOption(ZaftoColors colors, String label, String value, String desc) {
    final selected = _phasing == value;
    return Expanded(child: GestureDetector(
      onTap: () { setState(() => _phasing = value); _calculate(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(desc, style: TextStyle(color: selected ? Colors.white.withValues(alpha: 0.8) : colors.textTertiary, fontSize: 10)),
        ]),
      ),
    ));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('In-Phase + Equal Angles = Smooth', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Proper phasing cancels u-joint speed variations', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _isCorrect == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Speed Variation', '${_speedVariation!.toStringAsFixed(1)}%', isPrimary: true),
        if (_vibrationFreq != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Vibration Frequency', '${_vibrationFreq!.toStringAsFixed(1)} Hz'),
        ],
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
      ]),
    );
  }

  Widget _buildPhasingDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PHASING REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildDiagramRow(colors, 'In-Phase (Correct)', 'Both yoke ears point same direction', true),
        const SizedBox(height: 8),
        _buildDiagramRow(colors, 'Out-of-Phase', 'Yokes 90° apart - rotate tube', false),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('For smooth operation: angles must be equal AND yokes must be in-phase. Check by sighting down the shaft.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildDiagramRow(ZaftoColors colors, String title, String desc, bool isCorrect) {
    return Row(children: [
      Icon(isCorrect ? LucideIcons.checkCircle : LucideIcons.xCircle, color: isCorrect ? colors.accentSuccess : colors.error, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ])),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
