import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tracker ROI Calculator - Solar tracker investment analysis
class TrackerRoiScreen extends ConsumerStatefulWidget {
  const TrackerRoiScreen({super.key});
  @override
  ConsumerState<TrackerRoiScreen> createState() => _TrackerRoiScreenState();
}

class _TrackerRoiScreenState extends ConsumerState<TrackerRoiScreen> {
  final _systemSizeController = TextEditingController(text: '100');
  final _fixedCostController = TextEditingController(text: '1.00');
  final _trackerCostController = TextEditingController(text: '1.25');
  final _electricityRateController = TextEditingController(text: '0.10');
  final _fixedProductionController = TextEditingController(text: '1500');
  final _yearsController = TextEditingController(text: '25');

  String _trackerType = 'Single Axis';
  String _location = 'Southwest US';

  double? _productionGain;
  double? _additionalCost;
  double? _additionalRevenue;
  double? _paybackYears;
  double? _lifetimeRoi;
  String? _recommendation;

  // Production gain by tracker type and location
  final Map<String, Map<String, double>> _productionGains = {
    'Southwest US': {'Single Axis': 25, 'Dual Axis': 35},
    'Southeast US': {'Single Axis': 20, 'Dual Axis': 28},
    'Northeast US': {'Single Axis': 18, 'Dual Axis': 25},
    'Northwest US': {'Single Axis': 22, 'Dual Axis': 30},
    'Midwest US': {'Single Axis': 20, 'Dual Axis': 27},
  };

  List<String> get _locations => _productionGains.keys.toList();
  List<String> get _trackerTypes => ['Single Axis', 'Dual Axis'];

  @override
  void dispose() {
    _systemSizeController.dispose();
    _fixedCostController.dispose();
    _trackerCostController.dispose();
    _electricityRateController.dispose();
    _fixedProductionController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemSize = double.tryParse(_systemSizeController.text);
    final fixedCost = double.tryParse(_fixedCostController.text);
    final trackerCost = double.tryParse(_trackerCostController.text);
    final electricityRate = double.tryParse(_electricityRateController.text);
    final fixedProduction = double.tryParse(_fixedProductionController.text);
    final years = int.tryParse(_yearsController.text);

    if (systemSize == null || fixedCost == null || trackerCost == null ||
        electricityRate == null || fixedProduction == null || years == null) {
      setState(() {
        _productionGain = null;
        _additionalCost = null;
        _additionalRevenue = null;
        _paybackYears = null;
        _lifetimeRoi = null;
        _recommendation = null;
      });
      return;
    }

    // Get production gain percentage
    final gainPercent = _productionGains[_location]![_trackerType]!;

    // Annual production comparison
    final fixedAnnualKwh = systemSize * fixedProduction;
    final trackerAnnualKwh = fixedAnnualKwh * (1 + gainPercent / 100);
    final additionalKwh = trackerAnnualKwh - fixedAnnualKwh;

    // Additional annual revenue
    final additionalRevenue = additionalKwh * electricityRate;

    // Additional upfront cost
    final fixedSystemCost = systemSize * 1000 * fixedCost;
    final trackerSystemCost = systemSize * 1000 * trackerCost;
    final additionalCost = trackerSystemCost - fixedSystemCost;

    // Payback period for tracker premium
    final paybackYears = additionalCost / additionalRevenue;

    // Lifetime ROI
    final lifetimeAdditionalRevenue = additionalRevenue * years;
    // Account for O&M difference (~$0.005/W/yr more for trackers)
    final additionalOm = systemSize * 1000 * 0.005 * years;
    final netLifetimeBenefit = lifetimeAdditionalRevenue - additionalOm;
    final lifetimeRoi = ((netLifetimeBenefit - additionalCost) / additionalCost) * 100;

    String recommendation;
    if (paybackYears > years) {
      recommendation = 'Tracker does not pay back within system life. Fixed tilt recommended.';
    } else if (paybackYears > 15) {
      recommendation = 'Long payback. Consider fixed tilt unless land is constrained.';
    } else if (paybackYears > 8) {
      recommendation = 'Reasonable payback. Tracker viable if maximizing energy is priority.';
    } else if (paybackYears > 5) {
      recommendation = 'Good payback. Tracker recommended for utility-scale projects.';
    } else {
      recommendation = 'Excellent ROI. Tracker strongly recommended.';
    }

    setState(() {
      _productionGain = gainPercent;
      _additionalCost = additionalCost;
      _additionalRevenue = additionalRevenue;
      _paybackYears = paybackYears;
      _lifetimeRoi = lifetimeRoi;
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
    _systemSizeController.text = '100';
    _fixedCostController.text = '1.00';
    _trackerCostController.text = '1.25';
    _electricityRateController.text = '0.10';
    _fixedProductionController.text = '1500';
    _yearsController.text = '25';
    setState(() {
      _trackerType = 'Single Axis';
      _location = 'Southwest US';
    });
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
        title: Text('Tracker ROI', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TRACKER TYPE'),
              const SizedBox(height: 12),
              _buildTrackerTypeSelector(colors),
              const SizedBox(height: 12),
              _buildLocationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'System Size',
                      unit: 'kW DC',
                      hint: 'Capacity',
                      controller: _systemSizeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Fixed Production',
                      unit: 'kWh/kW',
                      hint: 'Annual',
                      controller: _fixedProductionController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'COSTS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Fixed Tilt Cost',
                      unit: '\$/W',
                      hint: 'Installed',
                      controller: _fixedCostController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Tracker Cost',
                      unit: '\$/W',
                      hint: 'Installed',
                      controller: _trackerCostController,
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
                      label: 'Electricity Rate',
                      unit: '\$/kWh',
                      hint: 'PPA/Retail',
                      controller: _electricityRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Analysis Period',
                      unit: 'years',
                      hint: 'Project life',
                      controller: _yearsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_paybackYears != null) ...[
                _buildSectionHeader(colors, 'TRACKER ANALYSIS'),
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
              Icon(LucideIcons.sunMedium, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Solar Tracker ROI',
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
            'Compare fixed tilt vs tracking system economics',
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

  Widget _buildTrackerTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: _trackerTypes.map((type) {
          final isSelected = _trackerType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _trackerType = type);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _location,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary),
          items: _locations.map((loc) {
            return DropdownMenuItem(value: loc, child: Text(loc));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _location = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGoodRoi = _paybackYears! < 10;
    final statusColor = _paybackYears! < 8 ? colors.accentSuccess : (_paybackYears! < 15 ? colors.accentInfo : colors.accentWarning);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Production Gain', '+${_productionGain!.toStringAsFixed(0)}%', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Payback', '${_paybackYears!.toStringAsFixed(1)} yrs', statusColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('Lifetime ROI', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                Text(
                  '${_lifetimeRoi!.toStringAsFixed(0)}%',
                  style: TextStyle(color: statusColor, fontSize: 36, fontWeight: FontWeight.w700),
                ),
              ],
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
                _buildResultRow(colors, 'Tracker Premium', '\$${(_additionalCost! / 1000).toStringAsFixed(0)}k'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Additional Revenue/yr', '\$${_additionalRevenue!.toStringAsFixed(0)}'),
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
