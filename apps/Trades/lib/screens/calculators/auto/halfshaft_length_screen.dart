import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Half Shaft Length Calculator - Calculate required halfshaft length
class HalfshaftLengthScreen extends ConsumerStatefulWidget {
  const HalfshaftLengthScreen({super.key});
  @override
  ConsumerState<HalfshaftLengthScreen> createState() => _HalfshaftLengthScreenState();
}

class _HalfshaftLengthScreenState extends ConsumerState<HalfshaftLengthScreen> {
  final _innerJointController = TextEditingController();
  final _outerJointController = TextEditingController();
  final _compressionController = TextEditingController();
  final _extensionController = TextEditingController();

  double? _installedLength;
  double? _minLength;
  double? _maxLength;
  double? _travelRange;
  String? _status;

  void _calculate() {
    final innerJoint = double.tryParse(_innerJointController.text);
    final outerJoint = double.tryParse(_outerJointController.text);
    final compression = double.tryParse(_compressionController.text) ?? 0;
    final extension = double.tryParse(_extensionController.text) ?? 0;

    if (innerJoint == null || outerJoint == null) {
      setState(() { _installedLength = null; });
      return;
    }

    // Installed length is center-to-center of CV joints
    final installed = innerJoint + outerJoint;

    // Min length = installed - compression travel
    final minLen = installed - compression;

    // Max length = installed + extension travel (droop)
    final maxLen = installed + extension;

    // Total travel range
    final travel = compression + extension;

    String statusMsg;
    // Typical plunge joint travel is 1-2" (25-50mm)
    // Check if travel requirements are reasonable
    if (travel <= 1.5) {
      statusMsg = 'Standard travel - Most axles will work';
    } else if (travel <= 2.5) {
      statusMsg = 'Moderate travel - Verify plunge capacity';
    } else if (travel <= 3.5) {
      statusMsg = 'High travel - Extended-plunge axle needed';
    } else {
      statusMsg = 'Extreme travel - Custom axle may be required';
    }

    setState(() {
      _installedLength = installed;
      _minLength = minLen;
      _maxLength = maxLen;
      _travelRange = travel;
      _status = statusMsg;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _innerJointController.clear();
    _outerJointController.clear();
    _compressionController.clear();
    _extensionController.clear();
    setState(() { _installedLength = null; });
  }

  @override
  void dispose() {
    _innerJointController.dispose();
    _outerJointController.dispose();
    _compressionController.dispose();
    _extensionController.dispose();
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
        title: Text('Halfshaft Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('JOINT POSITIONS (at ride height)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Inner Joint to Center', unit: 'in', hint: 'Trans/diff to inner CV', controller: _innerJointController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Outer Joint to Center', unit: 'in', hint: 'Wheel hub to outer CV', controller: _outerJointController, onChanged: (_) => _calculate()),
            const SizedBox(height: 24),
            Text('SUSPENSION TRAVEL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Compression Travel', unit: 'in', hint: 'Bump - shortens axle', controller: _compressionController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Extension Travel', unit: 'in', hint: 'Droop - lengthens axle', controller: _extensionController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_installedLength != null) _buildResultsCard(colors),
            const SizedBox(height: 20),
            _buildMeasurementGuide(colors),
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
        Text('Length = Inner + Outer (C-to-C)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Plus plunge travel for suspension movement', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final highTravel = _travelRange! > 2.5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Installed Length', '${_installedLength!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min Length (bump)', '${_minLength!.toStringAsFixed(2)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Max Length (droop)', '${_maxLength!.toStringAsFixed(2)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Travel Range', '${_travelRange!.toStringAsFixed(2)}"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: highTravel ? colors.warning.withValues(alpha: 0.1) : colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(highTravel ? LucideIcons.alertTriangle : LucideIcons.info, color: highTravel ? colors.warning : colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_status!, style: TextStyle(color: highTravel ? colors.warning : colors.accentInfo, fontSize: 13, fontWeight: FontWeight.w500))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMeasurementGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEASUREMENT GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildGuideRow(colors, '1', 'Measure at ride height, wheels on ground'),
        const SizedBox(height: 8),
        _buildGuideRow(colors, '2', 'Inner: Trans output flange to inner CV center'),
        const SizedBox(height: 8),
        _buildGuideRow(colors, '3', 'Outer: Hub spline end to outer CV center'),
        const SizedBox(height: 8),
        _buildGuideRow(colors, '4', 'Cycle suspension to find actual travel'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Plunge Joint Types:', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tripod: 1.0-1.5" plunge typical\nCross-groove: 1.5-2.0" plunge typical\nDouble-offset: 2.0-2.5" plunge typical', style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildGuideRow(ZaftoColors colors, String num, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
        child: Center(child: Text(num, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
