import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Lavatory (Bathroom Sink) Rough-In Calculator - Design System v2.6
///
/// Determines bathroom sink drain, supply, and mounting dimensions.
/// Covers undermount, vessel, pedestal, and wall-mount installations.
///
/// References: IPC 2024 Section 405, ADA Standards
class LavatoryRoughInScreen extends ConsumerStatefulWidget {
  const LavatoryRoughInScreen({super.key});
  @override
  ConsumerState<LavatoryRoughInScreen> createState() => _LavatoryRoughInScreenState();
}

class _LavatoryRoughInScreenState extends ConsumerState<LavatoryRoughInScreen> {
  // Sink type
  String _sinkType = 'vanity';

  // Counter height (from floor)
  double _counterHeight = 36;

  // Sink width
  double _sinkWidth = 20;

  // ADA compliant
  bool _adaRequired = false;

  static const Map<String, ({String desc, int drainHeight, bool needsCounter})> _sinkTypes = {
    'vanity': (desc: 'Vanity/Undermount', drainHeight: 18, needsCounter: true),
    'vessel': (desc: 'Vessel Sink', drainHeight: 24, needsCounter: true),
    'pedestal': (desc: 'Pedestal Sink', drainHeight: 18, needsCounter: false),
    'wall_mount': (desc: 'Wall-Mount', drainHeight: 22, needsCounter: false),
    'console': (desc: 'Console Table', drainHeight: 18, needsCounter: true),
  };

  // Standard heights
  static const int _standardDrainHeight = 18; // From floor to drain center
  static const int _adaDrainHeight = 27; // ADA max
  static const int _standardSupplyHeight = 22; // Supply valves
  static const int _adaMaxRimHeight = 34; // ADA max rim height
  static const int _adaKneeSpace = 27; // ADA knee clearance

  int get _drainCenterHeight {
    if (_adaRequired) {
      return _adaDrainHeight;
    }
    return _sinkTypes[_sinkType]?.drainHeight ?? _standardDrainHeight;
  }

  int get _supplyHeight {
    if (_adaRequired) return 24;
    if (_sinkType == 'vessel') return 26;
    return _standardSupplyHeight;
  }

  double get _rimHeight {
    if (_sinkType == 'vessel') {
      return _counterHeight + 5; // Vessel sits on top
    }
    return _counterHeight;
  }

  bool get _rimMeetsAda => !_adaRequired || _rimHeight <= _adaMaxRimHeight;

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
          'Lavatory Rough-In',
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
          _buildSinkTypeCard(colors),
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
    final allMeetsCode = _rimMeetsAda;
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
            '1¼"',
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
                    allMeetsCode ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allMeetsCode ? 'ADA Compliant' : 'Rim Too High for ADA',
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
                _buildResultRow(colors, 'Sink Type', _sinkTypes[_sinkType]?.desc ?? 'Vanity'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Height', '$_drainCenterHeight" from floor'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Height', '$_supplyHeight" from floor'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Rim Height', '${_rimHeight.toStringAsFixed(0)}"'),
                if (_adaRequired) ...[
                  Divider(color: colors.borderSubtle, height: 20),
                  _buildResultRow(colors, 'Knee Clearance', '27" min required'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Insulation', 'Required on pipes'),
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
              _counterHeight = 34;
              _sinkType = 'wall_mount';
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
                    '34" max rim height, 27" knee clearance, insulated pipes',
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
                        'Drain @ ${entry.value.drainHeight}"',
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
    final needsCounter = _sinkTypes[_sinkType]?.needsCounter ?? true;

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
          if (needsCounter) ...[
            _buildSlider(
              colors,
              'Counter/Rim Height',
              _counterHeight,
              (v) => setState(() => _counterHeight = v),
              30,
              40,
              _adaRequired && !_rimMeetsAda,
            ),
            const SizedBox(height: 16),
          ],
          _buildSlider(colors, 'Sink Width', _sinkWidth, (v) => setState(() => _sinkWidth = v), 14, 30, false),
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
          _buildDimRow(colors, 'Drain C/L Height', '18" (standard), 27" max (ADA)'),
          _buildDimRow(colors, 'Drain Size', '1¼" (bathroom lav)'),
          _buildDimRow(colors, 'Trap Size', '1¼" P-trap'),
          _buildDimRow(colors, 'Supply Height', '20-22" from floor'),
          _buildDimRow(colors, 'Supply Spread', '8" (widespread), 4" (centerset)'),
          _buildDimRow(colors, 'Supply Size', '½" or ⅜" compression'),
          _buildDimRow(colors, 'Hot Supply', 'Left side'),
          _buildDimRow(colors, 'Cold Supply', 'Right side'),
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
            '• IPC 405: Lavatory waste 1¼" min\n'
            '• 21" min clearance in front\n'
            '• ADA: 34" max rim height\n'
            '• ADA: 27" min knee clearance\n'
            '• ADA: 8" knee depth at 27"\n'
            '• Insulate pipes for ADA lavatories',
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
