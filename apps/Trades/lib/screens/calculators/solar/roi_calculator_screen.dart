import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// ROI Calculator - Return on investment for solar
class RoiCalculatorScreen extends ConsumerStatefulWidget {
  const RoiCalculatorScreen({super.key});
  @override
  ConsumerState<RoiCalculatorScreen> createState() => _RoiCalculatorScreenState();
}

class _RoiCalculatorScreenState extends ConsumerState<RoiCalculatorScreen> {
  final _systemCostController = TextEditingController(text: '25000');
  final _incentivesController = TextEditingController(text: '7500');
  final _annualSavingsController = TextEditingController(text: '2400');
  final _yearsController = TextEditingController(text: '25');

  double? _netCost;
  double? _totalSavings;
  double? _netGain;
  double? _roi;
  double? _annualRoi;

  @override
  void dispose() {
    _systemCostController.dispose();
    _incentivesController.dispose();
    _annualSavingsController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemCost = double.tryParse(_systemCostController.text);
    final incentives = double.tryParse(_incentivesController.text);
    final annualSavings = double.tryParse(_annualSavingsController.text);
    final years = double.tryParse(_yearsController.text);

    if (systemCost == null || incentives == null || annualSavings == null || years == null) {
      setState(() {
        _netCost = null;
        _totalSavings = null;
        _netGain = null;
        _roi = null;
        _annualRoi = null;
      });
      return;
    }

    final netCost = systemCost - incentives;
    final totalSavings = annualSavings * years;
    final netGain = totalSavings - netCost;
    final roi = netCost > 0 ? (netGain / netCost) * 100 : 0;
    final annualRoi = years > 0 ? roi / years : 0;

    setState(() {
      _netCost = netCost;
      _totalSavings = totalSavings;
      _netGain = netGain;
      _roi = roi.toDouble();
      _annualRoi = annualRoi.toDouble();
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
    _incentivesController.text = '7500';
    _annualSavingsController.text = '2400';
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
        title: Text('ROI Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                      label: 'System Cost',
                      unit: '\$',
                      hint: 'Gross cost',
                      controller: _systemCostController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Incentives',
                      unit: '\$',
                      hint: 'ITC + rebates',
                      controller: _incentivesController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RETURNS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Annual Savings',
                      unit: '\$/yr',
                      hint: 'Utility savings',
                      controller: _annualSavingsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'System Life',
                      unit: 'years',
                      hint: '25 typical',
                      controller: _yearsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_roi != null) ...[
                _buildSectionHeader(colors, 'RETURN ON INVESTMENT'),
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
            'ROI = (Gain - Cost) ÷ Cost × 100',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate total return on solar investment',
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
    final isPositive = _roi! > 0;
    final statusColor = _roi! > 100 ? colors.accentSuccess : (_roi! > 0 ? colors.accentInfo : colors.accentWarning);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Total ROI (${_yearsController.text} years)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_roi!.toStringAsFixed(0)}%',
            style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700),
          ),
          Text(
            '${_annualRoi!.toStringAsFixed(1)}% per year',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
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
                _buildResultRow(colors, 'Net Investment', '\$${_netCost!.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Total Savings', '\$${_totalSavings!.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Net Gain', '\$${_netGain!.toStringAsFixed(0)}', isPositive ? colors.accentSuccess : colors.accentError),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor ?? colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
