import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Simple Payback Calculator - Years to recover solar investment
class SimplePaybackScreen extends ConsumerStatefulWidget {
  const SimplePaybackScreen({super.key});
  @override
  ConsumerState<SimplePaybackScreen> createState() => _SimplePaybackScreenState();
}

class _SimplePaybackScreenState extends ConsumerState<SimplePaybackScreen> {
  final _systemCostController = TextEditingController(text: '25000');
  final _itcPercentController = TextEditingController(text: '30');
  final _annualSavingsController = TextEditingController(text: '2400');
  final _stateRebateController = TextEditingController(text: '0');

  double? _netCost;
  double? _paybackYears;
  String? _rating;

  @override
  void dispose() {
    _systemCostController.dispose();
    _itcPercentController.dispose();
    _annualSavingsController.dispose();
    _stateRebateController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemCost = double.tryParse(_systemCostController.text);
    final itcPercent = double.tryParse(_itcPercentController.text);
    final annualSavings = double.tryParse(_annualSavingsController.text);
    final stateRebate = double.tryParse(_stateRebateController.text);

    if (systemCost == null || itcPercent == null || annualSavings == null || stateRebate == null || annualSavings == 0) {
      setState(() {
        _netCost = null;
        _paybackYears = null;
        _rating = null;
      });
      return;
    }

    // Calculate net cost after incentives
    final federalCredit = systemCost * (itcPercent / 100);
    final netCost = systemCost - federalCredit - stateRebate;

    // Simple payback = Net Cost / Annual Savings
    final paybackYears = netCost / annualSavings;

    String rating;
    if (paybackYears <= 5) {
      rating = 'Excellent - Very quick payback';
    } else if (paybackYears <= 7) {
      rating = 'Very Good - Strong investment';
    } else if (paybackYears <= 10) {
      rating = 'Good - Solid returns';
    } else if (paybackYears <= 12) {
      rating = 'Fair - Acceptable payback';
    } else {
      rating = 'Long payback - Review pricing';
    }

    setState(() {
      _netCost = netCost;
      _paybackYears = paybackYears;
      _rating = rating;
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
    _annualSavingsController.text = '2400';
    _stateRebateController.text = '0';
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
        title: Text('Simple Payback', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM COST'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Gross System Cost',
                unit: '\$',
                hint: 'Before incentives',
                controller: _systemCostController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INCENTIVES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Federal ITC',
                      unit: '%',
                      hint: '30% through 2032',
                      controller: _itcPercentController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'State Rebate',
                      unit: '\$',
                      hint: 'If applicable',
                      controller: _stateRebateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SAVINGS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Annual Electric Savings',
                unit: '\$/yr',
                hint: 'Utility bill reduction',
                controller: _annualSavingsController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_paybackYears != null) ...[
                _buildSectionHeader(colors, 'PAYBACK PERIOD'),
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
          Text(
            'Payback = Net Cost ÷ Annual Savings',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Years until solar investment pays for itself',
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
    final years = _paybackYears!;
    final isGood = years <= 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isGood ? colors.accentSuccess : colors.accentWarning).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Simple Payback Period', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${years.toStringAsFixed(1)} years',
            style: TextStyle(color: isGood ? colors.accentSuccess : colors.accentWarning, fontSize: 40, fontWeight: FontWeight.w700),
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
                _buildResultRow(colors, 'Gross Cost', '\$${double.parse(_systemCostController.text).toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Net Cost (after incentives)', '\$${_netCost!.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Annual Savings', '\$${_annualSavingsController.text}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isGood ? colors.accentSuccess : colors.accentWarning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isGood ? LucideIcons.trendingUp : LucideIcons.info,
                  size: 18,
                  color: isGood ? colors.accentSuccess : colors.accentWarning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _rating!,
                    style: TextStyle(
                      color: isGood ? colors.accentSuccess : colors.accentWarning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
