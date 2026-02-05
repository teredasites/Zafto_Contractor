import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Recessed Light Layout Calculator - Design System v2.6
/// Spacing, count, and lumen calculations for recessed lighting
class RecessedLightScreen extends ConsumerStatefulWidget {
  const RecessedLightScreen({super.key});
  @override
  ConsumerState<RecessedLightScreen> createState() => _RecessedLightScreenState();
}

class _RecessedLightScreenState extends ConsumerState<RecessedLightScreen> {
  double _roomLength = 12; // feet
  double _roomWidth = 10; // feet
  double _ceilingHeight = 8; // feet
  String _roomType = 'general'; // general, kitchen, bathroom, office, bedroom
  String _lightSize = '6'; // 4, 5, 6 inch trim
  int _lightWatts = 12; // LED watts
  bool _dimmerRequired = false;

  // Recommended spacing ratios based on ceiling height
  // Rule of thumb: Spacing = Ceiling Height / 2 for general lighting
  double get _recommendedSpacing => _ceilingHeight / 2;

  // Edge distance from walls (typically half the spacing)
  double get _wallOffset => _recommendedSpacing / 2;

  // Calculate optimal number of lights
  int get _lightsAlongLength {
    final usableLength = _roomLength - (2 * _wallOffset);
    return math.max(1, (usableLength / _recommendedSpacing).ceil() + 1);
  }

  int get _lightsAlongWidth {
    final usableWidth = _roomWidth - (2 * _wallOffset);
    return math.max(1, (usableWidth / _recommendedSpacing).ceil() + 1);
  }

  int get _totalLights => _lightsAlongLength * _lightsAlongWidth;

  // Actual spacing with calculated lights
  double get _actualSpacingLength =>
      _lightsAlongLength > 1 ? (_roomLength - (2 * _wallOffset)) / (_lightsAlongLength - 1) : _roomLength;

  double get _actualSpacingWidth =>
      _lightsAlongWidth > 1 ? (_roomWidth - (2 * _wallOffset)) / (_lightsAlongWidth - 1) : _roomWidth;

  double get _roomArea => _roomLength * _roomWidth;

  // Recommended foot-candles by room type
  static const Map<String, Map<String, dynamic>> _roomTypes = {
    'general': {'fc': 30, 'label': 'General Living', 'desc': '20-40 fc'},
    'kitchen': {'fc': 50, 'label': 'Kitchen', 'desc': '30-75 fc'},
    'bathroom': {'fc': 50, 'label': 'Bathroom', 'desc': '30-70 fc'},
    'office': {'fc': 50, 'label': 'Home Office', 'desc': '40-60 fc'},
    'bedroom': {'fc': 20, 'label': 'Bedroom', 'desc': '10-30 fc'},
    'hallway': {'fc': 15, 'label': 'Hallway', 'desc': '10-20 fc'},
    'garage': {'fc': 50, 'label': 'Garage', 'desc': '30-75 fc'},
  };

  int get _targetFootCandles => _roomTypes[_roomType]?['fc'] ?? 30;

  // Lumens calculation
  // Light Loss Factor (LLF) = 0.75 typical
  // Coefficient of Utilization (CU) = 0.6 typical for recessed
  double get _lumensRequired => (_roomArea * _targetFootCandles) / 0.45; // LLF × CU

  // Typical lumens per watt for LED (100 lm/W)
  int get _lumensPerLight => _lightWatts * 100;

  int get _lightsNeededByLumens => (_lumensRequired / _lumensPerLight).ceil();

  double get _actualFootCandles => (_totalLights * _lumensPerLight * 0.45) / _roomArea;

  // Light size options with beam angles
  static const Map<String, Map<String, dynamic>> _lightSizes = {
    '4': {'beam': 60, 'minSpacing': 4, 'maxSpacing': 6, 'desc': '4" - Accent/Task'},
    '5': {'beam': 65, 'minSpacing': 5, 'maxSpacing': 7, 'desc': '5" - General Purpose'},
    '6': {'beam': 70, 'minSpacing': 6, 'maxSpacing': 8, 'desc': '6" - General/High Ceiling'},
  };

  String get _lightSizeDesc => _lightSizes[_lightSize]?['desc'] ?? '6" Standard';

  // Circuit load calculation
  double get _totalWatts => _totalLights * _lightWatts.toDouble();

  double get _circuitAmps => _totalWatts / 120;

  int get _circuitsNeeded {
    // 80% of 15A = 12A continuous, or 1440W
    final wattsPerCircuit = 1440;
    return (_totalWatts / wattsPerCircuit).ceil();
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
        title: Text('Recessed Light Layout', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRoomSizeCard(colors),
          const SizedBox(height: 16),
          _buildRoomTypeCard(colors),
          const SizedBox(height: 16),
          _buildLightOptionsCard(colors),
          const SizedBox(height: 20),
          _buildLayoutResultCard(colors),
          const SizedBox(height: 16),
          _buildSpacingCard(colors),
          const SizedBox(height: 16),
          _buildLightLevelsCard(colors),
          const SizedBox(height: 16),
          _buildElectricalCard(colors),
          const SizedBox(height: 16),
          _buildTipsCard(colors),
        ],
      ),
    );
  }

  Widget _buildRoomSizeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ROOM DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildDimensionSlider(colors, 'Length', _roomLength, 6, 30, 'ft', (v) => setState(() => _roomLength = v)),
          const SizedBox(height: 12),
          _buildDimensionSlider(colors, 'Width', _roomWidth, 6, 20, 'ft', (v) => setState(() => _roomWidth = v)),
          const SizedBox(height: 12),
          _buildDimensionSlider(colors, 'Ceiling Height', _ceilingHeight, 7, 12, 'ft', (v) => setState(() => _ceilingHeight = v)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.square, color: colors.textTertiary, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Room Area: ${_roomArea.toStringAsFixed(0)} sq ft',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text('${value.toStringAsFixed(0)} $unit', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: colors.accentPrimary,
          inactiveColor: colors.bgBase,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRoomTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ROOM TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _roomTypes.entries.map((e) {
              final isSelected = _roomType == e.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _roomType = e.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.value['label'],
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
            'Target: ${_roomTypes[_roomType]?['desc']} foot-candles',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLightOptionsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIGHT OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text('Trim Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: _lightSizes.keys.map((size) {
              final isSelected = _lightSize == size;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _lightSize = size);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: size != '6' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$size"',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('LED Wattage', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [8, 10, 12, 15, 18].map((watts) {
              final isSelected = _lightWatts == watts;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _lightWatts = watts);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${watts}W',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text('~${_lumensPerLight} lumens per light', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLayoutResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text('RECOMMENDED LAYOUT', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            '$_totalLights',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text('recessed lights', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('$_lightsAlongLength', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                    Text('Along Length', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
                Text('×', style: TextStyle(color: colors.textTertiary, fontSize: 20)),
                Column(
                  children: [
                    Text('$_lightsAlongWidth', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                    Text('Along Width', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SPACING DETAILS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildSpacingRow(colors, 'Spacing (length)', '${_actualSpacingLength.toStringAsFixed(1)} ft'),
          _buildSpacingRow(colors, 'Spacing (width)', '${_actualSpacingWidth.toStringAsFixed(1)} ft'),
          _buildSpacingRow(colors, 'From walls', '${_wallOffset.toStringAsFixed(1)} ft'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.textTertiary, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rule of thumb: Spacing = Ceiling height ÷ 2 (${_ceilingHeight.toStringAsFixed(0)}\' ÷ 2 = ${_recommendedSpacing.toStringAsFixed(1)}\')',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLightLevelsCard(ZaftoColors colors) {
    final adequate = _actualFootCandles >= _targetFootCandles * 0.8;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIGHT LEVELS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildLevelRow(colors, 'Target', '$_targetFootCandles fc', false),
          _buildLevelRow(colors, 'Calculated', '${_actualFootCandles.toStringAsFixed(0)} fc', true),
          _buildLevelRow(colors, 'Total lumens', '${(_totalLights * _lumensPerLight)}', false),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: adequate ? Colors.green.withValues(alpha: 0.1) : const Color(0xFFE53935).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  adequate ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                  color: adequate ? Colors.green : const Color(0xFFE53935),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  adequate ? 'Adequate light levels' : 'Consider adding more lights or higher wattage',
                  style: TextStyle(
                    color: adequate ? Colors.green : const Color(0xFFE53935),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow(ZaftoColors colors, String label, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
      ),
    );
  }

  Widget _buildElectricalCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.zap, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('ELECTRICAL REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildElecRow(colors, 'Total watts', '${_totalWatts.toStringAsFixed(0)}W'),
          _buildElecRow(colors, 'Circuit amps', '${_circuitAmps.toStringAsFixed(1)}A'),
          _buildElecRow(colors, 'Circuits needed', '$_circuitsNeeded × 15A'),
          _buildElecRow(colors, 'Wire size', '14 AWG (15A circuit)'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dimmer required?', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              Switch(
                value: _dimmerRequired,
                onChanged: (v) => setState(() => _dimmerRequired = v),
                activeColor: colors.accentPrimary,
              ),
            ],
          ),
          if (_dimmerRequired)
            Text('Use LED-compatible dimmer rated for ${_totalWatts.toStringAsFixed(0)}W+', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildElecRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('INSTALLATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip(colors, 'Use IC-rated (insulation contact) cans in insulated ceilings'),
          _buildTip(colors, 'Maintain 3" clearance from insulation for non-IC rated'),
          _buildTip(colors, 'Keep lights 2-3\' from walls for wall washing effect'),
          _buildTip(colors, 'Use airtight (AT) cans to prevent air leakage'),
          _buildTip(colors, 'LED retrofit kits work with existing cans'),
        ],
      ),
    );
  }

  Widget _buildTip(ZaftoColors colors, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }
}
