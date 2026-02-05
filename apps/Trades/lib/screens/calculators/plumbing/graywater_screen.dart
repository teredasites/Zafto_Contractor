import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Graywater System Calculator - Design System v2.6
///
/// Sizes graywater recycling systems for irrigation.
/// Calculates daily generation and irrigation coverage.
///
/// References: IPC Appendix C, California Graywater Code
class GraywaterScreen extends ConsumerStatefulWidget {
  const GraywaterScreen({super.key});
  @override
  ConsumerState<GraywaterScreen> createState() => _GraywaterScreenState();
}

class _GraywaterScreenState extends ConsumerState<GraywaterScreen> {
  // Number of occupants
  int _occupants = 4;

  // Source fixtures
  Map<String, bool> _sources = {
    'shower': true,
    'bathtub': true,
    'bathroom_sink': true,
    'laundry': true,
  };

  // System type
  String _systemType = 'laundry';

  // Soil type
  String _soilType = 'loam';

  static const Map<String, ({String desc, double gallonsPerPerson})> _sourceFixtures = {
    'shower': (desc: 'Shower', gallonsPerPerson: 15),
    'bathtub': (desc: 'Bathtub', gallonsPerPerson: 25),
    'bathroom_sink': (desc: 'Bathroom Sink', gallonsPerPerson: 5),
    'laundry': (desc: 'Clothes Washer', gallonsPerPerson: 15),
  };

  static const Map<String, ({String desc, bool permitRequired})> _systemTypes = {
    'laundry': (desc: 'Laundry to Landscape', permitRequired: false),
    'branched': (desc: 'Branched Drain', permitRequired: true),
    'pumped': (desc: 'Pumped System', permitRequired: true),
  };

  static const Map<String, ({String desc, double percolationRate})> _soilTypes = {
    'sand': (desc: 'Sandy', percolationRate: 1.2),
    'loam': (desc: 'Loam', percolationRate: 0.8),
    'clay': (desc: 'Clay', percolationRate: 0.4),
  };

  double get _dailyGraywater {
    double total = 0;
    _sources.forEach((key, enabled) {
      if (enabled) {
        total += (_sourceFixtures[key]?.gallonsPerPerson ?? 0) * _occupants;
      }
    });
    return total;
  }

  double get _weeklyGraywater => _dailyGraywater * 7;

  // Irrigation coverage = Weekly gallons / 2 (assumes 2" per week)
  // = gallons × 231 cu in / (144 sq in × 2")
  double get _irrigationSqFt => (_weeklyGraywater * 231) / (144 * 2);

  double get _percolationRate => _soilTypes[_soilType]?.percolationRate ?? 0.8;

  // Required mulch basin area
  double get _mulchBasinArea => _dailyGraywater / (_percolationRate * 24);

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
          'Graywater System',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildOccupancyCard(colors),
          const SizedBox(height: 16),
          _buildSourcesCard(colors),
          const SizedBox(height: 16),
          _buildSystemTypeCard(colors),
          const SizedBox(height: 16),
          _buildSoilCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final permitRequired = _systemTypes[_systemType]?.permitRequired ?? true;

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
            '${_dailyGraywater.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Gallons/Day Generated',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (!permitRequired) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.accentSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'No Permit Required*',
                    style: TextStyle(color: colors.accentSuccess, fontSize: 13, fontWeight: FontWeight.w600),
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
                _buildResultRow(colors, 'Weekly Volume', '${_weeklyGraywater.toStringAsFixed(0)} gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Irrigation Coverage', '${_irrigationSqFt.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Mulch Basin Area', '${_mulchBasinArea.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'System Type', _systemTypes[_systemType]?.desc ?? 'Laundry'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard(ZaftoColors colors) {
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
            'HOUSEHOLD',
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
              Text('Occupants', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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

  Widget _buildSourcesCard(ZaftoColors colors) {
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
            'GRAYWATER SOURCES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._sourceFixtures.entries.map((entry) {
            final enabled = _sources[entry.key] ?? false;
            return _buildToggleRow(
              colors,
              entry.value.desc,
              '~${entry.value.gallonsPerPerson} gal/person/day',
              enabled,
              (v) => setState(() => _sources[entry.key] = v),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kitchen sinks and toilets are NOT graywater',
                    style: TextStyle(color: colors.accentWarning, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: value
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTypeCard(ZaftoColors colors) {
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
            'SYSTEM TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._systemTypes.entries.map((entry) {
            final isSelected = _systemType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _systemType = entry.key);
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
                      if (entry.value.permitRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (colors.isDark ? Colors.black26 : Colors.white30)
                                : colors.bgElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Permit',
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
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

  Widget _buildSoilCard(ZaftoColors colors) {
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
            'SOIL TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _soilTypes.entries.map((entry) {
              final isSelected = _soilType == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _soilType = entry.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
          const SizedBox(height: 8),
          Text(
            'Percolation: ${_percolationRate.toStringAsFixed(1)} gal/sq ft/hr',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
              Icon(LucideIcons.recycle, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Graywater Code',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• *Laundry-to-landscape often exempt\n'
            '• Subsurface irrigation only\n'
            '• No surface ponding\n'
            '• 5\' from property lines\n'
            '• Not in setback zones\n'
            '• Check local health department',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
