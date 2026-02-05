import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Radiant Floor Tubing Calculator - Design System v2.6
///
/// Calculates tubing spacing, loop length, and requirements.
/// Essential for hydronic radiant floor heating design.
///
/// References: ASHRAE, RPA Guidelines
class RadiantFloorScreen extends ConsumerStatefulWidget {
  const RadiantFloorScreen({super.key});
  @override
  ConsumerState<RadiantFloorScreen> createState() => _RadiantFloorScreenState();
}

class _RadiantFloorScreenState extends ConsumerState<RadiantFloorScreen> {
  // Room area (sq ft)
  double _roomArea = 200;

  // Tubing spacing (inches on center)
  String _spacing = '9';

  // Tubing diameter
  String _tubeDiameter = '1/2';

  // Floor covering
  String _floorCovering = 'tile';

  // Required BTU/sq ft
  double _btuPerSqFt = 25;

  static const List<String> _spacings = ['6', '9', '12'];
  static const List<String> _diameters = ['3/8', '1/2', '5/8'];

  static const Map<String, ({double rValue, String name})> _coverings = {
    'tile': (rValue: 0.5, name: 'Tile/Stone'),
    'hardwood': (rValue: 0.7, name: 'Hardwood'),
    'laminate': (rValue: 0.5, name: 'Laminate'),
    'vinyl': (rValue: 0.2, name: 'Vinyl/LVP'),
    'carpet': (rValue: 2.0, name: 'Carpet + Pad'),
  };

  // Max loop length by tube diameter
  static const Map<String, int> _maxLoopLength = {
    '3/8': 200,
    '1/2': 300,
    '5/8': 400,
  };

  double get _tubingLength {
    // Length = (Area × 12) / Spacing
    final spacingInches = double.parse(_spacing);
    return (_roomArea * 12) / spacingInches;
  }

  int get _numberOfLoops {
    final maxLoop = _maxLoopLength[_tubeDiameter] ?? 300;
    return (_tubingLength / maxLoop).ceil().clamp(1, 20);
  }

  double get _loopLength => _tubingLength / _numberOfLoops;

  double get _totalBtu => _roomArea * _btuPerSqFt;

  double get _gpm {
    // Approximate GPM based on heat load
    // 10,000 BTU/hr requires ~1 GPM at 20°F delta-T
    return _totalBtu / 10000;
  }

  String get _supplyTemp {
    final covering = _coverings[_floorCovering];
    final rValue = covering?.rValue ?? 0.5;

    // Higher R-value needs higher supply temp
    if (rValue <= 0.5) return '95-110°F';
    if (rValue <= 1.0) return '110-120°F';
    return '120-130°F';
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
          'Radiant Floor Tubing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildRoomAreaCard(colors),
          const SizedBox(height: 16),
          _buildSpacingCard(colors),
          const SizedBox(height: 16),
          _buildTubeDiameterCard(colors),
          const SizedBox(height: 16),
          _buildFloorCoveringCard(colors),
          const SizedBox(height: 16),
          _buildHeatLoadCard(colors),
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
            '${_tubingLength.toStringAsFixed(0)} ft',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Total Tubing Required',
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
                _buildResultRow(colors, 'Room Area', '${_roomArea.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Spacing', '$_spacing" O.C.'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Tube Diameter', '$_tubeDiameter"'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Number of Loops', '$_numberOfLoops', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Loop Length', '${_loopLength.toStringAsFixed(0)} ft each'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total BTU', '${_totalBtu.toStringAsFixed(0)} BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Est. Flow', '${_gpm.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Temp', _supplyTemp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomAreaCard(ZaftoColors colors) {
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
            'ROOM AREA (SQ FT)',
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
                '${_roomArea.toStringAsFixed(0)} sq ft',
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
                    value: _roomArea,
                    min: 50,
                    max: 1000,
                    divisions: 38,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _roomArea = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingCard(ZaftoColors colors) {
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
            'TUBING SPACING (ON CENTER)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _spacings.map((spacing) {
              final isSelected = _spacing == spacing;
              String desc;
              switch (spacing) {
                case '6': desc = 'High output'; break;
                case '9': desc = 'Standard'; break;
                case '12': desc = 'Low output'; break;
                default: desc = '';
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _spacing = spacing);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$spacing"',
                            style: TextStyle(
                              color: isSelected
                                  ? (colors.isDark ? Colors.black : Colors.white)
                                  : colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            desc,
                            style: TextStyle(
                              color: isSelected
                                  ? (colors.isDark ? Colors.black54 : Colors.white70)
                                  : colors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
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

  Widget _buildTubeDiameterCard(ZaftoColors colors) {
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
            'TUBE DIAMETER',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _diameters.map((dia) {
              final isSelected = _tubeDiameter == dia;
              final maxLoop = _maxLoopLength[dia] ?? 300;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _tubeDiameter = dia);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$dia"',
                            style: TextStyle(
                              color: isSelected
                                  ? (colors.isDark ? Colors.black : Colors.white)
                                  : colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Max ${maxLoop}ft loop',
                            style: TextStyle(
                              color: isSelected
                                  ? (colors.isDark ? Colors.black54 : Colors.white70)
                                  : colors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
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

  Widget _buildFloorCoveringCard(ZaftoColors colors) {
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
            'FLOOR COVERING',
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
            children: _coverings.entries.map((entry) {
              final isSelected = _floorCovering == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _floorCovering = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.name,
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
            'R-value: ${_coverings[_floorCovering]?.rValue ?? 0.5}',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatLoadCard(ZaftoColors colors) {
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
            'HEAT LOAD (BTU/SQ FT)',
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
                '${_btuPerSqFt.toStringAsFixed(0)} BTU/sf',
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
                    value: _btuPerSqFt,
                    min: 15,
                    max: 45,
                    divisions: 6,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _btuPerSqFt = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            '15-25 typical • 25-35 cold climate • 35-45 high loss',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
              Icon(LucideIcons.info, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Radiant Floor Guidelines',
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
            '• Max 300 ft loop for 1/2" PEX\n'
            '• Keep loops balanced (within 10%)\n'
            '• 9" O.C. standard residential\n'
            '• Max floor surface temp: 85°F\n'
            '• Use oxygen barrier PEX\n'
            '• Pressure test before cover',
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
