import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Depreciation Calculator - Calculate vehicle depreciation
class DepreciationScreen extends ConsumerStatefulWidget {
  const DepreciationScreen({super.key});
  @override
  ConsumerState<DepreciationScreen> createState() => _DepreciationScreenState();
}

class _DepreciationScreenState extends ConsumerState<DepreciationScreen> {
  final _purchasePriceController = TextEditingController();
  final _yearsController = TextEditingController();
  final _currentMileageController = TextEditingController();

  double? _currentValue;
  double? _depreciation;
  double? _depreciationPercent;
  List<Map<String, double>>? _schedule;

  void _calculate() {
    final purchasePrice = double.tryParse(_purchasePriceController.text);
    final years = double.tryParse(_yearsController.text);

    if (purchasePrice == null) {
      setState(() { _currentValue = null; });
      return;
    }

    final yearsOwned = years ?? 0;

    // Standard depreciation curve
    // Year 1: 20%, Year 2: 15%, Year 3-5: 10%, Year 6+: 5%
    double value = purchasePrice;
    List<Map<String, double>> schedule = [];

    for (int i = 1; i <= math.max(yearsOwned.ceil(), 10); i++) {
      double depRate;
      if (i == 1) depRate = 0.20;
      else if (i == 2) depRate = 0.15;
      else if (i <= 5) depRate = 0.10;
      else depRate = 0.05;

      value = value * (1 - depRate);
      schedule.add({'year': i.toDouble(), 'value': value, 'depRate': depRate * 100});
    }

    // Get current value based on years owned
    double currentValue = purchasePrice;
    for (int i = 1; i <= yearsOwned.floor(); i++) {
      double depRate;
      if (i == 1) depRate = 0.20;
      else if (i == 2) depRate = 0.15;
      else if (i <= 5) depRate = 0.10;
      else depRate = 0.05;
      currentValue = currentValue * (1 - depRate);
    }

    // Partial year
    final partialYear = yearsOwned - yearsOwned.floor();
    if (partialYear > 0) {
      double depRate;
      final nextYear = yearsOwned.floor() + 1;
      if (nextYear == 1) depRate = 0.20;
      else if (nextYear == 2) depRate = 0.15;
      else if (nextYear <= 5) depRate = 0.10;
      else depRate = 0.05;
      currentValue = currentValue * (1 - depRate * partialYear);
    }

    setState(() {
      _currentValue = currentValue;
      _depreciation = purchasePrice - currentValue;
      _depreciationPercent = (1 - currentValue / purchasePrice) * 100;
      _schedule = schedule;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _purchasePriceController.clear();
    _yearsController.clear();
    _currentMileageController.clear();
    setState(() { _currentValue = null; });
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _yearsController.dispose();
    _currentMileageController.dispose();
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
        title: Text('Depreciation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Purchase Price', unit: '\$', hint: 'Original cost', controller: _purchasePriceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Years Owned', unit: 'yrs', hint: 'e.g., 3.5', controller: _yearsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_currentValue != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            if (_schedule != null) _buildDepreciationSchedule(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Icon(LucideIcons.trendingDown, color: colors.error, size: 32),
        const SizedBox(height: 8),
        Text('Vehicle Depreciation Calculator', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Estimate current vehicle value based on typical depreciation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('ESTIMATED VALUE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('\$${_currentValue!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox(colors, 'Depreciation', '\$${_depreciation!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(colors, 'Loss', '${_depreciationPercent!.toStringAsFixed(0)}%')),
        ]),
      ]),
    );
  }

  Widget _buildStatBox(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.error, fontSize: 18, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildDepreciationSchedule(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DEPRECIATION SCHEDULE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(flex: 1, child: Text('Year', style: TextStyle(color: colors.textTertiary, fontSize: 11))),
          Expanded(flex: 2, child: Text('Value', style: TextStyle(color: colors.textTertiary, fontSize: 11))),
          Expanded(flex: 1, child: Text('Rate', style: TextStyle(color: colors.textTertiary, fontSize: 11), textAlign: TextAlign.right)),
        ]),
        const SizedBox(height: 8),
        ..._schedule!.take(7).map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(flex: 1, child: Text('${row['year']!.toInt()}', style: TextStyle(color: colors.textPrimary, fontSize: 13))),
            Expanded(flex: 2, child: Text('\$${row['value']!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
            Expanded(flex: 1, child: Text('-${row['depRate']!.toInt()}%', style: TextStyle(color: colors.error, fontSize: 13), textAlign: TextAlign.right)),
          ]),
        )),
      ]),
    );
  }
}
