import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Utility Bill Analyzer - Extract kWh from bill amount
class UtilityBillAnalyzerScreen extends ConsumerStatefulWidget {
  const UtilityBillAnalyzerScreen({super.key});
  @override
  ConsumerState<UtilityBillAnalyzerScreen> createState() => _UtilityBillAnalyzerScreenState();
}

class _UtilityBillAnalyzerScreenState extends ConsumerState<UtilityBillAnalyzerScreen> {
  final _billAmountController = TextEditingController();
  final _rateController = TextEditingController(text: '0.15');
  final _fixedChargeController = TextEditingController(text: '15');

  double? _monthlyKwh;
  double? _annualKwh;
  double? _recommendedSystem;

  @override
  void dispose() {
    _billAmountController.dispose();
    _rateController.dispose();
    _fixedChargeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final billAmount = double.tryParse(_billAmountController.text);
    final rate = double.tryParse(_rateController.text);
    final fixedCharge = double.tryParse(_fixedChargeController.text) ?? 0;

    if (billAmount == null || rate == null || rate <= 0) {
      setState(() {
        _monthlyKwh = null;
        _annualKwh = null;
        _recommendedSystem = null;
      });
      return;
    }

    // kWh = (Bill - Fixed Charges) / Rate
    final energyPortion = billAmount - fixedCharge;
    if (energyPortion <= 0) {
      setState(() {
        _monthlyKwh = null;
        _annualKwh = null;
        _recommendedSystem = null;
      });
      return;
    }

    final monthlyKwh = energyPortion / rate;
    final annualKwh = monthlyKwh * 12;

    // Recommended system: annual kWh / (4.5 sun hours * 365 * 0.86 derate)
    final systemKw = annualKwh / (4.5 * 365 * 0.86);

    setState(() {
      _monthlyKwh = monthlyKwh;
      _annualKwh = annualKwh;
      _recommendedSystem = systemKw;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _billAmountController.clear();
    _rateController.text = '0.15';
    _fixedChargeController.text = '15';
    setState(() {
      _monthlyKwh = null;
      _annualKwh = null;
      _recommendedSystem = null;
    });
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
        title: Text('Bill Analyzer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Clear all',
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
              _buildSectionHeader(colors, 'BILL INFORMATION'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Monthly Bill Amount',
                unit: '\$',
                hint: 'Total bill',
                controller: _billAmountController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Electric Rate',
                unit: '\$/kWh',
                hint: 'From bill or utility',
                controller: _rateController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Fixed Charges',
                unit: '\$',
                hint: 'Service fees, etc.',
                controller: _fixedChargeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 16),
              _buildCommonRates(colors),
              const SizedBox(height: 32),
              if (_monthlyKwh != null) ...[
                _buildSectionHeader(colors, 'ANALYSIS'),
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
            'kWh = (Bill - Fixed Charges) / Rate',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Convert dollar amount to energy usage for system sizing',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
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

  Widget _buildCommonRates(ZaftoColors colors) {
    final rates = [0.10, 0.12, 0.15, 0.18, 0.22, 0.30];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Common Rates (\$/kWh)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rates.map((r) {
              final isSelected = _rateController.text == r.toString();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _rateController.text = r.toString();
                  _calculate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.fillDefault,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '\$${r.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Monthly Usage', '${_monthlyKwh!.toStringAsFixed(0)} kWh', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Estimated Annual', '${_formatNumber(_annualKwh!)} kWh'),
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'Recommended System', '${_recommendedSystem!.toStringAsFixed(1)} kW'),
          const SizedBox(height: 8),
          Text(
            'Based on 4.5 peak sun hours, 86% efficiency',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 16, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For accurate sizing, use 12 months of bills',
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

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? colors.accentPrimary : colors.textPrimary,
            fontSize: isPrimary ? 20 : 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
