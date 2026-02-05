import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Urinal Rough-In Calculator - Design System v2.6
///
/// Determines urinal drain, supply, and mounting rough-in dimensions.
/// Covers wall-hung, floor-mount, and waterless installations.
///
/// References: IPC 2024 Section 410, ADA Standards
class UrinalRoughInScreen extends ConsumerStatefulWidget {
  const UrinalRoughInScreen({super.key});
  @override
  ConsumerState<UrinalRoughInScreen> createState() => _UrinalRoughInScreenState();
}

class _UrinalRoughInScreenState extends ConsumerState<UrinalRoughInScreen> {
  // Urinal type
  String _urinalType = 'wall_hung';

  // Flush type
  String _flushType = 'manual';

  // ADA compliant
  bool _adaRequired = false;

  // Mounting height (rim from floor)
  double _rimHeight = 24;

  static const Map<String, ({String desc, int drain, double gpf})> _urinalTypes = {
    'wall_hung': (desc: 'Wall-Hung', drain: 2, gpf: 0.5),
    'stall': (desc: 'Stall (Floor)', drain: 2, gpf: 1.0),
    'trough': (desc: 'Trough', drain: 2, gpf: 1.0),
    'waterless': (desc: 'Waterless', drain: 2, gpf: 0),
  };

  static const Map<String, ({String desc, int supplyHeight})> _flushTypes = {
    'manual': (desc: 'Manual Flush Valve', supplyHeight: 48),
    'sensor': (desc: 'Sensor Flush Valve', supplyHeight: 48),
    'tank': (desc: 'Tank Type', supplyHeight: 36),
  };

  // ADA requirements
  static const int _adaRimHeight = 17; // Max 17" for ADA
  static const int _standardRimHeight = 24; // Standard 24"

  int get _drainSize => _urinalTypes[_urinalType]?.drain ?? 2;
  double get _gpf => _urinalTypes[_urinalType]?.gpf ?? 0.5;
  int get _supplyHeight => _flushTypes[_flushType]?.supplyHeight ?? 48;

  bool get _rimMeetsAda => !_adaRequired || _rimHeight <= _adaRimHeight;

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
          'Urinal Rough-In',
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
          _buildUrinalTypeCard(colors),
          const SizedBox(height: 16),
          if (_urinalType != 'waterless') _buildFlushTypeCard(colors),
          if (_urinalType != 'waterless') const SizedBox(height: 16),
          _buildHeightCard(colors),
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
    final statusColor = _rimMeetsAda ? colors.accentSuccess : colors.accentError;

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
            '$_drainSize"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Drain Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (_adaRequired) ...[
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
                    _rimMeetsAda ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _rimMeetsAda ? 'ADA Compliant' : 'Rim Too High for ADA',
                    style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Type', _urinalTypes[_urinalType]?.desc ?? 'Wall-Hung'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Rim Height', '${_rimHeight.toStringAsFixed(0)}" from floor'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Flow Rate', _gpf > 0 ? '${_gpf.toStringAsFixed(1)} GPF' : 'Waterless'),
                if (_urinalType != 'waterless') ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Flush Type', _flushTypes[_flushType]?.desc ?? 'Manual'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Supply Height', '$_supplyHeight" from floor'),
                ],
              ],
            ),
          ),
        ],
      ),
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
          setState(() {
            _adaRequired = !_adaRequired;
            if (_adaRequired) {
              _rimHeight = 17;
            } else {
              _rimHeight = 24;
            }
          });
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
                    '17" max rim height, elongated bowl',
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

  Widget _buildUrinalTypeCard(ZaftoColors colors) {
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
            'URINAL TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._urinalTypes.entries.map((entry) {
            final isSelected = _urinalType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _urinalType = entry.key);
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
                        entry.value.gpf > 0 ? '${entry.value.gpf} GPF' : 'No Water',
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

  Widget _buildFlushTypeCard(ZaftoColors colors) {
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
            'FLUSH TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._flushTypes.entries.map((entry) {
            final isSelected = _flushType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _flushType = entry.key);
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
                        'Supply @ ${entry.value.supplyHeight}"',
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

  Widget _buildHeightCard(ZaftoColors colors) {
    final minHeight = _urinalType == 'stall' ? 0 : 14;
    final maxHeight = _adaRequired ? 17 : 30;

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
            'MOUNTING HEIGHT',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildSlider(
            colors,
            'Rim Height',
            _rimHeight,
            (v) => setState(() => _rimHeight = v),
            minHeight.toDouble(),
            maxHeight.toDouble(),
            !_rimMeetsAda,
          ),
          const SizedBox(height: 8),
          Text(
            _adaRequired ? 'ADA max: 17" from floor' : 'Standard: 24" from floor',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(ZaftoColors colors, String label, double value, Function(double) onChanged, double min, double max, bool warning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text(
              '${value.toStringAsFixed(0)}"',
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
            value: value.clamp(min, max),
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
          _buildDimRow(colors, 'Drain Size', '2" (code minimum)'),
          _buildDimRow(colors, 'Drain Height', '18-20" from floor'),
          _buildDimRow(colors, 'Center Spacing', '30" min (24" ADA)'),
          if (_urinalType != 'waterless') ...[
            _buildDimRow(colors, 'Supply Size', '¾" (flush valve)'),
            _buildDimRow(colors, 'Supply Height', '48" (flush valve)'),
          ],
          _buildDimRow(colors, 'Side Clearance', '15" from wall to C/L'),
          if (_adaRequired)
            _buildDimRow(colors, 'Grab Bars', 'Not required for urinals'),
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
            '• IPC 410: Urinal waste 1½" min (2" typical)\n'
            '• Max 0.5 GPF (WaterSense)\n'
            '• 30" min center-to-center spacing\n'
            '• ADA: 17" max rim height\n'
            '• Flush valve: ¾" supply\n'
            '• Waterless urinals code accepted',
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
