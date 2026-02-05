import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Battery Inverter Sizing Calculator - Power output needs
class BatteryInverterSizingScreen extends ConsumerStatefulWidget {
  const BatteryInverterSizingScreen({super.key});
  @override
  ConsumerState<BatteryInverterSizingScreen> createState() => _BatteryInverterSizingScreenState();
}

class _BatteryInverterSizingScreenState extends ConsumerState<BatteryInverterSizingScreen> {
  final _continuousLoadController = TextEditingController(text: '5');
  final _peakLoadController = TextEditingController(text: '10');
  final _startupMultiplierController = TextEditingController(text: '3');

  double? _minContinuousRating;
  double? _minPeakRating;
  double? _recommendedRating;
  String? _recommendation;

  @override
  void dispose() {
    _continuousLoadController.dispose();
    _peakLoadController.dispose();
    _startupMultiplierController.dispose();
    super.dispose();
  }

  void _calculate() {
    final continuousLoad = double.tryParse(_continuousLoadController.text);
    final peakLoad = double.tryParse(_peakLoadController.text);
    final startupMultiplier = double.tryParse(_startupMultiplierController.text);

    if (continuousLoad == null || peakLoad == null || startupMultiplier == null) {
      setState(() {
        _minContinuousRating = null;
        _minPeakRating = null;
        _recommendedRating = null;
        _recommendation = null;
      });
      return;
    }

    // Continuous rating with 25% margin
    final minContinuousRating = continuousLoad * 1.25;

    // Peak/surge rating for motor startups
    final minPeakRating = peakLoad * startupMultiplier;

    // Use higher of continuous or peak/3 (since peak is usually 3x continuous rating)
    final recommendedRating = [minContinuousRating, minPeakRating / 3].reduce((a, b) => a > b ? a : b);

    String recommendation;
    if (recommendedRating <= 5) {
      recommendation = 'Small inverter (Tesla, Enphase, etc.) suitable.';
    } else if (recommendedRating <= 10) {
      recommendation = 'Mid-size inverter or multiple batteries recommended.';
    } else if (recommendedRating <= 15) {
      recommendation = 'Large system - consider stacked batteries or hybrid inverter.';
    } else {
      recommendation = 'Commercial-scale system may be needed.';
    }

    setState(() {
      _minContinuousRating = minContinuousRating;
      _minPeakRating = minPeakRating;
      _recommendedRating = recommendedRating;
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
    _continuousLoadController.text = '5';
    _peakLoadController.text = '10';
    _startupMultiplierController.text = '3';
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
        title: Text('Battery Inverter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD REQUIREMENTS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Continuous Load',
                      unit: 'kW',
                      hint: 'Running load',
                      controller: _continuousLoadController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Peak Load',
                      unit: 'kW',
                      hint: 'All loads on',
                      controller: _peakLoadController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Motor Startup Multiplier',
                unit: '×',
                hint: '3× typical',
                controller: _startupMultiplierController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_recommendedRating != null) ...[
                _buildSectionHeader(colors, 'INVERTER SIZING'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildCommonSystems(colors),
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
              Icon(LucideIcons.zap, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Battery Inverter Sizing',
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
            'Size inverter for continuous and peak power needs',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Recommended Inverter Rating', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_recommendedRating!.toStringAsFixed(1)} kW+',
            style: TextStyle(color: colors.accentSuccess, fontSize: 44, fontWeight: FontWeight.w700),
          ),
          Text(
            'continuous output',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Min Continuous', '${_minContinuousRating!.toStringAsFixed(1)} kW', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Peak/Surge', '${_minPeakRating!.toStringAsFixed(1)} kW', colors.accentWarning),
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

  Widget _buildCommonSystems(ZaftoColors colors) {
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
          Text('COMMON BATTERY INVERTERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildSystemRow(colors, 'Tesla Powerwall 3', '11.5 kW', '22 kW peak'),
          _buildSystemRow(colors, 'Enphase IQ 5P', '3.84 kW', '7.68 kW peak'),
          _buildSystemRow(colors, 'SolarEdge Home', '5-9.6 kW', 'Varies'),
          _buildSystemRow(colors, 'Generac PWRcell', '4.5-9 kW', '2x peak'),
          _buildSystemRow(colors, 'LG ESS', '5 kW', '7 kW peak'),
        ],
      ),
    );
  }

  Widget _buildSystemRow(ZaftoColors colors, String name, String continuous, String peak) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(name, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(continuous, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(peak, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
