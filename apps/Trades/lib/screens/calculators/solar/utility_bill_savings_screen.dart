import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Utility Bill Savings Calculator - Monthly savings estimate
class UtilityBillSavingsScreen extends ConsumerStatefulWidget {
  const UtilityBillSavingsScreen({super.key});
  @override
  ConsumerState<UtilityBillSavingsScreen> createState() => _UtilityBillSavingsScreenState();
}

class _UtilityBillSavingsScreenState extends ConsumerState<UtilityBillSavingsScreen> {
  final _currentBillController = TextEditingController(text: '200');
  final _solarOffsetController = TextEditingController(text: '90');
  final _connectionFeeController = TextEditingController(text: '15');
  final _escalationController = TextEditingController(text: '3');
  final _yearsController = TextEditingController(text: '25');

  double? _monthlySavings;
  double? _newBill;
  double? _year1Savings;
  double? _lifetimeSavings;

  @override
  void dispose() {
    _currentBillController.dispose();
    _solarOffsetController.dispose();
    _connectionFeeController.dispose();
    _escalationController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final currentBill = double.tryParse(_currentBillController.text);
    final solarOffset = double.tryParse(_solarOffsetController.text);
    final connectionFee = double.tryParse(_connectionFeeController.text);
    final escalation = double.tryParse(_escalationController.text);
    final years = int.tryParse(_yearsController.text);

    if (currentBill == null || solarOffset == null || connectionFee == null ||
        escalation == null || years == null) {
      setState(() {
        _monthlySavings = null;
        _newBill = null;
        _year1Savings = null;
        _lifetimeSavings = null;
      });
      return;
    }

    // Monthly calculations
    final energyPortion = currentBill - connectionFee;
    final solarSavings = energyPortion * (solarOffset / 100);
    final newBill = connectionFee + (energyPortion - solarSavings);
    final monthlySavings = currentBill - newBill;
    final year1Savings = monthlySavings * 12;

    // Lifetime savings with escalation
    double lifetimeSavings = 0;
    double currentAnnualBill = currentBill * 12;
    final e = escalation / 100;

    for (int t = 0; t < years; t++) {
      final annualSavings = (currentAnnualBill - connectionFee * 12) * (solarOffset / 100);
      lifetimeSavings += annualSavings;
      currentAnnualBill *= (1 + e);
    }

    setState(() {
      _monthlySavings = monthlySavings;
      _newBill = newBill;
      _year1Savings = year1Savings;
      _lifetimeSavings = lifetimeSavings;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentBillController.text = '200';
    _solarOffsetController.text = '90';
    _connectionFeeController.text = '15';
    _escalationController.text = '3';
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
        title: Text('Bill Savings', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CURRENT BILL'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Monthly Bill',
                      unit: '\$',
                      hint: 'Current avg',
                      controller: _currentBillController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Connection Fee',
                      unit: '\$',
                      hint: 'Fixed charge',
                      controller: _connectionFeeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SOLAR SYSTEM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Solar Offset',
                      unit: '%',
                      hint: 'Usage covered',
                      controller: _solarOffsetController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Rate Escalation',
                      unit: '%/yr',
                      hint: 'Utility increase',
                      controller: _escalationController,
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
              if (_monthlySavings != null) ...[
                _buildSectionHeader(colors, 'SAVINGS PROJECTION'),
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
              Icon(LucideIcons.piggyBank, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Utility Bill Savings',
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
            'Estimate monthly and lifetime savings with solar',
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
                child: Column(
                  children: [
                    Text('Before Solar', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${double.parse(_currentBillController.text).toStringAsFixed(0)}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 28, fontWeight: FontWeight.w600),
                    ),
                    Text('/month', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
              Icon(LucideIcons.arrowRight, color: colors.accentSuccess, size: 24),
              Expanded(
                child: Column(
                  children: [
                    Text('After Solar', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_newBill!.toStringAsFixed(0)}',
                      style: TextStyle(color: colors.accentSuccess, fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    Text('/month', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('Monthly Savings', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                Text(
                  '\$${_monthlySavings!.toStringAsFixed(0)}',
                  style: TextStyle(color: colors.accentSuccess, fontSize: 36, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Year 1', '\$${_year1Savings!.toStringAsFixed(0)}', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, '${_yearsController.text}-Year', '\$${(_lifetimeSavings! / 1000).toStringAsFixed(0)}k', colors.accentInfo),
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
}
