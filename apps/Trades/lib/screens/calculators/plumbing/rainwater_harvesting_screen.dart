import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Rainwater Harvesting Calculator - Design System v2.6
///
/// Sizes rainwater collection systems including cisterns and filters.
/// Calculates collection potential and storage requirements.
///
/// References: IPC Appendix C, ARCSA/ASPE 63
class RainwaterHarvestingScreen extends ConsumerStatefulWidget {
  const RainwaterHarvestingScreen({super.key});
  @override
  ConsumerState<RainwaterHarvestingScreen> createState() => _RainwaterHarvestingScreenState();
}

class _RainwaterHarvestingScreenState extends ConsumerState<RainwaterHarvestingScreen> {
  // Roof collection area (sq ft)
  double _roofArea = 2000;

  // Annual rainfall (inches)
  double _annualRainfall = 40;

  // Roof efficiency factor
  String _roofType = 'metal';

  // Intended use
  String _intendedUse = 'irrigation';

  // Daily demand (gallons)
  double _dailyDemand = 50;

  static const Map<String, ({String desc, double efficiency})> _roofTypes = {
    'metal': (desc: 'Metal Roof', efficiency: 0.95),
    'asphalt': (desc: 'Asphalt Shingles', efficiency: 0.85),
    'tile': (desc: 'Tile/Concrete', efficiency: 0.90),
    'flat': (desc: 'Flat/Membrane', efficiency: 0.85),
    'green': (desc: 'Green Roof', efficiency: 0.50),
  };

  static const Map<String, ({String desc, bool potable})> _uses = {
    'irrigation': (desc: 'Irrigation Only', potable: false),
    'toilet': (desc: 'Toilet Flushing', potable: false),
    'laundry': (desc: 'Laundry', potable: false),
    'potable': (desc: 'Potable (Treated)', potable: true),
    'all_non_potable': (desc: 'All Non-Potable', potable: false),
  };

  double get _efficiency => _roofTypes[_roofType]?.efficiency ?? 0.85;

  // Gallons = Roof Area × Rainfall × 0.623 × Efficiency
  double get _annualCollection => _roofArea * _annualRainfall * 0.623 * _efficiency;

  double get _monthlyCollection => _annualCollection / 12;

  // Storage = Monthly demand × 1.5 (for dry periods)
  double get _recommendedStorage => (_dailyDemand * 30 * 1.5).clamp(500, 50000);

  // First flush = 10 gallons per 1000 sq ft
  double get _firstFlush => (_roofArea / 1000) * 10;

  String get _cisternSize {
    final storage = _recommendedStorage;
    if (storage <= 500) return '500 gallon';
    if (storage <= 1000) return '1,000 gallon';
    if (storage <= 2500) return '2,500 gallon';
    if (storage <= 5000) return '5,000 gallon';
    if (storage <= 10000) return '10,000 gallon';
    return '${(storage / 1000).ceil()},000 gallon';
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
          'Rainwater Harvesting',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildRoofCard(colors),
          const SizedBox(height: 16),
          _buildRainfallCard(colors),
          const SizedBox(height: 16),
          _buildUseCard(colors),
          const SizedBox(height: 16),
          _buildComponentsCard(colors),
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
            '${(_annualCollection / 1000).toStringAsFixed(1)}K',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Gallons/Year Collection',
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
                _buildResultRow(colors, 'Monthly Average', '${_monthlyCollection.toStringAsFixed(0)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Daily Demand', '${_dailyDemand.toStringAsFixed(0)} gal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Recommended Storage', _cisternSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'First Flush', '${_firstFlush.toStringAsFixed(0)} gallons'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoofCard(ZaftoColors colors) {
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
            'COLLECTION SURFACE',
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
              Text('Roof Area', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_roofArea.toStringAsFixed(0)} sq ft',
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
              value: _roofArea,
              min: 500,
              max: 10000,
              divisions: 38,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _roofArea = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ROOF TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ..._roofTypes.entries.map((entry) {
            final isSelected = _roofType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _roofType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        '${(entry.value.efficiency * 100).toStringAsFixed(0)}% eff',
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

  Widget _buildRainfallCard(ZaftoColors colors) {
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
            'RAINFALL & DEMAND',
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
              Text('Annual Rainfall', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_annualRainfall.toStringAsFixed(0)}" per year',
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
              value: _annualRainfall,
              min: 5,
              max: 80,
              divisions: 75,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _annualRainfall = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Demand', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_dailyDemand.toStringAsFixed(0)} gallons',
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
              value: _dailyDemand,
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _dailyDemand = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseCard(ZaftoColors colors) {
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
            'INTENDED USE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._uses.entries.map((entry) {
            final isSelected = _intendedUse == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _intendedUse = entry.key);
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
                      if (entry.value.potable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (colors.isDark ? Colors.black26 : Colors.white30)
                                : colors.accentWarning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Treatment Req',
                            style: TextStyle(
                              color: isSelected
                                  ? (colors.isDark ? Colors.black54 : Colors.white70)
                                  : colors.accentWarning,
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

  Widget _buildComponentsCard(ZaftoColors colors) {
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
            'SYSTEM COMPONENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Gutter/Downspout', 'Sized per storm drain calcs'),
          _buildDimRow(colors, 'First Flush Diverter', '${_firstFlush.toStringAsFixed(0)} gal'),
          _buildDimRow(colors, 'Pre-Filter', 'Leaf screen + sediment'),
          _buildDimRow(colors, 'Cistern', _cisternSize),
          _buildDimRow(colors, 'Pump', 'Match demand GPM'),
          _buildDimRow(colors, 'Overflow', 'To approved drainage'),
          if (_uses[_intendedUse]?.potable ?? false) ...[
            Divider(color: colors.borderSubtle, height: 16),
            _buildDimRow(colors, 'UV Treatment', 'Required'),
            _buildDimRow(colors, 'Carbon Filter', 'Required'),
            _buildDimRow(colors, 'Testing', 'Per local health code'),
          ],
        ],
      ),
    );
  }

  Widget _buildDimRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Expanded(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
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
              Icon(LucideIcons.droplet, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC Appendix C / ARCSA',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• First flush diverter required\n'
            '• Cross-connection protection\n'
            '• Purple pipe for non-potable\n'
            '• Signage at fixtures required\n'
            '• Potable requires treatment\n'
            '• Check local water rights',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
