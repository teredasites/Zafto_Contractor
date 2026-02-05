import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Advanced Derating Calculator - Design System v2.6
/// Multiple derating factors combined per NEC 310.15
class DeratingAdvancedScreen extends ConsumerStatefulWidget {
  const DeratingAdvancedScreen({super.key});
  @override
  ConsumerState<DeratingAdvancedScreen> createState() => _DeratingAdvancedScreenState();
}

class _DeratingAdvancedScreenState extends ConsumerState<DeratingAdvancedScreen> {
  double _baseAmpacity = 30;
  int _ambientTempC = 30;
  int _conductorsInConduit = 3;
  bool _continuousLoad = false;
  bool _rooftopInstallation = false;
  double _rooftopDistanceInches = 7;

  // NEC Table 310.15(B)(1) - Temperature correction factors
  static const Map<int, Map<String, double>> _tempCorrectionFactors = {
    // Ambient temp °C: {insulation temp rating: factor}
    21: {'60': 1.08, '75': 1.05, '90': 1.04},
    26: {'60': 1.00, '75': 1.00, '90': 1.00},
    30: {'60': 0.91, '75': 0.94, '90': 0.96},
    35: {'60': 0.82, '75': 0.88, '90': 0.91},
    40: {'60': 0.71, '75': 0.82, '90': 0.87},
    45: {'60': 0.58, '75': 0.75, '90': 0.82},
    50: {'60': 0.41, '75': 0.67, '90': 0.76},
    55: {'60': 0.00, '75': 0.58, '90': 0.71},
    60: {'60': 0.00, '75': 0.47, '90': 0.65},
  };

  // NEC Table 310.15(C)(1) - Conduit fill adjustment
  static const Map<int, double> _conduitFillFactors = {
    3: 1.00,  // 1-3 conductors
    6: 0.80,  // 4-6 conductors
    9: 0.70,  // 7-9 conductors
    20: 0.50, // 10-20 conductors
    30: 0.45, // 21-30 conductors
    40: 0.40, // 31-40 conductors
    41: 0.35, // 41+ conductors
  };

  // NEC Table 310.15(B)(3)(c) - Rooftop temperature adders
  static final Map<double, int> _rooftopTempAdders = {
    0.5: 60,   // 0-0.5" above roof
    3.5: 40,   // 0.5-3.5" above roof
    12.0: 30,  // 3.5-12" above roof
    36.0: 25,  // 12-36" above roof
  };

  double get _tempCorrectionFactor {
    int closestTemp = 26;
    for (final temp in _tempCorrectionFactors.keys) {
      if (_effectiveAmbient >= temp) closestTemp = temp;
    }
    // Using 75°C insulation as default
    return _tempCorrectionFactors[closestTemp]?['75'] ?? 1.0;
  }

  int get _rooftopTempAdder {
    if (!_rooftopInstallation) return 0;
    for (final entry in _rooftopTempAdders.entries) {
      if (_rooftopDistanceInches <= entry.key) return entry.value;
    }
    return 0;
  }

  int get _effectiveAmbient => _ambientTempC + (_rooftopInstallation ? _rooftopTempAdder : 0);

  double get _conduitFillFactor {
    if (_conductorsInConduit <= 3) return 1.0;
    if (_conductorsInConduit <= 6) return 0.80;
    if (_conductorsInConduit <= 9) return 0.70;
    if (_conductorsInConduit <= 20) return 0.50;
    if (_conductorsInConduit <= 30) return 0.45;
    if (_conductorsInConduit <= 40) return 0.40;
    return 0.35;
  }

  double get _continuousLoadFactor => _continuousLoad ? 0.80 : 1.0; // 125% rule inverted

  double get _combinedFactor => _tempCorrectionFactor * _conduitFillFactor * _continuousLoadFactor;

  double get _deratedAmpacity => _baseAmpacity * _combinedFactor;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Advanced Derating', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBaseAmpacityCard(colors),
          const SizedBox(height: 16),
          _buildAmbientTempCard(colors),
          const SizedBox(height: 16),
          _buildRooftopCard(colors),
          const SizedBox(height: 16),
          _buildConduitFillCard(colors),
          const SizedBox(height: 16),
          _buildContinuousLoadCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildBaseAmpacityCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BASE AMPACITY (from NEC 310.16)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [15.0, 20.0, 30.0, 40.0, 55.0, 75.0, 95.0].map((amp) {
          final isSelected = _baseAmpacity == amp;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _baseAmpacity = amp); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${amp.toInt()}A', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_baseAmpacity.toInt()}A', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _baseAmpacity, min: 10, max: 400, divisions: 39, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _baseAmpacity = v); }),
          )),
        ]),
      ]),
    );
  }

  Widget _buildAmbientTempCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AMBIENT TEMPERATURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [26, 30, 35, 40, 45, 50].map((temp) {
          final isSelected = _ambientTempC == temp;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _ambientTempC = temp); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('$temp°C', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 8),
        Text('${(_ambientTempC * 9 / 5 + 32).toInt()}°F equivalent', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildRooftopCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('ROOFTOP INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1))),
          Switch(
            value: _rooftopInstallation,
            onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _rooftopInstallation = v); },
            activeColor: colors.accentPrimary,
          ),
        ]),
        if (_rooftopInstallation) ...[
          const SizedBox(height: 12),
          Text('Distance above roof:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [0.5, 3.5, 7.0, 12.0, 36.0].map((dist) {
            final isSelected = _rooftopDistanceInches == dist;
            return GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _rooftopDistanceInches = dist); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Text('${dist}"', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13)),
              ),
            );
          }).toList()),
          const SizedBox(height: 8),
          Text('Temperature adder: +$_rooftopTempAdder°C', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ]),
    );
  }

  Widget _buildConduitFillCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONDUCTORS IN CONDUIT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text('Current-carrying conductors only', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: _conductorsInConduit > 1 ? () { HapticFeedback.selectionClick(); setState(() => _conductorsInConduit--); } : null, icon: Icon(LucideIcons.minusCircle, color: _conductorsInConduit > 1 ? colors.accentPrimary : colors.textTertiary, size: 32)),
          const SizedBox(width: 20),
          Text('$_conductorsInConduit', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          const SizedBox(width: 20),
          IconButton(onPressed: _conductorsInConduit < 50 ? () { HapticFeedback.selectionClick(); setState(() => _conductorsInConduit++); } : null, icon: Icon(LucideIcons.plusCircle, color: _conductorsInConduit < 50 ? colors.accentPrimary : colors.textTertiary, size: 32)),
        ]),
        Center(child: Text('Adjustment factor: ${(_conduitFillFactor * 100).toInt()}%', style: TextStyle(color: _conduitFillFactor < 1 ? colors.accentWarning : colors.textTertiary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildContinuousLoadCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CONTINUOUS LOAD (3+ hrs)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(_continuousLoad ? 'Limited to 80% of ampacity' : 'Can use full ampacity', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ])),
        Switch(
          value: _continuousLoad,
          onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _continuousLoad = v); },
          activeColor: colors.accentPrimary,
        ),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isHeavilyDerated = _combinedFactor < 0.6;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHeavilyDerated ? colors.accentWarning.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(_deratedAmpacity.toStringAsFixed(1), style: TextStyle(color: isHeavilyDerated ? colors.accentWarning : colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('Amps (Derated)', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text('${(_combinedFactor * 100).toInt()}% of base', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Base Ampacity', '${_baseAmpacity.toInt()}A'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Effective Ambient', '$_effectiveAmbient°C'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Temp Factor', '${(_tempCorrectionFactor * 100).toInt()}%'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Conduit Fill Factor', '${(_conduitFillFactor * 100).toInt()}%'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Continuous Factor', '${(_continuousLoadFactor * 100).toInt()}%'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Combined Factor', '${(_combinedFactor * 100).toInt()}%', highlight: true),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Final Ampacity', '${_deratedAmpacity.toStringAsFixed(1)}A'),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 310.15', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• (B)(1) Temp correction factors\n• (C)(1) Conduit fill adjustment\n• (B)(3)(c) Rooftop temp adders\n• 210.20(A) Continuous loads at 80%', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
