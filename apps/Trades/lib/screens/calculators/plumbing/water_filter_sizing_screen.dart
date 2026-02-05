import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Filter Sizing Calculator - Design System v2.6
///
/// Sizes whole-house and point-of-use water filtration systems.
/// Calculates flow rate requirements and filter capacity.
///
/// References: NSF/ANSI Standards, WQA Guidelines
class WaterFilterSizingScreen extends ConsumerStatefulWidget {
  const WaterFilterSizingScreen({super.key});
  @override
  ConsumerState<WaterFilterSizingScreen> createState() => _WaterFilterSizingScreenState();
}

class _WaterFilterSizingScreenState extends ConsumerState<WaterFilterSizingScreen> {
  // Number of bathrooms
  double _bathrooms = 2.5;

  // Number of occupants
  int _occupants = 4;

  // Water source
  String _waterSource = 'municipal';

  // Contaminant concern
  String _contaminant = 'sediment';

  static const Map<String, ({String desc, double flowMultiplier})> _waterSources = {
    'municipal': (desc: 'City Water', flowMultiplier: 1.0),
    'well_clean': (desc: 'Well (Clean)', flowMultiplier: 1.0),
    'well_sediment': (desc: 'Well (Sediment)', flowMultiplier: 1.2),
    'well_iron': (desc: 'Well (High Iron)', flowMultiplier: 1.3),
  };

  static const Map<String, ({String desc, String filterType, int micron})> _contaminants = {
    'sediment': (desc: 'Sediment/Sand', filterType: 'Sediment Filter', micron: 20),
    'chlorine': (desc: 'Chlorine/Taste', filterType: 'Carbon Block', micron: 5),
    'iron': (desc: 'Iron/Manganese', filterType: 'Iron Filter', micron: 10),
    'hardness': (desc: 'Hard Water', filterType: 'Water Softener', micron: 0),
    'bacteria': (desc: 'Bacteria', filterType: 'UV + Sediment', micron: 1),
  };

  // Peak flow rate (GPM) based on bathrooms
  double get _peakFlowGpm {
    // Rule of thumb: 10 GPM for first bathroom + 5 GPM each additional
    final base = 10.0 + ((_bathrooms - 1) * 5);
    final multiplier = _waterSources[_waterSource]?.flowMultiplier ?? 1.0;
    return base * multiplier;
  }

  // Daily usage (gallons)
  int get _dailyUsage => _occupants * 80; // 80 gallons per person per day

  // Recommended filter size
  String get _filterSize {
    final flow = _peakFlowGpm;
    if (flow <= 10) return '1\" Inlet';
    if (flow <= 15) return '1\" Inlet (High Flow)';
    if (flow <= 20) return '1¼\" Inlet';
    return '1½\" Inlet';
  }

  // Filter capacity (gallons between changes)
  int get _filterCapacity {
    final micron = _contaminants[_contaminant]?.micron ?? 10;
    if (micron >= 20) return 100000;
    if (micron >= 10) return 50000;
    if (micron >= 5) return 30000;
    return 10000;
  }

  // Months between filter changes
  int get _changeInterval => (_filterCapacity / (_dailyUsage * 30)).floor().clamp(1, 12);

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
          'Water Filter Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildBathroomCard(colors),
          const SizedBox(height: 16),
          _buildOccupantsCard(colors),
          const SizedBox(height: 16),
          _buildWaterSourceCard(colors),
          const SizedBox(height: 16),
          _buildContaminantCard(colors),
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
            '${_peakFlowGpm.toStringAsFixed(0)} GPM',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Required Flow Rate',
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
                _buildResultRow(colors, 'Filter Size', _filterSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Filter Type', _contaminants[_contaminant]?.filterType ?? 'Sediment'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Daily Usage', '$_dailyUsage gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Change Interval', '$_changeInterval months'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBathroomCard(ZaftoColors colors) {
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
            'BATHROOMS',
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
              Text('Number of Bathrooms', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                _bathrooms.toString(),
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
              value: _bathrooms,
              min: 1,
              max: 6,
              divisions: 10,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _bathrooms = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupantsCard(ZaftoColors colors) {
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
            'OCCUPANTS',
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
              Text('Number of People', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_occupants',
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
              value: _occupants.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _occupants = v.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterSourceCard(ZaftoColors colors) {
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

  Widget _buildContaminantCard(ZaftoColors colors) {
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
            'PRIMARY CONCERN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._contaminants.entries.map((entry) {
            final isSelected = _contaminant == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _contaminant = entry.key);
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
                        entry.value.filterType,
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
              Icon(LucideIcons.filter, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'NSF/ANSI Standards',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• NSF 42: Aesthetic effects (taste/odor)\n'
            '• NSF 53: Health effects (lead/cysts)\n'
            '• NSF 55: UV treatment\n'
            '• NSF 58: Reverse osmosis\n'
            '• Size for peak demand, not average\n'
            '• Pre-filter sediment before carbon',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
