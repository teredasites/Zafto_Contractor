import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Drying Equipment Calculator - IICRC S500
///
/// Calculates the number of dehumidifiers, air movers, and air scrubbers
/// needed for a water damage restoration job based on IICRC S500 standards.
///
/// References: IICRC S500-2021, RIA (Restoration Industry Association)
class DryingEquipmentScreen extends ConsumerStatefulWidget {
  const DryingEquipmentScreen({super.key});
  @override
  ConsumerState<DryingEquipmentScreen> createState() => _DryingEquipmentScreenState();
}

class _DryingEquipmentScreenState extends ConsumerState<DryingEquipmentScreen> {
  double _affectedSqft = 500;
  double _ceilingHeight = 8;
  int _damageClass = 2;
  int _category = 1;
  String _structureType = 'wood_frame';
  bool _needAirScrubbers = false;

  static const Map<String, ({String desc, double factor})> _structureTypes = {
    'wood_frame': (desc: 'Wood Frame', factor: 1.0),
    'concrete': (desc: 'Concrete/Masonry', factor: 1.3),
    'steel_frame': (desc: 'Steel Frame', factor: 0.9),
    'crawlspace': (desc: 'Crawlspace', factor: 1.4),
    'basement': (desc: 'Basement', factor: 1.2),
  };

  double get _volume => _affectedSqft * _ceilingHeight;

  // Air movers: IICRC recommends 1 per 10-16 LF of wall for Class 2,
  // 1 per 7 LF for Class 3, and specialty placement for Class 4.
  // Simplified: based on square footage and class multiplier.
  int get _airMoversNeeded {
    // Base: 1 air mover per 50-80 sqft depending on class
    final sqftPerMover = switch (_damageClass) {
      1 => 100.0,
      2 => 50.0,
      3 => 40.0,
      4 => 60.0, // Class 4 uses fewer movers but more focused
      _ => 50.0,
    };
    final structFactor = _structureTypes[_structureType]?.factor ?? 1.0;
    return math.max(1, (_affectedSqft / sqftPerMover * structFactor).ceil());
  }

  // Dehumidifiers: based on cubic feet of affected volume
  // IICRC: 1 conventional dehu per ~3,000-6,000 cu ft depending on class
  // LGR dehumidifiers are more efficient (~100 pints/day per unit)
  int get _dehumidifiersNeeded {
    final cuftPerDehu = switch (_damageClass) {
      1 => 8000.0,
      2 => 4000.0,
      3 => 3000.0,
      4 => 2500.0, // Class 4 needs more dehumidification capacity
      _ => 4000.0,
    };
    final structFactor = _structureTypes[_structureType]?.factor ?? 1.0;
    return math.max(1, (_volume / cuftPerDehu * structFactor).ceil());
  }

  // Air scrubbers: required for Cat 2/3 or mold-suspect
  // 1 per 500-1000 sqft depending on contamination level
  int get _airScrubbersNeeded {
    if (!_needAirScrubbers && _category < 2) return 0;
    final sqftPerScrubber = _category >= 3 ? 500.0 : 1000.0;
    return math.max(1, (_affectedSqft / sqftPerScrubber).ceil());
  }

  // Estimated drying days (assuming proper setup)
  int get _estimatedDryDays {
    return switch (_damageClass) {
      1 => 2,
      2 => 3,
      3 => 5,
      4 => 7,
      _ => 3,
    };
  }

  // Total CFM needed (air movers at ~2500 CFM each average)
  int get _totalCfm => _airMoversNeeded * 2500;

  // Dehumidification capacity needed (pints/day)
  // Rule of thumb: 1 pint per 10 sqft per day for Class 2
  int get _pintsPerDay {
    final pintsPerSqft = switch (_damageClass) {
      1 => 0.05,
      2 => 0.10,
      3 => 0.15,
      4 => 0.12,
      _ => 0.10,
    };
    return (_affectedSqft * pintsPerSqft).ceil();
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
          'Drying Equipment Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildAreaCard(colors),
          const SizedBox(height: 16),
          _buildClassCard(colors),
          const SizedBox(height: 16),
          _buildCategoryCard(colors),
          const SizedBox(height: 16),
          _buildStructureCard(colors),
          const SizedBox(height: 16),
          _buildOptionsCard(colors),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEquipmentCount(colors, '$_airMoversNeeded', 'Air Movers', LucideIcons.wind),
              Container(width: 1, height: 50, color: colors.borderSubtle),
              _buildEquipmentCount(colors, '$_dehumidifiersNeeded', 'Dehumidifiers', LucideIcons.droplets),
              if (_airScrubbersNeeded > 0) ...[
                Container(width: 1, height: 50, color: colors.borderSubtle),
                _buildEquipmentCount(colors, '$_airScrubbersNeeded', 'Air Scrubbers', LucideIcons.fan),
              ],
            ],
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
                _buildResultRow(colors, 'Affected Area', '${_affectedSqft.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Volume', '${_volume.toStringAsFixed(0)} cu ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total CFM', '${_totalCfm.toStringAsFixed(0)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Dehu Capacity', '$_pintsPerDay pints/day'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: colors.borderSubtle),
                ),
                _buildResultRow(colors, 'Est. Dry Time', '$_estimatedDryDays days'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCount(ZaftoColors colors, String count, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: colors.accentPrimary, size: 24),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            color: colors.accentPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ],
    );
  }

  Widget _buildAreaCard(ZaftoColors colors) {
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
            'AFFECTED AREA',
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
              Text('Square Footage', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_affectedSqft.toStringAsFixed(0)} sq ft',
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
              value: _affectedSqft,
              min: 50,
              max: 5000,
              divisions: 99,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _affectedSqft = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ceiling Height', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_ceilingHeight.toStringAsFixed(0)} ft',
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
              value: _ceilingHeight,
              min: 7,
              max: 14,
              divisions: 14,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _ceilingHeight = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(ZaftoColors colors) {
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
            'IICRC DAMAGE CLASS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (i) {
            final cls = i + 1;
            final isSelected = _damageClass == cls;
            final desc = switch (cls) {
              1 => 'Least (small area, minimal absorption)',
              2 => 'Significant (carpet + cushion, wicking < 24")',
              3 => 'Extensive (from above, walls + subfloor saturated)',
              4 => 'Specialty (hardwood, plaster, concrete)',
              _ => '',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _damageClass = cls);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Class $cls',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.accentPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textSecondary,
                            fontSize: 11,
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

  Widget _buildCategoryCard(ZaftoColors colors) {
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
            'WATER CATEGORY',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (i) {
              final cat = i + 1;
              final isSelected = _category == cat;
              final catColor = switch (cat) {
                1 => Colors.blue,
                2 => Colors.orange,
                3 => Colors.red,
                _ => colors.accentPrimary,
              };
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _category = cat;
                        if (cat >= 2) _needAirScrubbers = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Cat $cat',
                            style: TextStyle(
                              color: isSelected ? Colors.white : colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            switch (cat) { 1 => 'Clean', 2 => 'Gray', 3 => 'Black', _ => '' },
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : colors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureCard(ZaftoColors colors) {
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
            'STRUCTURE TYPE',
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
            children: _structureTypes.entries.map((entry) {
              final isSelected = _structureType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _structureType = entry.key);
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
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _needAirScrubbers = !_needAirScrubbers);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _needAirScrubbers ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _needAirScrubbers ? LucideIcons.checkCircle : LucideIcons.circle,
                    size: 18,
                    color: _needAirScrubbers ? colors.accentPrimary : colors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Include Air Scrubbers',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Required for Cat 2/3, mold-suspect, or occupied spaces',
                          style: TextStyle(color: colors.textTertiary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              Icon(LucideIcons.bookOpen, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IICRC S500 Equipment Guidelines',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Air movers: 1 per 10-16 LF wall (Class 2)\n'
            '• LGR dehumidifiers preferred for Class 3-4\n'
            '• Air scrubbers: HEPA filtration for Cat 2/3\n'
            '• Monitor moisture daily — adjust equipment\n'
            '• Class 4: consider desiccant or heat drying\n'
            '• Document all equipment placement and readings',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
