import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Room CFM Calculator - Design System v2.6
///
/// Calculates required airflow for individual rooms based on
/// heating/cooling load or air changes per hour.
///
/// References: ACCA Manual J/D, ASHRAE 62.1/62.2
class CfmRoomScreen extends ConsumerStatefulWidget {
  const CfmRoomScreen({super.key});
  @override
  ConsumerState<CfmRoomScreen> createState() => _CfmRoomScreenState();
}

class _CfmRoomScreenState extends ConsumerState<CfmRoomScreen> {
  // Room dimensions
  double _length = 15;
  double _width = 12;
  double _height = 8;

  // Room type
  String _roomType = 'bedroom';

  // Calculation method
  String _calcMethod = 'load';

  // Room BTU load (for load method)
  double _roomBtu = 5000;

  static const Map<String, ({String desc, double achMin, double cfmPerSqft})> _roomTypes = {
    'bedroom': (desc: 'Bedroom', achMin: 0.35, cfmPerSqft: 1.0),
    'living': (desc: 'Living Room', achMin: 0.35, cfmPerSqft: 1.0),
    'kitchen': (desc: 'Kitchen', achMin: 0.35, cfmPerSqft: 2.0),
    'bathroom': (desc: 'Bathroom', achMin: 0.35, cfmPerSqft: 1.5),
    'office': (desc: 'Home Office', achMin: 0.35, cfmPerSqft: 1.0),
    'basement': (desc: 'Basement', achMin: 0.35, cfmPerSqft: 0.75),
    'garage': (desc: 'Garage (conditioned)', achMin: 0.5, cfmPerSqft: 0.5),
  };

  static const Map<String, String> _calcMethods = {
    'load': 'BTU Load Method',
    'ach': 'Air Changes/Hour',
    'sqft': 'CFM per Sq Ft',
  };

  // Room area
  double get _area => _length * _width;

  // Room volume
  double get _volume => _area * _height;

  // CFM calculation
  double get _cfm {
    final room = _roomTypes[_roomType];

    switch (_calcMethod) {
      case 'load':
        // CFM = BTU / (1.08 × ΔT) - using 20°F delta T typical
        return _roomBtu / (1.08 * 20);
      case 'ach':
        // CFM = (Volume × ACH) / 60
        return (_volume * (room?.achMin ?? 0.35)) / 60 * 8; // Typical 8 ACH for comfort
      case 'sqft':
        return _area * (room?.cfmPerSqft ?? 1.0);
      default:
        return _area;
    }
  }

  // Register size (inches)
  String get _registerSize {
    final cfm = _cfm;
    if (cfm <= 75) return '6×10\" or 8×8\"';
    if (cfm <= 125) return '8×12\" or 10×10\"';
    if (cfm <= 175) return '10×12\" or 12×12\"';
    if (cfm <= 250) return '12×14\" or 14×14\"';
    return '14×16\" or larger';
  }

  // Flex duct size (round)
  int get _flexSize {
    final cfm = _cfm;
    if (cfm <= 50) return 5;
    if (cfm <= 75) return 6;
    if (cfm <= 125) return 7;
    if (cfm <= 175) return 8;
    if (cfm <= 250) return 9;
    return 10;
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
          'Room CFM Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildDimensionsCard(colors),
          const SizedBox(height: 16),
          _buildRoomTypeCard(colors),
          const SizedBox(height: 16),
          _buildMethodCard(colors),
          if (_calcMethod == 'load') ...[
            const SizedBox(height: 16),
            _buildBtuCard(colors),
          ],
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
            '${_cfm.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'CFM Required',
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
                _buildResultRow(colors, 'Room Area', '${_area.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Room Volume', '${_volume.toStringAsFixed(0)} cu ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'CFM/sq ft', '${(_cfm / _area).toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Register Size', _registerSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Flex Duct', '$_flexSize\" round'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsCard(ZaftoColors colors) {
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
            'ROOM DIMENSIONS',
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
              Text('Length', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_length.toStringAsFixed(0)} ft',
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
              value: _length,
              min: 6,
              max: 30,
              divisions: 24,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _length = v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Width', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_width.toStringAsFixed(0)} ft',
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
              value: _width,
              min: 6,
              max: 25,
              divisions: 19,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _width = v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ceiling Height', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_height.toStringAsFixed(0)} ft',
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
              value: _height,
              min: 7,
              max: 12,
              divisions: 10,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _height = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeCard(ZaftoColors colors) {
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
            'ROOM TYPE',
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
            children: _roomTypes.entries.map((entry) {
              final isSelected = _roomType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _roomType = entry.key);
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

  Widget _buildMethodCard(ZaftoColors colors) {
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
            'CALCULATION METHOD',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._calcMethods.entries.map((entry) {
            final isSelected = _calcMethod == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _calcMethod = entry.key);
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
                          entry.value,
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
            'ROOM BTU LOAD',
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
                '${_roomBtu.toStringAsFixed(0)}',
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
              value: _roomBtu,
              min: 1000,
              max: 20000,
              divisions: 38,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _roomBtu = v);
              },
            ),
          ),
          Text(
            'From Manual J room-by-room calculation',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
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
              Icon(LucideIcons.wind, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ACCA Manual D',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Base on Manual J loads\n'
            '• Distribute by room load ratio\n'
            '• Verify register face velocity\n'
            '• Size trunk for total CFM\n'
            '• Balance all rooms\n'
            '• Consider throw distance',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
