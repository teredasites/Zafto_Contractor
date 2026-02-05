import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// DC/AC Ratio Calculator - Optimal inverter loading
class DcAcRatioScreen extends ConsumerStatefulWidget {
  const DcAcRatioScreen({super.key});
  @override
  ConsumerState<DcAcRatioScreen> createState() => _DcAcRatioScreenState();
}

class _DcAcRatioScreenState extends ConsumerState<DcAcRatioScreen> {
  final _dcCapacityController = TextEditingController();
  final _acCapacityController = TextEditingController();

  double? _dcAcRatio;
  String? _recommendation;
  double? _clippingEstimate;

  @override
  void dispose() {
    _dcCapacityController.dispose();
    _acCapacityController.dispose();
    super.dispose();
  }

  void _calculate() {
    final dcKw = double.tryParse(_dcCapacityController.text);
    final acKw = double.tryParse(_acCapacityController.text);

    if (dcKw == null || acKw == null || acKw <= 0) {
      setState(() {
        _dcAcRatio = null;
        _recommendation = null;
        _clippingEstimate = null;
      });
      return;
    }

    final ratio = dcKw / acKw;

    // Estimate annual clipping losses based on ratio
    double clipping;
    String rec;
    if (ratio < 1.0) {
      clipping = 0;
      rec = 'Undersized - Add more panels';
    } else if (ratio <= 1.15) {
      clipping = 0;
      rec = 'Conservative - No clipping';
    } else if (ratio <= 1.25) {
      clipping = 0.5;
      rec = 'Optimal - Minimal clipping';
    } else if (ratio <= 1.35) {
      clipping = 1.5;
      rec = 'Aggressive - Some clipping';
    } else if (ratio <= 1.50) {
      clipping = 3.0;
      rec = 'High - Moderate clipping';
    } else {
      clipping = 5.0 + (ratio - 1.5) * 5;
      rec = 'Very High - Significant clipping';
    }

    setState(() {
      _dcAcRatio = ratio;
      _recommendation = rec;
      _clippingEstimate = clipping;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _dcCapacityController.clear();
    _acCapacityController.clear();
    setState(() {
      _dcAcRatio = null;
      _recommendation = null;
      _clippingEstimate = null;
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
        title: Text('DC/AC Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM CAPACITIES'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'DC Array Size',
                unit: 'kWp',
                hint: 'Total panel capacity',
                controller: _dcCapacityController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Inverter AC Rating',
                unit: 'kW',
                hint: 'Inverter output capacity',
                controller: _acCapacityController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_dcAcRatio != null) ...[
                _buildSectionHeader(colors, 'RESULTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildRatioGuide(colors),
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
            'DC/AC Ratio = DC kWp / AC kW',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Typical range: 1.10 - 1.35 (varies by climate)',
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
    final ratio = _dcAcRatio!;
    final ratingColor = ratio >= 1.10 && ratio <= 1.35
        ? colors.accentSuccess
        : ratio < 1.10
            ? colors.accentWarning
            : ratio <= 1.50
                ? colors.accentPrimary
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
          _buildResultRow(colors, 'DC/AC Ratio', '${ratio.toStringAsFixed(2)}', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Est. Annual Clipping', '${_clippingEstimate!.toStringAsFixed(1)}%'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ratingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  ratio >= 1.10 && ratio <= 1.35 ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                  size: 18,
                  color: ratingColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
                    style: TextStyle(
                      color: ratingColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DC/AC RATIO GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildGuideRow(colors, '< 1.10', 'Undersized array', colors.accentWarning),
          _buildGuideRow(colors, '1.10 - 1.20', 'Conservative (cloudy climates)', colors.accentSuccess),
          _buildGuideRow(colors, '1.20 - 1.30', 'Optimal (most locations)', colors.accentSuccess),
          _buildGuideRow(colors, '1.30 - 1.40', 'Aggressive (sunny climates)', colors.accentPrimary),
          _buildGuideRow(colors, '> 1.40', 'High clipping risk', colors.accentError),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.lightbulb, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Higher ratios maximize morning/evening production but clip midday peaks. Optimal ratio depends on local irradiance profile.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(ZaftoColors colors, String ratio, String description, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(ratio, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
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
            fontSize: isPrimary ? 28 : 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
