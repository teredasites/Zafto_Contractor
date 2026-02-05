import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// IRR Calculator - Internal rate of return
class IrrCalculatorScreen extends ConsumerStatefulWidget {
  const IrrCalculatorScreen({super.key});
  @override
  ConsumerState<IrrCalculatorScreen> createState() => _IrrCalculatorScreenState();
}

class _IrrCalculatorScreenState extends ConsumerState<IrrCalculatorScreen> {
  final _initialCostController = TextEditingController(text: '17500');
  final _annualSavingsController = TextEditingController(text: '2400');
  final _yearsController = TextEditingController(text: '25');
  final _degradationController = TextEditingController(text: '0.5');
  final _escalationController = TextEditingController(text: '3');

  double? _irr;
  double? _totalReturn;
  String? _recommendation;

  @override
  void dispose() {
    _initialCostController.dispose();
    _annualSavingsController.dispose();
    _yearsController.dispose();
    _degradationController.dispose();
    _escalationController.dispose();
    super.dispose();
  }

  // Newton-Raphson method to find IRR
  double _calculateIRR(double initialCost, List<double> cashFlows) {
    double rate = 0.1; // Initial guess 10%
    const int maxIterations = 100;
    const double tolerance = 0.0001;

    for (int i = 0; i < maxIterations; i++) {
      double npv = -initialCost;
      double dnpv = 0;

      for (int t = 0; t < cashFlows.length; t++) {
        final discountFactor = math.pow(1 + rate, t + 1);
        npv += cashFlows[t] / discountFactor;
        dnpv -= (t + 1) * cashFlows[t] / math.pow(1 + rate, t + 2);
      }

      if (dnpv.abs() < 1e-10) break;

      final newRate = rate - npv / dnpv;
      if ((newRate - rate).abs() < tolerance) {
        return newRate;
      }
      rate = newRate;

      // Bound the rate to reasonable values
      if (rate < -0.99) rate = -0.99;
      if (rate > 1.0) rate = 1.0;
    }

    return rate;
  }

  void _calculate() {
    final initialCost = double.tryParse(_initialCostController.text);
    final annualSavings = double.tryParse(_annualSavingsController.text);
    final years = int.tryParse(_yearsController.text);
    final degradation = double.tryParse(_degradationController.text);
    final escalation = double.tryParse(_escalationController.text);

    if (initialCost == null || annualSavings == null || years == null ||
        degradation == null || escalation == null) {
      setState(() {
        _irr = null;
        _totalReturn = null;
        _recommendation = null;
      });
      return;
    }

    // Build cash flow array
    List<double> cashFlows = [];
    double currentSavings = annualSavings;
    double totalReturn = 0;
    final d = degradation / 100;
    final e = escalation / 100;

    for (int t = 0; t < years; t++) {
      // Savings increase with utility escalation, decrease with panel degradation
      final yearSavings = currentSavings * math.pow(1 + e, t) * math.pow(1 - d, t);
      cashFlows.add(yearSavings);
      totalReturn += yearSavings;
    }

    // Calculate IRR
    final irr = _calculateIRR(initialCost, cashFlows) * 100;

    String recommendation;
    if (irr > 15) {
      recommendation = 'Excellent return - significantly beats most investments.';
    } else if (irr > 10) {
      recommendation = 'Very good return - outperforms typical stock market.';
    } else if (irr > 5) {
      recommendation = 'Good return - beats savings and most bonds.';
    } else if (irr > 0) {
      recommendation = 'Positive return - still profitable investment.';
    } else {
      recommendation = 'Negative return - review system cost or production.';
    }

    setState(() {
      _irr = irr;
      _totalReturn = totalReturn;
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
    _initialCostController.text = '17500';
    _annualSavingsController.text = '2400';
    _yearsController.text = '25';
    _degradationController.text = '0.5';
    _escalationController.text = '3';
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
        title: Text('IRR Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INVESTMENT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Net Cost',
                      unit: '\$',
                      hint: 'After incentives',
                      controller: _initialCostController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Year 1 Savings',
                      unit: '\$/yr',
                      hint: 'First year',
                      controller: _annualSavingsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'GROWTH FACTORS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Utility Escalation',
                      unit: '%/yr',
                      hint: 'Rate increase',
                      controller: _escalationController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Degradation',
                      unit: '%/yr',
                      hint: '0.5% typical',
                      controller: _degradationController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Analysis Period',
                unit: 'years',
                hint: 'System life',
                controller: _yearsController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_irr != null) ...[
                _buildSectionHeader(colors, 'INTERNAL RATE OF RETURN'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
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
              Icon(LucideIcons.percent, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Internal Rate of Return',
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
            'Annual return rate that makes NPV equal zero',
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

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _irr! > 5;
    final statusColor = _irr! > 10 ? colors.accentSuccess : (_irr! > 5 ? colors.accentInfo : colors.accentWarning);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Internal Rate of Return', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _irr!.toStringAsFixed(1),
                style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '%',
                  style: TextStyle(color: colors.textSecondary, fontSize: 24),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _irr! > 10 ? 'Excellent' : (_irr! > 5 ? 'Good' : 'Fair'),
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Initial Investment', '\$${double.parse(_initialCostController.text).toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Total Lifetime Return', '\$${_totalReturn!.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Return Multiple', '${(_totalReturn! / double.parse(_initialCostController.text)).toStringAsFixed(1)}x'),
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

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
