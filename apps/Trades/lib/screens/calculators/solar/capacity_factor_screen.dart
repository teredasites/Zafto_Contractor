import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Capacity Factor Calculator - Actual vs rated output
class CapacityFactorScreen extends ConsumerStatefulWidget {
  const CapacityFactorScreen({super.key});
  @override
  ConsumerState<CapacityFactorScreen> createState() => _CapacityFactorScreenState();
}

class _CapacityFactorScreenState extends ConsumerState<CapacityFactorScreen> {
  final _actualProductionController = TextEditingController();
  final _systemSizeController = TextEditingController();
  final _periodController = TextEditingController(text: '8760'); // hours in year

  double? _capacityFactor;
  double? _equivalentHours;
  String? _rating;

  @override
  void dispose() {
    _actualProductionController.dispose();
    _systemSizeController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _calculate() {
    final actual = double.tryParse(_actualProductionController.text);
    final systemKw = double.tryParse(_systemSizeController.text);
    final hours = double.tryParse(_periodController.text);

    if (actual == null || systemKw == null || hours == null || systemKw <= 0 || hours <= 0) {
      setState(() {
        _capacityFactor = null;
        _equivalentHours = null;
        _rating = null;
      });
      return;
    }

    // Maximum possible production = System kW × Hours
    final maxPossible = systemKw * hours;

    // Capacity Factor = Actual / Maximum × 100
    final cf = (actual / maxPossible) * 100;

    // Equivalent full-load hours
    final equivHours = actual / systemKw;

    // Rating
    String rating;
    if (cf >= 20) {
      rating = 'Excellent';
    } else if (cf >= 17) {
      rating = 'Good';
    } else if (cf >= 14) {
      rating = 'Average';
    } else if (cf >= 10) {
      rating = 'Below Average';
    } else {
      rating = 'Poor - Check System';
    }

    setState(() {
      _capacityFactor = cf;
      _equivalentHours = equivHours;
      _rating = rating;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _actualProductionController.clear();
    _systemSizeController.clear();
    _periodController.text = '8760';
    setState(() {
      _capacityFactor = null;
      _equivalentHours = null;
      _rating = null;
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
        title: Text('Capacity Factor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM DATA'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Actual Production',
                unit: 'kWh',
                hint: 'Metered output',
                controller: _actualProductionController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'System Size',
                unit: 'kW',
                hint: 'DC nameplate',
                controller: _systemSizeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Time Period',
                unit: 'hours',
                hint: '8760 = 1 year',
                controller: _periodController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              _buildPeriodPresets(colors),
              const SizedBox(height: 32),
              if (_capacityFactor != null) ...[
                _buildSectionHeader(colors, 'RESULTS'),
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
            'CF = Actual kWh / (kW × Hours) × 100',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'US residential solar: typically 15-20%',
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

  Widget _buildPeriodPresets(ZaftoColors colors) {
    final presets = {'Month': 730, 'Quarter': 2190, 'Year': 8760};
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
          Text('Quick Periods', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: presets.entries.map((e) {
              final isSelected = _periodController.text == e.value.toString();
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key != 'Year' ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _periodController.text = e.value.toString();
                      _calculate();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.fillDefault,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.key,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
    final cf = _capacityFactor!;
    final ratingColor = cf >= 17
        ? colors.accentSuccess
        : cf >= 14
            ? colors.accentPrimary
            : cf >= 10
                ? colors.accentWarning
                : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ratingColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Capacity Factor', '${cf.toStringAsFixed(1)}%', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Equivalent Full-Load Hours', '${_equivalentHours!.toStringAsFixed(0)} hrs'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ratingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cf >= 14 ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                  size: 18,
                  color: ratingColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _rating!,
                  style: TextStyle(
                    color: ratingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildBenchmarks(colors),
        ],
      ),
    );
  }

  Widget _buildBenchmarks(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Regional Benchmarks', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildBenchmarkRow(colors, 'Southwest US', '20-25%'),
          _buildBenchmarkRow(colors, 'Southeast US', '15-18%'),
          _buildBenchmarkRow(colors, 'Northeast US', '12-16%'),
          _buildBenchmarkRow(colors, 'Northwest US', '10-14%'),
        ],
      ),
    );
  }

  Widget _buildBenchmarkRow(ZaftoColors colors, String region, String range) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(region, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text(range, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
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
            fontSize: isPrimary ? 24 : 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
