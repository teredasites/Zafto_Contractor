import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Production Estimator - kWh/year by location and system size
class ProductionEstimatorScreen extends ConsumerStatefulWidget {
  const ProductionEstimatorScreen({super.key});
  @override
  ConsumerState<ProductionEstimatorScreen> createState() => _ProductionEstimatorScreenState();
}

class _ProductionEstimatorScreenState extends ConsumerState<ProductionEstimatorScreen> {
  final _systemSizeController = TextEditingController();
  final _sunHoursController = TextEditingController(text: '4.5');
  final _derateFactor = TextEditingController(text: '0.86');

  String _selectedRegion = 'Northeast';

  double? _annualProduction;
  double? _monthlyAverage;
  double? _dailyAverage;

  // Average peak sun hours by US region
  static const Map<String, double> _regionSunHours = {
    'Southwest': 6.0,
    'Southeast': 5.0,
    'Midwest': 4.5,
    'Northeast': 4.2,
    'Northwest': 3.8,
    'Hawaii': 5.5,
    'Alaska': 3.0,
  };

  @override
  void dispose() {
    _systemSizeController.dispose();
    _sunHoursController.dispose();
    _derateFactor.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemKw = double.tryParse(_systemSizeController.text);
    final sunHours = double.tryParse(_sunHoursController.text);
    final derate = double.tryParse(_derateFactor.text);

    if (systemKw == null || sunHours == null || derate == null) {
      setState(() {
        _annualProduction = null;
        _monthlyAverage = null;
        _dailyAverage = null;
      });
      return;
    }

    // Annual kWh = System kW × Sun Hours × 365 × Derate Factor
    final annual = systemKw * sunHours * 365 * derate;
    final monthly = annual / 12;
    final daily = annual / 365;

    setState(() {
      _annualProduction = annual;
      _monthlyAverage = monthly;
      _dailyAverage = daily;
    });
  }

  void _selectRegion(String region) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRegion = region;
      _sunHoursController.text = _regionSunHours[region]!.toString();
    });
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemSizeController.clear();
    _sunHoursController.text = '4.5';
    _derateFactor.text = '0.86';
    setState(() {
      _selectedRegion = 'Northeast';
      _annualProduction = null;
      _monthlyAverage = null;
      _dailyAverage = null;
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
        title: Text('Production Estimator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'REGION'),
              const SizedBox(height: 12),
              _buildRegionSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM PARAMETERS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'System Size',
                unit: 'kW',
                hint: 'DC capacity',
                controller: _systemSizeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Peak Sun Hours',
                unit: 'hrs/day',
                hint: 'Annual average',
                controller: _sunHoursController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Derate Factor',
                unit: '',
                hint: '0.80-0.90 typical',
                controller: _derateFactor,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_annualProduction != null) ...[
                _buildSectionHeader(colors, 'ESTIMATED PRODUCTION'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
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
            'Annual kWh = kW × Sun Hours × 365 × Derate',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Derate accounts for inverter, wiring, soiling losses',
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

  Widget _buildRegionSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _regionSunHours.keys.map((region) {
        final isSelected = region == _selectedRegion;
        return GestureDetector(
          onTap: () => _selectRegion(region),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              ),
            ),
            child: Column(
              children: [
                Text(
                  region,
                  style: TextStyle(
                    color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${_regionSunHours[region]} hrs',
                  style: TextStyle(
                    color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
          _buildResultRow(colors, 'Annual Production', '${_formatNumber(_annualProduction!)} kWh', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Monthly Average', '${_formatNumber(_monthlyAverage!)} kWh'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Daily Average', '${_dailyAverage!.toStringAsFixed(1)} kWh'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.leaf, size: 16, color: colors.accentSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Equivalent to ${(_annualProduction! * 0.0007).toStringAsFixed(1)} metric tons CO2 offset/year',
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
