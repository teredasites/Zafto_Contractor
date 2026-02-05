import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shade Analysis Calculator - Manual shade input for production loss estimate
class ShadeAnalysisScreen extends ConsumerStatefulWidget {
  const ShadeAnalysisScreen({super.key});
  @override
  ConsumerState<ShadeAnalysisScreen> createState() => _ShadeAnalysisScreenState();
}

class _ShadeAnalysisScreenState extends ConsumerState<ShadeAnalysisScreen> {
  // Shade percentages by time period (morning, midday, afternoon)
  double _morningShadeFactor = 1.0; // 1.0 = no shade
  double _middayShadeFactor = 1.0;
  double _afternoonShadeFactor = 1.0;

  // Seasonal weighting
  bool _winterShadeWorse = false;

  double? _totalShadeLoss;
  double? _effectiveProduction;
  String? _recommendation;

  void _calculate() {
    // Weight factors: midday is most important (highest irradiance)
    const morningWeight = 0.25;
    const middayWeight = 0.50;
    const afternoonWeight = 0.25;

    final avgShadeFactor = (_morningShadeFactor * morningWeight) +
        (_middayShadeFactor * middayWeight) +
        (_afternoonShadeFactor * afternoonWeight);

    // Winter shade penalty (solar path is lower)
    final seasonalFactor = _winterShadeWorse ? 0.95 : 1.0;

    final effectiveFactor = avgShadeFactor * seasonalFactor;
    final loss = (1 - effectiveFactor) * 100;

    String recommendation;
    if (loss <= 5) {
      recommendation = 'Excellent site - minimal shade impact';
    } else if (loss <= 10) {
      recommendation = 'Good site - consider microinverters';
    } else if (loss <= 20) {
      recommendation = 'Fair site - use optimizers or microinverters';
    } else if (loss <= 30) {
      recommendation = 'Marginal site - tree trimming recommended';
    } else {
      recommendation = 'Poor site - significant shading issues';
    }

    setState(() {
      _totalShadeLoss = loss;
      _effectiveProduction = effectiveFactor * 100;
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
    setState(() {
      _morningShadeFactor = 1.0;
      _middayShadeFactor = 1.0;
      _afternoonShadeFactor = 1.0;
      _winterShadeWorse = false;
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
        title: Text('Shade Analysis', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SHADE BY TIME OF DAY'),
              const SizedBox(height: 12),
              _buildShadeSlider(colors, 'Morning (7-10 AM)', _morningShadeFactor, (v) {
                setState(() => _morningShadeFactor = v);
                _calculate();
              }, LucideIcons.sunrise),
              const SizedBox(height: 12),
              _buildShadeSlider(colors, 'Midday (10 AM - 2 PM)', _middayShadeFactor, (v) {
                setState(() => _middayShadeFactor = v);
                _calculate();
              }, LucideIcons.sun),
              const SizedBox(height: 12),
              _buildShadeSlider(colors, 'Afternoon (2-5 PM)', _afternoonShadeFactor, (v) {
                setState(() => _afternoonShadeFactor = v);
                _calculate();
              }, LucideIcons.sunset),
              const SizedBox(height: 16),
              _buildWinterToggle(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SHADE IMPACT'),
              const SizedBox(height: 12),
              _buildResultsCard(colors),
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
              Icon(LucideIcons.treePine, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Manual Shade Assessment',
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
            'Estimate shading from trees, buildings, or other obstructions',
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

  Widget _buildShadeSlider(ZaftoColors colors, String label, double value, ValueChanged<double> onChanged, IconData icon) {
    final shadePercent = ((1 - value) * 100).round();
    final shadeColor = shadePercent <= 10
        ? colors.accentSuccess
        : shadePercent <= 25
            ? colors.accentWarning
            : colors.accentError;

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
          Row(
            children: [
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: shadeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$shadePercent% shaded',
                  style: TextStyle(color: shadeColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: shadeColor,
              inactiveTrackColor: colors.fillDefault,
              thumbColor: shadeColor,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('100% shaded', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              Text('No shade', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinterToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.snowflake, size: 18, color: colors.accentInfo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Winter Shade Worse', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                Text('Lower sun angle increases obstruction', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _winterShadeWorse,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _winterShadeWorse = v);
              _calculate();
            },
            activeColor: colors.accentInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final loss = _totalShadeLoss!;
    final ratingColor = loss <= 10
        ? colors.accentSuccess
        : loss <= 20
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
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Shade Loss', '${loss.toStringAsFixed(1)}%', ratingColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Effective', '${_effectiveProduction!.toStringAsFixed(1)}%', colors.accentSuccess),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ratingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  loss <= 20 ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  size: 18,
                  color: ratingColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
                    style: TextStyle(color: ratingColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildMitigationTips(colors),
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMitigationTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SHADE MITIGATION OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildTipRow(colors, 'Microinverters', 'Each panel operates independently'),
          _buildTipRow(colors, 'Power Optimizers', 'DC-DC optimization per panel'),
          _buildTipRow(colors, 'Tree Trimming', 'Remove or reduce obstructions'),
          _buildTipRow(colors, 'Panel Placement', 'Avoid shaded roof areas'),
        ],
      ),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.chevronRight, size: 12, color: colors.accentPrimary),
          const SizedBox(width: 4),
          Text('$title: ', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}
