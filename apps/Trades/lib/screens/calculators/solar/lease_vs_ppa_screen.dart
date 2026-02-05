import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lease vs PPA Analysis - Compare solar financing options
class LeaseVsPpaScreen extends ConsumerStatefulWidget {
  const LeaseVsPpaScreen({super.key});
  @override
  ConsumerState<LeaseVsPpaScreen> createState() => _LeaseVsPpaScreenState();
}

class _LeaseVsPpaScreenState extends ConsumerState<LeaseVsPpaScreen> {
  final _systemSizeController = TextEditingController(text: '8');
  final _annualKwhController = TextEditingController(text: '11000');
  final _currentBillController = TextEditingController(text: '200');
  final _leasePaymentController = TextEditingController(text: '150');
  final _leaseEscalationController = TextEditingController(text: '2.9');
  final _ppaRateController = TextEditingController(text: '0.12');
  final _ppaEscalationController = TextEditingController(text: '2.9');
  final _utilityEscalationController = TextEditingController(text: '3.5');
  final _termController = TextEditingController(text: '25');

  double? _leaseTotalCost;
  double? _ppaTotalCost;
  double? _leaseYear1Savings;
  double? _ppaYear1Savings;
  double? _leaseLifetimeSavings;
  double? _ppaLifetimeSavings;
  String? _recommendation;

  @override
  void dispose() {
    _systemSizeController.dispose();
    _annualKwhController.dispose();
    _currentBillController.dispose();
    _leasePaymentController.dispose();
    _leaseEscalationController.dispose();
    _ppaRateController.dispose();
    _ppaEscalationController.dispose();
    _utilityEscalationController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemSize = double.tryParse(_systemSizeController.text);
    final annualKwh = double.tryParse(_annualKwhController.text);
    final currentBill = double.tryParse(_currentBillController.text);
    final leasePayment = double.tryParse(_leasePaymentController.text);
    final leaseEscalation = double.tryParse(_leaseEscalationController.text);
    final ppaRate = double.tryParse(_ppaRateController.text);
    final ppaEscalation = double.tryParse(_ppaEscalationController.text);
    final utilityEscalation = double.tryParse(_utilityEscalationController.text);
    final term = int.tryParse(_termController.text);

    if (systemSize == null || annualKwh == null || currentBill == null ||
        leasePayment == null || leaseEscalation == null ||
        ppaRate == null || ppaEscalation == null ||
        utilityEscalation == null || term == null) {
      setState(() {
        _leaseTotalCost = null;
        _ppaTotalCost = null;
        _leaseYear1Savings = null;
        _ppaYear1Savings = null;
        _leaseLifetimeSavings = null;
        _ppaLifetimeSavings = null;
        _recommendation = null;
      });
      return;
    }

    final le = leaseEscalation / 100;
    final pe = ppaEscalation / 100;
    final ue = utilityEscalation / 100;

    // Year 1 calculations
    final annualBillNoSolar = currentBill * 12;
    final leaseYear1Cost = leasePayment * 12;
    final ppaYear1Cost = annualKwh * ppaRate;

    final leaseYear1Savings = annualBillNoSolar - leaseYear1Cost;
    final ppaYear1Savings = annualBillNoSolar - ppaYear1Cost;

    // Lifetime calculations
    double leaseTotalCost = 0;
    double ppaTotalCost = 0;
    double utilityTotalCost = 0;

    for (int t = 0; t < term; t++) {
      leaseTotalCost += leasePayment * 12 * math.pow(1 + le, t);
      ppaTotalCost += annualKwh * ppaRate * math.pow(1 + pe, t);
      utilityTotalCost += annualBillNoSolar * math.pow(1 + ue, t);
    }

    final leaseLifetimeSavings = utilityTotalCost - leaseTotalCost;
    final ppaLifetimeSavings = utilityTotalCost - ppaTotalCost;

    String recommendation;
    if (leaseLifetimeSavings > ppaLifetimeSavings * 1.1) {
      recommendation = 'Lease offers better value. Fixed payments protect against rate increases.';
    } else if (ppaLifetimeSavings > leaseLifetimeSavings * 1.1) {
      recommendation = 'PPA offers better value. Pay only for actual production.';
    } else {
      final diff = (leaseLifetimeSavings - ppaLifetimeSavings).abs();
      if (diff < 1000) {
        recommendation = 'Very similar outcomes. Choose based on preference and guarantees.';
      } else {
        recommendation = 'Close comparison. Review production guarantees and escalation terms.';
      }
    }

    setState(() {
      _leaseTotalCost = leaseTotalCost;
      _ppaTotalCost = ppaTotalCost;
      _leaseYear1Savings = leaseYear1Savings;
      _ppaYear1Savings = ppaYear1Savings;
      _leaseLifetimeSavings = leaseLifetimeSavings;
      _ppaLifetimeSavings = ppaLifetimeSavings;
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
    _systemSizeController.text = '8';
    _annualKwhController.text = '11000';
    _currentBillController.text = '200';
    _leasePaymentController.text = '150';
    _leaseEscalationController.text = '2.9';
    _ppaRateController.text = '0.12';
    _ppaEscalationController.text = '2.9';
    _utilityEscalationController.text = '3.5';
    _termController.text = '25';
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
        title: Text('Lease vs PPA', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM & USAGE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Annual Production',
                      unit: 'kWh',
                      hint: 'Expected',
                      controller: _annualKwhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Current Bill',
                      unit: '\$/mo',
                      hint: 'Average',
                      controller: _currentBillController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LEASE TERMS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Monthly Payment',
                      unit: '\$',
                      hint: 'Fixed payment',
                      controller: _leasePaymentController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Escalation',
                      unit: '%/yr',
                      hint: 'Annual increase',
                      controller: _leaseEscalationController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PPA TERMS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'PPA Rate',
                      unit: '\$/kWh',
                      hint: 'Per kWh',
                      controller: _ppaRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Escalation',
                      unit: '%/yr',
                      hint: 'Annual increase',
                      controller: _ppaEscalationController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'COMPARISON'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Utility Escalation',
                      unit: '%/yr',
                      hint: 'Rate increase',
                      controller: _utilityEscalationController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Term',
                      unit: 'years',
                      hint: 'Contract length',
                      controller: _termController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_leaseTotalCost != null) ...[
                _buildSectionHeader(colors, 'ANALYSIS'),
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
              Icon(LucideIcons.fileText, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Lease vs PPA Analysis',
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
            'Compare solar lease and power purchase agreement',
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
    final leaseIsBetter = _leaseLifetimeSavings! > _ppaLifetimeSavings!;

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
              Expanded(child: _buildOptionCard(colors, 'LEASE', _leaseYear1Savings!, _leaseLifetimeSavings!, leaseIsBetter)),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionCard(colors, 'PPA', _ppaYear1Savings!, _ppaLifetimeSavings!, !leaseIsBetter)),
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
                _buildCompareRow(colors, 'Lease Total Cost', '\$${(_leaseTotalCost! / 1000).toStringAsFixed(0)}k'),
                const SizedBox(height: 8),
                _buildCompareRow(colors, 'PPA Total Cost', '\$${(_ppaTotalCost! / 1000).toStringAsFixed(0)}k'),
                const SizedBox(height: 8),
                Divider(color: colors.borderSubtle),
                const SizedBox(height: 8),
                _buildCompareRow(
                  colors,
                  'Difference',
                  '\$${((_leaseTotalCost! - _ppaTotalCost!).abs() / 1000).toStringAsFixed(1)}k ${_leaseTotalCost! < _ppaTotalCost! ? '(Lease cheaper)' : '(PPA cheaper)'}',
                ),
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
          const SizedBox(height: 16),
          _buildKeyDifferences(colors),
        ],
      ),
    );
  }

  Widget _buildOptionCard(ZaftoColors colors, String title, double year1Savings, double lifetimeSavings, bool isBetter) {
    final accentColor = isBetter ? colors.accentSuccess : colors.accentInfo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: isBetter ? 0.5 : 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isBetter) ...[
                Icon(LucideIcons.check, size: 14, color: accentColor),
                const SizedBox(width: 4),
              ],
              Text(title, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${(lifetimeSavings / 1000).toStringAsFixed(0)}k',
            style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          Text('lifetime savings', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: year1Savings >= 0 ? colors.accentSuccess.withValues(alpha: 0.2) : colors.accentWarning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Yr 1: \$${year1Savings.toStringAsFixed(0)}',
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

  Widget _buildCompareRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildKeyDifferences(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KEY DIFFERENCES', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildDifferenceRow(colors, 'Lease:', 'Fixed monthly payment'),
          _buildDifferenceRow(colors, 'PPA:', 'Pay per kWh produced'),
          _buildDifferenceRow(colors, 'Lease:', 'Production risk on you'),
          _buildDifferenceRow(colors, 'PPA:', 'Production risk on provider'),
        ],
      ),
    );
  }

  Widget _buildDifferenceRow(ZaftoColors colors, String type, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(type, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
