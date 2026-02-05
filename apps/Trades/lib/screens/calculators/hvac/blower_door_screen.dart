import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Blower Door Test Calculator - Design System v2.6
///
/// Calculates air changes per hour and building tightness from blower door results.
/// Helps determine infiltration rates and verify code compliance.
///
/// References: ASHRAE 62.2, RESNET, IECC
class BlowerDoorScreen extends ConsumerStatefulWidget {
  const BlowerDoorScreen({super.key});
  @override
  ConsumerState<BlowerDoorScreen> createState() => _BlowerDoorScreenState();
}

class _BlowerDoorScreenState extends ConsumerState<BlowerDoorScreen> {
  // CFM50 (airflow at 50 Pa)
  double _cfm50 = 2000;

  // Conditioned floor area (sq ft)
  double _floorArea = 2000;

  // Building volume (cu ft)
  double _volume = 16000;

  // Number of stories
  int _stories = 1;

  // Climate zone
  String _climateZone = 'zone_4';

  static const Map<String, ({String desc, double achTarget})> _climateZones = {
    'zone_1': (desc: 'Zone 1-2 (Hot)', achTarget: 5.0),
    'zone_3': (desc: 'Zone 3 (Warm)', achTarget: 4.0),
    'zone_4': (desc: 'Zone 4 (Mixed)', achTarget: 3.0),
    'zone_5': (desc: 'Zone 5-6 (Cold)', achTarget: 3.0),
    'zone_7': (desc: 'Zone 7-8 (Very Cold)', achTarget: 3.0),
  };

  // Air Changes per Hour at 50 Pa
  double get _ach50 => (_cfm50 * 60) / _volume;

  // Estimated natural ACH (÷ N factor)
  double get _achNatural {
    // N factor varies by climate and stories
    final nFactor = 20 - (_stories - 1) * 2;
    return _ach50 / nFactor;
  }

  // CFM per square foot
  double get _cfmPerSqft => _cfm50 / _floorArea;

  // Leakage area (sq in) - using EqLA
  double get _leakageArea => _cfm50 * 0.055;

  // Building tightness rating
  String get _tightnessRating {
    if (_ach50 <= 1.5) return 'Very Tight (Passive House)';
    if (_ach50 <= 3.0) return 'Tight (High Performance)';
    if (_ach50 <= 5.0) return 'Average (Code Compliant)';
    if (_ach50 <= 7.0) return 'Loose';
    return 'Very Loose';
  }

  // Code compliance
  bool get _codeCompliant {
    final target = _climateZones[_climateZone]?.achTarget ?? 3.0;
    return _ach50 <= target;
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
          'Blower Door Test',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildCfm50Card(colors),
          const SizedBox(height: 16),
          _buildBuildingCard(colors),
          const SizedBox(height: 16),
          _buildClimateCard(colors),
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
            '${_ach50.toStringAsFixed(1)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'ACH50',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _codeCompliant
                  ? colors.accentPrimary.withValues(alpha: 0.1)
                  : colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _tightnessRating,
              style: TextStyle(
                color: _codeCompliant ? colors.accentPrimary : colors.accentWarning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                _buildResultRow(colors, 'CFM50', '${_cfm50.toStringAsFixed(0)} CFM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Natural ACH', '${_achNatural.toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'CFM/sq ft', '${_cfmPerSqft.toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'EqLA', '${_leakageArea.toStringAsFixed(1)} sq in'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Code Limit', '${_climateZones[_climateZone]?.achTarget ?? 3.0} ACH50'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Compliance', _codeCompliant ? 'Pass' : 'Fail'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCfm50Card(ZaftoColors colors) {
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
            'BLOWER DOOR READING',
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
              Text('CFM at 50 Pa', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_cfm50.toStringAsFixed(0)} CFM',
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
              value: _cfm50,
              min: 500,
              max: 5000,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _cfm50 = v);
              },
            ),
          ),
          Text(
            'Airflow at 50 Pascal pressure difference',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingCard(ZaftoColors colors) {
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
            'BUILDING SIZE',
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
              Text('Floor Area', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_floorArea.toStringAsFixed(0)} sq ft',
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
              value: _floorArea,
              min: 500,
              max: 5000,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() {
                  _floorArea = v;
                  _volume = v * 8 * _stories; // Auto-calculate volume
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Building Volume', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_volume.toStringAsFixed(0)} cu ft',
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
              value: _volume,
              min: 4000,
              max: 50000,
              divisions: 46,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _volume = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stories', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_stories',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3].map((s) {
              final isSelected = _stories == s;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _stories = s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$s Story',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 12,
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

  Widget _buildClimateCard(ZaftoColors colors) {
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
            'CLIMATE ZONE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._climateZones.entries.map((entry) {
            final isSelected = _climateZone == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _climateZone = entry.key);
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
                        '≤${entry.value.achTarget} ACH50',
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
              Icon(LucideIcons.wind, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IECC / RESNET',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• IECC: 3-5 ACH50 by climate\n'
            '• Passive House: ≤0.6 ACH50\n'
            '• Energy Star: 4-6 ACH50\n'
            '• Close all windows/doors\n'
            '• Seal combustion air intakes\n'
            '• Test at 50 Pa depressurization',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
