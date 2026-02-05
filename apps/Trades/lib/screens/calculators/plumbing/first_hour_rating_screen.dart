import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// First Hour Rating Calculator - Design System v2.6
///
/// Calculates peak hot water demand (FHR) for water heater selection.
/// Based on DOE test method for consumer comparison.
///
/// References: DOE 10 CFR 430, ENERGY STAR water heater sizing
class FirstHourRatingScreen extends ConsumerStatefulWidget {
  const FirstHourRatingScreen({super.key});
  @override
  ConsumerState<FirstHourRatingScreen> createState() => _FirstHourRatingScreenState();
}

class _FirstHourRatingScreenState extends ConsumerState<FirstHourRatingScreen> {
  // Household members
  int _members = 3;

  // Usage pattern
  String _usagePattern = 'moderate';

  // Peak time activities (how many running at once)
  int _showers = 1;
  int _dishwashers = 0;
  int _clothesWashers = 0;
  int _sinks = 1;

  // Hot water usage per fixture (gallons)
  static const Map<String, ({double gallons, String duration})> _fixtureUsage = {
    'shower': (gallons: 10.0, duration: '~5 min @ 2 GPM'),
    'bath': (gallons: 20.0, duration: 'Half tub'),
    'dishwasher': (gallons: 6.0, duration: 'Per cycle'),
    'clothesWasher': (gallons: 7.0, duration: 'Per load'),
    'handSink': (gallons: 2.0, duration: 'Per use'),
    'kitchenSink': (gallons: 4.0, duration: 'Dishes/prep'),
    'shaving': (gallons: 2.0, duration: 'Per use'),
  };

  // Usage pattern multipliers
  static const Map<String, ({double multiplier, String desc})> _usagePatterns = {
    'light': (multiplier: 0.8, desc: 'Quick showers, low usage'),
    'moderate': (multiplier: 1.0, desc: 'Average household'),
    'heavy': (multiplier: 1.3, desc: 'Long showers, multiple uses'),
    'veryHeavy': (multiplier: 1.5, desc: 'Spa-like, high demand'),
  };

  // Base FHR per household size (gallons)
  double get _baseFHR {
    switch (_members) {
      case 1: return 35;
      case 2: return 45;
      case 3: return 55;
      case 4: return 65;
      case 5: return 75;
      default: return 75 + ((_members - 5) * 10);
    }
  }

  // Peak demand from selected activities
  double get _peakDemand {
    return (_showers * _fixtureUsage['shower']!.gallons) +
        (_dishwashers * _fixtureUsage['dishwasher']!.gallons) +
        (_clothesWashers * _fixtureUsage['clothesWasher']!.gallons) +
        (_sinks * _fixtureUsage['kitchenSink']!.gallons);
  }

  // Adjusted FHR
  double get _adjustedFHR {
    final base = _baseFHR;
    final pattern = _usagePatterns[_usagePattern]?.multiplier ?? 1.0;
    final fromPeak = _peakDemand;

    // Use higher of base calculation or peak activity method
    final calculated = base * pattern;
    return calculated > fromPeak ? calculated : fromPeak;
  }

  // Recommended water heater size
  String get _recommendedSize {
    final fhr = _adjustedFHR;
    if (fhr <= 40) return '40 Gallon Tank';
    if (fhr <= 50) return '50 Gallon Tank';
    if (fhr <= 65) return '65 Gallon Tank';
    if (fhr <= 80) return '80 Gallon Tank';
    return '80+ Gallon or Tankless';
  }

  // Tank vs tankless recommendation
  String get _heaterTypeRecommendation {
    if (_adjustedFHR > 80) return 'Consider tankless or multiple tanks';
    if (_usagePattern == 'veryHeavy') return 'Tankless may provide unlimited hot water';
    if (_members <= 2 && _adjustedFHR <= 40) return 'Small tank or point-of-use units';
    return 'Standard tank water heater';
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
          'First Hour Rating',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildHouseholdCard(colors),
          const SizedBox(height: 16),
          _buildUsagePatternCard(colors),
          const SizedBox(height: 16),
          _buildPeakActivityCard(colors),
          const SizedBox(height: 16),
          _buildFixtureUsageTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _adjustedFHR.toStringAsFixed(0),
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ' gal',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'First Hour Rating Needed',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _recommendedSize,
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Household Size', '$_members people'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Usage Pattern', _usagePatterns[_usagePattern]?.desc ?? 'Average'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Peak Demand', '${_peakDemand.toStringAsFixed(0)} gal'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Recommendation', _heaterTypeRecommendation, highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdCard(ZaftoColors colors) {
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
            'HOUSEHOLD MEMBERS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 4, 5, 6].map((count) {
              final isSelected = _members == count;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _members = count);
                },
                child: Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Number of people using hot water during peak hour',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildUsagePatternCard(ZaftoColors colors) {
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
            'USAGE PATTERN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._usagePatterns.entries.map((entry) {
            final isSelected = _usagePattern == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _usagePattern = entry.key);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: isSelected ? colors.accentPrimary : colors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value.desc,
                        style: TextStyle(
                          color: isSelected ? colors.accentPrimary : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${(entry.value.multiplier * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPeakActivityCard(ZaftoColors colors) {
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
            'PEAK HOUR ACTIVITIES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How many running simultaneously during peak?',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 16),
          _buildActivityRow(colors, 'Showers', _showers, 10, (v) => setState(() => _showers = v)),
          _buildActivityRow(colors, 'Kitchen Sinks', _sinks, 4, (v) => setState(() => _sinks = v)),
          _buildActivityRow(colors, 'Dishwashers', _dishwashers, 6, (v) => setState(() => _dishwashers = v)),
          _buildActivityRow(colors, 'Clothes Washers', _clothesWashers, 7, (v) => setState(() => _clothesWashers = v)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(ZaftoColors colors, String label, int value, int gallons, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                Text('$gallons gal each', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
          _buildCounterButton(colors, LucideIcons.minus, () {
            if (value > 0) onChanged(value - 1);
          }),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              value.toString(),
              style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          _buildCounterButton(colors, LucideIcons.plus, () {
            onChanged(value + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildCounterButton(ZaftoColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: colors.textSecondary, size: 14),
      ),
    );
  }

  Widget _buildFixtureUsageTable(ZaftoColors colors) {
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
            'HOT WATER USAGE REFERENCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._fixtureUsage.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key[0].toUpperCase() + entry.key.substring(1).replaceAll(RegExp(r'([A-Z])'), ' \$1'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value.gallons.toStringAsFixed(0)} gal',
                      style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.value.duration,
                      style: TextStyle(color: colors.textTertiary, fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  ),
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
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? colors.accentPrimary : colors.textPrimary,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.right,
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'DOE / ENERGY STAR',
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
            '• FHR = gallons in first hour of use\n'
            '• Match water heater FHR to demand\n'
            '• Check EnergyGuide label for FHR\n'
            '• Tank recovery rate matters too\n'
            '• Tankless rated in GPM at temp rise\n'
            '• Consider ENERGY STAR rated units',
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
