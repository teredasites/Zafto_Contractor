import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Performance Ratio Calculator - System efficiency metric
class PerformanceRatioScreen extends ConsumerStatefulWidget {
  const PerformanceRatioScreen({super.key});
  @override
  ConsumerState<PerformanceRatioScreen> createState() => _PerformanceRatioScreenState();
}

class _PerformanceRatioScreenState extends ConsumerState<PerformanceRatioScreen> {
  final _actualYieldController = TextEditingController();
  final _referenceYieldController = TextEditingController();

  double? _performanceRatio;
  String? _rating;
  double? _lossPercent;

  @override
  void dispose() {
    _actualYieldController.dispose();
    _referenceYieldController.dispose();
    super.dispose();
  }

  void _calculate() {
    final actual = double.tryParse(_actualYieldController.text);
    final reference = double.tryParse(_referenceYieldController.text);

    if (actual == null || reference == null || reference <= 0) {
      setState(() {
        _performanceRatio = null;
        _rating = null;
        _lossPercent = null;
      });
      return;
    }

    // PR = Actual Yield / Reference Yield × 100
    final pr = (actual / reference) * 100;
    final losses = 100 - pr;

    // Rating
    String rating;
    if (pr >= 85) {
      rating = 'Excellent';
    } else if (pr >= 80) {
      rating = 'Very Good';
    } else if (pr >= 75) {
      rating = 'Good';
    } else if (pr >= 70) {
      rating = 'Fair';
    } else {
      rating = 'Poor - Needs Investigation';
    }

    setState(() {
      _performanceRatio = pr;
      _rating = rating;
      _lossPercent = losses;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _actualYieldController.clear();
    _referenceYieldController.clear();
    setState(() {
      _performanceRatio = null;
      _rating = null;
      _lossPercent = null;
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
        title: Text('Performance Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'YIELD DATA'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Actual Yield',
                unit: 'kWh',
                hint: 'Measured production',
                controller: _actualYieldController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Reference Yield',
                unit: 'kWh',
                hint: 'Theoretical max (from irradiance)',
                controller: _referenceYieldController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 16),
              _buildInfoBox(colors),
              const SizedBox(height: 32),
              if (_performanceRatio != null) ...[
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
            'PR = Actual Yield / Reference Yield × 100',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quality factor independent of location/irradiance',
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

  Widget _buildInfoBox(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reference Yield = (POA Irradiance × System Size) / 1000\nFrom weather station or satellite data',
              style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final pr = _performanceRatio!;
    final ratingColor = pr >= 80
        ? colors.accentSuccess
        : pr >= 75
            ? colors.accentPrimary
            : pr >= 70
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
          // Main result gauge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ratingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${pr.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: ratingColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Performance Ratio',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'System Losses', '${_lossPercent!.toStringAsFixed(1)}%'),
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
                  pr >= 75 ? LucideIcons.checkCircle : LucideIcons.alertCircle,
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
          _buildLossBreakdown(colors),
        ],
      ),
    );
  }

  Widget _buildLossBreakdown(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Typical Loss Sources', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildLossRow(colors, 'Temperature', '3-8%'),
          _buildLossRow(colors, 'Inverter', '2-4%'),
          _buildLossRow(colors, 'Wiring/Mismatch', '1-3%'),
          _buildLossRow(colors, 'Soiling', '1-5%'),
          _buildLossRow(colors, 'Shading', '0-10%'),
          _buildLossRow(colors, 'Availability', '0-2%'),
          const Divider(height: 16),
          _buildLossRow(colors, 'Typical Total', '10-25%', isBold: true),
        ],
      ),
    );
  }

  Widget _buildLossRow(ZaftoColors colors, String source, String range, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(source, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
          Text(range, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: isBold ? FontWeight.w600 : FontWeight.w500)),
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
