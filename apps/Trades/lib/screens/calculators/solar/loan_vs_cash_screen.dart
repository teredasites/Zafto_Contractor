import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Loan vs Cash Calculator - Financing comparison
class LoanVsCashScreen extends ConsumerStatefulWidget {
  const LoanVsCashScreen({super.key});
  @override
  ConsumerState<LoanVsCashScreen> createState() => _LoanVsCashScreenState();
}

class _LoanVsCashScreenState extends ConsumerState<LoanVsCashScreen> {
  final _systemCostController = TextEditingController(text: '25000');
  final _itcPercentController = TextEditingController(text: '30');
  final _loanRateController = TextEditingController(text: '6');
  final _loanTermController = TextEditingController(text: '15');
  final _annualSavingsController = TextEditingController(text: '2400');

  double? _cashNetCost;
  double? _loanTotalCost;
  double? _monthlyPayment;
  double? _cashSavingsYear1;
  double? _loanSavingsYear1;
  String? _recommendation;

  @override
  void dispose() {
    _systemCostController.dispose();
    _itcPercentController.dispose();
    _loanRateController.dispose();
    _loanTermController.dispose();
    _annualSavingsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemCost = double.tryParse(_systemCostController.text);
    final itcPercent = double.tryParse(_itcPercentController.text);
    final loanRate = double.tryParse(_loanRateController.text);
    final loanTerm = int.tryParse(_loanTermController.text);
    final annualSavings = double.tryParse(_annualSavingsController.text);

    if (systemCost == null || itcPercent == null || loanRate == null ||
        loanTerm == null || annualSavings == null) {
      setState(() {
        _cashNetCost = null;
        _loanTotalCost = null;
        _monthlyPayment = null;
        _cashSavingsYear1 = null;
        _loanSavingsYear1 = null;
        _recommendation = null;
      });
      return;
    }

    // Cash purchase
    final itcCredit = systemCost * (itcPercent / 100);
    final cashNetCost = systemCost - itcCredit;
    final cashSavingsYear1 = annualSavings;

    // Loan calculation
    final r = (loanRate / 100) / 12; // Monthly rate
    final n = loanTerm * 12; // Total payments
    double monthlyPayment;
    if (r > 0) {
      monthlyPayment = systemCost * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
    } else {
      monthlyPayment = systemCost / n;
    }
    final loanTotalCost = (monthlyPayment * n) - itcCredit;
    final loanSavingsYear1 = annualSavings - (monthlyPayment * 12);

    String recommendation;
    final interestPaid = loanTotalCost - cashNetCost;
    if (loanSavingsYear1 > 0) {
      recommendation = 'Loan: Positive cash flow from day 1. Pay \$${interestPaid.toStringAsFixed(0)} in interest over term.';
    } else if (interestPaid < annualSavings * 3) {
      recommendation = 'Loan: Reasonable if preserving capital. Cash saves \$${interestPaid.toStringAsFixed(0)} in interest.';
    } else {
      recommendation = 'Cash: Significant interest savings. Loan adds \$${interestPaid.toStringAsFixed(0)} to total cost.';
    }

    setState(() {
      _cashNetCost = cashNetCost;
      _loanTotalCost = loanTotalCost;
      _monthlyPayment = monthlyPayment;
      _cashSavingsYear1 = cashSavingsYear1;
      _loanSavingsYear1 = loanSavingsYear1;
      _recommendation = recommendation;
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
    _loanRateController.text = '6';
    _loanTermController.text = '15';
    _annualSavingsController.text = '2400';
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
        title: Text('Loan vs Cash', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Annual Savings',
                unit: '\$/yr',
                hint: 'Utility savings',
                controller: _annualSavingsController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAN TERMS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Interest Rate',
                      unit: '%',
                      hint: 'APR',
                      controller: _loanRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Loan Term',
                      unit: 'years',
                      hint: '10-25',
                      controller: _loanTermController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_cashNetCost != null) ...[
                _buildSectionHeader(colors, 'COMPARISON'),
                const SizedBox(height: 12),
                _buildComparisonCard(colors),
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
              Icon(LucideIcons.scale, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Financing Comparison',
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
            'Compare cash purchase vs solar loan',
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

  Widget _buildComparisonCard(ZaftoColors colors) {
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
              Expanded(child: _buildOptionCard(colors, 'CASH', _cashNetCost!, _cashSavingsYear1!, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionCard(colors, 'LOAN', _loanTotalCost!, _loanSavingsYear1!, false)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Loan Payment', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                Text('\$${_monthlyPayment!.toStringAsFixed(0)}/mo',
                    style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(ZaftoColors colors, String title, double totalCost, double year1Savings, bool isCash) {
    final accentColor = isCash ? colors.accentSuccess : colors.accentInfo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '\$${(totalCost / 1000).toStringAsFixed(1)}k',
            style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          Text('total cost', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: year1Savings >= 0 ? colors.accentSuccess.withValues(alpha: 0.2) : colors.accentWarning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Yr 1: ${year1Savings >= 0 ? '+' : ''}\$${year1Savings.toStringAsFixed(0)}',
              style: TextStyle(
                color: year1Savings >= 0 ? colors.accentSuccess : colors.accentWarning,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
