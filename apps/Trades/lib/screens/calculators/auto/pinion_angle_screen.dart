import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pinion Angle Calculator - Set correct pinion angle for driveline
class PinionAngleScreen extends ConsumerStatefulWidget {
  const PinionAngleScreen({super.key});
  @override
  ConsumerState<PinionAngleScreen> createState() => _PinionAngleScreenState();
}

class _PinionAngleScreenState extends ConsumerState<PinionAngleScreen> {
  final _transAngleController = TextEditingController();
  final _driveshaftAngleController = TextEditingController();
  final _currentPinionController = TextEditingController();
  String _suspensionType = 'leaf';

  double? _targetPinion;
  double? _adjustment;
  double? _workingAngle;
  String? _status;

  void _calculate() {
    final transAngle = double.tryParse(_transAngleController.text);
    final driveshaftAngle = double.tryParse(_driveshaftAngleController.text);
    final currentPinion = double.tryParse(_currentPinionController.text);

    if (transAngle == null || driveshaftAngle == null) {
      setState(() { _targetPinion = null; });
      return;
    }

    // Front working angle = trans angle - driveshaft angle
    final frontWorking = (transAngle - driveshaftAngle).abs();

    // For smooth operation, rear working angle should equal front
    // Rear working angle = driveshaft angle - pinion angle
    // Therefore: target pinion = driveshaft - front_working
    // But direction matters - pinion typically points UP (positive)

    // If driveshaft angles down from trans, pinion should point up by same amount
    // Target: pinion_angle = driveshaft_angle - working_angle (with signs)

    // Simplified: for most RWD setups
    // Target pinion = driveshaft angle - (trans angle - driveshaft angle)
    // = 2 * driveshaft - trans
    final targetAngle = (2 * driveshaftAngle) - transAngle;

    // Add suspension-specific offset
    double suspOffset;
    switch (_suspensionType) {
      case 'leaf':
        suspOffset = 0.0; // Leaf springs need exact match
        break;
      case 'link':
        suspOffset = -1.0; // 4-link often needs 1° more nose-down
        break;
      case 'coilover':
        suspOffset = -0.5; // Slight offset for coilover setups
        break;
      case 'irs':
        suspOffset = 0.0; // IRS typically needs exact angle
        break;
      default:
        suspOffset = 0.0;
    }

    final adjustedTarget = targetAngle + suspOffset;

    double? adj;
    if (currentPinion != null) {
      adj = adjustedTarget - currentPinion;
    }

    final rearWorking = (driveshaftAngle - adjustedTarget).abs();

    String statusMsg;
    final angleDiff = (frontWorking - rearWorking).abs();
    if (angleDiff <= 0.5) {
      statusMsg = 'Optimal - U-joint angles balanced';
    } else if (angleDiff <= 1.0) {
      statusMsg = 'Good - Within acceptable tolerance';
    } else if (angleDiff <= 2.0) {
      statusMsg = 'Marginal - Some vibration possible';
    } else {
      statusMsg = 'Poor - Adjustment strongly recommended';
    }

    setState(() {
      _targetPinion = adjustedTarget;
      _adjustment = adj;
      _workingAngle = frontWorking;
      _status = statusMsg;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _transAngleController.clear();
    _driveshaftAngleController.clear();
    _currentPinionController.clear();
    setState(() { _targetPinion = null; _suspensionType = 'leaf'; });
  }

  @override
  void dispose() {
    _transAngleController.dispose();
    _driveshaftAngleController.dispose();
    _currentPinionController.dispose();
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
        title: Text('Pinion Angle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSuspensionSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Transmission Angle', unit: 'deg', hint: 'Down from horizontal (+)', controller: _transAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Driveshaft Angle', unit: 'deg', hint: 'Down from horizontal (+)', controller: _driveshaftAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Current Pinion Angle', unit: 'deg', hint: 'Up from horizontal (+) optional', controller: _currentPinionController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_targetPinion != null) _buildResultsCard(colors),
            const SizedBox(height: 20),
            _buildAdjustmentGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSuspensionSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('REAR SUSPENSION TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _buildOption(colors, 'Leaf', 'leaf'),
        _buildOption(colors, '4-Link', 'link'),
        _buildOption(colors, 'Coilover', 'coilover'),
        _buildOption(colors, 'IRS', 'irs'),
      ]),
    ]);
  }

  Widget _buildOption(ZaftoColors colors, String label, String value) {
    final selected = _suspensionType == value;
    return GestureDetector(
      onTap: () { setState(() => _suspensionType = value); _calculate(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Front Angle = Rear Angle', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('U-joint working angles must match to cancel vibration', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _adjustment == null || _adjustment!.abs() <= 1.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Target Pinion Angle', '${_targetPinion!.toStringAsFixed(1)}° up', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Working Angle (each)', '${_workingAngle!.toStringAsFixed(1)}°'),
        if (_adjustment != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Adjustment Needed', '${_adjustment! > 0 ? '+' : ''}${_adjustment!.toStringAsFixed(1)}°'),
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

  Widget _buildAdjustmentGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HOW TO ADJUST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildAdjustmentRow(colors, 'Leaf Spring', 'Pinion angle shims under spring pads'),
        const SizedBox(height: 8),
        _buildAdjustmentRow(colors, '4-Link', 'Adjust upper/lower bar lengths'),
        const SizedBox(height: 8),
        _buildAdjustmentRow(colors, 'Coilover', 'Adjust control arm mounts'),
        const SizedBox(height: 8),
        _buildAdjustmentRow(colors, 'IRS', 'Subframe shims or diff mount adjustment'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Angle Sign Convention:', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Positive (+) = nose up for pinion\nPositive (+) = down from horizontal for trans/shaft\n\nMeasure with digital angle finder at ride height.', style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAdjustmentRow(ZaftoColors colors, String type, String method) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 70,
        child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      Expanded(child: Text(method, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
