import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// String Inverter Match Calculator - DC to AC ratio optimization
class StringInverterMatchScreen extends ConsumerStatefulWidget {
  const StringInverterMatchScreen({super.key});
  @override
  ConsumerState<StringInverterMatchScreen> createState() => _StringInverterMatchScreenState();
}

class _StringInverterMatchScreenState extends ConsumerState<StringInverterMatchScreen> {
  final _dcCapacityController = TextEditingController(text: '10');
  final _inverterRatingController = TextEditingController(text: '7.6');
  final _stringsController = TextEditingController(text: '2');
  final _modulesPerStringController = TextEditingController(text: '12');
  final _moduleWattsController = TextEditingController(text: '400');

  double? _dcAcRatio;
  double? _clippingRisk;
  String? _recommendation;
  String? _matchQuality;

  @override
  void dispose() {
    _dcCapacityController.dispose();
    _inverterRatingController.dispose();
    _stringsController.dispose();
    _modulesPerStringController.dispose();
    _moduleWattsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final inverterRating = double.tryParse(_inverterRatingController.text);
    final strings = int.tryParse(_stringsController.text);
    final modulesPerString = int.tryParse(_modulesPerStringController.text);
    final moduleWatts = double.tryParse(_moduleWattsController.text);

    if (inverterRating == null || strings == null || modulesPerString == null ||
        moduleWatts == null || inverterRating == 0) {
      setState(() {
        _dcAcRatio = null;
        _clippingRisk = null;
        _recommendation = null;
        _matchQuality = null;
      });
      return;
    }

    // Calculate DC capacity
    final dcCapacity = (strings * modulesPerString * moduleWatts) / 1000;
    _dcCapacityController.text = dcCapacity.toStringAsFixed(2);

    // DC/AC Ratio
    final dcAcRatio = dcCapacity / inverterRating;

    // Clipping risk estimate (simplified)
    double clippingRisk;
    if (dcAcRatio <= 1.0) {
      clippingRisk = 0;
    } else if (dcAcRatio <= 1.15) {
      clippingRisk = 1;
    } else if (dcAcRatio <= 1.25) {
      clippingRisk = 3;
    } else if (dcAcRatio <= 1.35) {
      clippingRisk = 5;
    } else {
      clippingRisk = 8 + (dcAcRatio - 1.35) * 20;
    }

    String matchQuality;
    String recommendation;
    if (dcAcRatio < 1.0) {
      matchQuality = 'Undersized';
      recommendation = 'Array too small for inverter. Add modules or use smaller inverter.';
    } else if (dcAcRatio <= 1.15) {
      matchQuality = 'Conservative';
      recommendation = 'Safe match with minimal clipping. Good for high-irradiance locations.';
    } else if (dcAcRatio <= 1.25) {
      matchQuality = 'Optimal';
      recommendation = 'Industry standard ratio. Best balance of cost and production.';
    } else if (dcAcRatio <= 1.35) {
      matchQuality = 'Aggressive';
      recommendation = 'Higher ratio OK for cloudy climates or east/west arrays.';
    } else {
      matchQuality = 'Excessive';
      recommendation = 'Too much DC capacity. Significant clipping losses expected.';
    }

    setState(() {
      _dcAcRatio = dcAcRatio;
      _clippingRisk = clippingRisk.clamp(0, 15);
      _recommendation = recommendation;
      _matchQuality = matchQuality;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _dcCapacityController.text = '10';
    _inverterRatingController.text = '7.6';
    _stringsController.text = '2';
    _modulesPerStringController.text = '12';
    _moduleWattsController.text = '400';
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
        title: Text('String Inverter Match', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ARRAY CONFIGURATION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Strings',
                      unit: '#',
                      hint: 'Parallel strings',
                      controller: _stringsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Modules/String',
                      unit: '#',
                      hint: 'Series modules',
                      controller: _modulesPerStringController,
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
                      label: 'Module Watts',
                      unit: 'W',
                      hint: 'STC rating',
                      controller: _moduleWattsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'DC Capacity',
                      unit: 'kW',
                      hint: 'Calculated',
                      controller: _dcCapacityController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INVERTER'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Inverter AC Rating',
                unit: 'kW',
                hint: 'Continuous output',
                controller: _inverterRatingController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_dcAcRatio != null) ...[
                _buildSectionHeader(colors, 'MATCH ANALYSIS'),
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
              Icon(LucideIcons.gitCompare, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Inverter Matching',
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
            'Optimize DC array size relative to inverter AC capacity',
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
    final isOptimal = _dcAcRatio! >= 1.15 && _dcAcRatio! <= 1.30;
    final accentColor = isOptimal ? colors.accentSuccess :
                        (_dcAcRatio! < 1.0 || _dcAcRatio! > 1.35) ? colors.accentWarning : colors.accentInfo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('DC/AC Ratio', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            _dcAcRatio!.toStringAsFixed(2),
            style: TextStyle(color: accentColor, fontSize: 44, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _matchQuality!,
              style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'DC Array', '${double.parse(_dcCapacityController.text).toStringAsFixed(2)} kW', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Est. Clipping', '${_clippingRisk!.toStringAsFixed(1)}%', colors.accentWarning),
              ),
            ],
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
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
          _buildGuideRow(colors, '< 1.00', 'Undersized array', colors.accentError),
          _buildGuideRow(colors, '1.00 - 1.15', 'Conservative', colors.accentInfo),
          _buildGuideRow(colors, '1.15 - 1.25', 'Optimal (typical)', colors.accentSuccess),
          _buildGuideRow(colors, '1.25 - 1.35', 'Aggressive', colors.accentWarning),
          _buildGuideRow(colors, '> 1.35', 'Excessive clipping', colors.accentError),
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
          const SizedBox(width: 12),
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
}
