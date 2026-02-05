import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Solar Fraction Calculator - % of usage covered by solar
class SolarFractionScreen extends ConsumerStatefulWidget {
  const SolarFractionScreen({super.key});
  @override
  ConsumerState<SolarFractionScreen> createState() => _SolarFractionScreenState();
}

class _SolarFractionScreenState extends ConsumerState<SolarFractionScreen> {
  final _annualUsageController = TextEditingController();
  final _solarProductionController = TextEditingController();

  double? _solarFraction;
  double? _gridUsage;
  double? _excessProduction;

  @override
  void dispose() {
    _annualUsageController.dispose();
    _solarProductionController.dispose();
    super.dispose();
  }

  void _calculate() {
    final usage = double.tryParse(_annualUsageController.text);
    final production = double.tryParse(_solarProductionController.text);

    if (usage == null || production == null || usage <= 0) {
      setState(() {
        _solarFraction = null;
        _gridUsage = null;
        _excessProduction = null;
      });
      return;
    }

    final fraction = (production / usage) * 100;
    final grid = usage - production;
    final excess = production > usage ? production - usage : 0.0;

    setState(() {
      _solarFraction = fraction;
      _gridUsage = grid > 0 ? grid : 0;
      _excessProduction = excess;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _annualUsageController.clear();
    _solarProductionController.clear();
    setState(() {
      _solarFraction = null;
      _gridUsage = null;
      _excessProduction = null;
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
        title: Text('Solar Fraction', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ENERGY VALUES'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Annual Usage',
                unit: 'kWh',
                hint: 'Total consumption',
                controller: _annualUsageController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Solar Production',
                unit: 'kWh',
                hint: 'Expected or actual',
                controller: _solarProductionController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_solarFraction != null) ...[
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
            'Solar Fraction = Production / Usage × 100',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Percentage of energy needs met by solar',
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
    final fraction = _solarFraction!;
    final isOver100 = fraction > 100;
    final coverageColor = fraction >= 100
        ? colors.accentSuccess
        : fraction >= 75
            ? colors.accentPrimary
            : fraction >= 50
                ? colors.accentWarning
                : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: coverageColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Large percentage display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: coverageColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${fraction.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: coverageColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isOver100 ? 'Net Producer' : 'Solar Coverage',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_gridUsage! > 0)
            _buildResultRow(colors, 'Still from Grid', '${_formatNumber(_gridUsage!)} kWh/yr'),
          if (_excessProduction! > 0) ...[
            const SizedBox(height: 12),
            _buildResultRow(colors, 'Excess for Net Metering', '${_formatNumber(_excessProduction!)} kWh/yr'),
          ],
          const SizedBox(height: 16),
          _buildCoverageBar(colors, fraction.clamp(0, 150)),
        ],
      ),
    );
  }

  Widget _buildCoverageBar(ZaftoColors colors, double fraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Coverage', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            Text('${fraction.toStringAsFixed(0)}%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (fraction / 100).clamp(0, 1.5),
            minHeight: 8,
            backgroundColor: colors.fillDefault,
            valueColor: AlwaysStoppedAnimation(
              fraction >= 100 ? colors.accentSuccess : colors.accentPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
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
