import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Toilet Rough-In Calculator - Design System v2.6
///
/// Determines toilet rough-in dimensions and clearances.
/// Essential for proper toilet installation and ADA compliance.
///
/// References: IPC 2024 Section 405, ADA Standards
class ToiletRoughInScreen extends ConsumerStatefulWidget {
  const ToiletRoughInScreen({super.key});
  @override
  ConsumerState<ToiletRoughInScreen> createState() => _ToiletRoughInScreenState();
}

class _ToiletRoughInScreenState extends ConsumerState<ToiletRoughInScreen> {
  // Rough-in measurement (center of drain to wall)
  String _roughIn = '12';

  // Side clearance (center to nearest obstruction)
  double _sideClearance = 15;

  // Front clearance (to front of toilet from wall)
  double _frontClearance = 21;

  // ADA compliant
  bool _adaRequired = false;

  // Toilet type
  String _toiletType = 'round';

  static const List<String> _roughIns = ['10', '12', '14'];

  static const Map<String, ({int length, String desc})> _toiletTypes = {
    'round': (length: 28, desc: 'Round Bowl'),
    'elongated': (length: 31, desc: 'Elongated Bowl'),
    'compact': (length: 26, desc: 'Compact Elongated'),
  };

  // Code requirements
  static const int _minSideClearance = 15; // IPC 405.3.1
  static const int _minFrontClearance = 21; // IPC 405.3.1
  static const int _adaSideClearance = 18; // ADA
  static const int _adaFrontClearance = 48; // ADA clear floor space

  bool get _sideMeetsCode {
    final required = _adaRequired ? _adaSideClearance : _minSideClearance;
    return _sideClearance >= required;
  }

  bool get _frontMeetsCode {
    final toiletLength = _toiletTypes[_toiletType]?.length ?? 28;
    final totalFront = _frontClearance + toiletLength;
    final required = _adaRequired ? _adaFrontClearance : _minFrontClearance;
    return _frontClearance >= required || totalFront >= required;
  }

  double get _totalFrontProjection {
    final toiletLength = _toiletTypes[_toiletType]?.length ?? 28;
    final roughIn = double.parse(_roughIn);
    return roughIn + toiletLength - 6; // 6" behind rough-in typical
  }

  double get _minWidth {
    final side = _adaRequired ? _adaSideClearance.toDouble() : _minSideClearance.toDouble();
    return side * 2;
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
          'Toilet Rough-In',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildAdaToggle(colors),
          const SizedBox(height: 16),
          _buildRoughInCard(colors),
          const SizedBox(height: 16),
          _buildToiletTypeCard(colors),
          const SizedBox(height: 16),
          _buildClearancesCard(colors),
          const SizedBox(height: 16),
          _buildDimensionsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final allMeetsCode = _sideMeetsCode && _frontMeetsCode;
    final statusColor = allMeetsCode ? colors.accentSuccess : colors.accentError;

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
            '$_roughIn"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Rough-In (Center to Wall)',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allMeetsCode ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  allMeetsCode ? 'Clearances OK' : 'Check Clearances',
                  style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
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
                _buildStatusRow(colors, 'Side Clearance', '${_sideClearance.toStringAsFixed(0)}"', _sideMeetsCode),
                const SizedBox(height: 10),
                _buildStatusRow(colors, 'Front Clearance', '${_frontClearance.toStringAsFixed(0)}"', _frontMeetsCode),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Total Front Proj.', '${_totalFrontProjection.toStringAsFixed(0)}"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Width', '${_minWidth.toStringAsFixed(0)}"'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(ZaftoColors colors, String label, String value, bool meetsCode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: meetsCode ? colors.textPrimary : colors.accentError,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              meetsCode ? LucideIcons.check : LucideIcons.x,
              color: meetsCode ? colors.accentSuccess : colors.accentError,
              size: 14,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdaToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _adaRequired ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _adaRequired ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _adaRequired = !_adaRequired);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _adaRequired ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _adaRequired ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _adaRequired
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADA Compliant',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Requires 18" side, 48" clear floor space',
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

  Widget _buildRoughInCard(ZaftoColors colors) {
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
            'ROUGH-IN MEASUREMENT',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _roughIns.map((ri) {
              final isSelected = _roughIn == ri;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _roughIn = ri);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$ri"',
                            style: TextStyle(
                              color: isSelected
                                  ? (colors.isDark ? Colors.black : Colors.white)
                                  : colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ri == '12' ? 'Standard' : ri == '10' ? 'Compact' : 'Extended',
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
          const SizedBox(height: 8),
          Text(
            'Distance from finished wall to center of drain',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildToiletTypeCard(ZaftoColors colors) {
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
            'TOILET BOWL TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._toiletTypes.entries.map((entry) {
            final isSelected = _toiletType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _toiletType = entry.key);
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
                        '~${entry.value.length}" long',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 12,
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

  Widget _buildClearancesCard(ZaftoColors colors) {
    final minSide = _adaRequired ? _adaSideClearance : _minSideClearance;
    final minFront = _adaRequired ? 21 : _minFrontClearance; // Always 21" min in front

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
            'CLEARANCES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildClearanceSlider(
            colors,
            'Side (C/L to obstruction)',
            _sideClearance,
            (v) => setState(() => _sideClearance = v),
            minSide.toDouble(),
            !_sideMeetsCode,
          ),
          const SizedBox(height: 16),
          _buildClearanceSlider(
            colors,
            'Front (in front of toilet)',
            _frontClearance,
            (v) => setState(() => _frontClearance = v),
            minFront.toDouble(),
            !_frontMeetsCode,
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceSlider(ZaftoColors colors, String label, double value, Function(double) onChanged, double min, bool warning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text(
              '${value.toStringAsFixed(0)}" (min $min")',
              style: TextStyle(
                color: warning ? colors.accentError : colors.accentPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: warning ? colors.accentError : colors.accentPrimary,
            inactiveTrackColor: colors.bgBase,
            thumbColor: warning ? colors.accentError : colors.accentPrimary,
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 12,
            max: 36,
            divisions: 24,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ],
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
            'STANDARD DIMENSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Supply Valve Height', '6" above floor'),
          _buildDimRow(colors, 'Supply Location', '6" left of C/L'),
          _buildDimRow(colors, 'Flange Height', 'Flush to 1/4" above finished floor'),
          _buildDimRow(colors, 'Drain Size', '3" or 4" (3" typical residential)'),
          _buildDimRow(colors, 'Vent Within', '6\' developed length'),
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 405',
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
            '• IPC 405.3.1: 15" min C/L to side wall\n'
            '• IPC 405.3.1: 21" min in front of toilet\n'
            '• ADA: 18" C/L to side wall\n'
            '• ADA: 60" × 56" clear floor space\n'
            '• 12" is most common rough-in\n'
            '• Measure before ordering toilet',
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
