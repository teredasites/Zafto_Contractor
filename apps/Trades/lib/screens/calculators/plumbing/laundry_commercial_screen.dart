import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Commercial Laundry Plumbing Calculator - Design System v2.6
///
/// Sizes plumbing for commercial laundry facilities.
/// Calculates water supply, drain, and hot water requirements.
///
/// References: IPC 2024, ASHRAE
class LaundryCommercialScreen extends ConsumerStatefulWidget {
  const LaundryCommercialScreen({super.key});
  @override
  ConsumerState<LaundryCommercialScreen> createState() => _LaundryCommercialScreenState();
}

class _LaundryCommercialScreenState extends ConsumerState<LaundryCommercialScreen> {
  // Number of washers
  int _washerCount = 4;

  // Washer size
  String _washerSize = 'medium';

  // Facility type
  String _facilityType = 'laundromat';

  static const Map<String, ({String desc, double gallonsPerLoad, int dfu})> _washerSizes = {
    'small': (desc: 'Small (20 lb)', gallonsPerLoad: 25, dfu: 3),
    'medium': (desc: 'Medium (35 lb)', gallonsPerLoad: 40, dfu: 4),
    'large': (desc: 'Large (50 lb)', gallonsPerLoad: 55, dfu: 5),
    'xlarge': (desc: 'Extra Large (80+ lb)', gallonsPerLoad: 80, dfu: 6),
  };

  static const Map<String, ({String desc, double loadsPerDay})> _facilityTypes = {
    'laundromat': (desc: 'Laundromat', loadsPerDay: 8),
    'hotel': (desc: 'Hotel/Motel', loadsPerDay: 4),
    'hospital': (desc: 'Hospital/Healthcare', loadsPerDay: 6),
    'industrial': (desc: 'Industrial/Uniform', loadsPerDay: 10),
  };

  // Total DFU
  int get _totalDfu {
    final dfuPerWasher = _washerSizes[_washerSize]?.dfu ?? 4;
    return dfuPerWasher * _washerCount;
  }

  // Daily water usage (gallons)
  double get _dailyWater {
    final gallonsPerLoad = _washerSizes[_washerSize]?.gallonsPerLoad ?? 40;
    final loadsPerDay = _facilityTypes[_facilityType]?.loadsPerDay ?? 8;
    return gallonsPerLoad * loadsPerDay * _washerCount;
  }

  // Peak GPM (diversity factor)
  double get _peakGpm {
    // Assume 50% diversity for simultaneous use
    final gallonsPerLoad = _washerSizes[_washerSize]?.gallonsPerLoad ?? 40;
    final fillTime = 5.0; // minutes
    return (gallonsPerLoad / fillTime) * _washerCount * 0.5;
  }

  // Hot water demand (gallons per hour)
  double get _hotWaterGph {
    // 60% hot water ratio typically
    return _peakGpm * 60 * 0.6;
  }

  // Supply line size
  String get _supplySize {
    final gpm = _peakGpm;
    if (gpm <= 10) return '1\"';
    if (gpm <= 20) return '1¼\"';
    if (gpm <= 35) return '1½\"';
    return '2\"';
  }

  // Drain line size
  String get _drainSize {
    if (_totalDfu <= 20) return '2\"';
    if (_totalDfu <= 42) return '3\"';
    return '4\"';
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
          'Commercial Laundry',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildFacilityCard(colors),
          const SizedBox(height: 16),
          _buildWasherCountCard(colors),
          const SizedBox(height: 16),
          _buildWasherSizeCard(colors),
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
            '${_dailyWater.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Gallons per Day',
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
                _buildResultRow(colors, 'Total DFU', '$_totalDfu'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Peak Flow', '${_peakGpm.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Line', _supplySize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Line', _drainSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hot Water', '${_hotWaterGph.toStringAsFixed(0)} GPH'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(ZaftoColors colors) {
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
            'FACILITY TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._facilityTypes.entries.map((entry) {
            final isSelected = _facilityType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _facilityType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.loadsPerDay.toInt()} loads/day/washer',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 10,
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

  Widget _buildWasherCountCard(ZaftoColors colors) {
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
            'NUMBER OF WASHERS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Washers', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_washerCount',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _washerCount.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _washerCount = v.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasherSizeCard(ZaftoColors colors) {
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
            'WASHER SIZE',
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
            children: _washerSizes.entries.map((entry) {
              final isSelected = _washerSize == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _washerSize = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.shirt, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC Requirements',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Standpipe or floor drain required\n'
            '• Air gap on drain connections\n'
            '• Hot water at 140°F available\n'
            '• Backflow preventer on supply\n'
            '• Floor drain in laundry area\n'
            '• Check ADA requirements',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
