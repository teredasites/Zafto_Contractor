import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Bathtub Rough-In Calculator - Design System v2.6
///
/// Determines bathtub drain, overflow, and supply rough-in dimensions.
/// Covers standard, soaking, and whirlpool tub installations.
///
/// References: IPC 2024 Section 407, UPC Section 408
class TubRoughInScreen extends ConsumerStatefulWidget {
  const TubRoughInScreen({super.key});
  @override
  ConsumerState<TubRoughInScreen> createState() => _TubRoughInScreenState();
}

class _TubRoughInScreenState extends ConsumerState<TubRoughInScreen> {
  // Tub type
  String _tubType = 'alcove';

  // Tub dimensions
  double _tubLength = 60;
  double _tubWidth = 32;

  // Drain position from wall (left end)
  String _drainPosition = 'left';

  // Has whirlpool/jets
  bool _hasJets = false;

  static const Map<String, ({String desc, int length, int width, int drainSize})> _tubTypes = {
    'alcove': (desc: 'Alcove (Standard)', length: 60, width: 32, drainSize: 2),
    'drop_in': (desc: 'Drop-In', length: 60, width: 36, drainSize: 2),
    'freestanding': (desc: 'Freestanding', length: 66, width: 32, drainSize: 2),
    'corner': (desc: 'Corner', length: 60, width: 60, drainSize: 2),
    'soaking': (desc: 'Soaking/Deep', length: 66, width: 36, drainSize: 2),
    'walk_in': (desc: 'Walk-In (ADA)', length: 52, width: 30, drainSize: 2),
  };

  int get _drainSize => _tubTypes[_tubType]?.drainSize ?? 2;

  String get _drainLocationFromWall {
    // Drain is typically 14-15" from end wall
    if (_drainPosition == 'left') {
      return '14-15" from left wall';
    } else if (_drainPosition == 'right') {
      return '14-15" from right wall';
    }
    return 'Center';
  }

  double get _overflowHeight {
    // Overflow is typically 14-16" from floor
    if (_tubType == 'soaking') return 20;
    if (_tubType == 'walk_in') return 12;
    return 16;
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
          'Bathtub Rough-In',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildTubTypeCard(colors),
          const SizedBox(height: 16),
          _buildDimensionsCard(colors),
          const SizedBox(height: 16),
          _buildDrainPositionCard(colors),
          const SizedBox(height: 16),
          _buildJetsToggle(colors),
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
            '1½"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Drain Size (Trap is 1½")',
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
                _buildResultRow(colors, 'Tub Type', _tubTypes[_tubType]?.desc ?? 'Standard'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Tub Size', '${_tubLength.toStringAsFixed(0)}" × ${_tubWidth.toStringAsFixed(0)}"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Location', _drainLocationFromWall),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Overflow Height', '${_overflowHeight.toStringAsFixed(0)}" from floor'),
                if (_hasJets) ...[
                  Divider(color: colors.borderSubtle, height: 20),
                  _buildResultRow(colors, 'Motor Access', 'Required access panel'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Electrical', 'Dedicated 20A GFCI'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTubTypeCard(ZaftoColors colors) {
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
            'TUB TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._tubTypes.entries.map((entry) {
            final isSelected = _tubType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _tubType = entry.key;
                    _tubLength = entry.value.length.toDouble();
                    _tubWidth = entry.value.width.toDouble();
                  });
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
                        '${entry.value.length}" × ${entry.value.width}"',
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
            'TUB DIMENSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildSlider(colors, 'Length', _tubLength, (v) => setState(() => _tubLength = v), 48, 84),
          const SizedBox(height: 16),
          _buildSlider(colors, 'Width', _tubWidth, (v) => setState(() => _tubWidth = v), 28, 72),
        ],
      ),
    );
  }

  Widget _buildSlider(ZaftoColors colors, String label, double value, Function(double) onChanged, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text(
              '${value.toStringAsFixed(0)}"',
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
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrainPositionCard(ZaftoColors colors) {
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
            'DRAIN POSITION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['left', 'center', 'right'].map((pos) {
              final isSelected = _drainPosition == pos;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _drainPosition = pos);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          pos[0].toUpperCase() + pos.substring(1),
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 14,
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
            'When facing tub from open side',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildJetsToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasJets ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _hasJets ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _hasJets = !_hasJets);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _hasJets ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _hasJets ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _hasJets
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Whirlpool / Jetted Tub',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Requires dedicated 20A GFCI circuit, access panel',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            'STANDARD ROUGH-IN DIMENSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Drain C/L from End Wall', '14-15"'),
          _buildDimRow(colors, 'Drain C/L from Back Wall', '~16" (varies by tub)'),
          _buildDimRow(colors, 'Drain Size', '1½" tailpiece'),
          _buildDimRow(colors, 'Trap Size', '1½" P-trap'),
          _buildDimRow(colors, 'Overflow Height', '14-16" (20" for soaking)'),
          _buildDimRow(colors, 'Spout Height', '4" above tub rim'),
          _buildDimRow(colors, 'Valve Height', '28-32" from floor'),
          _buildDimRow(colors, 'Supply Lines', '½" hot & cold'),
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 407',
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
            '• IPC 407.2: Bathtub waste 1½" min\n'
            '• Overflow required on all bathtubs\n'
            '• ASSE 1016 anti-scald valve required\n'
            '• Whirlpool: GFCI protected circuit\n'
            '• Access panel for motor/pump\n'
            '• 21" clearance in front of tub',
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
