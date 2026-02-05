import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Gas Pipe Sizing Calculator - Design System v2.6
///
/// Calculates gas pipe size using longest run method per IFGC 2024.
/// Supports natural gas and propane (LP).
///
/// References: IFGC Table 402.4(2), IFGC 402.4, NFPA 54
class GasPipeSizingScreen extends ConsumerStatefulWidget {
  const GasPipeSizingScreen({super.key});
  @override
  ConsumerState<GasPipeSizingScreen> createState() => _GasPipeSizingScreenState();
}

class _GasPipeSizingScreenState extends ConsumerState<GasPipeSizingScreen> {
  // Gas type
  String _gasType = 'natural'; // 'natural' or 'propane'

  // Pipe material
  String _pipeMaterial = 'black_iron'; // 'black_iron', 'csst', 'copper'

  // Pressure
  String _pressure = 'low'; // 'low' (< 2 PSI) or 'high' (2 PSI)

  // Total BTU demand
  double _totalBtu = 0;

  // Longest run in feet
  double _longestRun = 50;

  // Appliance entries
  final List<({String name, int btu})> _appliances = [];

  // Common appliance BTU ratings (approximate)
  static const Map<String, int> _commonAppliances = {
    'Furnace (80k)': 80000,
    'Furnace (100k)': 100000,
    'Furnace (120k)': 120000,
    'Water Heater (40k)': 40000,
    'Water Heater (50k)': 50000,
    'Tankless WH (150k)': 150000,
    'Tankless WH (199k)': 199000,
    'Range/Oven (65k)': 65000,
    'Cooktop (40k)': 40000,
    'Dryer (22k)': 22000,
    'Fireplace (30k)': 30000,
    'Fireplace (50k)': 50000,
    'Pool Heater (250k)': 250000,
    'Pool Heater (400k)': 400000,
    'BBQ Grill (40k)': 40000,
    'Generator (200k)': 200000,
  };

  // Gas pipe capacity tables (CFH at specific lengths)
  // IFGC Table 402.4(2) - Low pressure natural gas, Schedule 40 iron pipe
  // Values: {pipe size: {length: max CFH}}
  static const Map<String, Map<int, int>> _blackIronCapacity = {
    '1/2"': {10: 175, 20: 120, 30: 97, 40: 82, 50: 73, 60: 66, 80: 56, 100: 50, 150: 40, 200: 34},
    '3/4"': {10: 360, 20: 250, 30: 200, 40: 170, 50: 151, 60: 138, 80: 118, 100: 104, 150: 84, 200: 72},
    '1"': {10: 680, 20: 465, 30: 375, 40: 320, 50: 285, 60: 260, 80: 220, 100: 195, 150: 160, 200: 135},
    '1-1/4"': {10: 1400, 20: 950, 30: 770, 40: 660, 50: 580, 60: 530, 80: 450, 100: 400, 150: 325, 200: 280},
    '1-1/2"': {10: 2100, 20: 1460, 30: 1180, 40: 990, 50: 890, 60: 810, 80: 690, 100: 620, 150: 500, 200: 430},
    '2"': {10: 3950, 20: 2750, 30: 2200, 40: 1900, 50: 1680, 60: 1520, 80: 1300, 100: 1150, 150: 950, 200: 800},
    '2-1/2"': {10: 6300, 20: 4350, 30: 3520, 40: 3000, 50: 2650, 60: 2400, 80: 2050, 100: 1850, 150: 1500, 200: 1280},
    '3"': {10: 11000, 20: 7700, 30: 6250, 40: 5300, 50: 4700, 60: 4300, 80: 3700, 100: 3250, 150: 2650, 200: 2280},
  };

  // CSST sizing (EHD-based, simplified)
  static const Map<String, Map<int, int>> _csstCapacity = {
    '3/8" (EHD 13)': {10: 60, 20: 42, 30: 34, 50: 26, 75: 21, 100: 18, 150: 15, 200: 13},
    '1/2" (EHD 18)': {10: 115, 20: 79, 30: 64, 50: 49, 75: 40, 100: 35, 150: 28, 200: 24},
    '3/4" (EHD 23)': {10: 200, 20: 138, 30: 111, 50: 86, 75: 70, 100: 60, 150: 49, 200: 42},
    '1" (EHD 30)': {10: 380, 20: 265, 30: 215, 50: 165, 75: 135, 100: 117, 150: 95, 200: 82},
    '1-1/4" (EHD 37)': {10: 680, 20: 465, 30: 375, 50: 290, 75: 235, 100: 205, 150: 165, 200: 145},
  };

  // Natural gas: 1000 BTU per CFH (approximately 1030)
  // Propane: 2516 BTU per CFH
  double get _btuPerCfh => _gasType == 'natural' ? 1000 : 2516;

  double get _requiredCfh => _totalBtu / _btuPerCfh;

  int get _totalBtuFromAppliances {
    int total = 0;
    for (final appliance in _appliances) {
      total += appliance.btu;
    }
    return total;
  }

  String get _recommendedPipeSize {
    final cfh = _requiredCfh;
    if (cfh <= 0) return '--';

    final table = _pipeMaterial == 'csst' ? _csstCapacity : _blackIronCapacity;
    final runFt = _longestRun.round();

    // Find the appropriate length column (round up to next available)
    int lengthColumn = 10;
    final lengths = [10, 20, 30, 40, 50, 60, 75, 80, 100, 150, 200];
    for (final len in lengths) {
      if (runFt <= len) {
        lengthColumn = len;
        break;
      }
    }
    if (runFt > 200) lengthColumn = 200;

    // Find smallest pipe that can handle the CFH
    for (final entry in table.entries) {
      final capacityMap = entry.value;
      // Find closest length
      int capacity = 0;
      for (final len in capacityMap.keys.toList()..sort()) {
        if (len >= lengthColumn) {
          capacity = capacityMap[len] ?? 0;
          break;
        }
      }
      if (capacity == 0 && capacityMap.isNotEmpty) {
        capacity = capacityMap.values.last;
      }
      if (capacity >= cfh) {
        return entry.key;
      }
    }
    return _pipeMaterial == 'csst' ? '1-1/4"+' : '3"+';
  }

  void _addAppliance(String name, int btu) {
    HapticFeedback.selectionClick();
    setState(() {
      _appliances.add((name: name, btu: btu));
      _totalBtu = _totalBtuFromAppliances.toDouble();
    });
  }

  void _removeAppliance(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _appliances.removeAt(index);
      _totalBtu = _totalBtuFromAppliances.toDouble();
    });
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
          'Gas Pipe Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildGasTypeSelector(colors),
          const SizedBox(height: 16),
          _buildPipeMaterialSelector(colors),
          const SizedBox(height: 16),
          _buildLongestRunInput(colors),
          const SizedBox(height: 16),
          _buildApplianceList(colors),
          const SizedBox(height: 16),
          _buildAddApplianceCard(colors),
          const SizedBox(height: 16),
          _buildPipeTable(colors),
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
            _recommendedPipeSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Pipe Size',
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
                _buildResultRow(colors, 'Total BTU/hr', _formatBtu(_totalBtu.toInt())),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Required CFH', _requiredCfh.toStringAsFixed(0)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Gas Type', _gasType == 'natural' ? 'Natural Gas' : 'Propane (LP)'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Longest Run', '${_longestRun.toInt()} ft', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Material', _getPipeMaterialName()),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Appliances', '${_appliances.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBtu(int btu) {
    if (btu >= 1000000) {
      return '${(btu / 1000000).toStringAsFixed(1)}M';
    } else if (btu >= 1000) {
      return '${(btu / 1000).toStringAsFixed(0)}k';
    }
    return btu.toString();
  }

  String _getPipeMaterialName() {
    switch (_pipeMaterial) {
      case 'black_iron':
        return 'Black Iron (Sch 40)';
      case 'csst':
        return 'CSST';
      case 'copper':
        return 'Copper (Type K/L)';
      default:
        return _pipeMaterial;
    }
  }

  Widget _buildGasTypeSelector(ZaftoColors colors) {
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
            children: [
              Expanded(child: _buildChip(colors, 'natural', 'Natural Gas', '1000 BTU/CFH', _gasType, (v) => setState(() => _gasType = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildChip(colors, 'propane', 'Propane (LP)', '2516 BTU/CFH', _gasType, (v) => setState(() => _gasType = v))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipeMaterialSelector(ZaftoColors colors) {
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
            children: [
              _buildMaterialChip(colors, 'black_iron', 'Black Iron'),
              _buildMaterialChip(colors, 'csst', 'CSST'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialChip(ZaftoColors colors, String value, String label) {
    final isSelected = _pipeMaterial == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _pipeMaterial = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ZaftoColors colors, String value, String label, String desc, String selectedValue, void Function(String) onTap) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLongestRunInput(ZaftoColors colors) {
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
            'LONGEST RUN (FEET)',
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
                '${_longestRun.toInt()} ft',
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
                    value: _longestRun,
                    min: 10,
                    max: 200,
                    divisions: 19,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _longestRun = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Meter to farthest appliance (include fittings equivalent length)',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceList(ZaftoColors colors) {
    if (_appliances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.flame, color: colors.textTertiary, size: 32),
            const SizedBox(height: 8),
            Text(
              'No appliances added',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            Text(
              'Add appliances below to calculate pipe size',
              style: TextStyle(color: colors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

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
            children: [
              Icon(LucideIcons.flame, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'APPLIANCES (${_appliances.length})',
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
          ..._appliances.asMap().entries.map((entry) {
            final index = entry.key;
            final appliance = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appliance.name,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                        ),
                        Text(
                          '${_formatBtu(appliance.btu)} BTU/hr',
                          style: TextStyle(color: colors.textTertiary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeAppliance(index),
                    icon: Icon(LucideIcons.x, color: colors.accentError, size: 18),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddApplianceCard(ZaftoColors colors) {
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
            'ADD APPLIANCE',
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
            children: _commonAppliances.entries.map((entry) {
              return GestureDetector(
                onTap: () => _addAppliance(entry.key, entry.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, color: colors.accentPrimary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        entry.key,
                        style: TextStyle(color: colors.textPrimary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeTable(ZaftoColors colors) {
    final table = _pipeMaterial == 'csst' ? _csstCapacity : _blackIronCapacity;
    final runFt = _longestRun.round();

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
            _pipeMaterial == 'csst' ? 'CSST CAPACITY (CFH)' : 'BLACK IRON CAPACITY (CFH)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Low pressure (< 2 PSI), ${_gasType == 'natural' ? 'Natural Gas' : 'Propane'}',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: table.entries.map((entry) {
                final size = entry.key;
                final capacityMap = entry.value;

                // Get capacity at current run length
                int capacity = 0;
                for (final len in capacityMap.keys.toList()..sort()) {
                  if (len >= runFt) {
                    capacity = capacityMap[len] ?? 0;
                    break;
                  }
                }
                if (capacity == 0 && capacityMap.isNotEmpty) {
                  capacity = capacityMap.values.last;
                }

                final isSelected = size == _recommendedPipeSize;
                final isAdequate = capacity >= _requiredCfh && _requiredCfh > 0;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.accentPrimary.withValues(alpha: 0.2)
                        : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected ? Border.all(color: colors.accentPrimary) : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          size,
                          style: TextStyle(
                            color: isSelected ? colors.accentPrimary : colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '$capacity CFH',
                          style: TextStyle(
                            color: isAdequate
                                ? colors.accentSuccess
                                : colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
                    ],
                  ),
                );
              }).toList(),
            ),
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
                'IFGC 2024 / NFPA 54',
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
            '• Table 402.4(2) - Low pressure gas sizing\n'
            '• 402.4 - Longest run method\n'
            '• Add equivalent length for fittings\n'
            '• LP gas: multiply capacity by 1.5\n'
            '• CSST: use manufacturer tables\n'
            '• Always verify with local AHJ',
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
