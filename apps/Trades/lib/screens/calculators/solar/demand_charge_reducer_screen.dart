import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Demand Charge Reducer - Peak demand reduction analysis
class DemandChargeReducerScreen extends ConsumerStatefulWidget {
  const DemandChargeReducerScreen({super.key});
  @override
  ConsumerState<DemandChargeReducerScreen> createState() => _DemandChargeReducerScreenState();
}

class _DemandChargeReducerScreenState extends ConsumerState<DemandChargeReducerScreen> {
  final _peakDemandController = TextEditingController(text: '25');
  final _demandChargeController = TextEditingController(text: '15');
  final _solarCapacityController = TextEditingController(text: '10');
  final _batteryCapacityController = TextEditingController(text: '13.5');
  final _batteryPowerController = TextEditingController(text: '5');

  bool _hasBattery = true;

  double? _currentDemandCost;
  double? _solarOnlyReduction;
  double? _withBatteryReduction;
  double? _totalSavings;
  double? _newPeakDemand;
  String? _recommendation;

  @override
  void dispose() {
    _peakDemandController.dispose();
    _demandChargeController.dispose();
    _solarCapacityController.dispose();
    _batteryCapacityController.dispose();
    _batteryPowerController.dispose();
    super.dispose();
  }

  void _calculate() {
    final peakDemand = double.tryParse(_peakDemandController.text);
    final demandCharge = double.tryParse(_demandChargeController.text);
    final solarCapacity = double.tryParse(_solarCapacityController.text);
    final batteryCapacity = double.tryParse(_batteryCapacityController.text);
    final batteryPower = double.tryParse(_batteryPowerController.text);

    if (peakDemand == null || demandCharge == null || solarCapacity == null) {
      setState(() {
        _currentDemandCost = null;
        _solarOnlyReduction = null;
        _withBatteryReduction = null;
        _totalSavings = null;
        _newPeakDemand = null;
        _recommendation = null;
      });
      return;
    }

    // Current monthly demand cost
    final currentDemandCost = peakDemand * demandCharge;

    // Solar alone typically reduces peak by ~30-50% of capacity during peak hours
    // Conservative estimate: 30% contribution during demand peaks
    final solarPeakContribution = solarCapacity * 0.30;
    final solarOnlyReduction = math.min(solarPeakContribution, peakDemand * 0.3);
    final newPeakWithSolar = peakDemand - solarOnlyReduction;

    // With battery: can shave additional peak
    double withBatteryReduction = 0;
    double newPeakDemand = newPeakWithSolar;

    if (_hasBattery && batteryCapacity != null && batteryPower != null) {
      // Battery can discharge at its power rating to shave peaks
      // Effective reduction depends on peak duration and battery capacity
      // Assume 2-hour peak period for sizing
      final batteryContribution = math.min(batteryPower, batteryCapacity / 2);
      withBatteryReduction = math.min(batteryContribution, newPeakWithSolar * 0.5);
      newPeakDemand = newPeakWithSolar - withBatteryReduction;
    }

    final totalReduction = solarOnlyReduction + withBatteryReduction;
    final totalSavings = totalReduction * demandCharge;

    String recommendation;
    final reductionPercent = (totalReduction / peakDemand) * 100;
    if (reductionPercent > 50) {
      recommendation = 'Excellent peak shaving. ${reductionPercent.toStringAsFixed(0)}% demand reduction achieved.';
    } else if (reductionPercent > 30) {
      recommendation = 'Good reduction. Consider larger battery for more savings.';
    } else if (reductionPercent > 15) {
      recommendation = 'Moderate reduction. Battery storage highly recommended.';
    } else {
      recommendation = 'Limited reduction. Review system sizing for demand charges.';
    }

    setState(() {
      _currentDemandCost = currentDemandCost;
      _solarOnlyReduction = solarOnlyReduction;
      _withBatteryReduction = withBatteryReduction;
      _totalSavings = totalSavings;
      _newPeakDemand = newPeakDemand;
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
    _peakDemandController.text = '25';
    _demandChargeController.text = '15';
    _solarCapacityController.text = '10';
    _batteryCapacityController.text = '13.5';
    _batteryPowerController.text = '5';
    setState(() => _hasBattery = true);
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
        title: Text('Demand Charge Reducer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CURRENT DEMAND'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Peak Demand',
                      unit: 'kW',
                      hint: 'Monthly max',
                      controller: _peakDemandController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Demand Charge',
                      unit: '\$/kW',
                      hint: 'Per kW',
                      controller: _demandChargeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SOLAR SYSTEM'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Solar Capacity',
                unit: 'kW DC',
                hint: 'System size',
                controller: _solarCapacityController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BATTERY STORAGE'),
              const SizedBox(height: 12),
              _buildBatteryToggle(colors),
              if (_hasBattery) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ZaftoInputField(
                        label: 'Battery Capacity',
                        unit: 'kWh',
                        hint: 'Total storage',
                        controller: _batteryCapacityController,
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ZaftoInputField(
                        label: 'Max Power',
                        unit: 'kW',
                        hint: 'Discharge rate',
                        controller: _batteryPowerController,
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              if (_currentDemandCost != null) ...[
                _buildSectionHeader(colors, 'DEMAND REDUCTION'),
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
              Icon(LucideIcons.trendingDown, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Demand Charge Reducer',
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
            'Reduce peak demand with solar + battery',
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

  Widget _buildBatteryToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.battery, color: _hasBattery ? colors.accentPrimary : colors.textTertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Include Battery Storage',
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
          Switch(
            value: _hasBattery,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _hasBattery = value);
              _calculate();
            },
            activeColor: colors.accentPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final peakDemand = double.parse(_peakDemandController.text);
    final reductionPercent = ((peakDemand - _newPeakDemand!) / peakDemand) * 100;

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
                    Text('Current Peak', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${peakDemand.toStringAsFixed(0)} kW',
                      style: TextStyle(color: colors.textSecondary, fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    Text('\$${_currentDemandCost!.toStringAsFixed(0)}/mo', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
              Icon(LucideIcons.arrowRight, color: colors.accentSuccess, size: 24),
              Expanded(
                child: Column(
                  children: [
                    Text('New Peak', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${_newPeakDemand!.toStringAsFixed(1)} kW',
                      style: TextStyle(color: colors.accentSuccess, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    Text('-${reductionPercent.toStringAsFixed(0)}%', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
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
                _buildResultRow(colors, 'Solar Reduction', '${_solarOnlyReduction!.toStringAsFixed(1)} kW'),
                if (_hasBattery) ...[
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Battery Reduction', '${_withBatteryReduction!.toStringAsFixed(1)} kW'),
                ],
                const SizedBox(height: 8),
                Divider(color: colors.borderSubtle),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Total Reduction', '${(_solarOnlyReduction! + _withBatteryReduction!).toStringAsFixed(1)} kW'),
              ],
            ),
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
                Text('Monthly Demand Savings', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                Text(
                  '\$${_totalSavings!.toStringAsFixed(0)}',
                  style: TextStyle(color: colors.accentSuccess, fontSize: 36, fontWeight: FontWeight.w700),
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
