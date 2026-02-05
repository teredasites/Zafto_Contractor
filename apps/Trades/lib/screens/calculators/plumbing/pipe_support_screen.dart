import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pipe Support Spacing Calculator - Design System v2.6
///
/// Determines pipe hanger and support spacing requirements.
/// Based on pipe material, size, and orientation.
///
/// References: IPC 2024 Table 308.5, MSS SP-69
class PipeSupportScreen extends ConsumerStatefulWidget {
  const PipeSupportScreen({super.key});
  @override
  ConsumerState<PipeSupportScreen> createState() => _PipeSupportScreenState();
}

class _PipeSupportScreenState extends ConsumerState<PipeSupportScreen> {
  // Pipe material
  String _material = 'copper';

  // Pipe size
  String _pipeSize = '1';

  // Orientation
  String _orientation = 'horizontal';

  static const Map<String, ({String desc, Map<String, int> horizontalSpacing, int verticalSpacing})> _materials = {
    'copper': (
      desc: 'Copper Tube',
      horizontalSpacing: {'0.5': 6, '0.75': 6, '1': 6, '1.25': 6, '1.5': 8, '2': 8, '2.5': 9, '3': 10, '4': 12},
      verticalSpacing: 10,
    ),
    'cpvc': (
      desc: 'CPVC',
      horizontalSpacing: {'0.5': 3, '0.75': 3, '1': 3, '1.25': 4, '1.5': 4, '2': 4, '2.5': 5, '3': 5, '4': 5},
      verticalSpacing: 5,
    ),
    'pex': (
      desc: 'PEX Tubing',
      horizontalSpacing: {'0.5': 32, '0.75': 32, '1': 32, '1.25': 32, '1.5': 32, '2': 32, '2.5': 32, '3': 32, '4': 32},
      verticalSpacing: 4,
    ),
    'steel': (
      desc: 'Steel Pipe',
      horizontalSpacing: {'0.5': 7, '0.75': 7, '1': 7, '1.25': 7, '1.5': 9, '2': 10, '2.5': 11, '3': 12, '4': 14},
      verticalSpacing: 15,
    ),
    'cast_iron': (
      desc: 'Cast Iron',
      horizontalSpacing: {'0.5': 5, '0.75': 5, '1': 5, '1.25': 5, '1.5': 5, '2': 5, '2.5': 5, '3': 5, '4': 5},
      verticalSpacing: 15,
    ),
    'pvc_dwv': (
      desc: 'PVC DWV',
      horizontalSpacing: {'0.5': 4, '0.75': 4, '1': 4, '1.25': 4, '1.5': 4, '2': 4, '2.5': 4, '3': 4, '4': 4},
      verticalSpacing: 4,
    ),
    'abs': (
      desc: 'ABS',
      horizontalSpacing: {'0.5': 4, '0.75': 4, '1': 4, '1.25': 4, '1.5': 4, '2': 4, '2.5': 4, '3': 4, '4': 4},
      verticalSpacing: 4,
    ),
  };

  static const List<String> _pipeSizes = ['0.5', '0.75', '1', '1.25', '1.5', '2', '2.5', '3', '4'];

  // Get spacing in feet
  int get _spacing {
    final materialData = _materials[_material];
    if (materialData == null) return 6;

    if (_orientation == 'vertical') {
      return materialData.verticalSpacing;
    }
    return materialData.horizontalSpacing[_pipeSize] ?? 6;
  }

  // Hanger type recommendation
  String get _hangerType {
    switch (_material) {
      case 'copper':
        return 'Copper-plated or plastic-coated';
      case 'cpvc':
      case 'pvc_dwv':
      case 'abs':
        return 'Plastic or padded metal';
      case 'pex':
        return 'Plastic clips or J-hooks';
      case 'steel':
        return 'Clevis or ring hanger';
      case 'cast_iron':
        return 'Riser clamp or beam clamp';
      default:
        return 'Per manufacturer';
    }
  }

  // Display pipe size
  String get _displaySize {
    switch (_pipeSize) {
      case '0.5': return '½\"';
      case '0.75': return '¾\"';
      case '1': return '1\"';
      case '1.25': return '1¼\"';
      case '1.5': return '1½\"';
      case '2': return '2\"';
      case '2.5': return '2½\"';
      case '3': return '3\"';
      case '4': return '4\"';
      default: return '$_pipeSize\"';
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
          'Pipe Support Spacing',
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
          _buildSizeCard(colors),
          const SizedBox(height: 16),
          _buildOrientationCard(colors),
          const SizedBox(height: 16),
          _buildSpacingTable(colors),
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
            '$_spacing\'',
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
                _buildResultRow(colors, 'Material', _materials[_material]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Size', _displaySize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Orientation', _orientation == 'horizontal' ? 'Horizontal' : 'Vertical'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hanger Type', _hangerType),
              ],
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
          ..._materials.entries.map((entry) {
            final isSelected = _material == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _material = entry.key);
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

  Widget _buildSizeCard(ZaftoColors colors) {
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
            children: _pipeSizes.map((size) {
              final isSelected = _pipeSize == size;
              String displaySize;
              switch (size) {
                case '0.5': displaySize = '½\"'; break;
                case '0.75': displaySize = '¾\"'; break;
                case '1': displaySize = '1\"'; break;
                case '1.25': displaySize = '1¼\"'; break;
                case '1.5': displaySize = '1½\"'; break;
                case '2': displaySize = '2\"'; break;
                case '2.5': displaySize = '2½\"'; break;
                case '3': displaySize = '3\"'; break;
                case '4': displaySize = '4\"'; break;
                default: displaySize = '$size\"';
              }
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displaySize,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.moveHorizontal,
                          color: _orientation == 'horizontal' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Horizontal',
                          style: TextStyle(
                            color: _orientation == 'horizontal' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.moveVertical,
                          color: _orientation == 'vertical' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vertical',
                          style: TextStyle(
                            color: _orientation == 'vertical' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildSpacingTable(ZaftoColors colors) {
    final materialData = _materials[_material];
    if (materialData == null) return const SizedBox.shrink();

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
            'SPACING TABLE (${materialData.desc})',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader(colors, 'Size'),
                  _buildTableHeader(colors, 'Horizontal'),
                ],
              ),
              ...materialData.horizontalSpacing.entries.map((entry) {
                String displaySize;
                switch (entry.key) {
                  case '0.5': displaySize = '½\"'; break;
                  case '0.75': displaySize = '¾\"'; break;
                  case '1.25': displaySize = '1¼\"'; break;
                  case '1.5': displaySize = '1½\"'; break;
                  case '2.5': displaySize = '2½\"'; break;
                  default: displaySize = '${entry.key}\"';
                }
                final isCurrentSize = entry.key == _pipeSize;
                return TableRow(
                  decoration: isCurrentSize ? BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                  ) : null,
                  children: [
                    _buildTableCell(colors, displaySize, isCurrentSize),
                    _buildTableCell(colors, '${entry.value}\'', isCurrentSize),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vertical: ${materialData.verticalSpacing}\' max (base of riser + each floor)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(ZaftoColors colors, String text, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          color: highlight ? colors.accentPrimary : colors.textPrimary,
          fontSize: 12,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
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
            '• Support at base of vertical risers\n'
            '• Support at each floor for risers\n'
            '• Isolate dissimilar metals\n'
            '• Allow for thermal movement\n'
            '• No point loads on plastic pipe\n'
            '• Mid-span support for horizontal',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
