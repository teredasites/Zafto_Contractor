import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Firestop Penetration Calculator - Design System v2.6
///
/// Determines firestop requirements for pipe penetrations.
/// Covers wall and floor assemblies with various pipe materials.
///
/// References: IBC 2024, UL Systems, ASTM E814
class FirestopScreen extends ConsumerStatefulWidget {
  const FirestopScreen({super.key});
  @override
  ConsumerState<FirestopScreen> createState() => _FirestopScreenState();
}

class _FirestopScreenState extends ConsumerState<FirestopScreen> {
  // Assembly type
  String _assemblyType = 'wall_2hr';

  // Pipe material
  String _pipeMaterial = 'cast_iron';

  // Pipe size (inches)
  double _pipeSize = 4.0;

  // Insulated
  bool _insulated = false;

  static const Map<String, ({String desc, int rating})> _assemblyTypes = {
    'wall_1hr': (desc: '1-Hour Rated Wall', rating: 1),
    'wall_2hr': (desc: '2-Hour Rated Wall', rating: 2),
    'wall_3hr': (desc: '3-Hour Rated Wall', rating: 3),
    'floor_1hr': (desc: '1-Hour Rated Floor', rating: 1),
    'floor_2hr': (desc: '2-Hour Rated Floor', rating: 2),
    'floor_3hr': (desc: '3-Hour Rated Floor', rating: 3),
  };

  static const Map<String, ({String desc, bool combustible, String firestop})> _pipeMaterials = {
    'cast_iron': (desc: 'Cast Iron', combustible: false, firestop: 'Caulk or putty'),
    'copper': (desc: 'Copper', combustible: false, firestop: 'Caulk or putty'),
    'steel': (desc: 'Steel/Black Iron', combustible: false, firestop: 'Caulk or putty'),
    'cpvc': (desc: 'CPVC', combustible: true, firestop: 'Intumescent wrap + caulk'),
    'pvc': (desc: 'PVC/DWV', combustible: true, firestop: 'Intumescent collar'),
    'pex': (desc: 'PEX', combustible: true, firestop: 'Intumescent wrap'),
    'abs': (desc: 'ABS', combustible: true, firestop: 'Intumescent collar'),
  };

  // Standard pipe sizes
  static const List<double> _pipeSizes = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 6.0, 8.0];

  // Firestop method
  String get _firestopMethod {
    final material = _pipeMaterials[_pipeMaterial];
    if (material == null) return 'UL Listed system';

    if (material.combustible) {
      if (_pipeSize >= 4) return 'Intumescent collar + caulk';
      return material.firestop;
    }

    return material.firestop;
  }

  // Annular space requirements
  String get _annularSpace {
    final material = _pipeMaterials[_pipeMaterial];
    if (material?.combustible ?? false) {
      return '½\" max each side';
    }
    return '1\" max each side';
  }

  // Through-penetration rating required
  String get _ratingRequired {
    final assembly = _assemblyTypes[_assemblyType];
    return '${assembly?.rating ?? 2}-Hour F/T Rating';
  }

  // UL system number hint
  String get _ulSystemHint {
    final isCombustible = _pipeMaterials[_pipeMaterial]?.combustible ?? false;
    final isFloor = _assemblyType.contains('floor');

    if (isCombustible && isFloor) return 'Look for: WL, FC systems';
    if (isCombustible) return 'Look for: W, WL systems';
    if (isFloor) return 'Look for: FC, C-AJ systems';
    return 'Look for: W, C-AJ systems';
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
          'Firestop Penetrations',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildAssemblyCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildInsulatedCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final material = _pipeMaterials[_pipeMaterial];
    final isCombustible = material?.combustible ?? false;

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
            _firestopMethod,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Firestop Method',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (isCombustible) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.flame, color: colors.accentWarning, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Combustible material - special requirements',
                    style: TextStyle(color: colors.accentWarning, fontSize: 11),
                  ),
                ],
              ),
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
                _buildResultRow(colors, 'Pipe Material', material?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Size', '${_pipeSize}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Rating Required', _ratingRequired),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Annular Space', _annularSpace),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Insulated', _insulated ? 'Yes' : 'No'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _ulSystemHint,
              style: TextStyle(color: colors.accentPrimary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssemblyCard(ZaftoColors colors) {
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
            'ASSEMBLY TYPE',
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
            children: _assemblyTypes.entries.map((entry) {
              final isSelected = _assemblyType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _assemblyType = entry.key);
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

  Widget _buildMaterialCard(ZaftoColors colors) {
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
          ..._pipeMaterials.entries.map((entry) {
            final isSelected = _pipeMaterial == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeMaterial = entry.key);
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
                      if (entry.value.combustible)
                        Icon(
                          LucideIcons.flame,
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.accentWarning,
                          size: 14,
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
              Text('Nominal Size', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_pipeSize}\"',
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
              value: _pipeSizes.indexOf(_pipeSize).toDouble(),
              min: 0,
              max: (_pipeSizes.length - 1).toDouble(),
              divisions: _pipeSizes.length - 1,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pipeSize = _pipeSizes[v.round()]);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1.0, 2.0, 3.0, 4.0, 6.0].map((size) {
              final isSelected = (_pipeSize - size).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$size\"',
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

  Widget _buildInsulatedCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _insulated ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _insulated ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _insulated = !_insulated);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _insulated ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _insulated ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _insulated
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pipe is Insulated',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Requires specific UL system for insulated pipes',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              Icon(LucideIcons.flame, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IBC 2024 Section 714',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Use UL listed systems only\n'
            '• F rating ≥ assembly rating\n'
            '• T rating where required\n'
            '• Install per manufacturer\n'
            '• Document system numbers\n'
            '• Inspection before concealing',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
