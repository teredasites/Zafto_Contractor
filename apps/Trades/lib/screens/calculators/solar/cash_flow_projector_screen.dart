import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cash Flow Projector - Year-by-year cash flow analysis
class CashFlowProjectorScreen extends ConsumerStatefulWidget {
  const CashFlowProjectorScreen({super.key});
  @override
  ConsumerState<CashFlowProjectorScreen> createState() => _CashFlowProjectorScreenState();
}

class _CashFlowProjectorScreenState extends ConsumerState<CashFlowProjectorScreen> {
  final _systemCostController = TextEditingController(text: '25000');
  final _itcPercentController = TextEditingController(text: '30');
  final _year1SavingsController = TextEditingController(text: '2400');
  final _escalationController = TextEditingController(text: '3');
  final _degradationController = TextEditingController(text: '0.5');
  final _yearsController = TextEditingController(text: '25');

  List<Map<String, double>>? _yearlyData;
  double? _paybackYear;
  double? _totalSavings;

  @override
  void dispose() {
    _systemCostController.dispose();
    _itcPercentController.dispose();
    _year1SavingsController.dispose();
    _escalationController.dispose();
    _degradationController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemCost = double.tryParse(_systemCostController.text);
    final itcPercent = double.tryParse(_itcPercentController.text);
    final year1Savings = double.tryParse(_year1SavingsController.text);
    final escalation = double.tryParse(_escalationController.text);
    final degradation = double.tryParse(_degradationController.text);
    final years = int.tryParse(_yearsController.text);

    if (systemCost == null || itcPercent == null || year1Savings == null ||
        escalation == null || degradation == null || years == null) {
      setState(() {
        _yearlyData = null;
        _paybackYear = null;
        _totalSavings = null;
      });
      return;
    }

    final itcCredit = systemCost * (itcPercent / 100);
    final netCost = systemCost - itcCredit;
    final e = escalation / 100;
    final d = degradation / 100;

    List<Map<String, double>> data = [];
    double cumulativeCashFlow = -netCost;
    double totalSavings = 0;
    double? paybackYear;

    for (int year = 1; year <= years; year++) {
      // Savings with escalation and degradation
      final savings = year1Savings * math.pow(1 + e, year - 1) * math.pow(1 - d, year - 1);
      cumulativeCashFlow += savings;
      totalSavings += savings;

      data.add({
        'year': year.toDouble(),
        'savings': savings,
        'cumulative': cumulativeCashFlow,
      });

      // Find payback year (when cumulative goes positive)
      if (paybackYear == null && cumulativeCashFlow >= 0) {
        // Linear interpolation for more precise payback
        final prevCumulative = cumulativeCashFlow - savings;
        paybackYear = year - 1 + (-prevCumulative / savings);
      }
    }

    setState(() {
      _yearlyData = data;
      _paybackYear = paybackYear;
      _totalSavings = totalSavings;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemCostController.text = '25000';
    _itcPercentController.text = '30';
    _year1SavingsController.text = '2400';
    _escalationController.text = '3';
    _degradationController.text = '0.5';
    _yearsController.text = '25';
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Cash Flow Projector', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'System Cost',
                      unit: '\$',
                      hint: 'Gross price',
                      controller: _systemCostController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Federal ITC',
                      unit: '%',
                      hint: '30% typical',
                      controller: _itcPercentController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SAVINGS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Year 1 Savings',
                      unit: '\$/yr',
                      hint: 'First year',
                      controller: _year1SavingsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Utility Escalation',
                      unit: '%/yr',
                      hint: 'Rate increase',
                      controller: _escalationController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Degradation',
                      unit: '%/yr',
                      hint: '0.5% typical',
                      controller: _degradationController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Analysis Period',
                      unit: 'years',
                      hint: 'System life',
                      controller: _yearsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_yearlyData != null) ...[
                _buildSectionHeader(colors, 'CASH FLOW PROJECTION'),
                const SizedBox(height: 12),
                _buildSummaryCard(colors),
                const SizedBox(height: 16),
                _buildYearlyTable(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.lineChart, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cash Flow Projector',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Year-by-year savings with escalation and degradation',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSummaryCard(ZaftoColors colors) {
    final systemCost = double.parse(_systemCostController.text);
    final itcPercent = double.parse(_itcPercentController.text);
    final netCost = systemCost * (1 - itcPercent / 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Net Cost', '\$${netCost.toStringAsFixed(0)}', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Total Savings', '\$${(_totalSavings! / 1000).toStringAsFixed(0)}k', colors.accentSuccess),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Payback', _paybackYear != null ? '${_paybackYear!.toStringAsFixed(1)} yrs' : 'N/A', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Net Profit', '\$${((_totalSavings! - netCost) / 1000).toStringAsFixed(0)}k', colors.accentInfo),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildYearlyTable(ZaftoColors colors) {
    // Show first 10 years and last year
    final displayYears = <Map<String, double>>[];
    if (_yearlyData!.length <= 12) {
      displayYears.addAll(_yearlyData!);
    } else {
      displayYears.addAll(_yearlyData!.take(10));
      displayYears.add(_yearlyData!.last);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 1, child: Text('Year', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Savings', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Cumulative', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ],
          ),
          const Divider(height: 16),
          ...displayYears.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final isPaybackYear = _paybackYear != null && data['year']! >= _paybackYear! && (index == 0 || displayYears[index - 1]['year']! < _paybackYear!);
            final isLastRow = index == displayYears.length - 1 && _yearlyData!.length > 12;

            return Column(
              children: [
                if (isLastRow) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('...', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isPaybackYear ? colors.accentSuccess.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${data['year']!.toInt()}',
                          style: TextStyle(
                            color: isPaybackYear ? colors.accentSuccess : colors.textPrimary,
                            fontSize: 12,
                            fontWeight: isPaybackYear ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${data['savings']!.toStringAsFixed(0)}',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${data['cumulative']!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: data['cumulative']! >= 0 ? colors.accentSuccess : colors.accentWarning,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
