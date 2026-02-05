import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Utility/Laundry Sink Rough-In Calculator - Design System v2.6
///
/// Determines utility sink and laundry tub rough-in dimensions.
/// Includes washer standpipe and drain requirements.
///
/// References: IPC 2024 Section 405
class UtilitySinkRoughInScreen extends ConsumerStatefulWidget {
  const UtilitySinkRoughInScreen({super.key});
  @override
  ConsumerState<UtilitySinkRoughInScreen> createState() => _UtilitySinkRoughInScreenState();
}

class _UtilitySinkRoughInScreenState extends ConsumerState<UtilitySinkRoughInScreen> {
  // Sink type
  String _sinkType = 'freestanding';

  // Has washer connection
  bool _hasWasher = true;

  // Washer type
  String _washerType = 'top';

  // Sink depth
  double _sinkDepth = 12;

  static const Map<String, ({String desc, int height, int drainSize})> _sinkTypes = {
    'freestanding': (desc: 'Freestanding Tub', height: 34, drainSize: 2),
    'wall_mount': (desc: 'Wall-Mount', height: 34, drainSize: 2),
    'drop_in': (desc: 'Drop-In', height: 36, drainSize: 2),
    'mop_sink': (desc: 'Mop Basin (Floor)', height: 12, drainSize: 3),
  };

  static const Map<String, ({String desc, int standpipeHeight})> _washerTypes = {
    'top': (desc: 'Top Load', standpipeHeight: 42),
    'front': (desc: 'Front Load', standpipeHeight: 36),
  };

  int get _drainSize => _sinkTypes[_sinkType]?.drainSize ?? 2;
  int get _sinkHeight => _sinkTypes[_sinkType]?.height ?? 34;
  int get _standpipeHeight => _washerTypes[_washerType]?.standpipeHeight ?? 42;

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
          'Utility Sink Rough-In',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSinkTypeCard(colors),
          const SizedBox(height: 16),
          _buildWasherToggle(colors),
          if (_hasWasher) ...[
            const SizedBox(height: 16),
            _buildWasherTypeCard(colors),
          ],
          const SizedBox(height: 16),
          _buildDimensionsCard(colors),
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Sink Type', _sinkTypes[_sinkType]?.desc ?? 'Freestanding'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Sink Height', '$_sinkHeight" rim'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Height', '${_sinkHeight - _sinkDepth.toInt()}" from floor'),
                if (_hasWasher) ...[
                  Divider(color: colors.borderSubtle, height: 20),
                  _buildResultRow(colors, 'Standpipe Height', '$_standpipeHeight"'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Standpipe Size', '2" min'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Hot/Cold Valves', '42" from floor'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinkTypeCard(ZaftoColors colors) {
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
            'SINK TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._sinkTypes.entries.map((entry) {
            final isSelected = _sinkType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sinkType = entry.key);
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
                        '${entry.value.drainSize}" drain',
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

  Widget _buildWasherToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasWasher ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _hasWasher ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _hasWasher = !_hasWasher);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _hasWasher ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _hasWasher ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _hasWasher
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Washer Connection',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Include standpipe and supply valves',
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

  Widget _buildWasherTypeCard(ZaftoColors colors) {
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
            'WASHER TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _washerTypes.entries.map((entry) {
              final isSelected = _washerType == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _washerType = entry.key);
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
                            entry.value.desc,
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Standpipe ${entry.value.standpipeHeight}"',
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
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
            'SINK DIMENSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildSlider(colors, 'Sink Depth', _sinkDepth, (v) => setState(() => _sinkDepth = v), 8, 24),
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
          _buildDimRow(colors, 'Sink Drain Height', '18-22" from floor'),
          _buildDimRow(colors, 'Drain Size', '1½" or 2"'),
          _buildDimRow(colors, 'Supply Height', '20" from floor'),
          _buildDimRow(colors, 'Supply Size', '½"'),
          if (_hasWasher) ...[
            Divider(color: colors.borderSubtle, height: 16),
            _buildDimRow(colors, 'Standpipe Height', '18-42" above trap'),
            _buildDimRow(colors, 'Standpipe Size', '2" min'),
            _buildDimRow(colors, 'Washer Valves', '42" from floor'),
            _buildDimRow(colors, 'Drain Box', '18" × 18" typical'),
          ],
          if (_sinkType == 'mop_sink') ...[
            Divider(color: colors.borderSubtle, height: 16),
            _buildDimRow(colors, 'Floor Drain', '3" required'),
            _buildDimRow(colors, 'Faucet Height', '24-30" above basin'),
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
                'IPC 2024 Section 405/802',
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
            '• Utility sink: 1½" or 2" drain\n'
            '• Mop basin: 3" floor drain\n'
            '• Washer standpipe: 2" min\n'
            '• Standpipe: 18-42" above trap\n'
            '• P-trap accessible location\n'
            '• Washer box recommended',
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
