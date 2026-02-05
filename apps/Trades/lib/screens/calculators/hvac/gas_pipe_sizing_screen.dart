import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Gas Pipe Sizing Calculator - Design System v2.6
///
/// Sizes natural gas and LP piping based on BTU load and length.
/// Uses longest run method per IFGC.
///
/// References: IFGC 2024, NFPA 54
class GasPipeSizingScreen extends ConsumerStatefulWidget {
  const GasPipeSizingScreen({super.key});
  @override
  ConsumerState<GasPipeSizingScreen> createState() => _GasPipeSizingScreenState();
}

class _GasPipeSizingScreenState extends ConsumerState<GasPipeSizingScreen> {
  // Total BTU load
  double _btuLoad = 150000;

  // Pipe length (feet)
  double _pipeLength = 50;

  // Gas type
  String _gasType = 'natural';

  // Pressure drop allowed (inches w.c.)
  double _pressureDrop = 0.5;

  // Pipe material
  String _pipeMaterial = 'black_iron';

  static const Map<String, ({String desc, double factor})> _gasTypes = {
    'natural': (desc: 'Natural Gas', factor: 1.0),
    'propane': (desc: 'Propane (LP)', factor: 0.5),
  };

  static const Map<String, ({String desc, double factor})> _pipeMaterials = {
    'black_iron': (desc: 'Black Iron', factor: 1.0),
    'csst': (desc: 'CSST (Flexible)', factor: 1.1),
    'copper': (desc: 'Copper Type K/L', factor: 0.95),
    'pe': (desc: 'PE Plastic (Underground)', factor: 1.0),
  };

  // Simplified sizing chart (Natural gas, 0.5" w.c. drop)
  // BTU capacity by pipe size and length
  static const Map<int, Map<int, int>> _sizingChart = {
    // Length (ft) -> BTU capacity
    // 1/2" pipe
    50: {50: 60000, 75: 49000, 100: 42000, 150: 35000, 200: 30000},
    // 3/4" pipe
    75: {50: 151000, 75: 124000, 100: 107000, 150: 88000, 200: 76000},
    // 1" pipe
    100: {50: 323000, 75: 263000, 100: 228000, 150: 186000, 200: 162000},
    // 1-1/4" pipe
    125: {50: 608000, 75: 496000, 100: 430000, 150: 351000, 200: 304000},
    // 1-1/2" pipe
    150: {50: 970000, 75: 791000, 100: 685000, 150: 559000, 200: 485000},
    // 2" pipe
    200: {50: 1920000, 75: 1570000, 100: 1360000, 150: 1110000, 200: 963000},
  };

  // Get required pipe size
  String get _requiredSize {
    final adjustedBtu = _btuLoad / (_gasTypes[_gasType]?.factor ?? 1.0);
    final lengths = [50, 75, 100, 150, 200];
    final roundedLength = lengths.firstWhere((l) => l >= _pipeLength, orElse: () => 200);

    // Check each pipe size
    final sizes = [50, 75, 100, 125, 150, 200];
    for (final size in sizes) {
      final capacity = _sizingChart[size]?[roundedLength] ?? 0;
      final adjustedCapacity = capacity / (_pipeMaterials[_pipeMaterial]?.factor ?? 1.0);
      if (adjustedCapacity >= adjustedBtu) {
        return _getSizeLabel(size);
      }
    }
    return '2\"+ (Consult engineer)';
  }

  String _getSizeLabel(int size) {
    switch (size) {
      case 50: return '½\"';
      case 75: return '¾\"';
      case 100: return '1\"';
      case 125: return '1¼\"';
      case 150: return '1½\"';
      case 200: return '2\"';
      default: return '${size / 100}\"';
    }
  }

  // CFH (cubic feet per hour)
  double get _cfh => _btuLoad / (_gasType == 'natural' ? 1000 : 2500);

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
          'Gas Pipe Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildBtuCard(colors),
          const SizedBox(height: 16),
          _buildLengthCard(colors),
          const SizedBox(height: 16),
          _buildGasTypeCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
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
            _requiredSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Minimum Pipe Size',
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
                _buildResultRow(colors, 'Total BTU', '${(_btuLoad / 1000).toStringAsFixed(0)}K BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Flow Rate', '${_cfh.toStringAsFixed(0)} CFH'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Length', '${_pipeLength.toStringAsFixed(0)} ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Gas Type', _gasTypes[_gasType]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Max Pressure Drop', '${_pressureDrop.toStringAsFixed(1)}\" w.c.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBtuCard(ZaftoColors colors) {
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
            'TOTAL BTU LOAD',
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
              Text('BTU/hr', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${(_btuLoad / 1000).toStringAsFixed(0)}K',
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
              value: _btuLoad,
              min: 30000,
              max: 500000,
              divisions: 47,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _btuLoad = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [60, 100, 150, 200, 300].map((btu) {
              final value = btu * 1000;
              final isSelected = (_btuLoad - value).abs() < 10000;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _btuLoad = value.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${btu}K',
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
              Text('Longest Run', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_pipeLength.toStringAsFixed(0)} ft',
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
              value: _pipeLength,
              min: 10,
              max: 200,
              divisions: 38,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pipeLength = v);
              },
            ),
          ),
          Text(
            'Use longest run method from meter',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildGasTypeCard(ZaftoColors colors) {
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
            'GAS TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _gasTypes.entries.map((entry) {
              final isSelected = _gasType == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _gasType = entry.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
                'IFGC 2024 / NFPA 54',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Use longest run method\n'
            '• Include fitting equiv. lengths\n'
            '• Max 0.5\" w.c. drop typical\n'
            '• Support per code tables\n'
            '• Pressure test before use\n'
            '• CSST requires bonding',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
