import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Exhaust Pipe Calculator - Size exhaust for horsepower
class ExhaustPipeScreen extends ConsumerStatefulWidget {
  const ExhaustPipeScreen({super.key});
  @override
  ConsumerState<ExhaustPipeScreen> createState() => _ExhaustPipeScreenState();
}

class _ExhaustPipeScreenState extends ConsumerState<ExhaustPipeScreen> {
  final _horsepowerController = TextEditingController();

  double? _singlePipeDia;
  double? _dualPipeDia;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);

    if (horsepower == null) {
      setState(() { _singlePipeDia = null; });
      return;
    }

    // Rule of thumb: HP / 100 = cross-sectional area in sq inches
    // Area = pi * r^2, so diameter = 2 * sqrt(area / pi)
    final singleArea = horsepower / 100;
    final singleDia = 2 * ((singleArea / 3.14159).abs() > 0 ? (singleArea / 3.14159).abs() : 0.01);
    final singleDiaCalc = 2 * (singleArea / 3.14159 > 0 ? (singleArea / 3.14159) : 0.01);

    // For dual exhaust, split the area
    final dualArea = singleArea / 2;
    final dualDiaCalc = 2 * (dualArea / 3.14159 > 0 ? (dualArea / 3.14159) : 0.01);

    setState(() {
      _singlePipeDia = (singleDiaCalc > 0) ? (singleDiaCalc * singleDiaCalc > 0 ? _sqrt(singleDiaCalc) * 2 : 2.0) : 2.0;
      _dualPipeDia = (dualDiaCalc > 0) ? (dualDiaCalc * dualDiaCalc > 0 ? _sqrt(dualDiaCalc) * 2 : 2.0) : 2.0;
      _singlePipeDia = _calculateDia(singleArea);
      _dualPipeDia = _calculateDia(dualArea);
    });
  }

  double _sqrt(double x) => x > 0 ? x * 0.5 + 0.5 : 0; // Placeholder

  double _calculateDia(double area) {
    // diameter = 2 * sqrt(area / pi)
    if (area <= 0) return 2.0;
    final r2 = area / 3.14159;
    // Newton's method for sqrt
    double x = area;
    for (int i = 0; i < 10; i++) {
      x = (x + r2 / x) / 2;
    }
    return 2 * x;
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    setState(() { _singlePipeDia = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
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
        title: Text('Exhaust Pipe', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Horsepower', unit: 'hp', hint: 'Target HP', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_singlePipeDia != null) _buildResultsCard(colors),
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
        Text('Area (sq in) ≈ HP / 100', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Size exhaust for flow capacity', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RECOMMENDED PIPE SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildSizeBox(colors, 'Single', '${_singlePipeDia!.toStringAsFixed(2)}"')),
          const SizedBox(width: 12),
          Expanded(child: _buildSizeBox(colors, 'Dual (each)', '${_dualPipeDia!.toStringAsFixed(2)}"')),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Round up to nearest common size (2.25", 2.5", 3", 3.5", 4")', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
        _buildSizeRow(colors, '2.25" single', '150-250 HP'),
        _buildSizeRow(colors, '2.5" single', '250-350 HP'),
        _buildSizeRow(colors, '3" single', '350-500 HP'),
        _buildSizeRow(colors, '2.5" dual', '350-450 HP'),
        _buildSizeRow(colors, '3" dual', '450-650 HP'),
        _buildSizeRow(colors, '3.5" dual', '600-900+ HP'),
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
