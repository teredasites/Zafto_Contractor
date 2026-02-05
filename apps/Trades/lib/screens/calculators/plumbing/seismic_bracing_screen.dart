import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Seismic Bracing Calculator - Design System v2.6
///
/// Determines seismic bracing requirements for piping systems.
/// Based on pipe size, weight, and seismic design category.
///
/// References: ASCE 7, SMACNA, IPC Chapter 3
class SeismicBracingScreen extends ConsumerStatefulWidget {
  const SeismicBracingScreen({super.key});
  @override
  ConsumerState<SeismicBracingScreen> createState() => _SeismicBracingScreenState();
}

class _SeismicBracingScreenState extends ConsumerState<SeismicBracingScreen> {
  // Pipe size (inches)
  double _pipeSize = 4;

  // Pipe material
  String _pipeMaterial = 'steel';

  // Seismic design category
  String _seismicCategory = 'D';

  // Building height above grade (feet)
  double _buildingHeight = 30;

  static const Map<String, ({String desc, double weightPerFt})> _pipeMaterials = {
    'steel': (desc: 'Steel (Sch 40)', weightPerFt: 1.0),
    'copper': (desc: 'Copper (Type L)', weightPerFt: 0.7),
    'cast_iron': (desc: 'Cast Iron', weightPerFt: 1.5),
    'pvc': (desc: 'PVC (Sch 40)', weightPerFt: 0.3),
    'cpvc': (desc: 'CPVC', weightPerFt: 0.25),
  };

  static const Map<String, ({String desc, bool bracingRequired, double spacing})> _seismicCategories = {
    'A': (desc: 'A - Very Low', bracingRequired: false, spacing: 0),
    'B': (desc: 'B - Low', bracingRequired: false, spacing: 0),
    'C': (desc: 'C - Moderate', bracingRequired: true, spacing: 40),
    'D': (desc: 'D - Moderate-High', bracingRequired: true, spacing: 30),
    'E': (desc: 'E - High', bracingRequired: true, spacing: 24),
    'F': (desc: 'F - Very High', bracingRequired: true, spacing: 20),
  };

  // Pipe weight per foot (approx)
  double get _pipeWeight {
    final baseFactor = _pipeMaterials[_pipeMaterial]?.weightPerFt ?? 1.0;
    // Simplified: weight increases with square of diameter
    return baseFactor * (_pipeSize * _pipeSize * 0.1);
  }

  // Bracing required
  bool get _bracingRequired {
    final catData = _seismicCategories[_seismicCategory];
    if (catData == null) return false;
    if (!catData.bracingRequired) return false;
    // IPC: Bracing required for pipe 1" and larger in SDC C-F
    return _pipeSize >= 1.0;
  }

  // Maximum brace spacing (feet)
  int get _braceSpacing {
    if (!_bracingRequired) return 0;
    final baseSpacing = _seismicCategories[_seismicCategory]?.spacing ?? 40;
    // Reduce spacing for heavier pipe
    if (_pipeSize >= 6) return (baseSpacing * 0.75).round();
    if (_pipeSize >= 4) return (baseSpacing * 0.85).round();
    return baseSpacing.round();
  }

  // Lateral brace type
  String get _lateralBraceType {
    if (_pipeSize <= 2) return 'Wire restraint';
    if (_pipeSize <= 4) return 'Strut brace';
    return 'Strut brace or cable';
  }

  // Longitudinal brace type
  String get _longitudinalBraceType {
    if (_pipeSize <= 2) return 'Wire restraint';
    if (_pipeSize <= 4) return 'Strut brace';
    return 'Strut brace or sway brace';
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
          'Seismic Bracing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSeismicCategoryCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildPipeMaterialCard(colors),
          const SizedBox(height: 16),
          _buildBuildingCard(colors),
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
          if (_bracingRequired) ...[
            Text(
              '$_braceSpacing\'',
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 56,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
              ),
            ),
            Text(
              'Max Brace Spacing',
              style: TextStyle(color: colors.textTertiary, fontSize: 14),
            ),
          ] else ...[
            Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 56),
            const SizedBox(height: 8),
            Text(
              'Not Required',
              style: TextStyle(
                color: colors.accentSuccess,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Seismic bracing not required for SDC $_seismicCategory',
              style: TextStyle(color: colors.textTertiary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Seismic Category', _seismicCategories[_seismicCategory]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Size', '${_pipeSize.toStringAsFixed(0)}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Weight', '${_pipeWeight.toStringAsFixed(1)} lbs/ft'),
                if (_bracingRequired) ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Lateral Brace', _lateralBraceType),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Longitudinal Brace', _longitudinalBraceType),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeismicCategoryCard(ZaftoColors colors) {
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
            'SEISMIC DESIGN CATEGORY',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._seismicCategories.entries.map((entry) {
            final isSelected = _seismicCategory == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _seismicCategory = entry.key);
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
                        entry.value.bracingRequired ? 'Required' : 'Not Req.',
                        style: TextStyle(
                          color: isSelected
                              ? (colors.isDark ? Colors.black54 : Colors.white70)
                              : (entry.value.bracingRequired ? colors.accentWarning : colors.textTertiary),
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
            'PIPE SIZE',
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
              Text('Nominal Diameter', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_pipeSize.toStringAsFixed(0)}\"',
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
              value: _pipeSize,
              min: 0.5,
              max: 12,
              divisions: 23,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pipeSize = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeMaterialCard(ZaftoColors colors) {
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
            'PIPE MATERIAL',
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
            children: _pipeMaterials.entries.map((entry) {
              final isSelected = _pipeMaterial == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeMaterial = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  Widget _buildBuildingCard(ZaftoColors colors) {
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
            'BUILDING HEIGHT',
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
              Text('Height Above Grade', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_buildingHeight.toStringAsFixed(0)} ft',
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
              value: _buildingHeight,
              min: 10,
              max: 200,
              divisions: 38,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _buildingHeight = v);
              },
            ),
          ),
          Text(
            'Higher floors require more bracing attention',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
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
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
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
              Icon(LucideIcons.activity, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ASCE 7 / IPC Chapter 3',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• SDC determined by soil and location\n'
            '• Bracing both lateral and longitudinal\n'
            '• Flexible connections at equipment\n'
            '• Clearance at building joints\n'
            '• Engineer of record approval\n'
            '• Check local amendments',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
