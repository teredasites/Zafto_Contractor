import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Center Support Bearing Alignment Calculator
class CenterBearingScreen extends ConsumerStatefulWidget {
  const CenterBearingScreen({super.key});
  @override
  ConsumerState<CenterBearingScreen> createState() => _CenterBearingScreenState();
}

class _CenterBearingScreenState extends ConsumerState<CenterBearingScreen> {
  final _frontShaftAngleController = TextEditingController();
  final _rearShaftAngleController = TextEditingController();
  final _bearingHeightController = TextEditingController();
  final _totalLengthController = TextEditingController();

  double? _angularMisalignment;
  double? _recommendedHeight;
  double? _shimRequired;
  String? _status;

  void _calculate() {
    final frontAngle = double.tryParse(_frontShaftAngleController.text);
    final rearAngle = double.tryParse(_rearShaftAngleController.text);
    final bearingHeight = double.tryParse(_bearingHeightController.text);
    final totalLength = double.tryParse(_totalLengthController.text);

    if (frontAngle == null || rearAngle == null) {
      setState(() { _angularMisalignment = null; });
      return;
    }

    // Calculate angular misalignment between front and rear shafts
    final misalignment = (frontAngle - rearAngle).abs();

    // Ideal: center bearing aligns shaft segments to minimize angle
    // Target angle: average of front and rear
    final targetAngle = (frontAngle + rearAngle) / 2;

    double? recommendedHt;
    double? shimNeeded;

    if (bearingHeight != null && totalLength != null && totalLength > 0) {
      // Calculate height adjustment needed
      // Height change = length * tan(angle_correction)
      final angleCorrection = (frontAngle - targetAngle) * math.pi / 180;
      final heightChange = (totalLength / 2) * math.tan(angleCorrection);
      recommendedHt = bearingHeight - heightChange;
      shimNeeded = (recommendedHt - bearingHeight).abs();
    }

    String statusMsg;
    if (misalignment <= 0.5) {
      statusMsg = 'Excellent alignment - No adjustment needed';
    } else if (misalignment <= 1.5) {
      statusMsg = 'Good - Within acceptable tolerance';
    } else if (misalignment <= 3.0) {
      statusMsg = 'Adjustment recommended - Minor vibration possible';
    } else {
      statusMsg = 'Poor alignment - Bearing wear/vibration likely';
    }

    setState(() {
      _angularMisalignment = misalignment;
      _recommendedHeight = recommendedHt;
      _shimRequired = shimNeeded;
      _status = statusMsg;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _frontShaftAngleController.clear();
    _rearShaftAngleController.clear();
    _bearingHeightController.clear();
    _totalLengthController.clear();
    setState(() { _angularMisalignment = null; });
  }

  @override
  void dispose() {
    _frontShaftAngleController.dispose();
    _rearShaftAngleController.dispose();
    _bearingHeightController.dispose();
    _totalLengthController.dispose();
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
        title: Text('Center Bearing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Front Shaft Angle', unit: 'deg', hint: 'Trans to center bearing', controller: _frontShaftAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Rear Shaft Angle', unit: 'deg', hint: 'Center bearing to diff', controller: _rearShaftAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 24),
            Text('ADJUSTMENT CALCULATION (optional)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Bearing Height', unit: 'in', hint: 'From frame rail', controller: _bearingHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Total Shaft Length', unit: 'in', hint: 'Trans to diff', controller: _totalLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_angularMisalignment != null) _buildResultsCard(colors),
            const SizedBox(height: 20),
            _buildTipsCard(colors),
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
        Text('Target: Equal angles front & rear', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Center bearing height affects both shaft angles', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _angularMisalignment! <= 1.5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Angular Misalignment', '${_angularMisalignment!.toStringAsFixed(2)}°', isPrimary: true),
        if (_recommendedHeight != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Recommended Height', '${_recommendedHeight!.toStringAsFixed(3)}"'),
        ],
        if (_shimRequired != null && _shimRequired! > 0.01) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Shim Required', '${_shimRequired!.toStringAsFixed(3)}"'),
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

  Widget _buildTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ALIGNMENT TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTipRow(colors, 'Both angles should be within 1° of each other'),
        const SizedBox(height: 8),
        _buildTipRow(colors, 'Max individual angle: 3° continuous operation'),
        const SizedBox(height: 8),
        _buildTipRow(colors, 'Check with vehicle at ride height, not on lift'),
        const SizedBox(height: 8),
        _buildTipRow(colors, 'Worn rubber isolator can cause height change'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Use adjustable carrier bearing drop brackets for lowered vehicles. Stock location often becomes incorrect after suspension mods.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, String tip) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.only(top: 6),
        width: 4, height: 4,
        decoration: BoxDecoration(color: colors.accentPrimary, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(tip, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
