import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Area Requirement Calculator - Sq ft needed for target kW
class RoofAreaScreen extends ConsumerStatefulWidget {
  const RoofAreaScreen({super.key});
  @override
  ConsumerState<RoofAreaScreen> createState() => _RoofAreaScreenState();
}

class _RoofAreaScreenState extends ConsumerState<RoofAreaScreen> {
  final _systemSizeController = TextEditingController();
  final _panelWattageController = TextEditingController(text: '400');

  int _roofPitch = 4; // 4:12 pitch
  bool _includeSetbacks = true;

  double? _minArea;
  double? _withSetbacks;
  int? _panelCount;

  // Standard 400W panel: ~21.5 sq ft
  static const double _panelAreaSqFt = 21.5;

  // Pitch multipliers (rise:12)
  static const Map<int, double> _pitchMultipliers = {
    0: 1.000, 2: 1.014, 3: 1.031, 4: 1.054,
    5: 1.083, 6: 1.118, 7: 1.158, 8: 1.202,
    9: 1.250, 10: 1.302, 11: 1.357, 12: 1.414,
  };

  @override
  void dispose() {
    _systemSizeController.dispose();
    _panelWattageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemKw = double.tryParse(_systemSizeController.text);
    final panelWatts = double.tryParse(_panelWattageController.text);

    if (systemKw == null || panelWatts == null || panelWatts <= 0) {
      setState(() {
        _minArea = null;
        _withSetbacks = null;
        _panelCount = null;
      });
      return;
    }

    final systemWatts = systemKw * 1000;
    final panels = (systemWatts / panelWatts).ceil();
    final pitchMult = _pitchMultipliers[_roofPitch] ?? 1.054;

    // Base area needed
    final baseArea = panels * _panelAreaSqFt;

    // Adjust for roof pitch (actual roof surface area)
    final pitchAdjusted = baseArea * pitchMult;

    // Add setbacks (typically 3ft from edges, ridge, valleys)
    // Rough estimate: add 30% for setbacks and spacing
    final withSetbacks = _includeSetbacks ? pitchAdjusted * 1.3 : pitchAdjusted;

    setState(() {
      _panelCount = panels;
      _minArea = pitchAdjusted;
      _withSetbacks = withSetbacks;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemSizeController.clear();
    _panelWattageController.text = '400';
    setState(() {
      _roofPitch = 4;
      _includeSetbacks = true;
      _minArea = null;
      _withSetbacks = null;
      _panelCount = null;
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
        title: Text('Roof Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INPUTS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Target System Size',
                unit: 'kW',
                hint: 'Desired DC capacity',
                controller: _systemSizeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Panel Wattage',
                unit: 'W',
                hint: 'Per module rating',
                controller: _panelWattageController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              _buildPitchSelector(colors),
              const SizedBox(height: 12),
              _buildSetbacksToggle(colors),
              const SizedBox(height: 32),
              if (_minArea != null) ...[
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
            'Area = Panels × Panel Size × Pitch Factor',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Includes NEC 690.12 fire setback requirements',
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

  Widget _buildPitchSelector(ZaftoColors colors) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Roof Pitch', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              Text('$_roofPitch:12', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.fillDefault,
              thumbColor: colors.accentPrimary,
            ),
            child: Slider(
              value: _roofPitch.toDouble(),
              min: 0,
              max: 12,
              divisions: 12,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _roofPitch = v.round());
                _calculate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetbacksToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Include Fire Setbacks', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              Text('NEC 690.12 pathways', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            ],
          ),
          Switch(
            value: _includeSetbacks,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _includeSetbacks = v);
              _calculate();
            },
            activeColor: colors.accentPrimary,
          ),
        ],
      ),
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
          _buildResultRow(colors, 'Required Roof Area', '${_withSetbacks!.toStringAsFixed(0)} sq ft', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Panel Footprint Only', '${_minArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Number of Panels', '$_panelCount modules'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Pitch Multiplier', '${(_pitchMultipliers[_roofPitch] ?? 1.0).toStringAsFixed(3)}x'),
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
            fontSize: isPrimary ? 20 : 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
