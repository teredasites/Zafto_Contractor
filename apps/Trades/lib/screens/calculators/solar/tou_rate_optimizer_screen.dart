import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// TOU Rate Optimizer - Time-of-use rate analysis
class TouRateOptimizerScreen extends ConsumerStatefulWidget {
  const TouRateOptimizerScreen({super.key});
  @override
  ConsumerState<TouRateOptimizerScreen> createState() => _TouRateOptimizerScreenState();
}

class _TouRateOptimizerScreenState extends ConsumerState<TouRateOptimizerScreen> {
  final _peakRateController = TextEditingController(text: '0.35');
  final _offPeakRateController = TextEditingController(text: '0.12');
  final _midPeakRateController = TextEditingController(text: '0.22');
  final _dailyUsageController = TextEditingController(text: '30');
  final _solarProductionController = TextEditingController(text: '35');

  // Percentage of usage in each period
  final _peakUsageController = TextEditingController(text: '40');
  final _midPeakUsageController = TextEditingController(text: '35');
  final _offPeakUsageController = TextEditingController(text: '25');

  // Solar production during each period
  final _peakSolarController = TextEditingController(text: '60');
  final _midPeakSolarController = TextEditingController(text: '35');

  double? _billWithoutSolar;
  double? _billWithSolar;
  double? _monthlySavings;
  double? _peakShiftValue;
  String? _recommendation;

  @override
  void dispose() {
    _peakRateController.dispose();
    _offPeakRateController.dispose();
    _midPeakRateController.dispose();
    _dailyUsageController.dispose();
    _solarProductionController.dispose();
    _peakUsageController.dispose();
    _midPeakUsageController.dispose();
    _offPeakUsageController.dispose();
    _peakSolarController.dispose();
    _midPeakSolarController.dispose();
    super.dispose();
  }

  void _calculate() {
    final peakRate = double.tryParse(_peakRateController.text);
    final offPeakRate = double.tryParse(_offPeakRateController.text);
    final midPeakRate = double.tryParse(_midPeakRateController.text);
    final dailyUsage = double.tryParse(_dailyUsageController.text);
    final solarProduction = double.tryParse(_solarProductionController.text);
    final peakUsage = double.tryParse(_peakUsageController.text);
    final midPeakUsage = double.tryParse(_midPeakUsageController.text);
    final offPeakUsage = double.tryParse(_offPeakUsageController.text);
    final peakSolar = double.tryParse(_peakSolarController.text);
    final midPeakSolar = double.tryParse(_midPeakSolarController.text);

    if (peakRate == null || offPeakRate == null || midPeakRate == null ||
        dailyUsage == null || solarProduction == null ||
        peakUsage == null || midPeakUsage == null || offPeakUsage == null ||
        peakSolar == null || midPeakSolar == null) {
      setState(() {
        _billWithoutSolar = null;
        _billWithSolar = null;
        _monthlySavings = null;
        _peakShiftValue = null;
        _recommendation = null;
      });
      return;
    }

    // Daily usage by period
    final peakKwh = dailyUsage * (peakUsage / 100);
    final midPeakKwh = dailyUsage * (midPeakUsage / 100);
    final offPeakKwh = dailyUsage * (offPeakUsage / 100);

    // Daily bill without solar
    final dailyBillNoSolar = (peakKwh * peakRate) + (midPeakKwh * midPeakRate) + (offPeakKwh * offPeakRate);

    // Solar production by period
    final offPeakSolar = 100 - peakSolar - midPeakSolar;
    final solarPeak = solarProduction * (peakSolar / 100);
    final solarMidPeak = solarProduction * (midPeakSolar / 100);
    final solarOffPeak = solarProduction * (offPeakSolar / 100);

    // Net usage with solar (can be negative = export)
    final netPeak = (peakKwh - solarPeak).clamp(0, double.infinity);
    final netMidPeak = (midPeakKwh - solarMidPeak).clamp(0, double.infinity);
    final netOffPeak = (offPeakKwh - solarOffPeak).clamp(0, double.infinity);

    // Daily bill with solar
    final dailyBillWithSolar = (netPeak * peakRate) + (netMidPeak * midPeakRate) + (netOffPeak * offPeakRate);

    // Monthly values (30 days)
    final monthlyBillNoSolar = dailyBillNoSolar * 30;
    final monthlyBillWithSolar = dailyBillWithSolar * 30;
    final monthlySavings = monthlyBillNoSolar - monthlyBillWithSolar;

    // Value of peak shaving (solar during peak hours)
    final peakShiftValue = solarPeak * peakRate * 30;

    String recommendation;
    final peakCoverage = peakKwh > 0 ? (solarPeak / peakKwh * 100) : 0;
    if (peakCoverage > 100) {
      recommendation = 'Excellent TOU alignment. ${(peakCoverage - 100).toStringAsFixed(0)}% peak export at high rates.';
    } else if (peakCoverage > 80) {
      recommendation = 'Good TOU alignment. Consider battery to capture more peak value.';
    } else if (peakCoverage > 50) {
      recommendation = 'Moderate alignment. Shift loads to midday for better TOU optimization.';
    } else {
      recommendation = 'Low peak coverage. Consider west-facing panels or battery storage.';
    }

    setState(() {
      _billWithoutSolar = monthlyBillNoSolar;
      _billWithSolar = monthlyBillWithSolar;
      _monthlySavings = monthlySavings;
      _peakShiftValue = peakShiftValue;
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
    _peakRateController.text = '0.35';
    _offPeakRateController.text = '0.12';
    _midPeakRateController.text = '0.22';
    _dailyUsageController.text = '30';
    _solarProductionController.text = '35';
    _peakUsageController.text = '40';
    _midPeakUsageController.text = '35';
    _offPeakUsageController.text = '25';
    _peakSolarController.text = '60';
    _midPeakSolarController.text = '35';
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
        title: Text('TOU Optimizer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TOU RATES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Peak Rate',
                      unit: '\$/kWh',
                      hint: '4-9pm',
                      controller: _peakRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Mid-Peak',
                      unit: '\$/kWh',
                      hint: 'Shoulder',
                      controller: _midPeakRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Off-Peak',
                      unit: '\$/kWh',
                      hint: 'Night',
                      controller: _offPeakRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'USAGE PROFILE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Daily Usage',
                      unit: 'kWh',
                      hint: 'Total',
                      controller: _dailyUsageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Solar Production',
                      unit: 'kWh/day',
                      hint: 'Average',
                      controller: _solarProductionController,
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
                      label: 'Peak Usage',
                      unit: '%',
                      hint: 'Of daily',
                      controller: _peakUsageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Mid-Peak',
                      unit: '%',
                      hint: 'Of daily',
                      controller: _midPeakUsageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Off-Peak',
                      unit: '%',
                      hint: 'Of daily',
                      controller: _offPeakUsageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SOLAR PRODUCTION TIMING'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'During Peak',
                      unit: '%',
                      hint: 'Of solar',
                      controller: _peakSolarController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'During Mid-Peak',
                      unit: '%',
                      hint: 'Of solar',
                      controller: _midPeakSolarController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_monthlySavings != null) ...[
                _buildSectionHeader(colors, 'TOU ANALYSIS'),
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
              Icon(LucideIcons.clock, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Time-of-Use Optimizer',
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
            'Maximize savings with TOU rate alignment',
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
                    Text('Without Solar', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_billWithoutSolar!.toStringAsFixed(0)}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    Text('/month', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
              Icon(LucideIcons.arrowRight, color: colors.accentSuccess, size: 24),
              Expanded(
                child: Column(
                  children: [
                    Text('With Solar', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_billWithSolar!.toStringAsFixed(0)}',
                      style: TextStyle(color: colors.accentSuccess, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    Text('/month', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Monthly Savings', '\$${_monthlySavings!.toStringAsFixed(0)}', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Peak Shaving Value', '\$${_peakShiftValue!.toStringAsFixed(0)}/mo', colors.accentWarning),
              ),
            ],
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
