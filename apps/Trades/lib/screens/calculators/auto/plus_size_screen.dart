import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Plus Size Calculator - Upsize wheels while maintaining diameter
class PlusSizeScreen extends ConsumerStatefulWidget {
  const PlusSizeScreen({super.key});
  @override
  ConsumerState<PlusSizeScreen> createState() => _PlusSizeScreenState();
}

class _PlusSizeScreenState extends ConsumerState<PlusSizeScreen> {
  final _stockWidthController = TextEditingController();
  final _stockAspectController = TextEditingController();
  final _stockWheelController = TextEditingController();
  final _newWheelController = TextEditingController();

  double? _stockDiameter;
  double? _newWidth;
  double? _newAspect;
  double? _newDiameter;

  void _calculate() {
    final stockWidth = double.tryParse(_stockWidthController.text);
    final stockAspect = double.tryParse(_stockAspectController.text);
    final stockWheel = double.tryParse(_stockWheelController.text);
    final newWheel = double.tryParse(_newWheelController.text);

    if (stockWidth == null || stockAspect == null || stockWheel == null || newWheel == null) {
      setState(() { _stockDiameter = null; });
      return;
    }

    // Calculate stock tire overall diameter
    final stockSidewall = stockWidth * (stockAspect / 100) / 25.4; // Convert mm to inches
    final stockDia = (stockSidewall * 2) + stockWheel;

    // Calculate new tire parameters to match diameter
    final wheelDiff = newWheel - stockWheel;
    final newSidewallNeeded = stockSidewall - (wheelDiff / 2);

    // Increase width by ~10mm per inch of wheel size increase (typical)
    final widthIncrease = wheelDiff * 10;
    final newW = stockWidth + widthIncrease;
    final newAsp = (newSidewallNeeded * 25.4 / newW) * 100;
    final newDia = (newSidewallNeeded * 2) + newWheel;

    setState(() {
      _stockDiameter = stockDia;
      _newWidth = newW;
      _newAspect = newAsp;
      _newDiameter = newDia;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _stockWidthController.clear();
    _stockAspectController.clear();
    _stockWheelController.clear();
    _newWheelController.clear();
    setState(() { _stockDiameter = null; });
  }

  @override
  void dispose() {
    _stockWidthController.dispose();
    _stockAspectController.dispose();
    _stockWheelController.dispose();
    _newWheelController.dispose();
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
        title: Text('Plus Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'STOCK TIRE'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Width', unit: 'mm', hint: 'e.g. 225', controller: _stockWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Aspect Ratio', unit: '%', hint: 'e.g. 45', controller: _stockAspectController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Diameter', unit: 'in', hint: 'e.g. 17', controller: _stockWheelController, onChanged: (_) => _calculate()),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, 'NEW WHEEL'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'New Wheel Diameter', unit: 'in', hint: 'e.g. 18', controller: _newWheelController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_stockDiameter != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Plus sizing: +1" wheel = -10mm sidewall', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Maintain overall diameter when upgrading wheels', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final aspectRounded = (_newAspect! / 5).round() * 5;
    final widthRounded = (_newWidth! / 5).round() * 5;
    final newWheel = int.tryParse(_newWheelController.text) ?? 18;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RECOMMENDED SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('$widthRounded/$aspectRounded R$newWheel', style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Stock Diameter', '${_stockDiameter!.toStringAsFixed(1)}"'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'New Diameter', '${_newDiameter!.toStringAsFixed(1)}"'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Exact Width', '${_newWidth!.toStringAsFixed(0)} mm'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Exact Aspect', '${_newAspect!.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Standard sizes are rounded to nearest 5. Verify availability and check fitment.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
