import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Kitchen Sink Rough-In Calculator - Design System v2.6
///
/// Determines kitchen sink drain, supply, and disposal rough-in dimensions.
/// Covers single, double bowl, and farmhouse sink installations.
///
/// References: IPC 2024 Section 405
class KitchenSinkRoughInScreen extends ConsumerStatefulWidget {
  const KitchenSinkRoughInScreen({super.key});
  @override
  ConsumerState<KitchenSinkRoughInScreen> createState() => _KitchenSinkRoughInScreenState();
}

class _KitchenSinkRoughInScreenState extends ConsumerState<KitchenSinkRoughInScreen> {
  // Sink type
  String _sinkType = 'double';

  // Counter height
  double _counterHeight = 36;

  // Sink width
  double _sinkWidth = 33;

  // Has garbage disposal
  bool _hasDisposal = true;

  // Has dishwasher
  bool _hasDishwasher = true;

  // Has instant hot
  bool _hasInstantHot = false;

  // Has RO system
  bool _hasRO = false;

  static const Map<String, ({String desc, int width, int drainSize})> _sinkTypes = {
    'single': (desc: 'Single Bowl', width: 25, drainSize: 2),
    'double': (desc: 'Double Bowl', width: 33, drainSize: 2),
    'triple': (desc: 'Triple Bowl', width: 42, drainSize: 2),
    'farmhouse': (desc: 'Farmhouse/Apron', width: 33, drainSize: 2),
    'undermount': (desc: 'Undermount', width: 30, drainSize: 2),
    'workstation': (desc: 'Workstation', width: 36, drainSize: 2),
  };

  int get _drainSize => _sinkTypes[_sinkType]?.drainSize ?? 2;

  int get _outletCount {
    int count = 1; // Main drain
    if (_hasDisposal) count++;
    if (_hasDishwasher) count++; // Air gap or high loop
    if (_hasInstantHot) count++;
    if (_hasRO) count += 2; // RO faucet + drain
    return count;
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
          'Kitchen Sink Rough-In',
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
          _buildDimensionsCard(colors),
          const SizedBox(height: 16),
          _buildAccessoriesCard(colors),
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
                _buildResultRow(colors, 'Sink Type', _sinkTypes[_sinkType]?.desc ?? 'Double'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Sink Width', '${_sinkWidth.toStringAsFixed(0)}"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Height', '18" from floor'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Height', '20-22" from floor'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Electrical Outlets', '$_outletCount under cabinet'),
                if (_hasDisposal)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _buildResultRow(colors, 'Disposal Circuit', 'Switched 15A or 20A'),
                  ),
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
                  setState(() {
                    _sinkType = entry.key;
                    _sinkWidth = entry.value.width.toDouble();
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
                        '~${entry.value.width}"',
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
            'DIMENSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildSlider(colors, 'Counter Height', _counterHeight, (v) => setState(() => _counterHeight = v), 34, 42),
          const SizedBox(height: 16),
          _buildSlider(colors, 'Sink Width', _sinkWidth, (v) => setState(() => _sinkWidth = v), 20, 48),
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

  Widget _buildAccessoriesCard(ZaftoColors colors) {
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
            'ACCESSORIES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleRow(colors, 'Garbage Disposal', 'Switched outlet, 15A or 20A', _hasDisposal, (v) => setState(() => _hasDisposal = v)),
          _buildToggleRow(colors, 'Dishwasher', 'Air gap or high loop drain', _hasDishwasher, (v) => setState(() => _hasDishwasher = v)),
          _buildToggleRow(colors, 'Instant Hot Water', '½ gallon tank, separate outlet', _hasInstantHot, (v) => setState(() => _hasInstantHot = v)),
          _buildToggleRow(colors, 'RO System', 'Faucet hole + drain connection', _hasRO, (v) => setState(() => _hasRO = v)),
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
          _buildDimRow(colors, 'Drain C/L Height', '18" from floor'),
          _buildDimRow(colors, 'Drain Size', '1½" (trap is 1½")'),
          _buildDimRow(colors, 'Drain Location', 'Center of cabinet'),
          _buildDimRow(colors, 'Supply Height', '20-22" from floor'),
          _buildDimRow(colors, 'Supply Spread', '8" apart typical'),
          _buildDimRow(colors, 'Hot Supply', 'Left side'),
          _buildDimRow(colors, 'Cold Supply', 'Right side'),
          _buildDimRow(colors, 'Dishwasher Drain', 'High loop or air gap'),
          if (_hasDisposal)
            _buildDimRow(colors, 'Disposal Outlet', 'Switched, 110V, 15-20A'),
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
            '• IPC 405: Kitchen sink waste 1½" min\n'
            '• Vent within 3½\' of trap (1½" drain)\n'
            '• Dishwasher: High loop or air gap required\n'
            '• Disposal: Switched outlet required\n'
            '• Hot on left, cold on right standard\n'
            '• P-trap must be accessible',
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
