import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Vent Sizing Calculator - Design System v2.6
///
/// Calculates vent pipe size based on DFU load and developed length per IPC 2024.
/// Covers individual vents, branch vents, and vent stacks.
///
/// References: IPC Table 906.1, IPC 906.1, IPC 916.1
class VentSizingScreen extends ConsumerStatefulWidget {
  const VentSizingScreen({super.key});
  @override
  ConsumerState<VentSizingScreen> createState() => _VentSizingScreenState();
}

class _VentSizingScreenState extends ConsumerState<VentSizingScreen> {
  // Vent type
  String _ventType = 'individual'; // 'individual', 'branch', 'stack'

  // Connected DFU
  double _connectedDfu = 2;

  // Developed length (feet)
  double _developedLength = 20;

  // Drain size connected (for individual vents)
  String _drainSize = '2';

  // IPC Table 906.1 - Vent sizing based on DFU and developed length
  // Format: {vent diameter: {max DFU at length in feet}}
  static const Map<String, List<({int maxDfu, int maxLength})>> _ventSizingTable = {
    '1-1/4': [
      (maxDfu: 1, maxLength: 45),
    ],
    '1-1/2': [
      (maxDfu: 8, maxLength: 60),
      (maxDfu: 4, maxLength: 120),
      (maxDfu: 2, maxLength: 180),
    ],
    '2': [
      (maxDfu: 24, maxLength: 100),
      (maxDfu: 12, maxLength: 200),
      (maxDfu: 6, maxLength: 300),
    ],
    '2-1/2': [
      (maxDfu: 48, maxLength: 140),
      (maxDfu: 24, maxLength: 280),
      (maxDfu: 12, maxLength: 420),
    ],
    '3': [
      (maxDfu: 84, maxLength: 212),
      (maxDfu: 42, maxLength: 424),
      (maxDfu: 21, maxLength: 640),
    ],
    '4': [
      (maxDfu: 256, maxLength: 300),
      (maxDfu: 128, maxLength: 600),
      (maxDfu: 64, maxLength: 900),
    ],
  };

  // Minimum vent sizes by drain size (IPC 906.1)
  static const Map<String, String> _minVentByDrain = {
    '1-1/4': '1-1/4',
    '1-1/2': '1-1/4',
    '2': '1-1/2',
    '2-1/2': '1-1/2',
    '3': '2',
    '4': '2',
    '5': '2-1/2',
    '6': '3',
  };

  // Individual vent - max trap arm distance (IPC Table 906.1)
  static const Map<String, ({String minVent, int maxTrapArm})> _trapArmLimits = {
    '1-1/4': (minVent: '1-1/4"', maxTrapArm: 30), // inches
    '1-1/2': (minVent: '1-1/4"', maxTrapArm: 42),
    '2': (minVent: '1-1/2"', maxTrapArm: 60),
    '3': (minVent: '2"', maxTrapArm: 72),
    '4': (minVent: '2"', maxTrapArm: 120),
  };

  String get _recommendedVentSize {
    final dfu = _connectedDfu;
    final length = _developedLength;

    if (dfu <= 0) return '--';

    // Find smallest vent that can handle the DFU at the developed length
    for (final entry in _ventSizingTable.entries) {
      for (final limit in entry.value) {
        if (dfu <= limit.maxDfu && length <= limit.maxLength) {
          // Check minimum vent size based on drain
          final minVent = _minVentByDrain[_drainSize];
          if (minVent != null) {
            final minVentNum = _parseVentSize(minVent);
            final thisVentNum = _parseVentSize(entry.key);
            if (thisVentNum >= minVentNum) {
              return '${entry.key}"';
            }
          } else {
            return '${entry.key}"';
          }
        }
      }
    }

    // If nothing found, return minimum based on drain
    final minVent = _minVentByDrain[_drainSize] ?? '2';
    return '$minVent"';
  }

  double _parseVentSize(String size) {
    if (size.contains('1/4')) return 1.25;
    if (size.contains('1/2')) return 1.5;
    return double.tryParse(size.replaceAll('"', '')) ?? 2.0;
  }

  int get _maxDevelopedLength {
    final dfu = _connectedDfu;
    final ventSize = _recommendedVentSize.replaceAll('"', '');

    final limits = _ventSizingTable[ventSize];
    if (limits == null) return 100;

    for (final limit in limits) {
      if (dfu <= limit.maxDfu) {
        return limit.maxLength;
      }
    }
    return 100;
  }

  String get _trapArmInfo {
    final limit = _trapArmLimits[_drainSize];
    if (limit == null) return '--';
    return '${limit.maxTrapArm}" max (${(limit.maxTrapArm / 12).toStringAsFixed(1)} ft)';
  }

  String get _minVentForDrain {
    final limit = _trapArmLimits[_drainSize];
    return limit?.minVent ?? '--';
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
          'Vent Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildVentTypeSelector(colors),
          const SizedBox(height: 16),
          _buildDrainSizeCard(colors),
          const SizedBox(height: 16),
          _buildDfuCard(colors),
          const SizedBox(height: 16),
          _buildLengthCard(colors),
          const SizedBox(height: 16),
          _buildSizingTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
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
            _recommendedVentSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Minimum Vent Size',
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
                _buildResultRow(colors, 'Vent Type', _ventType.substring(0, 1).toUpperCase() + _ventType.substring(1)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Connected DFU', _connectedDfu.toStringAsFixed(0)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Developed Length', '${_developedLength.toInt()} ft'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Max Length @ Size', '$_maxDevelopedLength ft', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Size', '$_drainSize"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Vent for Drain', _minVentForDrain),
                if (_ventType == 'individual') ...[
                  Divider(color: colors.borderSubtle, height: 20),
                  _buildResultRow(colors, 'Max Trap Arm', _trapArmInfo),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentTypeSelector(ZaftoColors colors) {
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
            'VENT TYPE',
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
            children: [
              _buildTypeChip(colors, 'individual', 'Individual', 'Single fixture'),
              _buildTypeChip(colors, 'branch', 'Branch', 'Multiple fixtures'),
              _buildTypeChip(colors, 'stack', 'Stack', 'Vertical main'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(ZaftoColors colors, String value, String label, String desc) {
    final isSelected = _ventType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _ventType = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            'CONNECTED DRAIN SIZE',
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
            children: ['1-1/4', '1-1/2', '2', '3', '4'].map((size) {
              final isSelected = _drainSize == size;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _drainSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$size"',
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

  Widget _buildDfuCard(ZaftoColors colors) {
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
            'CONNECTED DFU',
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
            children: [1, 2, 4, 8, 12, 24, 48].map((dfu) {
              final isSelected = _connectedDfu == dfu.toDouble();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _connectedDfu = dfu.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$dfu',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_connectedDfu.toInt()} DFU',
                style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
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
                    value: _connectedDfu,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _connectedDfu = v);
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

  Widget _buildLengthCard(ZaftoColors colors) {
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
            'DEVELOPED LENGTH (FEET)',
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
                '${_developedLength.toInt()} ft',
                style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
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
                    value: _developedLength,
                    min: 5,
                    max: 300,
                    divisions: 59,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _developedLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total length from trap weir to vent terminal',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSizingTable(ZaftoColors colors) {
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
            'IPC TABLE 906.1 - VENT SIZE LIMITS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._ventSizingTable.entries.take(4).map((entry) {
            final isSelected = _recommendedVentSize.replaceAll('"', '') == entry.key;
            final firstLimit = entry.value.first;
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
                  Expanded(
                    child: Text(
                      'Max ${firstLimit.maxDfu} DFU @ ${firstLimit.maxLength} ft',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
                ],
              ),
            );
          }),
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
                'IPC 2024 Chapter 9',
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
            '• Table 906.1 - Vent size by DFU and length\n'
            '• 906.1 - Min vent 1/2 drain size (not < 1-1/4")\n'
            '• 906.2 - Developed length limits\n'
            '• 909.1 - Wet vent sizing\n'
            '• 918.1 - AAV limitations\n'
            '• Always terminate above roof',
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
