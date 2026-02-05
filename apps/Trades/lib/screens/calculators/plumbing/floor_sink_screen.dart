import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Floor Sink Calculator - Design System v2.6
///
/// Sizes floor sinks for commercial kitchens and food service.
/// Includes indirect waste and grease waste connections.
///
/// References: IPC 2024 Section 802, NSF Standards
class FloorSinkScreen extends ConsumerStatefulWidget {
  const FloorSinkScreen({super.key});
  @override
  ConsumerState<FloorSinkScreen> createState() => _FloorSinkScreenState();
}

class _FloorSinkScreenState extends ConsumerState<FloorSinkScreen> {
  // Application type
  String _applicationType = 'kitchen';

  // Number of indirect connections
  int _indirectConnections = 3;

  // Has grease waste
  bool _hasGreaseWaste = true;

  // Sink size
  String _sinkSize = '12x12';

  static const Map<String, ({String desc, int drainSize, bool needsInterceptor})> _applicationTypes = {
    'kitchen': (desc: 'Commercial Kitchen', drainSize: 3, needsInterceptor: true),
    'bar': (desc: 'Bar/Beverage', drainSize: 2, needsInterceptor: false),
    'dishwasher': (desc: 'Dishwasher Area', drainSize: 2, needsInterceptor: true),
    'walk_in': (desc: 'Walk-In Cooler', drainSize: 2, needsInterceptor: false),
    'ice_machine': (desc: 'Ice Machine', drainSize: 2, needsInterceptor: false),
    'prep_area': (desc: 'Prep Area', drainSize: 2, needsInterceptor: true),
  };

  static const Map<String, ({int width, int depth, int drainMin})> _sinkSizes = {
    '8x8': (width: 8, depth: 8, drainMin: 2),
    '10x10': (width: 10, depth: 10, drainMin: 2),
    '12x12': (width: 12, depth: 12, drainMin: 3),
    '14x14': (width: 14, depth: 14, drainMin: 3),
    '18x18': (width: 18, depth: 18, drainMin: 3),
    '24x24': (width: 24, depth: 24, drainMin: 4),
  };

  int get _drainSize => _sinkSizes[_sinkSize]?.drainMin ?? 3;
  bool get _needsInterceptor => _applicationTypes[_applicationType]?.needsInterceptor ?? false;

  int get _minAirGap {
    // Air gap = 2× drain diameter minimum
    return _drainSize * 2;
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
          'Floor Sink',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          _buildSinkSizeCard(colors),
          const SizedBox(height: 16),
          _buildConnectionsCard(colors),
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
          const SizedBox(height: 16),
          if (_needsInterceptor && _hasGreaseWaste)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Grease Interceptor Required',
                    style: TextStyle(color: colors.accentWarning, fontSize: 13, fontWeight: FontWeight.w600),
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
                _buildResultRow(colors, 'Application', _applicationTypes[_applicationType]?.desc ?? 'Kitchen'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Sink Size', _sinkSize.replaceAll('x', '" × ') + '"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Air Gap', '$_minAirGap"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Indirect Connections', '$_indirectConnections fixtures'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ZaftoColors colors) {
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
            'APPLICATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._applicationTypes.entries.map((entry) {
            final isSelected = _applicationType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _applicationType = entry.key);
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
                      if (entry.value.needsInterceptor)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (colors.isDark ? Colors.black26 : Colors.white30)
                                : colors.accentWarning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Grease',
                            style: TextStyle(
                              color: isSelected
                                  ? (colors.isDark ? Colors.black54 : Colors.white70)
                                  : colors.accentWarning,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
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

  Widget _buildSinkSizeCard(ZaftoColors colors) {
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
            'SINK SIZE',
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
            children: _sinkSizes.entries.map((entry) {
              final isSelected = _sinkSize == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sinkSize = entry.key);
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
                        entry.key.replaceAll('x', '×'),
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${entry.value.drainMin}" drain',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 10,
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

  Widget _buildConnectionsCard(ZaftoColors colors) {
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
            'INDIRECT CONNECTIONS',
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
              Text('Number of Fixtures', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_indirectConnections',
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
              value: _indirectConnections.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _indirectConnections = v.round());
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleRow(colors, 'Grease Waste', 'Food prep, cooking equipment', _hasGreaseWaste, (v) => setState(() => _hasGreaseWaste = v)),
        ],
      ),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, String title, String subtitle, bool value, Function(bool) onChanged) {
    return GestureDetector(
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
            'INSTALLATION REQUIREMENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Drain Size', '$_drainSize" min'),
          _buildDimRow(colors, 'Air Gap', '$_minAirGap" min (2× drain)'),
          _buildDimRow(colors, 'Strainer', 'Required (removable)'),
          _buildDimRow(colors, 'Grate', 'NSF rated for location'),
          if (_needsInterceptor && _hasGreaseWaste) ...[
            Divider(color: colors.borderSubtle, height: 16),
            _buildDimRow(colors, 'Grease Interceptor', 'Required before sewer'),
            _buildDimRow(colors, 'Sampling Port', 'May be required'),
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
                'IPC 2024 Section 802',
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
            '• Indirect waste: Air gap = 2× drain dia\n'
            '• Floor sink vs floor drain distinction\n'
            '• Grease interceptor per local code\n'
            '• NSF 18 strainer requirement\n'
            '• Accessible for cleaning\n'
            '• No direct connection from fixtures',
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
