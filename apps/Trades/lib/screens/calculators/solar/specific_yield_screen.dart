import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Specific Yield Calculator - kWh per kWp
class SpecificYieldScreen extends ConsumerStatefulWidget {
  const SpecificYieldScreen({super.key});
  @override
  ConsumerState<SpecificYieldScreen> createState() => _SpecificYieldScreenState();
}

class _SpecificYieldScreenState extends ConsumerState<SpecificYieldScreen> {
  final _annualProductionController = TextEditingController();
  final _systemSizeController = TextEditingController();

  double? _specificYield;
  String? _rating;
  double? _equivalentSunHours;

  @override
  void dispose() {
    _annualProductionController.dispose();
    _systemSizeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final production = double.tryParse(_annualProductionController.text);
    final systemKwp = double.tryParse(_systemSizeController.text);

    if (production == null || systemKwp == null || systemKwp <= 0) {
      setState(() {
        _specificYield = null;
        _rating = null;
        _equivalentSunHours = null;
      });
      return;
    }

    // Specific Yield = Annual kWh / kWp
    final sy = production / systemKwp;

    // Equivalent daily sun hours = SY / 365
    final dailySun = sy / 365;

    // Rating based on US benchmarks
    String rating;
    if (sy >= 1600) {
      rating = 'Excellent (Southwest)';
    } else if (sy >= 1400) {
      rating = 'Very Good';
    } else if (sy >= 1200) {
      rating = 'Good (Average US)';
    } else if (sy >= 1000) {
      rating = 'Below Average';
    } else {
      rating = 'Poor - Investigate';
    }

    setState(() {
      _specificYield = sy;
      _rating = rating;
      _equivalentSunHours = dailySun;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _annualProductionController.clear();
    _systemSizeController.clear();
    setState(() {
      _specificYield = null;
      _rating = null;
      _equivalentSunHours = null;
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
        title: Text('Specific Yield', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                label: 'Annual Production',
                unit: 'kWh',
                hint: 'Total yearly output',
                controller: _annualProductionController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'System Size',
                unit: 'kWp',
                hint: 'DC nameplate rating',
                controller: _systemSizeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_specificYield != null) ...[
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
            'Specific Yield = Annual kWh / kWp',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Energy produced per unit of installed capacity',
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

  Widget _buildResultsCard(ZaftoColors colors) {
    final sy = _specificYield!;
    final ratingColor = sy >= 1400
        ? colors.accentSuccess
        : sy >= 1200
            ? colors.accentPrimary
            : sy >= 1000
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
          // Main result
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ratingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${sy.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: ratingColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'kWh/kWp/year',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'Equivalent Sun Hours', '${_equivalentSunHours!.toStringAsFixed(1)} hrs/day'),
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
                  sy >= 1200 ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                  size: 18,
                  color: ratingColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _rating!,
                  style: TextStyle(
                    color: ratingColor,
                    fontSize: 14,
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
          Text('US Regional Benchmarks', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildBenchmarkRow(colors, 'Arizona/Nevada', '1,700-1,900'),
          _buildBenchmarkRow(colors, 'California', '1,500-1,700'),
          _buildBenchmarkRow(colors, 'Texas/Florida', '1,400-1,600'),
          _buildBenchmarkRow(colors, 'Midwest', '1,200-1,400'),
          _buildBenchmarkRow(colors, 'Northeast', '1,100-1,300'),
          _buildBenchmarkRow(colors, 'Pacific NW', '1,000-1,200'),
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

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
