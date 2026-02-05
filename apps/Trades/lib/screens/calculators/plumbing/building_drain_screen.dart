import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Building Drain Sizing - Design System v2.6
///
/// Sizes building drain and building sewer based on DFU load and slope.
/// Main horizontal drain from all stacks to outside building.
///
/// References: IPC 2024 Table 710.1(2)
class BuildingDrainScreen extends ConsumerStatefulWidget {
  const BuildingDrainScreen({super.key});
  @override
  ConsumerState<BuildingDrainScreen> createState() => _BuildingDrainScreenState();
}

class _BuildingDrainScreenState extends ConsumerState<BuildingDrainScreen> {
  // Total DFU load
  double _totalDFU = 50.0;

  // Drain slope
  String _slope = '1/8';

  // Building type
  String _buildingType = 'residential';

  // Sizing table per IPC Table 710.1(2)
  // Building drains and sewers - max DFU
  static const Map<String, List<({String size, int slope125, int slope25, int slope50})>> _sizingData = {
    'standard': [
      (size: '2"', slope125: 0, slope25: 21, slope50: 26),
      (size: '2-1/2"', slope125: 0, slope25: 24, slope50: 31),
      (size: '3"', slope125: 36, slope25: 42, slope50: 50),
      (size: '4"', slope125: 180, slope25: 216, slope50: 250),
      (size: '5"', slope125: 390, slope25: 480, slope50: 575),
      (size: '6"', slope125: 700, slope25: 840, slope50: 1000),
      (size: '8"', slope125: 1400, slope25: 1680, slope50: 2000),
      (size: '10"', slope125: 2500, slope25: 3000, slope50: 3600),
      (size: '12"', slope125: 3900, slope25: 4600, slope50: 5600),
    ],
  };

  // Slope options
  static const List<({String label, String value, double decimal})> _slopeOptions = [
    (label: '1/8" per ft', value: '1/8', decimal: 0.125),
    (label: '1/4" per ft', value: '1/4', decimal: 0.25),
    (label: '1/2" per ft', value: '1/2', decimal: 0.5),
  ];

  // Building types with DFU multipliers
  static const Map<String, ({String name, String note})> _buildingTypes = {
    'residential': (name: 'Residential', note: 'Single/multi-family'),
    'commercial': (name: 'Commercial', note: 'Office, retail'),
    'restaurant': (name: 'Restaurant', note: 'High grease load'),
    'industrial': (name: 'Industrial', note: 'Process drainage'),
    'school': (name: 'School', note: 'High peak demand'),
    'hospital': (name: 'Hospital', note: 'Medical waste'),
  };

  int get _maxDFUForSlope {
    switch (_slope) {
      case '1/8':
        return _sizingData['standard']!.last.slope125;
      case '1/4':
        return _sizingData['standard']!.last.slope25;
      case '1/2':
        return _sizingData['standard']!.last.slope50;
      default:
        return _sizingData['standard']!.last.slope25;
    }
  }

  String get _recommendedSize {
    final dfu = _totalDFU.toInt();
    final data = _sizingData['standard']!;

    for (final pipe in data) {
      int maxDFU;
      switch (_slope) {
        case '1/8':
          maxDFU = pipe.slope125;
          break;
        case '1/4':
          maxDFU = pipe.slope25;
          break;
        case '1/2':
          maxDFU = pipe.slope50;
          break;
        default:
          maxDFU = pipe.slope25;
      }

      if (maxDFU > 0 && dfu <= maxDFU) {
        return pipe.size;
      }
    }
    return '12" or larger';
  }

  // Check if 1/8" slope is allowed for this size
  bool get _requires14Slope {
    // Per IPC, pipes 2" and 2-1/2" cannot use 1/8" slope
    return _recommendedSize == '2"' || _recommendedSize == '2-1/2"';
  }

  // Capacity percentage
  double get _capacityUsed {
    final dfu = _totalDFU.toInt();
    final data = _sizingData['standard']!;

    for (final pipe in data) {
      int maxDFU;
      switch (_slope) {
        case '1/8':
          maxDFU = pipe.slope125;
          break;
        case '1/4':
          maxDFU = pipe.slope25;
          break;
        case '1/2':
          maxDFU = pipe.slope50;
          break;
        default:
          maxDFU = pipe.slope25;
      }

      if (maxDFU > 0 && dfu <= maxDFU) {
        return (dfu / maxDFU) * 100;
      }
    }
    return 100;
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
          'Building Drain Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildDFUCard(colors),
          const SizedBox(height: 16),
          _buildSlopeCard(colors),
          const SizedBox(height: 16),
          _buildBuildingTypeCard(colors),
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
            _recommendedSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Minimum Building Drain Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (_requires14Slope && _slope == '1/8') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '1/8" slope not allowed for this size',
                    style: TextStyle(
                      color: colors.accentError,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Total DFU', _totalDFU.toStringAsFixed(0)),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Slope', _slopeOptions.firstWhere((s) => s.value == _slope).label),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Building Type', _buildingTypes[_buildingType]?.name ?? 'Standard'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Capacity Used', '${_capacityUsed.toStringAsFixed(0)}%', highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDFUCard(ZaftoColors colors) {
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
            'TOTAL DRAINAGE FIXTURE UNITS',
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
                '${_totalDFU.toStringAsFixed(0)} DFU',
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
                    value: _totalDFU,
                    min: 10,
                    max: 500,
                    divisions: 49,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _totalDFU = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Sum of all fixture DFU values draining to this line',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Typical Totals:', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('1-2 Bath Home: 25-40 DFU', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                Text('3-4 Bath Home: 45-75 DFU', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                Text('Small Office: 50-100 DFU', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                Text('Restaurant: 100-300 DFU', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeCard(ZaftoColors colors) {
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
            'DRAIN SLOPE',
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
            children: _slopeOptions.map((option) {
              final isSelected = _slope == option.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _slope = option.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    option.label,
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
            '1/8"/ft min for 3"+, 1/4"/ft min for smaller',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingTypeCard(ZaftoColors colors) {
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
            'BUILDING TYPE',
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
            children: _buildingTypes.entries.map((entry) {
              final isSelected = _buildingType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _buildingType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.name,
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
            'IPC TABLE 710.1(2) - BUILDING DRAINS',
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
              const SizedBox(width: 50),
              Expanded(child: Text('1/8"/ft', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
              Expanded(child: Text('1/4"/ft', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
              Expanded(child: Text('1/2"/ft', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
            ],
          ),
          const SizedBox(height: 6),
          ..._sizingData['standard']!.map((pipe) {
            final isRecommended = pipe.size == _recommendedSize;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isRecommended ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      pipe.size,
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pipe.slope125 == 0 ? '-' : '${pipe.slope125}',
                      style: TextStyle(color: pipe.slope125 == 0 ? colors.textTertiary : colors.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(child: Text('${pipe.slope25}', style: TextStyle(color: colors.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text('${pipe.slope50}', style: TextStyle(color: colors.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Maximum DFU for each pipe size and slope',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
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
                'IPC 2024 Section 710',
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
            '• 710.1 - Drainage pipe sizing\n'
            '• Table 710.1(2) - Building drains/sewers\n'
            '• Min 1/4"/ft slope for < 3" pipe\n'
            '• Min 1/8"/ft slope for 3"+ pipe\n'
            '• Consider future expansion\n'
            '• Verify cleanout placement',
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
