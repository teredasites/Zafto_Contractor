import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Zero to Sixty Calculator - Estimate 0-60 times
class ZeroToSixtyScreen extends ConsumerStatefulWidget {
  const ZeroToSixtyScreen({super.key});
  @override
  ConsumerState<ZeroToSixtyScreen> createState() => _ZeroToSixtyScreenState();
}

class _ZeroToSixtyScreenState extends ConsumerState<ZeroToSixtyScreen> {
  final _horsepowerController = TextEditingController();
  final _weightController = TextEditingController();

  double? _estimatedTime;
  double? _powerToWeight;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);
    final weight = double.tryParse(_weightController.text);

    if (horsepower == null || weight == null || horsepower <= 0) {
      setState(() { _estimatedTime = null; });
      return;
    }

    final powerToWeight = weight / horsepower;

    // Empirical formula for 0-60 time estimation
    // Time ≈ (Weight / HP) ^ 0.5 × factor
    // Various factors account for drivetrain, traction, etc.
    // Using average factor of 0.95 for typical car
    final time = math.pow(powerToWeight, 0.5) * 0.95;

    setState(() {
      _estimatedTime = time;
      _powerToWeight = powerToWeight;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    _weightController.clear();
    setState(() { _estimatedTime = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
    _weightController.dispose();
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
        title: Text('0-60 MPH', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Horsepower', unit: 'hp', hint: 'Wheel HP', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Weight', unit: 'lbs', hint: 'Curb + driver', controller: _weightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_estimatedTime != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildPerformanceChart(colors),
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
        Text('0-60 MPH Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate acceleration time based on power-to-weight ratio', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String category;
    Color categoryColor;

    if (_estimatedTime! < 3.5) {
      category = 'Supercar';
      categoryColor = colors.error;
    } else if (_estimatedTime! < 5.0) {
      category = 'Sports Car';
      categoryColor = colors.warning;
    } else if (_estimatedTime! < 7.0) {
      category = 'Performance';
      categoryColor = colors.accentSuccess;
    } else if (_estimatedTime! < 9.0) {
      category = 'Average';
      categoryColor = colors.accentPrimary;
    } else {
      category = 'Economy';
      categoryColor = colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('ESTIMATED 0-60 TIME', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_estimatedTime!.toStringAsFixed(1)} sec', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(category, style: TextStyle(color: categoryColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Power-to-Weight', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text('${_powerToWeight!.toStringAsFixed(1)} lbs/hp', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 12),
        Text('Actual times depend on traction, gearing, and driver skill', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildPerformanceChart(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PERFORMANCE BENCHMARKS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildBenchRow(colors, 'Hypercar', '< 2.5 sec', colors.error),
        _buildBenchRow(colors, 'Supercar', '2.5-3.5 sec', colors.error),
        _buildBenchRow(colors, 'Sports Car', '3.5-5.0 sec', colors.warning),
        _buildBenchRow(colors, 'Performance', '5.0-7.0 sec', colors.accentSuccess),
        _buildBenchRow(colors, 'Average Car', '7.0-9.0 sec', colors.accentPrimary),
        _buildBenchRow(colors, 'Economy', '9.0+ sec', colors.textSecondary),
        const SizedBox(height: 12),
        Text('AWD and launch control significantly improve times', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildBenchRow(ZaftoColors colors, String category, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(category, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        Text(time, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
