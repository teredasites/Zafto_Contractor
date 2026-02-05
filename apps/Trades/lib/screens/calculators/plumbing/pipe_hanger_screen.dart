import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pipe Hanger Spacing Calculator - Design System v2.6
///
/// Determines maximum hanger spacing for various pipe materials.
/// Covers horizontal and vertical installations.
///
/// References: IPC 2024 Table 308.5, MSS SP-69
class PipeHangerScreen extends ConsumerStatefulWidget {
  const PipeHangerScreen({super.key});
  @override
  ConsumerState<PipeHangerScreen> createState() => _PipeHangerScreenState();
}

class _PipeHangerScreenState extends ConsumerState<PipeHangerScreen> {
  // Pipe material
  String _pipeMaterial = 'copper';

  // Pipe size (inches)
  double _pipeSize = 1.0;

  // Orientation
  String _orientation = 'horizontal';

  static const Map<String, ({String desc, Map<String, int> spacing})> _pipeMaterials = {
    'copper': (
      desc: 'Copper Tube',
      spacing: {'0.5': 6, '0.75': 6, '1.0': 6, '1.25': 10, '1.5': 10, '2.0': 10, '2.5': 10, '3.0': 10, '4.0': 10}
    ),
    'cpvc': (
      desc: 'CPVC',
      spacing: {'0.5': 3, '0.75': 3, '1.0': 3, '1.25': 4, '1.5': 4, '2.0': 4, '2.5': 4, '3.0': 4, '4.0': 4}
    ),
    'pvc': (
      desc: 'PVC/DWV',
      spacing: {'1.5': 4, '2.0': 4, '3.0': 4, '4.0': 4, '6.0': 4, '8.0': 4}
    ),
    'abs': (
      desc: 'ABS',
      spacing: {'1.5': 4, '2.0': 4, '3.0': 4, '4.0': 4, '6.0': 4, '8.0': 4}
    ),
    'cast_iron': (
      desc: 'Cast Iron',
      spacing: {'2.0': 5, '3.0': 5, '4.0': 5, '6.0': 5, '8.0': 5}
    ),
    'steel': (
      desc: 'Steel/Black Iron',
      spacing: {'0.5': 7, '0.75': 7, '1.0': 7, '1.25': 7, '1.5': 9, '2.0': 10, '2.5': 11, '3.0': 12, '4.0': 14}
    ),
    'pex': (
      desc: 'PEX Tubing',
      spacing: {'0.5': 32, '0.75': 32, '1.0': 32}
    ),
  };

  static const List<double> _pipeSizes = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 6.0, 8.0];

  // Get hanger spacing
  int get _hangerSpacing {
    final material = _pipeMaterials[_pipeMaterial];
    if (material == null) return 10;

    final sizeKey = _pipeSize.toString();
    return material.spacing[sizeKey] ?? 10;
  }

  // Vertical adjustment
  int get _verticalSpacing {
    if (_orientation == 'vertical') {
      // Vertical runs need support at each floor (10' typical) or every other hanger
      return (_hangerSpacing * 2).clamp(10, 15);
    }
    return _hangerSpacing;
  }

  // Hanger type recommendation
  String get _hangerType {
    if (_orientation == 'vertical') {
      return 'Riser clamp';
    }
    switch (_pipeMaterial) {
      case 'copper':
        return 'Copper split ring or clevis';
      case 'cpvc':
      case 'pvc':
      case 'abs':
        return 'Plastic pipe clip or strap';
      case 'cast_iron':
        return 'Cast iron hanger or clevis';
      case 'steel':
        return 'Clevis hanger or roller';
      case 'pex':
        return 'PEX support clip';
      default:
        return 'Appropriate hanger for material';
    }
  }

  // Special notes
  String get _specialNote {
    switch (_pipeMaterial) {
      case 'cpvc':
        return 'Support within 12" of fittings. Allow for thermal movement.';
      case 'pex':
        return 'Support in horizontal runs per manufacturer. PEX needs more support than shown for bundled runs.';
      case 'cast_iron':
        return 'Support at each hub. Use hanger sized for hub OD.';
      default:
        return 'Support within 12\" of fittings and valves.';
    }
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
          'Pipe Hanger Spacing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildOrientationCard(colors),
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
            '$_verticalSpacing\'',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Maximum Spacing',
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
                _buildResultRow(colors, 'Pipe Material', _pipeMaterials[_pipeMaterial]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Size', '${_pipeSize}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Orientation', _orientation == 'horizontal' ? 'Horizontal' : 'Vertical'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hanger Type', _hangerType),
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
              _specialNote,
              style: TextStyle(color: colors.accentPrimary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
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
                  setState(() {
                    _pipeMaterial = entry.key;
                    // Reset pipe size if not available for this material
                    final availableSizes = entry.value.spacing.keys.map((s) => double.parse(s)).toList();
                    if (!availableSizes.contains(_pipeSize)) {
                      _pipeSize = availableSizes.first;
                    }
                  });
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
    final material = _pipeMaterials[_pipeMaterial];
    final availableSizes = material?.spacing.keys.map((s) => double.parse(s)).toList() ?? _pipeSizes;

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSizes.map((size) {
              final isSelected = (_pipeSize - size).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$size\"',
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
        ],
      ),
    );
  }

  Widget _buildOrientationCard(ZaftoColors colors) {
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
            'ORIENTATION',
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
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _orientation = 'horizontal');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _orientation == 'horizontal' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Horizontal',
                        style: TextStyle(
                          color: _orientation == 'horizontal'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _orientation = 'vertical');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _orientation == 'vertical' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Vertical',
                        style: TextStyle(
                          color: _orientation == 'vertical'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
              Icon(LucideIcons.anchor, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Table 308.5',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Support within 12\" of fittings\n'
            '• Base of risers supported\n'
            '• Vertical risers at each floor\n'
            '• Mid-story guide if over 10\'\n'
            '• Allow for thermal movement\n'
            '• No point loads on plastic',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
