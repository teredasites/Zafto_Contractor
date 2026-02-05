import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Drinking Fountain / Water Cooler Calculator - Design System v2.6
///
/// Determines drinking fountain rough-in and fixture count requirements.
/// Covers wall-mount, freestanding, bottle fillers, and ADA installations.
///
/// References: IPC 2024 Section 410, ADA Standards
class DrinkingFountainScreen extends ConsumerStatefulWidget {
  const DrinkingFountainScreen({super.key});
  @override
  ConsumerState<DrinkingFountainScreen> createState() => _DrinkingFountainScreenState();
}

class _DrinkingFountainScreenState extends ConsumerState<DrinkingFountainScreen> {
  // Fountain type
  String _fountainType = 'wall_mount';

  // Has bottle filler
  bool _hasBottleFiller = true;

  // ADA compliant
  bool _adaRequired = true;

  // Hi-Lo combination (ADA + Standard)
  bool _hiLoCombination = true;

  // Occupancy count (for fixture requirements)
  int _occupancy = 100;

  static const Map<String, ({String desc, int spout, bool needsDrain})> _fountainTypes = {
    'wall_mount': (desc: 'Wall-Mount', spout: 36, needsDrain: true),
    'recessed': (desc: 'Recessed', spout: 36, needsDrain: true),
    'freestanding': (desc: 'Freestanding', spout: 36, needsDrain: true),
    'bottle_filler': (desc: 'Bottle Filler Only', spout: 42, needsDrain: true),
    'pedestal': (desc: 'Pedestal', spout: 36, needsDrain: true),
  };

  // ADA requirements
  static const int _adaSpoutHeight = 36; // Max 36" for forward approach
  static const int _adaHiSpoutHeight = 43; // Hi unit (38-43")
  static const int _adaClearFloor = 27; // Min knee clearance
  static const int _adaClearWidth = 30; // Min clear width

  int get _spoutHeight {
    if (_hiLoCombination) return _adaSpoutHeight;
    return _fountainTypes[_fountainType]?.spout ?? 36;
  }

  int get _fountainsRequired {
    // IPC Table 403.1 - 1 per 100 occupants typical
    return ((_occupancy + 99) / 100).ceil();
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
          'Drinking Fountain',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildFountainTypeCard(colors),
          const SizedBox(height: 16),
          _buildOptionsCard(colors),
          const SizedBox(height: 16),
          _buildOccupancyCard(colors),
          const SizedBox(height: 16),
          _buildRoughInTable(colors),
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
            '$_fountainsRequired',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Fountain${_fountainsRequired != 1 ? 's' : ''} Required',
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
                _buildResultRow(colors, 'Type', _fountainTypes[_fountainType]?.desc ?? 'Wall-Mount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Spout Height', '$_spoutHeight" from floor'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Size', '1¼"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Size', '½"'),
                if (_hiLoCombination) ...[
                  Divider(color: colors.borderSubtle, height: 20),
                  _buildResultRow(colors, 'Lo Unit (ADA)', '36" max spout'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Hi Unit', '38-43" spout'),
                ],
                if (_hasBottleFiller) ...[
                  Divider(color: colors.borderSubtle, height: 20),
                  _buildResultRow(colors, 'Bottle Filler', '42" fill height'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFountainTypeCard(ZaftoColors colors) {
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
            'FOUNTAIN TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._fountainTypes.entries.map((entry) {
            final isSelected = _fountainType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _fountainType = entry.key);
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Spout ${entry.value.spout}"',
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

  Widget _buildOptionsCard(ZaftoColors colors) {
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
            'OPTIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleRow(colors, 'Hi-Lo Combination', 'ADA + standard height units', _hiLoCombination, (v) => setState(() => _hiLoCombination = v)),
          _buildToggleRow(colors, 'Bottle Filler', 'Integrated bottle fill station', _hasBottleFiller, (v) => setState(() => _hasBottleFiller = v)),
          _buildToggleRow(colors, 'ADA Required', '36" max spout, knee clearance', _adaRequired, (v) => setState(() => _adaRequired = v)),
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
                  Text(
                    title,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.textTertiary, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            'BUILDING OCCUPANCY',
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Occupancy', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                        Text(
                          '$_occupancy people',
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
                        value: _occupancy.toDouble(),
                        min: 10,
                        max: 500,
                        divisions: 49,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _occupancy = v.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            'IPC requires 1 fountain per 100 occupants (typical)',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRoughInTable(ZaftoColors colors) {
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
            'ROUGH-IN DIMENSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Drain Size', '1¼" (gravity drain)'),
          _buildDimRow(colors, 'Supply Size', '½" cold only'),
          _buildDimRow(colors, 'Drain Height', '4-6" from floor'),
          _buildDimRow(colors, 'Supply Height', '8-10" from floor'),
          if (_adaRequired) ...[
            Divider(color: colors.borderSubtle, height: 16),
            _buildDimRow(colors, 'ADA Spout Max', '36" from floor'),
            _buildDimRow(colors, 'Knee Clearance', '27" min'),
            _buildDimRow(colors, 'Clear Floor', '30" × 48" min'),
            _buildDimRow(colors, 'Toe Clearance', '9" min height'),
          ],
          if (_hasBottleFiller) ...[
            Divider(color: colors.borderSubtle, height: 16),
            _buildDimRow(colors, 'Fill Height', '42" AFF typical'),
            _buildDimRow(colors, 'Electrical', 'Dedicated circuit if cooled'),
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
          Text(
            '$label: ',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
            ),
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
        Text(
          value,
          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
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
                'IPC 2024 Section 410',
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
            '• IPC 410: 1 fountain per 100 occupants\n'
            '• 50% must be ADA accessible\n'
            '• Hi-Lo satisfies both requirements\n'
            '• Bottle filler may substitute fountain\n'
            '• ADA: 36" max spout height\n'
            '• Recirculating cooler requires drain',
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
