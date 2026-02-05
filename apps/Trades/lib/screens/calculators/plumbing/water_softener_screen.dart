import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Softener Sizing Calculator - Design System v2.6
///
/// Calculates required water softener capacity based on household size,
/// water hardness, and usage patterns.
///
/// References: Water Quality Association guidelines, Industry standards
class WaterSoftenerScreen extends ConsumerStatefulWidget {
  const WaterSoftenerScreen({super.key});
  @override
  ConsumerState<WaterSoftenerScreen> createState() => _WaterSoftenerScreenState();
}

class _WaterSoftenerScreenState extends ConsumerState<WaterSoftenerScreen> {
  // Household size
  int _numberOfPeople = 4;

  // Water hardness (GPG - grains per gallon)
  double _hardnessGpg = 10;

  // Iron content (PPM)
  double _ironPpm = 0;

  // Daily water usage per person (gallons)
  double _gallonsPerPerson = 75;

  // Regeneration frequency (days)
  int _regenDays = 7;

  // Hardness measurement unit
  String _hardnessUnit = 'gpg'; // 'gpg' or 'ppm'

  // Common hardness levels
  static const Map<String, ({double gpg, String desc})> _hardnessLevels = {
    'soft': (gpg: 1.0, desc: '0-1 GPG'),
    'slightly': (gpg: 3.5, desc: '1-3.5 GPG'),
    'moderate': (gpg: 7.0, desc: '3.5-7 GPG'),
    'hard': (gpg: 10.5, desc: '7-10.5 GPG'),
    'very_hard': (gpg: 15.0, desc: '10.5+ GPG'),
  };

  // Standard softener capacities (grain capacity)
  static const List<int> _softenerSizes = [
    24000,
    32000,
    40000,
    48000,
    64000,
    80000,
    96000,
  ];

  // Convert PPM to GPG (17.1 PPM = 1 GPG)
  double get _effectiveHardnessGpg {
    double hardness = _hardnessUnit == 'ppm' ? _hardnessGpg / 17.1 : _hardnessGpg;
    // Add 5 GPG per 1 PPM iron
    hardness += _ironPpm * 5;
    return hardness;
  }

  // Daily hardness removal (grains per day)
  double get _dailyGrains {
    return _numberOfPeople * _gallonsPerPerson * _effectiveHardnessGpg;
  }

  // Grains needed between regenerations
  double get _grainsPerCycle {
    return _dailyGrains * _regenDays;
  }

  // Recommended capacity (with 25% safety margin)
  int get _recommendedCapacity {
    final needed = _grainsPerCycle * 1.25;
    for (final size in _softenerSizes) {
      if (size >= needed) return size;
    }
    return _softenerSizes.last;
  }

  // Salt usage per regeneration (lbs)
  double get _saltPerRegen {
    // Approximately 6-8 lbs salt per 10,000 grains regenerated
    return (_recommendedCapacity / 10000) * 7;
  }

  // Monthly salt usage (lbs)
  double get _monthlySalt {
    final regensPerMonth = 30 / _regenDays;
    return _saltPerRegen * regensPerMonth;
  }

  // Water hardness classification
  String get _hardnessClassification {
    final gpg = _effectiveHardnessGpg;
    if (gpg <= 1) return 'Soft';
    if (gpg <= 3.5) return 'Slightly Hard';
    if (gpg <= 7) return 'Moderately Hard';
    if (gpg <= 10.5) return 'Hard';
    return 'Very Hard';
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
          'Water Softener Sizing',
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
          _buildHardnessCard(colors),
          const SizedBox(height: 16),
          _buildIronCard(colors),
          const SizedBox(height: 16),
          _buildRegenCard(colors),
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
            '${(_recommendedCapacity / 1000).toStringAsFixed(0)}K',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Grain Capacity Recommended',
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
                _buildResultRow(colors, 'Daily Grains', '${_dailyGrains.toStringAsFixed(0)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Grains Per Cycle', '${_grainsPerCycle.toStringAsFixed(0)}', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Regen Every', '$_regenDays days'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Effective Hardness', '${_effectiveHardnessGpg.toStringAsFixed(1)} GPG'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Classification', _hardnessClassification),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Salt/Regen', '${_saltPerRegen.toStringAsFixed(1)} lbs'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Monthly Salt', '${_monthlySalt.toStringAsFixed(0)} lbs'),
              ],
            ),
          ),
          if (_ironPpm > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: colors.accentWarning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Iron adds ${(_ironPpm * 5).toStringAsFixed(1)} GPG equivalent. Consider iron filter for >1 PPM.',
                      style: TextStyle(color: colors.accentWarning, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            'HOUSEHOLD',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('People', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildCounter(colors, _numberOfPeople, 1, 10, (v) => setState(() => _numberOfPeople = v)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gal/Person/Day', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [50, 75, 100].map((gal) {
                        final isSelected = _gallonsPerPerson == gal.toDouble();
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _gallonsPerPerson = gal.toDouble());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.accentPrimary : colors.bgBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$gal',
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(ZaftoColors colors, int value, int min, int max, void Function(int) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > min ? () { HapticFeedback.selectionClick(); onChanged(value - 1); } : null,
            icon: Icon(LucideIcons.minus, color: value > min ? colors.textSecondary : colors.textQuaternary, size: 18),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text('$value', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            onPressed: value < max ? () { HapticFeedback.selectionClick(); onChanged(value + 1); } : null,
            icon: Icon(LucideIcons.plus, color: value < max ? colors.accentPrimary : colors.textQuaternary, size: 18),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildHardnessCard(ZaftoColors colors) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WATER HARDNESS',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  _buildUnitChip(colors, 'gpg', 'GPG'),
                  const SizedBox(width: 6),
                  _buildUnitChip(colors, 'ppm', 'PPM'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_hardnessGpg.toStringAsFixed(1)} ${_hardnessUnit.toUpperCase()}',
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
                    value: _hardnessGpg,
                    min: 0,
                    max: _hardnessUnit == 'gpg' ? 30 : 500,
                    divisions: _hardnessUnit == 'gpg' ? 60 : 100,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _hardnessGpg = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _hardnessLevels.entries.map((entry) {
              final gpg = _hardnessUnit == 'gpg' ? entry.value.gpg : entry.value.gpg * 17.1;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _hardnessGpg = gpg);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(color: colors.textTertiary, fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitChip(ZaftoColors colors, String value, String label) {
    final isSelected = _hardnessUnit == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (value == 'ppm' && _hardnessUnit == 'gpg') {
            _hardnessGpg = _hardnessGpg * 17.1;
          } else if (value == 'gpg' && _hardnessUnit == 'ppm') {
            _hardnessGpg = _hardnessGpg / 17.1;
          }
          _hardnessUnit = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildIronCard(ZaftoColors colors) {
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
            'IRON CONTENT (PPM)',
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
                '${_ironPpm.toStringAsFixed(1)} PPM',
                style: TextStyle(
                  color: _ironPpm > 0 ? colors.accentWarning : colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentWarning,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentWarning,
                  ),
                  child: Slider(
                    value: _ironPpm,
                    min: 0,
                    max: 5,
                    divisions: 50,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _ironPpm = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            '0-0.3 PPM: No treatment. 0.3-3 PPM: Softener handles. >3 PPM: Iron filter needed.',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRegenCard(ZaftoColors colors) {
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
            'REGENERATION FREQUENCY',
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
            children: [3, 5, 7, 10, 14].map((days) {
              final isSelected = _regenDays == days;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _regenDays = days);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$days days',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '7 days typical. Shorter = more salt, softer water. Longer = less salt, risk of hard water.',
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
            'STANDARD SOFTENER SIZES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._softenerSizes.map((size) {
            final isSelected = _recommendedCapacity == size;
            final household = (size / (_effectiveHardnessGpg * 75 * 7)).floor();
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
                    width: 70,
                    child: Text(
                      '${(size / 1000).toStringAsFixed(0)}K grains',
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Up to $household people @ 10 GPG',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                    ),
                  ),
                  if (isSelected)
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Water Quality Association',
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
            '• 1 GPG = 17.1 PPM (mg/L)\n'
            '• Average person uses 75 gal/day\n'
            '• Iron adds 5 GPG equivalent per PPM\n'
            '• Size for 7-day regen cycle typical\n'
            '• Salt: ~7 lbs per 10K grains regenerated\n'
            '• Install on main line after meter',
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
