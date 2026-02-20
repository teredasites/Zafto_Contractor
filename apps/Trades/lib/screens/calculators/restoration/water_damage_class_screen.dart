import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Damage Classification Calculator - IICRC S500
///
/// Determines IICRC water damage Class (1-4) and Category (1-3)
/// based on source, materials, and conditions.
///
/// References: IICRC S500-2021 Standard for Water Damage Restoration
class WaterDamageClassScreen extends ConsumerStatefulWidget {
  const WaterDamageClassScreen({super.key});
  @override
  ConsumerState<WaterDamageClassScreen> createState() => _WaterDamageClassScreenState();
}

class _WaterDamageClassScreenState extends ConsumerState<WaterDamageClassScreen> {
  // Water source category
  String _waterSource = 'clean';

  // Affected materials
  String _materials = 'nonporous';

  // Duration since loss (hours)
  double _hoursSinceLoss = 12;

  // Area affected percentage (of room)
  double _areaPercent = 25;

  // Standing water present
  bool _standingWater = false;

  // Wall wicking height (inches)
  double _wickingHeight = 0;

  // IICRC S500 Category definitions
  static const Map<String, ({String desc, String detail, int category})> _waterSources = {
    'clean': (
      desc: 'Category 1 — Clean',
      detail: 'Supply line, tub overflow, rain (fresh)',
      category: 1,
    ),
    'gray': (
      desc: 'Category 2 — Gray',
      detail: 'Dishwasher, washing machine, toilet (urine only)',
      category: 2,
    ),
    'black': (
      desc: 'Category 3 — Black',
      detail: 'Sewage, river flood, stagnant water > 72h',
      category: 3,
    ),
  };

  static const Map<String, ({String desc, String detail})> _materialTypes = {
    'nonporous': (
      desc: 'Non-Porous',
      detail: 'Concrete, metal, vinyl, ceramic tile',
    ),
    'semiporous': (
      desc: 'Semi-Porous',
      detail: 'Wood, plaster, drywall (painted)',
    ),
    'porous': (
      desc: 'Porous',
      detail: 'Carpet, pad, insulation, upholstery',
    ),
    'deep_porous': (
      desc: 'Deep-Absorbing',
      detail: 'Hardwood subfloor, crawlspace, plaster walls',
    ),
  };

  // Category may escalate based on time
  int get _effectiveCategory {
    final source = _waterSources[_waterSource];
    final baseCategory = source?.category ?? 1;
    // Per IICRC S500: Cat 1 becomes Cat 2 after 48h, Cat 2 becomes Cat 3 after 72h
    if (baseCategory == 1 && _hoursSinceLoss > 48) return 2;
    if (baseCategory == 2 && _hoursSinceLoss > 72) return 3;
    return baseCategory;
  }

  // IICRC Class determination
  // Class 1: Least amount — small area, minimal absorption
  // Class 2: Significant — entire room, carpet and cushion, wall wicking < 24"
  // Class 3: Extensive — from above, walls, insulation, carpet, subfloor saturated
  // Class 4: Specialty — hardwood, plaster, concrete, crawlspace (low-evaporation materials)
  int get _damageClass {
    if (_materials == 'deep_porous') return 4;
    if (_areaPercent > 75 || _standingWater) {
      if (_wickingHeight > 24) return 3;
      return 3;
    }
    if (_areaPercent > 40 || _wickingHeight > 12) return 2;
    return 1;
  }

  String get _className {
    return switch (_damageClass) {
      1 => 'Class 1 — Least',
      2 => 'Class 2 — Significant',
      3 => 'Class 3 — Extensive',
      4 => 'Class 4 — Specialty',
      _ => 'Unknown',
    };
  }

  String get _classDescription {
    return switch (_damageClass) {
      1 => 'Small area affected, minimal absorption. Water contacts only part of a room or area. Little or no carpet/cushion wet.',
      2 => 'Significant amount of water. Entire room of carpet/cushion wet. Wall wicking 12-24". Structural moisture present.',
      3 => 'Greatest amount of water. Water may have come from overhead. Walls, insulation, carpet, cushion, and subfloor saturated.',
      4 => 'Specialty drying situations. Significant amount of moisture trapped in low-permeance materials (hardwood, plaster, concrete).',
      _ => '',
    };
  }

  String get _responseGuideline {
    final cat = _effectiveCategory;
    final cls = _damageClass;
    if (cat == 3) {
      return 'HAZARDOUS — Full PPE required. Remove and dispose all porous materials. Antimicrobial treatment. Air scrubbers with HEPA filtration. Consider industrial hygienist.';
    }
    if (cat == 2 && cls >= 3) {
      return 'HIGH PRIORITY — Extract water immediately. Remove saturated porous materials. Antimicrobial treatment. Begin structural drying within 24h.';
    }
    if (cls == 4) {
      return 'SPECIALTY DRYING — Low-grain refrigerant dehumidifiers required. Extended drying times. Specialty monitoring (deep probes). May require heat drying systems.';
    }
    if (cls >= 2) {
      return 'STANDARD RESPONSE — Extract standing water. Set up air movers and dehumidifiers. Monitor daily with moisture meters. Document readings.';
    }
    return 'MINOR LOSS — Extract water, clean and dry affected materials. Monitor for 24-48h. May not require professional equipment.';
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
          'Water Damage Classification',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSourceCard(colors),
          const SizedBox(height: 16),
          _buildMaterialsCard(colors),
          const SizedBox(height: 16),
          _buildConditionsCard(colors),
          const SizedBox(height: 16),
          _buildResponseCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final catColor = switch (_effectiveCategory) {
      1 => Colors.blue,
      2 => Colors.orange,
      3 => Colors.red,
      _ => colors.accentPrimary,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: catColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    'Cat $_effectiveCategory',
                    style: TextStyle(
                      color: catColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    switch (_effectiveCategory) {
                      1 => 'Clean Water',
                      2 => 'Gray Water',
                      3 => 'Black Water',
                      _ => 'Unknown',
                    },
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
              Container(width: 1, height: 50, color: colors.borderSubtle),
              Column(
                children: [
                  Text(
                    'Class $_damageClass',
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    switch (_damageClass) {
                      1 => 'Least',
                      2 => 'Significant',
                      3 => 'Extensive',
                      4 => 'Specialty',
                      _ => 'Unknown',
                    },
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _classDescription,
              style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
          if (_effectiveCategory > (_waterSources[_waterSource]?.category ?? 1)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Category escalated due to elapsed time (${_hoursSinceLoss.toStringAsFixed(0)}h)',
                      style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500),
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

  Widget _buildSourceCard(ZaftoColors colors) {
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
            'WATER SOURCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._waterSources.entries.map((entry) {
            final isSelected = _waterSource == entry.key;
            final catColor = switch (entry.value.category) {
              1 => Colors.blue,
              2 => Colors.orange,
              3 => Colors.red,
              _ => colors.accentPrimary,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _waterSource = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? catColor : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.desc,
                        style: TextStyle(
                          color: isSelected ? Colors.white : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.value.detail,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : colors.textTertiary,
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

  Widget _buildMaterialsCard(ZaftoColors colors) {
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
            'PRIMARY AFFECTED MATERIALS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._materialTypes.entries.map((entry) {
            final isSelected = _materials == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _materials = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.desc,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.value.detail,
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

  Widget _buildConditionsCard(ZaftoColors colors) {
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
            'SITE CONDITIONS',
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
              Text('Hours Since Loss', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_hoursSinceLoss.toStringAsFixed(0)}h',
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
              value: _hoursSinceLoss,
              min: 0,
              max: 168,
              divisions: 28,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _hoursSinceLoss = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Affected Area', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_areaPercent.toStringAsFixed(0)}% of room',
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
              value: _areaPercent,
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _areaPercent = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wall Wicking Height', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_wickingHeight.toStringAsFixed(0)}"',
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
              value: _wickingHeight,
              min: 0,
              max: 48,
              divisions: 48,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _wickingHeight = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _standingWater = !_standingWater);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _standingWater ? Colors.red.withValues(alpha: 0.1) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _standingWater ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _standingWater ? LucideIcons.checkCircle : LucideIcons.circle,
                    size: 18,
                    color: _standingWater ? Colors.red : colors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Standing water present',
                    style: TextStyle(
                      color: _standingWater ? Colors.red : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildResponseCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _effectiveCategory == 3
              ? Colors.red.withValues(alpha: 0.3)
              : colors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shieldAlert, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'RESPONSE GUIDELINE',
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
          Text(
            _responseGuideline,
            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.6),
          ),
        ],
      ),
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
                'IICRC S500-2021',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Cat 1 escalates to Cat 2 after 48h\n'
            '• Cat 2 escalates to Cat 3 after 72h\n'
            '• Class 4: low-permeance materials require specialty drying\n'
            '• Document category/class before starting work\n'
            '• Cat 3: full PPE — Tyvek, N95/P100, gloves, boots\n'
            '• Always verify with moisture meter readings',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
