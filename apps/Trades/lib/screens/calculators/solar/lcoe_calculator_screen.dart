import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// LCOE Calculator - Levelized cost of energy
class LcoeCalculatorScreen extends ConsumerStatefulWidget {
  const LcoeCalculatorScreen({super.key});
  @override
  ConsumerState<LcoeCalculatorScreen> createState() => _LcoeCalculatorScreenState();
}

class _LcoeCalculatorScreenState extends ConsumerState<LcoeCalculatorScreen> {
  final _totalCostController = TextEditingController(text: '17500');
  final _annualKwhController = TextEditingController(text: '12000');
  final _yearsController = TextEditingController(text: '25');
  final _degradationController = TextEditingController(text: '0.5');
  final _omCostController = TextEditingController(text: '200');

  double? _lcoe;
  double? _totalEnergy;
  double? _totalCosts;
  String? _comparison;

  @override
  void dispose() {
    _totalCostController.dispose();
    _annualKwhController.dispose();
    _yearsController.dispose();
    _degradationController.dispose();
    _omCostController.dispose();
    super.dispose();
  }

  void _calculate() {
    final totalCost = double.tryParse(_totalCostController.text);
    final annualKwh = double.tryParse(_annualKwhController.text);
    final years = int.tryParse(_yearsController.text);
    final degradation = double.tryParse(_degradationController.text);
    final omCost = double.tryParse(_omCostController.text);

    if (totalCost == null || annualKwh == null || years == null ||
        degradation == null || omCost == null) {
      setState(() {
        _lcoe = null;
        _totalEnergy = null;
        _totalCosts = null;
        _comparison = null;
      });
      return;
    }

    // Calculate total lifetime energy with degradation
    double totalEnergy = 0;
    double currentProduction = annualKwh;
    final d = degradation / 100;

    for (int t = 1; t <= years; t++) {
      totalEnergy += currentProduction;
      currentProduction *= (1 - d);
    }

    // Total costs = Initial + O&M over lifetime
    final totalCosts = totalCost + (omCost * years);

    // LCOE = Total Costs / Total Energy
    final lcoe = totalEnergy > 0 ? (totalCosts / totalEnergy) * 100 : 0; // cents/kWh

    String comparison;
    if (lcoe < 5) {
      comparison = 'Excellent - well below average utility rates.';
    } else if (lcoe < 8) {
      comparison = 'Very Good - competitive with most utility rates.';
    } else if (lcoe < 12) {
      comparison = 'Good - comparable to average US electricity.';
    } else if (lcoe < 15) {
      comparison = 'Fair - may still save vs high-cost utilities.';
    } else {
      comparison = 'Review system cost or production estimates.';
    }

    setState(() {
      _lcoe = lcoe.toDouble();
      _totalEnergy = totalEnergy;
      _totalCosts = totalCosts;
      _comparison = comparison;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _totalCostController.text = '17500';
    _annualKwhController.text = '12000';
    _yearsController.text = '25';
    _degradationController.text = '0.5';
    _omCostController.text = '200';
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
        title: Text('LCOE Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COSTS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'System Cost',
                      unit: '\$',
                      hint: 'Net after ITC',
                      controller: _totalCostController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Annual O&M',
                      unit: '\$/yr',
                      hint: 'Maintenance',
                      controller: _omCostController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PRODUCTION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Year 1 Production',
                      unit: 'kWh',
                      hint: 'Annual output',
                      controller: _annualKwhController,
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
                label: 'System Life',
                unit: 'years',
                hint: '25 typical',
                controller: _yearsController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_lcoe != null) ...[
                _buildSectionHeader(colors, 'LEVELIZED COST'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
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
          Text(
            'LCOE = Total Costs ÷ Total kWh',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Levelized cost of energy over system lifetime',
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
    final isGood = _lcoe! < 12;
    final statusColor = _lcoe! < 8 ? colors.accentSuccess : (_lcoe! < 12 ? colors.accentInfo : colors.accentWarning);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Levelized Cost of Energy', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _lcoe!.toStringAsFixed(1),
                style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  ' ¢/kWh',
                  style: TextStyle(color: colors.textSecondary, fontSize: 20),
                ),
              ),
            ],
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
                _buildResultRow(colors, 'Total Costs', '\$${_totalCosts!.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Total Energy', '${(_totalEnergy! / 1000).toStringAsFixed(0)} MWh'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _comparison!,
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

  Widget _buildComparisonCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('US ELECTRICITY RATES (2024)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildCompareRow(colors, 'National Average', '~12 ¢/kWh'),
          _buildCompareRow(colors, 'California', '~28 ¢/kWh'),
          _buildCompareRow(colors, 'Texas', '~12 ¢/kWh'),
          _buildCompareRow(colors, 'Hawaii', '~35 ¢/kWh'),
          _buildCompareRow(colors, 'Utility Solar (large)', '~3-5 ¢/kWh'),
        ],
      ),
    );
  }

  Widget _buildCompareRow(ZaftoColors colors, String location, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(location, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text(rate, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
