import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Shower Rough-In Calculator - Design System v2.6
///
/// Determines shower valve, drain, and fixture rough-in dimensions.
/// Ensures proper installation per code requirements.
///
/// References: IPC 2024 Section 408, ADA Standards
class ShowerRoughInScreen extends ConsumerStatefulWidget {
  const ShowerRoughInScreen({super.key});
  @override
  ConsumerState<ShowerRoughInScreen> createState() => _ShowerRoughInScreenState();
}

class _ShowerRoughInScreenState extends ConsumerState<ShowerRoughInScreen> {
  // Shower type
  String _showerType = 'standard';

  // Valve height from floor
  double _valveHeight = 48;

  // Shower head height from floor
  double _headHeight = 80;

  // Threshold height (for curb showers)
  double _thresholdHeight = 4;

  // ADA/Barrier-free
  bool _adaRequired = false;

  // Dimensions
  double _showerWidth = 36;
  double _showerDepth = 36;

  static const Map<String, ({String desc, int minWidth, int minDepth, int drain})> _showerTypes = {
    'standard': (desc: 'Standard Stall', minWidth: 30, minDepth: 30, drain: 2),
    'neo_angle': (desc: 'Neo-Angle', minWidth: 36, minDepth: 36, drain: 2),
    'walk_in': (desc: 'Walk-In (Barrier Free)', minWidth: 36, minDepth: 36, drain: 2),
    'tub_shower': (desc: 'Tub/Shower Combo', minWidth: 30, minDepth: 60, drain: 2),
    'custom': (desc: 'Custom Size', minWidth: 32, minDepth: 32, drain: 2),
  };

  // Code requirements
  static const int _minValveHeight = 38; // Typical min
  static const int _maxValveHeight = 48; // Typical max
  static const int _adaValveHeight = 48; // Max for ADA
  static const int _minHeadHeight = 72; // Min shower head
  static const int _adaMinWidth = 36; // ADA min
  static const int _adaMinDepth = 36; // ADA min
  static const int _standardMinWidth = 30; // Code min
  static const int _standardMinDepth = 30; // Code min

  int get _drainSize => _showerTypes[_showerType]?.drain ?? 2;

  bool get _widthMeetsCode {
    final min = _adaRequired ? _adaMinWidth : _standardMinWidth;
    return _showerWidth >= min;
  }

  bool get _depthMeetsCode {
    final min = _adaRequired ? _adaMinDepth : _standardMinDepth;
    return _showerDepth >= min;
  }

  bool get _valveMeetsCode {
    if (_adaRequired) {
      return _valveHeight <= _adaValveHeight && _valveHeight >= 38;
    }
    return _valveHeight >= _minValveHeight && _valveHeight <= 52;
  }

  bool get _allMeetsCode => _widthMeetsCode && _depthMeetsCode && _valveMeetsCode;

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
          'Shower Rough-In',
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
          _buildShowerTypeCard(colors),
          const SizedBox(height: 16),
          _buildDimensionsCard(colors),
          const SizedBox(height: 16),
          _buildValveCard(colors),
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
    final statusColor = _allMeetsCode ? colors.accentSuccess : colors.accentError;

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
                  _allMeetsCode ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _allMeetsCode ? 'Dimensions Meet Code' : 'Check Dimensions',
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
                _buildResultRow(colors, 'Shower Size', '${_showerWidth.toStringAsFixed(0)}" × ${_showerDepth.toStringAsFixed(0)}"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Valve Height', '${_valveHeight.toStringAsFixed(0)}" from floor'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Head Height', '${_headHeight.toStringAsFixed(0)}" from floor'),
                if (_showerType != 'walk_in') ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Threshold', '${_thresholdHeight.toStringAsFixed(0)}"'),
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
              _showerType = 'walk_in';
              _showerWidth = 36;
              _showerDepth = 36;
              _thresholdHeight = 0;
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
                    'ADA/Barrier-Free',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Zero threshold, 36" × 36" min, grab bars required',
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

  Widget _buildShowerTypeCard(ZaftoColors colors) {
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
            'SHOWER TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._showerTypes.entries.map((entry) {
            final isSelected = _showerType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showerType = entry.key;
                    if (entry.key == 'walk_in') {
                      _thresholdHeight = 0;
                    }
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
                        'Min ${entry.value.minWidth}" × ${entry.value.minDepth}"',
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
            'SHOWER DIMENSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildSlider(colors, 'Width', _showerWidth, (v) => setState(() => _showerWidth = v), 24, 72, !_widthMeetsCode),
          const SizedBox(height: 16),
          _buildSlider(colors, 'Depth', _showerDepth, (v) => setState(() => _showerDepth = v), 24, 72, !_depthMeetsCode),
          if (_showerType != 'walk_in') ...[
            const SizedBox(height: 16),
            _buildSlider(colors, 'Threshold Height', _thresholdHeight, (v) => setState(() => _thresholdHeight = v), 0, 9, false),
          ],
        ],
      ),
    );
  }

  Widget _buildValveCard(ZaftoColors colors) {
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
            'VALVE & HEAD HEIGHTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildSlider(colors, 'Valve Height', _valveHeight, (v) => setState(() => _valveHeight = v), 36, 52, !_valveMeetsCode),
          const SizedBox(height: 16),
          _buildSlider(colors, 'Shower Head Height', _headHeight, (v) => setState(() => _headHeight = v), 72, 96, false),
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
          _buildDimRow(colors, 'Drain Location', 'Center of shower pan'),
          _buildDimRow(colors, 'Drain Size', '2" (code minimum)'),
          _buildDimRow(colors, 'Trap Size', '2" P-trap'),
          _buildDimRow(colors, 'Valve Rough', '38-48" from floor'),
          _buildDimRow(colors, 'Mixing Valve', 'ASSE 1016 required'),
          _buildDimRow(colors, 'Supply Pipes', '1/2" hot & cold'),
          _buildDimRow(colors, 'Head Outlet', '72-80" typical'),
          if (_adaRequired) ...[
            _buildDimRow(colors, 'Grab Bar', '33-36" from floor'),
            _buildDimRow(colors, 'Seat Height', '17-19" from floor'),
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
                'IPC 2024 Section 408',
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
            '• IPC 408.6: 900 sq in min floor area (30" × 30")\n'
            '• 2" min drain required\n'
            '• ASSE 1016 anti-scald valve required\n'
            '• ADA: 36" × 36" min transfer shower\n'
            '• ADA: 30" × 60" min roll-in shower\n'
            '• Threshold max 1/2" for barrier-free',
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
