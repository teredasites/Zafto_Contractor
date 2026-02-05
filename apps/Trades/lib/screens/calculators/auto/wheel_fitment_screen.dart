import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wheel Fitment Calculator - Check if wheels will fit
class WheelFitmentScreen extends ConsumerStatefulWidget {
  const WheelFitmentScreen({super.key});
  @override
  ConsumerState<WheelFitmentScreen> createState() => _WheelFitmentScreenState();
}

class _WheelFitmentScreenState extends ConsumerState<WheelFitmentScreen> {
  final _wheelWidthController = TextEditingController();
  final _offsetController = TextEditingController();
  final _stockWidthController = TextEditingController();
  final _stockOffsetController = TextEditingController();

  double? _innerDiff;
  double? _outerDiff;

  void _calculate() {
    final wheelWidth = double.tryParse(_wheelWidthController.text);
    final offset = double.tryParse(_offsetController.text);
    final stockWidth = double.tryParse(_stockWidthController.text);
    final stockOffset = double.tryParse(_stockOffsetController.text);

    if (wheelWidth == null || offset == null || stockWidth == null || stockOffset == null) {
      setState(() { _innerDiff = null; });
      return;
    }

    // Convert width to mm (input in inches)
    final newWidthMm = wheelWidth * 25.4;
    final stockWidthMm = stockWidth * 25.4;

    // Calculate mounting surface position from centerline
    final newInner = (newWidthMm / 2) - offset;
    final newOuter = (newWidthMm / 2) + offset;
    final stockInner = (stockWidthMm / 2) - stockOffset;
    final stockOuter = (stockWidthMm / 2) + stockOffset;

    setState(() {
      _innerDiff = newInner - stockInner;
      _outerDiff = newOuter - stockOuter;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _wheelWidthController.clear();
    _offsetController.clear();
    _stockWidthController.clear();
    _stockOffsetController.clear();
    setState(() { _innerDiff = null; });
  }

  @override
  void dispose() {
    _wheelWidthController.dispose();
    _offsetController.dispose();
    _stockWidthController.dispose();
    _stockOffsetController.dispose();
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
        title: Text('Wheel Fitment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'NEW WHEELS'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Width', unit: 'in', hint: 'e.g. 9.5', controller: _wheelWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Offset', unit: 'mm', hint: 'e.g. +35', controller: _offsetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, 'STOCK WHEELS'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Stock Width', unit: 'in', hint: 'e.g. 8.0', controller: _stockWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Stock Offset', unit: 'mm', hint: 'e.g. +45', controller: _stockOffsetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_innerDiff != null) _buildResultsCard(colors),
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
        Text('Compare wheel positions vs stock', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Positive = sticks out more, Negative = tucked in', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Inner (Suspension)', '${_innerDiff! >= 0 ? '+' : ''}${_innerDiff!.toStringAsFixed(1)} mm', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Outer (Fender)', '${_outerDiff! >= 0 ? '+' : ''}${_outerDiff!.toStringAsFixed(1)} mm'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_innerDiff! > 10) Text('Warning: May contact suspension/brakes', style: TextStyle(color: colors.warning, fontSize: 12)),
            if (_outerDiff! > 15) Text('Warning: May require fender work', style: TextStyle(color: colors.warning, fontSize: 12)),
            if (_innerDiff! <= 10 && _outerDiff! <= 15) Text('Should fit within typical tolerances', style: TextStyle(color: colors.accentSuccess, fontSize: 12)),
          ]),
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
