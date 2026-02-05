import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pipe Weight Calculator - Design System v2.6
///
/// Calculates weight of filled pipe for support and structural loads.
/// Covers common plumbing pipe materials.
///
/// References: ASTM Standards, MSS SP-69
class PipeWeightScreen extends ConsumerStatefulWidget {
  const PipeWeightScreen({super.key});
  @override
  ConsumerState<PipeWeightScreen> createState() => _PipeWeightScreenState();
}

class _PipeWeightScreenState extends ConsumerState<PipeWeightScreen> {
  // Pipe material
  String _material = 'copper_l';

  // Pipe size
  String _pipeSize = '2';

  // Length (feet)
  double _length = 100;

  // Include water weight
  bool _includeWater = true;

  // Pipe data: weight per foot (lbs/ft) and ID (inches)
  static const Map<String, Map<String, ({double weightPerFt, double id})>> _pipeData = {
    'copper_k': {
      '0.5': (weightPerFt: 0.269, id: 0.527),
      '0.75': (weightPerFt: 0.418, id: 0.745),
      '1': (weightPerFt: 0.641, id: 0.995),
      '1.25': (weightPerFt: 0.884, id: 1.245),
      '1.5': (weightPerFt: 1.140, id: 1.481),
      '2': (weightPerFt: 1.780, id: 1.959),
      '3': (weightPerFt: 3.580, id: 2.907),
      '4': (weightPerFt: 5.380, id: 3.857),
    },
    'copper_l': {
      '0.5': (weightPerFt: 0.198, id: 0.545),
      '0.75': (weightPerFt: 0.362, id: 0.785),
      '1': (weightPerFt: 0.465, id: 1.025),
      '1.25': (weightPerFt: 0.655, id: 1.265),
      '1.5': (weightPerFt: 0.884, id: 1.505),
      '2': (weightPerFt: 1.140, id: 1.985),
      '3': (weightPerFt: 2.060, id: 2.945),
      '4': (weightPerFt: 2.930, id: 3.905),
    },
    'copper_m': {
      '0.5': (weightPerFt: 0.145, id: 0.569),
      '0.75': (weightPerFt: 0.269, id: 0.811),
      '1': (weightPerFt: 0.328, id: 1.055),
      '1.25': (weightPerFt: 0.465, id: 1.291),
      '1.5': (weightPerFt: 0.682, id: 1.527),
      '2': (weightPerFt: 0.884, id: 2.009),
      '3': (weightPerFt: 1.460, id: 2.981),
      '4': (weightPerFt: 2.060, id: 3.935),
    },
    'steel_sch40': {
      '0.5': (weightPerFt: 0.85, id: 0.622),
      '0.75': (weightPerFt: 1.13, id: 0.824),
      '1': (weightPerFt: 1.68, id: 1.049),
      '1.25': (weightPerFt: 2.27, id: 1.380),
      '1.5': (weightPerFt: 2.72, id: 1.610),
      '2': (weightPerFt: 3.65, id: 2.067),
      '3': (weightPerFt: 7.58, id: 3.068),
      '4': (weightPerFt: 10.79, id: 4.026),
    },
    'pvc_sch40': {
      '0.5': (weightPerFt: 0.057, id: 0.622),
      '0.75': (weightPerFt: 0.077, id: 0.824),
      '1': (weightPerFt: 0.102, id: 1.049),
      '1.25': (weightPerFt: 0.135, id: 1.380),
      '1.5': (weightPerFt: 0.160, id: 1.610),
      '2': (weightPerFt: 0.211, id: 2.067),
      '3': (weightPerFt: 0.424, id: 3.068),
      '4': (weightPerFt: 0.583, id: 4.026),
    },
    'cast_iron': {
      '2': (weightPerFt: 3.50, id: 2.0),
      '3': (weightPerFt: 5.50, id: 3.0),
      '4': (weightPerFt: 9.00, id: 4.0),
    },
  };

  static const Map<String, String> _materialNames = {
    'copper_k': 'Copper Type K',
    'copper_l': 'Copper Type L',
    'copper_m': 'Copper Type M',
    'steel_sch40': 'Steel Sch 40',
    'pvc_sch40': 'PVC Sch 40',
    'cast_iron': 'Cast Iron',
  };

  // Get pipe data for current selection
  ({double weightPerFt, double id})? get _currentPipeData {
    return _pipeData[_material]?[_pipeSize];
  }

  // Pipe weight per foot
  double get _pipeWeightPerFt => _currentPipeData?.weightPerFt ?? 0;

  // Water weight per foot (based on ID)
  double get _waterWeightPerFt {
    final id = _currentPipeData?.id ?? 0;
    // Water weight = π × (ID/2)² × 1 ft × 62.4 lb/ft³ / 144 (convert sq in to sq ft)
    return 3.14159 * (id / 2) * (id / 2) * 62.4 / 144;
  }

  // Total weight per foot
  double get _totalWeightPerFt {
    if (_includeWater) {
      return _pipeWeightPerFt + _waterWeightPerFt;
    }
    return _pipeWeightPerFt;
  }

  // Total weight for length
  double get _totalWeight => _totalWeightPerFt * _length;

  // Available sizes for current material
  List<String> get _availableSizes {
    return _pipeData[_material]?.keys.toList() ?? [];
  }

  String _displaySize(String size) {
    switch (size) {
      case '0.5': return '½\"';
      case '0.75': return '¾\"';
      case '1': return '1\"';
      case '1.25': return '1¼\"';
      case '1.5': return '1½\"';
      case '2': return '2\"';
      case '3': return '3\"';
      case '4': return '4\"';
      default: return '$size\"';
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
          'Pipe Weight',
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
          _buildLengthCard(colors),
          const SizedBox(height: 16),
          _buildWaterToggle(colors),
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
            '${_totalWeight.toStringAsFixed(1)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Total Pounds',
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
                _buildResultRow(colors, 'Material', _materialNames[_material] ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Size', _displaySize(_pipeSize)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Weight', '${_pipeWeightPerFt.toStringAsFixed(3)} lbs/ft'),
                if (_includeWater) ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Water Weight', '${_waterWeightPerFt.toStringAsFixed(3)} lbs/ft'),
                ],
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total per Foot', '${_totalWeightPerFt.toStringAsFixed(3)} lbs/ft'),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _materialNames.entries.map((entry) {
              final isSelected = _material == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _material = entry.key;
                    // Reset size if not available for this material
                    if (!_availableSizes.contains(_pipeSize)) {
                      _pipeSize = _availableSizes.first;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value,
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
            children: _availableSizes.map((size) {
              final isSelected = _pipeSize == size;
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
                    _displaySize(size),
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

  Widget _buildLengthCard(ZaftoColors colors) {
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
            'PIPE LENGTH',
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
              Text('Length', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_length.toStringAsFixed(0)} ft',
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
              value: _length,
              min: 1,
              max: 500,
              divisions: 499,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _length = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _includeWater = !_includeWater);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _includeWater ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _includeWater ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _includeWater
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Include Water Weight',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Add weight of water when pipe is full',
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Weight Considerations',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Include fittings (~10% add)\n'
            '• Account for insulation weight\n'
            '• Safety factor 1.25 for supports\n'
            '• Water = 8.34 lbs/gallon\n'
            '• Seismic adds to support loads\n'
            '• Verify structural capacity',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
