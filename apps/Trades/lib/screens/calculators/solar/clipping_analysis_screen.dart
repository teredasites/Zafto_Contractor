import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Clipping Analysis Calculator - DC vs AC output and energy loss
class ClippingAnalysisScreen extends ConsumerStatefulWidget {
  const ClippingAnalysisScreen({super.key});
  @override
  ConsumerState<ClippingAnalysisScreen> createState() => _ClippingAnalysisScreenState();
}

class _ClippingAnalysisScreenState extends ConsumerState<ClippingAnalysisScreen> {
  final _arrayDcKwController = TextEditingController(text: '12.0');
  final _inverterAcKwController = TextEditingController(text: '10.0');
  final _peakSunHoursController = TextEditingController(text: '4.5');

  double? _dcAcRatio;
  double? _clippingPercent;
  double? _annualClippingLoss;
  double? _actualProduction;
  String? _recommendation;

  @override
  void dispose() {
    _arrayDcKwController.dispose();
    _inverterAcKwController.dispose();
    _peakSunHoursController.dispose();
    super.dispose();
  }

  void _calculate() {
    final arrayDcKw = double.tryParse(_arrayDcKwController.text);
    final inverterAcKw = double.tryParse(_inverterAcKwController.text);
    final peakSunHours = double.tryParse(_peakSunHoursController.text);

    if (arrayDcKw == null || inverterAcKw == null || peakSunHours == null || inverterAcKw == 0) {
      setState(() {
        _dcAcRatio = null;
        _clippingPercent = null;
        _annualClippingLoss = null;
        _actualProduction = null;
        _recommendation = null;
      });
      return;
    }

    final dcAcRatio = arrayDcKw / inverterAcKw;

    // Clipping loss estimation (simplified model)
    // Real clipping depends on irradiance distribution
    double clippingPercent;
    if (dcAcRatio <= 1.0) {
      clippingPercent = 0;
    } else if (dcAcRatio <= 1.1) {
      clippingPercent = 0.2;
    } else if (dcAcRatio <= 1.15) {
      clippingPercent = 0.5;
    } else if (dcAcRatio <= 1.2) {
      clippingPercent = 1.0;
    } else if (dcAcRatio <= 1.25) {
      clippingPercent = 1.8;
    } else if (dcAcRatio <= 1.3) {
      clippingPercent = 2.8;
    } else if (dcAcRatio <= 1.35) {
      clippingPercent = 4.0;
    } else if (dcAcRatio <= 1.4) {
      clippingPercent = 5.5;
    } else {
      clippingPercent = 7.0 + (dcAcRatio - 1.4) * 10;
    }

    // Annual production estimates
    final theoreticalAnnual = arrayDcKw * peakSunHours * 365 * 0.85; // 85% system efficiency
    final clippingLossKwh = theoreticalAnnual * clippingPercent / 100;
    final actualProduction = theoreticalAnnual - clippingLossKwh;

    String recommendation;
    if (dcAcRatio < 1.1) {
      recommendation = 'Array undersized relative to inverter';
    } else if (dcAcRatio <= 1.2) {
      recommendation = 'Optimal range - minimal clipping';
    } else if (dcAcRatio <= 1.3) {
      recommendation = 'Acceptable - good for cloudy climates';
    } else if (dcAcRatio <= 1.4) {
      recommendation = 'High ratio - verify ROI on extra panels';
    } else {
      recommendation = 'Very high - significant energy loss';
    }

    setState(() {
      _dcAcRatio = dcAcRatio;
      _clippingPercent = clippingPercent;
      _annualClippingLoss = clippingLossKwh;
      _actualProduction = actualProduction;
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
    _arrayDcKwController.text = '12.0';
    _inverterAcKwController.text = '10.0';
    _peakSunHoursController.text = '4.5';
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
        title: Text('Clipping Analysis', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM CONFIGURATION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Array DC',
                      unit: 'kW',
                      hint: 'Total modules',
                      controller: _arrayDcKwController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Inverter AC',
                      unit: 'kW',
                      hint: 'Rated output',
                      controller: _inverterAcKwController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Peak Sun Hours',
                unit: 'hrs/day',
                hint: 'Annual average',
                controller: _peakSunHoursController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_dcAcRatio != null) ...[
                _buildSectionHeader(colors, 'CLIPPING IMPACT'),
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
          Text(
            'Clipping = DC power exceeding AC capacity',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyze energy loss when array oversized vs inverter',
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
    final clipping = _clippingPercent!;
    final isAcceptable = clipping <= 3.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isAcceptable ? colors.accentSuccess : colors.accentWarning).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'DC:AC Ratio', '${_dcAcRatio!.toStringAsFixed(2)}', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Clipping Loss', '${clipping.toStringAsFixed(1)}%', isAcceptable ? colors.accentSuccess : colors.accentWarning),
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
                _buildResultRow(colors, 'Annual Clipping Loss', '${(_annualClippingLoss! / 1000).toStringAsFixed(0)} kWh'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Expected Production', '${(_actualProduction! / 1000).toStringAsFixed(0)} kWh/yr'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isAcceptable ? colors.accentSuccess : colors.accentWarning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isAcceptable ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  size: 18,
                  color: isAcceptable ? colors.accentSuccess : colors.accentWarning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
                    style: TextStyle(
                      color: isAcceptable ? colors.accentSuccess : colors.accentWarning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildClippingVisual(colors),
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.w700)),
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

  Widget _buildClippingVisual(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('DC:AC RATIO GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRatioChip(colors, '1.0', 'Undersized', colors.accentInfo),
              _buildRatioChip(colors, '1.1-1.2', 'Optimal', colors.accentSuccess),
              _buildRatioChip(colors, '1.3+', 'Aggressive', colors.accentWarning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioChip(ZaftoColors colors, String ratio, String label, Color accentColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(ratio, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
