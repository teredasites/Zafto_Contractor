import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import 'dart:math' as math;

/// Pipe Sleeve Sizing Calculator - Design System v2.6
///
/// Calculates sleeve size for pipe penetrations through walls and floors.
/// Includes clearance for insulation and firestopping.
///
/// References: IPC 2024, ASTM E814
class PipeSleeveScreen extends ConsumerStatefulWidget {
  const PipeSleeveScreen({super.key});
  @override
  ConsumerState<PipeSleeveScreen> createState() => _PipeSleeveScreenState();
}

class _PipeSleeveScreenState extends ConsumerState<PipeSleeveScreen> {
  // Pipe OD (inches)
  double _pipeOd = 2.375;

  // Insulation thickness (inches)
  double _insulationThickness = 0;

  // Penetration type
  String _penetrationType = 'concrete_floor';

  // Fire rating required
  String _fireRating = 'none';

  static const Map<String, ({String desc, double minClearance})> _penetrationTypes = {
    'concrete_floor': (desc: 'Concrete Floor', minClearance: 0.25),
    'concrete_wall': (desc: 'Concrete Wall', minClearance: 0.25),
    'cmu_wall': (desc: 'CMU Wall', minClearance: 0.5),
    'wood_floor': (desc: 'Wood Floor', minClearance: 0.5),
    'wood_wall': (desc: 'Wood Stud Wall', minClearance: 0.75),
    'metal_deck': (desc: 'Metal Deck', minClearance: 0.25),
  };

  static const Map<String, ({String desc, double addClearance})> _fireRatings = {
    'none': (desc: 'Non-rated', addClearance: 0),
    '1_hour': (desc: '1-Hour', addClearance: 0.25),
    '2_hour': (desc: '2-Hour', addClearance: 0.5),
    '3_hour': (desc: '3-Hour', addClearance: 0.75),
  };

  // Common pipe ODs
  static const Map<String, double> _pipeODs = {
    '½\" Copper': 0.625,
    '¾\" Copper': 0.875,
    '1\" Copper': 1.125,
    '1¼\" Copper': 1.375,
    '1½\" Copper': 1.625,
    '2\" Copper': 2.125,
    '½\" PEX': 0.625,
    '¾\" PEX': 0.875,
    '1\" PEX': 1.125,
    '1½\" PVC': 1.9,
    '2\" PVC': 2.375,
    '3\" PVC': 3.5,
    '4\" PVC': 4.5,
    '2\" Cast Iron': 2.3,
    '3\" Cast Iron': 3.3,
    '4\" Cast Iron': 4.38,
  };

  // Total OD including insulation
  double get _totalOd => _pipeOd + (_insulationThickness * 2);

  // Minimum clearance
  double get _minClearance {
    final baseClearance = _penetrationTypes[_penetrationType]?.minClearance ?? 0.25;
    final fireClearance = _fireRatings[_fireRating]?.addClearance ?? 0;
    return baseClearance + fireClearance;
  }

  // Required sleeve ID
  double get _sleeveId => _totalOd + (_minClearance * 2);

  // Recommended sleeve size (round up to standard)
  String get _recommendedSleeve {
    final id = _sleeveId;
    if (id <= 1.5) return '1½\" (ID: 1.61\")';
    if (id <= 2.0) return '2\" (ID: 2.07\")';
    if (id <= 2.5) return '2½\" (ID: 2.47\")';
    if (id <= 3.0) return '3\" (ID: 3.07\")';
    if (id <= 3.5) return '3½\" (ID: 3.55\")';
    if (id <= 4.0) return '4\" (ID: 4.03\")';
    if (id <= 5.0) return '5\" (ID: 5.05\")';
    if (id <= 6.0) return '6\" (ID: 6.07\")';
    if (id <= 8.0) return '8\" (ID: 7.98\")';
    return '10\" (ID: 10.02\")';
  }

  // Annular space for firestop
  double get _annularSpace => (_sleeveId - _totalOd) / 2;

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
          'Pipe Sleeve Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildInsulationCard(colors),
          const SizedBox(height: 16),
          _buildPenetrationCard(colors),
          const SizedBox(height: 16),
          _buildFireRatingCard(colors),
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
            _recommendedSleeve.split(' ')[0],
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Sleeve Size',
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
                _buildResultRow(colors, 'Pipe OD', '${_pipeOd.toStringAsFixed(3)}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total OD (w/insulation)', '${_totalOd.toStringAsFixed(3)}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Clearance', '${_minClearance.toStringAsFixed(2)}\" each side'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Required Sleeve ID', '${_sleeveId.toStringAsFixed(2)}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Annular Space', '${_annularSpace.toStringAsFixed(2)}\"'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizeCard(ZaftoColors colors) {
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
            'PIPE SIZE (OD)',
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
              Text('Outside Diameter', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_pipeOd.toStringAsFixed(3)}\"',
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
              value: _pipeOd,
              min: 0.5,
              max: 10,
              divisions: 95,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pipeOd = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Common Pipe ODs:',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _pipeODs.entries.take(8).map((entry) {
              final isSelected = (_pipeOd - entry.value).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeOd = entry.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 10,
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

  Widget _buildInsulationCard(ZaftoColors colors) {
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
            'INSULATION THICKNESS',
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
              Text('Thickness', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                _insulationThickness == 0 ? 'None' : '${_insulationThickness.toStringAsFixed(2)}\"',
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
              value: _insulationThickness,
              min: 0,
              max: 2,
              divisions: 16,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _insulationThickness = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.0, 0.5, 1.0, 1.5, 2.0].map((thickness) {
              final isSelected = (_insulationThickness - thickness).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _insulationThickness = thickness);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    thickness == 0 ? 'None' : '${thickness}\"',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
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

  Widget _buildPenetrationCard(ZaftoColors colors) {
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
            'PENETRATION TYPE',
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
            children: _penetrationTypes.entries.map((entry) {
              final isSelected = _penetrationType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _penetrationType = entry.key);
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

  Widget _buildFireRatingCard(ZaftoColors colors) {
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
            'FIRE RATING',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._fireRatings.entries.map((entry) {
            final isSelected = _fireRating == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _fireRating = entry.key);
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
                      if (entry.value.addClearance > 0)
                        Text(
                          '+${entry.value.addClearance}\" clearance',
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
              Icon(LucideIcons.flame, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC / IBC Fire Protection',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• UL classified firestop required\n'
            '• ASTM E814 (UL 1479) tested\n'
            '• Maintain annular space per listing\n'
            '• Intumescent or mineral wool fill\n'
            '• Steel sleeves for fire-rated\n'
            '• Document firestop installations',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
