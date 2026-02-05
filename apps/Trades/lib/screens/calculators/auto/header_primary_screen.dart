import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Header Primary Calculator - Size primary tubes for exhaust headers
class HeaderPrimaryScreen extends ConsumerStatefulWidget {
  const HeaderPrimaryScreen({super.key});
  @override
  ConsumerState<HeaderPrimaryScreen> createState() => _HeaderPrimaryScreenState();
}

class _HeaderPrimaryScreenState extends ConsumerState<HeaderPrimaryScreen> {
  final _displacementController = TextEditingController();
  final _cylindersController = TextEditingController();
  final _rpmController = TextEditingController();

  double? _primaryDia;
  double? _primaryLength;

  void _calculate() {
    final displacement = double.tryParse(_displacementController.text);
    final cylinders = double.tryParse(_cylindersController.text);
    final rpm = double.tryParse(_rpmController.text);

    if (displacement == null || cylinders == null || rpm == null || cylinders <= 0) {
      setState(() { _primaryDia = null; });
      return;
    }

    // Single cylinder displacement in cc
    final singleCylCc = (displacement * 16.387) / cylinders;

    // Primary diameter formula (empirical): D = sqrt(singleCylCc / 25)
    // Gives diameter in mm, convert to inches
    final diameterMm = math.sqrt(singleCylCc / 25);
    final diameterIn = diameterMm / 25.4;

    // Primary length formula based on RPM target
    // Length (in) = (850 * 60) / (RPM * 2) - accounts for tuning
    final lengthIn = (850 * 60) / (rpm * 2);

    setState(() {
      _primaryDia = diameterIn;
      _primaryLength = lengthIn;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _displacementController.clear();
    _cylindersController.clear();
    _rpmController.clear();
    setState(() { _primaryDia = null; });
  }

  @override
  void dispose() {
    _displacementController.dispose();
    _cylindersController.dispose();
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
        title: Text('Header Primary', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Displacement', unit: 'ci', hint: 'Cubic inches', controller: _displacementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Cylinders', unit: '', hint: '4, 6, 8', controller: _cylindersController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Peak RPM', unit: 'rpm', hint: 'Power peak', controller: _rpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_primaryDia != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildSizeGuide(colors),
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
        Text('Primary Tube Sizing', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate header primary diameter and length for RPM target', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RECOMMENDED PRIMARY SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildSizeBox(colors, 'Diameter', '${_primaryDia!.toStringAsFixed(3)}"')),
          const SizedBox(width: 12),
          Expanded(child: _buildSizeBox(colors, 'Length', '${_primaryLength!.toStringAsFixed(1)}"')),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Round to nearest standard size: 1.5", 1.625", 1.75", 1.875", 2"', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildSizeBox(ZaftoColors colors, String label, String size) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(size, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildSizeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSizeRow(colors, '1.5"', '200-300 HP per cyl'),
        _buildSizeRow(colors, '1.625"', '300-400 HP per cyl'),
        _buildSizeRow(colors, '1.75"', '400-500 HP per cyl'),
        _buildSizeRow(colors, '1.875"', '500-600 HP per cyl'),
        _buildSizeRow(colors, '2.0"', '600+ HP per cyl'),
        const SizedBox(height: 12),
        Text('Longer primaries = lower RPM torque\nShorter primaries = higher RPM power', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildSizeRow(ZaftoColors colors, String size, String hp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(size, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(hp, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
