import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Ice Maker Plumbing Calculator - Design System v2.6
///
/// Sizes water supply and drainage for commercial ice machines.
/// Calculates water consumption and drain requirements.
///
/// References: ASHRAE, NSF/ANSI 12
class IceMakerScreen extends ConsumerStatefulWidget {
  const IceMakerScreen({super.key});
  @override
  ConsumerState<IceMakerScreen> createState() => _IceMakerScreenState();
}

class _IceMakerScreenState extends ConsumerState<IceMakerScreen> {
  // Ice production (lbs/day)
  double _iceProduction = 500;

  // Machine type
  String _machineType = 'cube';

  // Cooling type
  String _coolingType = 'air';

  // Water quality
  String _waterQuality = 'municipal';

  static const Map<String, ({String desc, double waterPerLb, double wasteRatio})> _machineTypes = {
    'cube': (desc: 'Cube Ice', waterPerLb: 0.12, wasteRatio: 0.1),
    'nugget': (desc: 'Nugget/Chewable', waterPerLb: 0.15, wasteRatio: 0.15),
    'flake': (desc: 'Flake Ice', waterPerLb: 0.10, wasteRatio: 0.05),
    'gourmet': (desc: 'Gourmet/Clear', waterPerLb: 0.18, wasteRatio: 0.25),
  };

  static const Map<String, ({String desc, double drainMultiplier})> _coolingTypes = {
    'air': (desc: 'Air Cooled', drainMultiplier: 1.0),
    'water': (desc: 'Water Cooled', drainMultiplier: 3.0),
    'remote': (desc: 'Remote Condenser', drainMultiplier: 1.0),
  };

  static const Map<String, ({String desc, bool filterRequired})> _waterQualities = {
    'municipal': (desc: 'City Water (Good)', filterRequired: false),
    'hard': (desc: 'Hard Water (>7 gpg)', filterRequired: true),
    'well': (desc: 'Well Water', filterRequired: true),
    'high_tds': (desc: 'High TDS (>500 ppm)', filterRequired: true),
  };

  // Water consumption (gallons per day)
  double get _waterConsumptionGpd {
    final waterPerLb = _machineTypes[_machineType]?.waterPerLb ?? 0.12;
    return _iceProduction * waterPerLb;
  }

  // Drain water (gallons per day)
  double get _drainWaterGpd {
    final wasteRatio = _machineTypes[_machineType]?.wasteRatio ?? 0.1;
    final drainMult = _coolingTypes[_coolingType]?.drainMultiplier ?? 1.0;
    return _waterConsumptionGpd * wasteRatio * drainMult + (_coolingType == 'water' ? _waterConsumptionGpd * 2 : 0);
  }

  // Supply line size
  String get _supplyLineSize {
    if (_iceProduction <= 400) return '⅜\"';
    if (_iceProduction <= 800) return '½\"';
    return '¾\"';
  }

  // Drain line size
  String get _drainLineSize {
    if (_drainWaterGpd <= 50) return '¾\"';
    if (_drainWaterGpd <= 150) return '1\"';
    return '1¼\"';
  }

  // Filter recommendation
  String get _filterType {
    if (_waterQualities[_waterQuality]?.filterRequired != true) {
      return '5 micron sediment + carbon';
    }
    if (_waterQuality == 'hard') {
      return 'Scale inhibitor + carbon';
    }
    if (_waterQuality == 'high_tds') {
      return 'RO system recommended';
    }
    return 'Sediment + carbon + scale inhibitor';
  }

  // Bin size recommendation (lbs)
  int get _binSize => (_iceProduction * 0.4).round().clamp(100, 1000);

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
          'Ice Maker Plumbing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildProductionCard(colors),
          const SizedBox(height: 16),
          _buildMachineTypeCard(colors),
          const SizedBox(height: 16),
          _buildCoolingTypeCard(colors),
          const SizedBox(height: 16),
          _buildWaterQualityCard(colors),
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
            '${_waterConsumptionGpd.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Gallons/Day Water',
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
                _buildResultRow(colors, 'Supply Line', _supplyLineSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Line', _drainLineSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Water', '${_drainWaterGpd.toStringAsFixed(0)} GPD'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Bin Size', '$_binSize lbs'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Filter', _filterType),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionCard(ZaftoColors colors) {
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
            'ICE PRODUCTION',
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
              Text('Daily Production', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_iceProduction.toStringAsFixed(0)} lbs/day',
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
              value: _iceProduction,
              min: 100,
              max: 2000,
              divisions: 38,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _iceProduction = v);
              },
            ),
          ),
          Text(
            'Rule: 1.5 lbs ice per person per day for restaurants',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineTypeCard(ZaftoColors colors) {
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
            'ICE TYPE',
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
            children: _machineTypes.entries.map((entry) {
              final isSelected = _machineType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _machineType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  Widget _buildCoolingTypeCard(ZaftoColors colors) {
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
            'COOLING TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._coolingTypes.entries.map((entry) {
            final isSelected = _coolingType == entry.key;
            final isWaterCooled = entry.key == 'water';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _coolingType = entry.key);
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
                      if (isWaterCooled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (colors.isDark ? Colors.black26 : Colors.white30)
                                : colors.accentWarning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'High Water Use',
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.accentWarning,
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

  Widget _buildWaterQualityCard(ZaftoColors colors) {
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
            'WATER QUALITY',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._waterQualities.entries.map((entry) {
            final isSelected = _waterQuality == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _waterQuality = entry.key);
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
                      if (entry.value.filterRequired)
                        Icon(
                          LucideIcons.filter,
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          size: 16,
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
              Icon(LucideIcons.snowflake, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'NSF/ANSI 12',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Air gap required on drain line\n'
            '• Min 1\" air gap above floor drain\n'
            '• Backflow preventer on supply\n'
            '• Shut-off valve accessible\n'
            '• Water filter recommended\n'
            '• Slope drain min ⅛\"/ft',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
