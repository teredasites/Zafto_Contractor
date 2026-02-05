import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Filter Sizing Calculator - Design System v2.6
///
/// Sizes air filters based on system CFM and desired velocity.
/// Helps select proper filter dimensions and MERV rating.
///
/// References: ASHRAE 52.2, Equipment Specifications
class FilterSizingScreen extends ConsumerStatefulWidget {
  const FilterSizingScreen({super.key});
  @override
  ConsumerState<FilterSizingScreen> createState() => _FilterSizingScreenState();
}

class _FilterSizingScreenState extends ConsumerState<FilterSizingScreen> {
  // System CFM
  double _cfm = 1200;

  // Filter type
  String _filterType = 'standard';

  // MERV rating
  int _mervRating = 8;

  static const Map<String, ({String desc, int maxVelocity, double pressureDrop})> _filterTypes = {
    'standard': (desc: 'Standard 1\"', maxVelocity: 300, pressureDrop: 0.1),
    'pleated': (desc: 'Pleated 2\"', maxVelocity: 350, pressureDrop: 0.15),
    'media': (desc: 'Media 4\"', maxVelocity: 400, pressureDrop: 0.2),
    'deep': (desc: 'Deep Pleat 5\"', maxVelocity: 450, pressureDrop: 0.25),
  };

  static const Map<int, String> _mervDescriptions = {
    1: 'Minimal - Pollen, dust mites',
    4: 'Low - Carpet fibers, dust',
    8: 'Standard - Mold, pet dander',
    11: 'Better - Legionella, lead dust',
    13: 'Good - Bacteria, smoke',
    16: 'Hospital - Virus carriers',
  };

  // Required filter area (sq ft)
  double get _requiredArea {
    final filterType = _filterTypes[_filterType];
    final maxVelocity = filterType?.maxVelocity ?? 300;
    return _cfm / maxVelocity;
  }

  // Face velocity
  double get _faceVelocity {
    final filterType = _filterTypes[_filterType];
    return filterType?.maxVelocity.toDouble() ?? 300;
  }

  // Standard filter sizes that meet requirement
  List<String> get _recommendedSizes {
    final needed = _requiredArea * 144; // Convert to sq inches
    final sizes = <String>[];

    // Check common filter sizes
    final standardSizes = [
      (14, 20), (14, 25), (16, 20), (16, 25), (18, 20), (18, 24), (18, 25),
      (20, 20), (20, 24), (20, 25), (20, 30), (24, 24), (24, 30), (25, 25),
    ];

    for (final size in standardSizes) {
      final area = size.$1 * size.$2;
      if (area >= needed * 0.9) { // Allow 10% under
        sizes.add('${size.$1}\" × ${size.$2}\"');
        if (sizes.length >= 4) break;
      }
    }

    if (sizes.isEmpty) {
      // Need multiple filters
      final singleArea = 20 * 25;
      final count = (needed / singleArea).ceil();
      sizes.add('$count × (20\" × 25\")');
    }

    return sizes;
  }

  // Estimated pressure drop
  double get _pressureDrop {
    final filterType = _filterTypes[_filterType];
    // Increase with MERV rating
    final baseDrop = filterType?.pressureDrop ?? 0.1;
    final mervFactor = 1 + (_mervRating - 8) * 0.02;
    return baseDrop * mervFactor;
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
          'Filter Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildCfmCard(colors),
          const SizedBox(height: 16),
          _buildFilterTypeCard(colors),
          const SizedBox(height: 16),
          _buildMervCard(colors),
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
            '${_requiredArea.toStringAsFixed(1)} sq ft',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Minimum Filter Area',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECOMMENDED SIZES',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ..._recommendedSizes.map((size) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(LucideIcons.check, color: colors.accentPrimary, size: 14),
                        const SizedBox(width: 8),
                        Text(size, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'System CFM', '${_cfm.toStringAsFixed(0)} CFM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Face Velocity', '${_faceVelocity.toStringAsFixed(0)} FPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'MERV Rating', 'MERV $_mervRating'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Est. Pressure Drop', '${_pressureDrop.toStringAsFixed(2)}\" w.c.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCfmCard(ZaftoColors colors) {
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
            'SYSTEM AIRFLOW',
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
              Text('CFM', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_cfm.toStringAsFixed(0)}',
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
              value: _cfm,
              min: 400,
              max: 3000,
              divisions: 26,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _cfm = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [800, 1200, 1600, 2000].map((cfm) {
              final isSelected = (_cfm - cfm).abs() < 100;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _cfm = cfm.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$cfm',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
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

  Widget _buildFilterTypeCard(ZaftoColors colors) {
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
            'FILTER TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._filterTypes.entries.map((entry) {
            final isSelected = _filterType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filterType = entry.key);
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
                        '≤${entry.value.maxVelocity} FPM',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 11,
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

  Widget _buildMervCard(ZaftoColors colors) {
    final ratings = [1, 4, 8, 11, 13, 16];

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
            'MERV RATING',
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
              Text('MERV', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_mervRating',
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
              value: _mervRating.toDouble(),
              min: 1,
              max: 16,
              divisions: 15,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _mervRating = v.round());
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _mervDescriptions.entries
                  .where((e) => e.key <= _mervRating)
                  .last
                  .value,
              style: TextStyle(color: colors.accentPrimary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.wind, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Filter Guidelines',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Face velocity ≤ 300-400 FPM\n'
            '• Higher MERV = more restriction\n'
            '• Check equipment static rating\n'
            '• Replace per manufacturer\n'
            '• Seal filter rack edges\n'
            '• Size for clean filter drop',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
