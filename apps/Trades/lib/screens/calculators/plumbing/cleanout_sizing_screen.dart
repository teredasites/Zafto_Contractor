import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Cleanout Sizing & Spacing Calculator - Design System v2.6
///
/// Determines cleanout size, spacing, and placement requirements.
/// Based on drain line size and location.
///
/// References: IPC 2024 Section 708
class CleanoutSizingScreen extends ConsumerStatefulWidget {
  const CleanoutSizingScreen({super.key});
  @override
  ConsumerState<CleanoutSizingScreen> createState() => _CleanoutSizingScreenState();
}

class _CleanoutSizingScreenState extends ConsumerState<CleanoutSizingScreen> {
  // Drain line size
  String _drainSize = '4';

  // Line location
  String _location = 'building_drain';

  // Building length (feet)
  double _buildingLength = 100;

  static const Map<String, ({String desc, int spacing, bool baseRequired})> _locations = {
    'building_drain': (desc: 'Building Drain', spacing: 100, baseRequired: true),
    'building_sewer': (desc: 'Building Sewer', spacing: 100, baseRequired: true),
    'horizontal_branch': (desc: 'Horizontal Branch', spacing: 100, baseRequired: false),
    'stack_base': (desc: 'Stack Base', spacing: 0, baseRequired: true),
  };

  static const Map<String, ({String desc, String cleanoutSize})> _drainSizes = {
    '1.5': (desc: '1½\"', cleanoutSize: '1½\"'),
    '2': (desc: '2\"', cleanoutSize: '2\"'),
    '3': (desc: '3\"', cleanoutSize: '3\"'),
    '4': (desc: '4\"', cleanoutSize: '4\"'),
    '6': (desc: '6\"', cleanoutSize: '6\"'),
    '8': (desc: '8\"', cleanoutSize: '6\"'),
    '10': (desc: '10\"', cleanoutSize: '6\"'),
  };

  // Cleanout size (same as drain up to 4", then 4" max per IPC)
  String get _cleanoutSize => _drainSizes[_drainSize]?.cleanoutSize ?? '4\"';

  // Maximum spacing
  int get _maxSpacing => _locations[_location]?.spacing ?? 100;

  // Number of cleanouts needed (for building length)
  int get _cleanutsNeeded {
    if (_maxSpacing == 0) return 1;
    final count = (_buildingLength / _maxSpacing).ceil();
    // Always need at least one at building entrance
    return count + 1;
  }

  // Cleanout locations
  List<String> get _cleanoutLocations {
    final locations = <String>[];

    // Base of each stack
    if (_location == 'building_drain' || _location == 'stack_base') {
      locations.add('Base of each stack');
    }

    // Building cleanout (within 5' of building)
    locations.add('Within 5\' inside foundation');

    // Every 100' or direction change
    if (_buildingLength > _maxSpacing && _maxSpacing > 0) {
      locations.add('Every ${_maxSpacing}\' on horizontal runs');
    }

    // Direction changes
    locations.add('At each aggregate direction change > 135°');

    // Junction of building drain and sewer
    if (_location == 'building_drain' || _location == 'building_sewer') {
      locations.add('Junction of building drain/sewer');
    }

    return locations;
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
          'Cleanout Requirements',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildDrainSizeCard(colors),
          const SizedBox(height: 16),
          _buildLocationCard(colors),
          const SizedBox(height: 16),
          _buildBuildingCard(colors),
          const SizedBox(height: 16),
          _buildLocationsCard(colors),
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
            _cleanoutSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Cleanout Size',
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
                _buildResultRow(colors, 'Drain Size', _drainSizes[_drainSize]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Max Spacing', _maxSpacing > 0 ? '$_maxSpacing ft' : 'At base'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Cleanouts Est.', '$_cleanutsNeeded minimum'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Clearance', _cleanoutSize == '3\"' || _cleanoutSize.contains('4') ? '18\" min' : '12\" min'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrainSizeCard(ZaftoColors colors) {
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
            'DRAIN LINE SIZE',
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
            children: _drainSizes.entries.map((entry) {
              final isSelected = _drainSize == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _drainSize = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
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
        ],
      ),
    );
  }

  Widget _buildLocationCard(ZaftoColors colors) {
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
            'LINE LOCATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._locations.entries.map((entry) {
            final isSelected = _location == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _location = entry.key);
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
                      if (entry.value.spacing > 0)
                        Text(
                          '${entry.value.spacing}\' max',
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
            'BUILDING LENGTH',
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
              Text('Horizontal Run', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_buildingLength.toStringAsFixed(0)} ft',
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
              value: _buildingLength,
              min: 20,
              max: 500,
              divisions: 48,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _buildingLength = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mapPin, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Required Cleanout Locations',
                style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._cleanoutLocations.map((location) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
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
              Icon(LucideIcons.circleDot, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 708',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Size: Same as drain (max 4\")\n'
            '• Clearance: 12\" for 3\" and smaller\n'
            '• Clearance: 18\" for over 3\"\n'
            '• 18\" max above floor when concealed\n'
            '• Direction of flow for access\n'
            '• Countersunk covers where exposed',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
