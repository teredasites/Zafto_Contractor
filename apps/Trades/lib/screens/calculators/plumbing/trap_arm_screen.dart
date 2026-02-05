import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Trap Arm Length Calculator - Design System v2.6
///
/// Calculates maximum trap arm distance from trap weir to vent per IPC 2024.
/// Also verifies slope and trap seal requirements.
///
/// References: IPC Table 1002.1, IPC 1002.1, IPC 1002.2
class TrapArmScreen extends ConsumerStatefulWidget {
  const TrapArmScreen({super.key});
  @override
  ConsumerState<TrapArmScreen> createState() => _TrapArmScreenState();
}

class _TrapArmScreenState extends ConsumerState<TrapArmScreen> {
  // Trap/drain size
  String _trapSize = '1-1/2';

  // Actual trap arm length (for verification)
  double _actualLength = 36; // inches

  // Calculation mode
  String _mode = 'lookup'; // 'lookup' or 'verify'

  // IPC Table 1002.1 - Trap arm lengths
  static const Map<String, ({int maxLengthInches, double slope, String note})> _trapArmLimits = {
    '1-1/4': (maxLengthInches: 30, slope: 0.25, note: 'Lavatory only'),
    '1-1/2': (maxLengthInches: 42, slope: 0.25, note: 'Lav, small fixtures'),
    '2': (maxLengthInches: 60, slope: 0.25, note: 'Standard residential'),
    '3': (maxLengthInches: 72, slope: 0.125, note: 'Water closet'),
    '4': (maxLengthInches: 120, slope: 0.125, note: 'Multiple WC'),
  };

  // Minimum trap seal depth
  static const double _minTrapSeal = 2.0; // inches

  // Maximum trap seal depth
  static const double _maxTrapSeal = 4.0; // inches

  ({int maxLengthInches, double slope, String note})? get _currentLimits {
    return _trapArmLimits[_trapSize];
  }

  int get _maxLengthInches => _currentLimits?.maxLengthInches ?? 42;
  double get _maxLengthFeet => _maxLengthInches / 12;
  double get _requiredSlope => _currentLimits?.slope ?? 0.25;

  // Total drop for trap arm at max length
  double get _maxDrop {
    return (_maxLengthInches / 12) * _requiredSlope;
  }

  // Verification results
  bool get _lengthOk => _actualLength <= _maxLengthInches;

  double get _actualLengthFeet => _actualLength / 12;

  double get _actualDrop => _actualLengthFeet * _requiredSlope;

  String get _verificationStatus {
    if (_actualLength <= _maxLengthInches * 0.75) {
      return 'GOOD - Well within limits';
    } else if (_actualLength <= _maxLengthInches) {
      return 'OK - Within maximum';
    } else {
      return 'EXCEEDS MAXIMUM - Add vent';
    }
  }

  Color _getStatusColor(ZaftoColors colors) {
    if (_actualLength <= _maxLengthInches * 0.75) {
      return colors.accentSuccess;
    } else if (_actualLength <= _maxLengthInches) {
      return colors.accentWarning;
    } else {
      return colors.accentError;
    }
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
          'Trap Arm Length',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModeSelector(colors),
          const SizedBox(height: 16),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildTrapSizeCard(colors),
          if (_mode == 'verify') ...[
            const SizedBox(height: 16),
            _buildActualLengthCard(colors),
          ],
          const SizedBox(height: 16),
          _buildLimitsTable(colors),
          const SizedBox(height: 16),
          _buildTrapSealInfo(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ZaftoColors colors) {
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
            'MODE',
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
              Expanded(child: _buildModeChip(colors, 'lookup', 'Lookup Limits', 'Find max distance')),
              const SizedBox(width: 12),
              Expanded(child: _buildModeChip(colors, 'verify', 'Verify Length', 'Check if OK')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(ZaftoColors colors, String value, String label, String desc) {
    final isSelected = _mode == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _mode = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    if (_mode == 'verify') {
      return _buildVerifyResultsCard(colors);
    }

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
            '$_maxLengthInches"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Maximum Trap Arm Length',
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
                _buildResultRow(colors, 'Trap Size', '$_trapSize"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Max Length', '${_maxLengthFeet.toStringAsFixed(1)} ft', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Required Slope', '${_requiredSlope}"/ft'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Max Drop @ Length', '${_maxDrop.toStringAsFixed(2)}"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Use Case', _currentLimits?.note ?? '--'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyResultsCard(ZaftoColors colors) {
    final statusColor = _getStatusColor(colors);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            _lengthOk ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
            color: statusColor,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            _verificationStatus,
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
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
                _buildResultRow(colors, 'Your Length', '${_actualLength.toInt()}"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Maximum Allowed', '$_maxLengthInches"', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Margin', '${(_maxLengthInches - _actualLength).toInt()}"'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Your Drop', '${_actualDrop.toStringAsFixed(2)}"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Trap Size', '$_trapSize"'),
              ],
            ),
          ),
          if (!_lengthOk) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: colors.accentError, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Install a vent within $_maxLengthInches" of trap weir',
                      style: TextStyle(color: colors.accentError, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrapSizeCard(ZaftoColors colors) {
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
            'TRAP/DRAIN SIZE',
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
            children: _trapArmLimits.keys.map((size) {
              final isSelected = _trapSize == size;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _trapSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$size"',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _trapArmLimits[size]?.note ?? '',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActualLengthCard(ZaftoColors colors) {
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
            'ACTUAL TRAP ARM LENGTH',
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
                '${_actualLength.toInt()}"',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                ' (${_actualLengthFeet.toStringAsFixed(1)} ft)',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _getStatusColor(colors),
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: _getStatusColor(colors),
                  ),
                  child: Slider(
                    value: _actualLength,
                    min: 6,
                    max: 150,
                    divisions: 144,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _actualLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'From trap weir (outlet) to vent connection',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsTable(ZaftoColors colors) {
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
            'IPC TABLE 1002.1 - TRAP ARM LIMITS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._trapArmLimits.entries.map((entry) {
            final isSelected = _trapSize == entry.key;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isSelected ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${entry.key}"',
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${entry.value.maxLengthInches}"',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${entry.value.slope}"/ft',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.note,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrapSealInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.droplet, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Text(
                'Trap Seal Requirements',
                style: TextStyle(
                  color: colors.accentInfo,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum seal depth: ${_minTrapSeal.toStringAsFixed(0)}" (2")\n'
            'Maximum seal depth: ${_maxTrapSeal.toStringAsFixed(0)}" (4")\n'
            'Deeper seals resist siphonage better',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              height: 1.5,
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
                'IPC 2024 Chapter 10',
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
            '• Table 1002.1 - Max trap arm distance\n'
            '• 1002.1 - Slope requirements\n'
            '• 1002.2 - Trap seal depth (2"-4")\n'
            '• 1002.3 - Trap prohibited from use\n'
            '• 1003.1 - Where traps required\n'
            '• Trap arm = trap outlet to vent',
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
