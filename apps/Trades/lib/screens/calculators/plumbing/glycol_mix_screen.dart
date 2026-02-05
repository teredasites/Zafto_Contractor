import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Glycol Mix Calculator - Design System v2.6
///
/// Calculates glycol percentage for freeze protection.
/// Determines mix ratio for hydronic systems.
///
/// References: ASHRAE Handbook, Manufacturer specs
class GlycolMixScreen extends ConsumerStatefulWidget {
  const GlycolMixScreen({super.key});
  @override
  ConsumerState<GlycolMixScreen> createState() => _GlycolMixScreenState();
}

class _GlycolMixScreenState extends ConsumerState<GlycolMixScreen> {
  // Glycol type
  String _glycolType = 'propylene';

  // Desired freeze protection temperature
  double _freezeTemp = 0;

  // System volume (gallons)
  double _systemVolume = 20;

  // Current glycol percentage (for existing systems)
  double _currentGlycol = 0;

  // Glycol type properties
  static const Map<String, String> _glycolTypes = {
    'propylene': 'Propylene Glycol (food-safe)',
    'ethylene': 'Ethylene Glycol (automotive)',
  };

  // Freeze protection by glycol percentage (propylene)
  // Simplified table
  static const List<({double percent, double propylene, double ethylene})> _freezePoints = [
    (percent: 0, propylene: 32, ethylene: 32),
    (percent: 10, propylene: 26, ethylene: 25),
    (percent: 20, propylene: 18, ethylene: 15),
    (percent: 30, propylene: 7, ethylene: 0),
    (percent: 40, propylene: -8, ethylene: -12),
    (percent: 50, propylene: -28, ethylene: -34),
    (percent: 60, propylene: -55, ethylene: -60),
  ];

  double get _requiredPercent {
    final freezeData = _glycolType == 'propylene'
        ? _freezePoints.map((f) => (percent: f.percent, freeze: f.propylene))
        : _freezePoints.map((f) => (percent: f.percent, freeze: f.ethylene));

    for (final data in freezeData) {
      if (data.freeze <= _freezeTemp) {
        return data.percent;
      }
    }
    return 60; // Max
  }

  double get _glycolGallons {
    if (_currentGlycol >= _requiredPercent) return 0;

    // Calculate glycol needed
    // If starting fresh: volume * percent
    // If adding to existing: more complex
    if (_currentGlycol == 0) {
      return _systemVolume * (_requiredPercent / 100);
    }

    // Adding to existing system (simplified)
    final currentGlycolVol = _systemVolume * (_currentGlycol / 100);
    final targetGlycolVol = _systemVolume * (_requiredPercent / 100);
    return (targetGlycolVol - currentGlycolVol).clamp(0, _systemVolume);
  }

  double get _waterGallons => _systemVolume - _glycolGallons;

  String get _boilPoint {
    // Approximate boil point elevation
    final percent = _requiredPercent;
    final elevation = percent * 0.5; // ~0.5°F per percent
    return '${(212 + elevation).toStringAsFixed(0)}°F';
  }

  String get _heatCapacityReduction {
    // Glycol reduces heat transfer capacity
    final percent = _requiredPercent;
    if (percent <= 20) return '~5%';
    if (percent <= 30) return '~10%';
    if (percent <= 40) return '~15%';
    if (percent <= 50) return '~20%';
    return '~25%';
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
        title: Text(
          'Glycol Mix Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildGlycolTypeCard(colors),
          const SizedBox(height: 16),
          _buildFreezeProtectionCard(colors),
          const SizedBox(height: 16),
          _buildSystemVolumeCard(colors),
          const SizedBox(height: 16),
          _buildCurrentGlycolCard(colors),
          const SizedBox(height: 16),
          _buildMixingCard(colors),
          const SizedBox(height: 16),
          _buildFreezeTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${_requiredPercent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Glycol Concentration',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Freeze Protection', '${_freezeTemp.toStringAsFixed(0)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'System Volume', '${_systemVolume.toStringAsFixed(0)} gal'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Glycol Needed', '${_glycolGallons.toStringAsFixed(1)} gal', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Water Needed', '${_waterGallons.toStringAsFixed(1)} gal'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Boil Point', _boilPoint),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Heat Cap. Reduction', _heatCapacityReduction),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlycolTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GLYCOL TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...['propylene', 'ethylene'].map((type) {
            final isSelected = _glycolType == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _glycolType = type);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _glycolTypes[type] ?? '',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFreezeProtectionCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FREEZE PROTECTION NEEDED',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_freezeTemp.toStringAsFixed(0)}°F',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: Colors.blue,
                  ),
                  child: Slider(
                    value: _freezeTemp,
                    min: -50,
                    max: 25,
                    divisions: 15,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _freezeTemp = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Lowest expected ambient temperature',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemVolumeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM VOLUME (GALLONS)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_systemVolume.toStringAsFixed(0)} gal',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _systemVolume,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _systemVolume = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total hydronic system capacity',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentGlycolCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT GLYCOL % (IF EXISTING)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_currentGlycol.toStringAsFixed(0)}%',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _currentGlycol,
                    min: 0,
                    max: 60,
                    divisions: 12,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentGlycol = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            '0% for new system, test existing systems',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMixingCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.beaker, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'MIXING INSTRUCTIONS',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Use ${_glycolGallons.toStringAsFixed(1)} gallons of ${_glycolType == 'propylene' ? 'Propylene' : 'Ethylene'} Glycol\n'
            '2. Mix with ${_waterGallons.toStringAsFixed(1)} gallons of distilled water\n'
            '3. Total system fill: ${_systemVolume.toStringAsFixed(0)} gallons\n'
            '4. Final concentration: ${_requiredPercent.toStringAsFixed(0)}%\n'
            '5. Verify with refractometer after fill',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FREEZE POINT REFERENCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._freezePoints.map((data) {
            final isRecommended = data.percent == _requiredPercent;
            final freezePoint = _glycolType == 'propylene' ? data.propylene : data.ethylene;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended
                    ? colors.accentPrimary.withValues(alpha: 0.2)
                    : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${data.percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Freezes at ${freezePoint.toStringAsFixed(0)}°F',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                  if (isRecommended)
                    Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.accentPrimary : colors.textPrimary,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertCircle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Text(
                'Important Notes',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Propylene glycol for potable systems\n'
            '• Ethylene is toxic - outdoor only\n'
            '• Use inhibited glycol for HVAC\n'
            '• Replace glycol every 3-5 years\n'
            '• Test concentration with refractometer\n'
            '• Glycol reduces heat transfer',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
