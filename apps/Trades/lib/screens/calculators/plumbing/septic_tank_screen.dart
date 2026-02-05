import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Septic Tank Sizing Calculator - Design System v2.6
///
/// Calculates minimum septic tank size based on number of bedrooms
/// and estimated daily flow per IRC/EPA guidelines.
///
/// References: IRC P2406.2, EPA Onsite Wastewater Guidelines
class SepticTankScreen extends ConsumerStatefulWidget {
  const SepticTankScreen({super.key});
  @override
  ConsumerState<SepticTankScreen> createState() => _SepticTankScreenState();
}

class _SepticTankScreenState extends ConsumerState<SepticTankScreen> {
  // Number of bedrooms
  int _bedrooms = 3;

  // Property type
  String _propertyType = 'residential'; // 'residential', 'commercial'

  // Water-saving fixtures
  bool _hasWaterSaving = false;

  // Garbage disposal
  bool _hasDisposal = false;

  // Pump schedule (days between pumping)
  int _pumpScheduleYears = 3;

  // Soil type for drain field
  String _soilType = 'medium'; // 'fast', 'medium', 'slow'

  // IRC Table P2406.2 - Minimum septic tank capacity
  static const Map<int, int> _minTankSizeByBedroom = {
    1: 750,
    2: 750,
    3: 1000,
    4: 1000,
    5: 1250,
    6: 1250,
  };

  // Additional capacity per bedroom over 6
  static const int _additionalPerBedroom = 250;

  // GPD per bedroom (EPA guideline: 150 GPD per bedroom typical)
  static const int _gpdPerBedroom = 150;

  // Garbage disposal adds ~50% to solids
  static const double _disposalFactor = 1.5;

  // Percolation rates by soil type (minutes per inch)
  static const Map<String, ({int minRate, int maxRate, String desc})> _percRates = {
    'fast': (minRate: 1, maxRate: 10, desc: 'Sand, gravel'),
    'medium': (minRate: 10, maxRate: 30, desc: 'Sandy loam, loam'),
    'slow': (minRate: 30, maxRate: 60, desc: 'Clay loam, silt'),
  };

  // Drain field sizing (sq ft per bedroom at different perc rates)
  static const Map<String, int> _drainFieldPerBedroom = {
    'fast': 150, // sq ft per bedroom
    'medium': 250,
    'slow': 400,
  };

  int get _minTankSize {
    int base;
    if (_bedrooms <= 6) {
      base = _minTankSizeByBedroom[_bedrooms] ?? 1000;
    } else {
      base = _minTankSizeByBedroom[6]! + ((_bedrooms - 6) * _additionalPerBedroom);
    }

    // Garbage disposal increases needed capacity
    if (_hasDisposal) {
      base = (base * 1.25).round();
    }

    return base;
  }

  int get _recommendedTankSize {
    // Round up to standard sizes
    final min = _minTankSize;
    const standardSizes = [750, 1000, 1250, 1500, 2000, 2500, 3000];

    for (final size in standardSizes) {
      if (size >= min) return size;
    }
    return ((min / 500).ceil() * 500);
  }

  int get _dailyFlow {
    int base = _bedrooms * _gpdPerBedroom;
    if (_hasWaterSaving) {
      base = (base * 0.7).round(); // 30% reduction
    }
    return base;
  }

  int get _drainFieldSize {
    final sqFtPerBedroom = _drainFieldPerBedroom[_soilType] ?? 250;
    return _bedrooms * sqFtPerBedroom;
  }

  String get _drainFieldLength {
    // Assuming 3 ft wide trenches
    final totalSqFt = _drainFieldSize;
    final lengthFt = totalSqFt / 3;
    return '${lengthFt.toStringAsFixed(0)} linear ft';
  }

  int get _pumpingIntervalDays {
    // Rough estimate based on tank size and household
    // Smaller tank = more frequent pumping
    final tankSize = _recommendedTankSize;
    final occupants = (_bedrooms * 2).clamp(2, 10); // Assume 2 per bedroom
    final dailySolids = occupants * 0.25; // ~0.25 gal solids per person/day

    // Time to fill 1/3 of tank with solids (trigger for pumping)
    final fillCapacity = tankSize / 3;
    final daysToFill = fillCapacity / dailySolids;

    return daysToFill.round();
  }

  String get _pumpingRecommendation {
    final days = _pumpingIntervalDays;
    final years = (days / 365).round();

    if (years <= 1) return 'Annually';
    if (years <= 2) return 'Every 2 years';
    if (years <= 3) return 'Every 3 years';
    if (years <= 5) return 'Every 3-5 years';
    return 'Every 5+ years';
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
          'Septic Tank Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildBedroomsCard(colors),
          const SizedBox(height: 16),
          _buildOptionsCard(colors),
          const SizedBox(height: 16),
          _buildSoilTypeCard(colors),
          const SizedBox(height: 16),
          _buildDrainFieldCard(colors),
          const SizedBox(height: 16),
          _buildSizingTable(colors),
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
          Text(
            '${_recommendedTankSize}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Gallons (Recommended Tank)',
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
                _buildResultRow(colors, 'Bedrooms', '$_bedrooms'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Code Minimum', '$_minTankSize gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Est. Daily Flow', '$_dailyFlow GPD', highlight: true),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Drain Field Size', '$_drainFieldSize sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Trench Length', _drainFieldLength),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Pump Every', _pumpingRecommendation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedroomsCard(ZaftoColors colors) {
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
            'NUMBER OF BEDROOMS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _bedrooms > 1
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _bedrooms--);
                      }
                    : null,
                icon: Icon(
                  LucideIcons.minusCircle,
                  color: _bedrooms > 1 ? colors.accentPrimary : colors.textTertiary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '$_bedrooms',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _bedrooms < 10
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _bedrooms++);
                      }
                    : null,
                icon: Icon(
                  LucideIcons.plusCircle,
                  color: _bedrooms < 10 ? colors.accentPrimary : colors.textTertiary,
                  size: 32,
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              'Based on design occupancy (2 per bedroom)',
              style: TextStyle(color: colors.textTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard(ZaftoColors colors) {
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
            'OPTIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggle(colors, 'Garbage Disposal', 'Increases tank size 25%', _hasDisposal, (v) => setState(() => _hasDisposal = v)),
          _buildToggle(colors, 'Water-Saving Fixtures', 'Reduces flow 30%', _hasWaterSaving, (v) => setState(() => _hasWaterSaving = v)),
        ],
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, String desc, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: value ? null : Border.all(color: colors.borderSubtle),
              ),
              child: value
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                  Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilTypeCard(ZaftoColors colors) {
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
            'SOIL TYPE (FOR DRAIN FIELD)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._percRates.entries.map((entry) {
            final isSelected = _soilType == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _soilType = entry.key);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected ? null : Border.all(color: colors.borderSubtle, width: 2),
                      ),
                      child: isSelected
                          ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key.substring(0, 1).toUpperCase()}${entry.key.substring(1)} Drainage',
                            style: TextStyle(
                              color: isSelected ? colors.accentPrimary : colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${entry.value.desc} (${entry.value.minRate}-${entry.value.maxRate} min/in)',
                            style: TextStyle(color: colors.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
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

  Widget _buildDrainFieldCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.layers, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'DRAIN FIELD ESTIMATE',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_drainFieldSize',
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('sq ft', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _drainFieldLength.replaceAll(' linear ft', ''),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('linear ft (3ft trenches)', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Based on ${_percRates[_soilType]?.desc ?? _soilType} soil conditions',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSizingTable(ZaftoColors colors) {
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
            'IRC TABLE P2406.2 - MINIMUM TANK SIZE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._minTankSizeByBedroom.entries.map((entry) {
            final isSelected = _bedrooms == entry.key;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isSelected ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${entry.key} bedroom${entry.key > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} gal minimum',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'For 7+ bedrooms: add 250 gal per bedroom',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IRC Chapter 24 / EPA Guidelines',
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
            '• P2406.2 - Minimum septic tank size\n'
            '• P2408 - Drain field requirements\n'
            '• Perc test required for drain field sizing\n'
            '• Pump every 3-5 years typical\n'
            '• Local codes may require larger tanks\n'
            '• Professional design recommended',
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
