import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// NPV Calculator - Net present value
class NpvCalculatorScreen extends ConsumerStatefulWidget {
  const NpvCalculatorScreen({super.key});
  @override
  ConsumerState<NpvCalculatorScreen> createState() => _NpvCalculatorScreenState();
}

class _NpvCalculatorScreenState extends ConsumerState<NpvCalculatorScreen> {
  final _initialCostController = TextEditingController(text: '17500');
  final _annualSavingsController = TextEditingController(text: '2400');
  final _discountRateController = TextEditingController(text: '5');
  final _yearsController = TextEditingController(text: '25');
  final _degradationController = TextEditingController(text: '0.5');

  double? _npv;
  double? _pvOfSavings;
  String? _recommendation;

  @override
  void dispose() {
    _initialCostController.dispose();
    _annualSavingsController.dispose();
    _discountRateController.dispose();
    _yearsController.dispose();
    _degradationController.dispose();
    super.dispose();
  }

  void _calculate() {
    final initialCost = double.tryParse(_initialCostController.text);
    final annualSavings = double.tryParse(_annualSavingsController.text);
    final discountRate = double.tryParse(_discountRateController.text);
    final years = int.tryParse(_yearsController.text);
    final degradation = double.tryParse(_degradationController.text);

    if (initialCost == null || annualSavings == null || discountRate == null ||
        years == null || degradation == null) {
      setState(() {
        _npv = null;
        _pvOfSavings = null;
        _recommendation = null;
      });
      return;
    }

    // Calculate NPV = -Initial + Sum(Savings / (1 + r)^t)
    double pvOfSavings = 0;
    double currentSavings = annualSavings;
    final r = discountRate / 100;
    final d = degradation / 100;

    for (int t = 1; t <= years; t++) {
      pvOfSavings += currentSavings / math.pow(1 + r, t);
      currentSavings *= (1 - d); // Apply degradation
    }

    final npv = pvOfSavings - initialCost;

    String recommendation;
    if (npv > initialCost * 0.5) {
      recommendation = 'Excellent investment - strong positive NPV.';
    } else if (npv > 0) {
      recommendation = 'Good investment - positive NPV means value creation.';
    } else if (npv > -initialCost * 0.1) {
      recommendation = 'Marginal - near break-even in present value terms.';
    } else {
      recommendation = 'Negative NPV - review assumptions or pricing.';
    }

    setState(() {
      _npv = npv;
      _pvOfSavings = pvOfSavings;
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
    _discountRateController.text = '5';
    _yearsController.text = '25';
    _degradationController.text = '0.5';
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
        title: Text('NPV Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DISCOUNT FACTORS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Discount Rate',
                      unit: '%',
                      hint: '5% typical',
                      controller: _discountRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Degradation',
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
              if (_npv != null) ...[
                _buildSectionHeader(colors, 'NET PRESENT VALUE'),
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
              Icon(LucideIcons.trendingUp, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Net Present Value',
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
            'Time value of money analysis for solar investment',
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
    final isPositive = _npv! > 0;
    final statusColor = isPositive ? colors.accentSuccess : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Net Present Value', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '\$${_npv!.toStringAsFixed(0)}',
            style: TextStyle(color: statusColor, fontSize: 44, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPositive ? 'Positive NPV' : 'Negative NPV',
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
                _buildResultRow(colors, 'Initial Investment', '-\$${double.parse(_initialCostController.text).toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'PV of Savings', '+\$${_pvOfSavings!.toStringAsFixed(0)}'),
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
