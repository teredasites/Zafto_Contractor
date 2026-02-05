import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Static Pressure Calculator - Design System v2.6
///
/// Calculates water pressure from elevation differences.
/// Essential for multi-story buildings and pressure analysis.
///
/// References: IPC 2024 Section 604, basic hydraulics
class StaticPressureScreen extends ConsumerStatefulWidget {
  const StaticPressureScreen({super.key});
  @override
  ConsumerState<StaticPressureScreen> createState() => _StaticPressureScreenState();
}

class _StaticPressureScreenState extends ConsumerState<StaticPressureScreen> {
  // Calculation mode
  String _mode = 'elevation'; // 'elevation' or 'pressure'

  // Elevation difference (feet)
  double _elevation = 20;

  // Known pressure (PSI) - for calculating elevation
  double _pressure = 8.66;

  // Reference pressure at base (PSI)
  double _basePressure = 60;

  // Direction
  String _direction = 'up'; // 'up' (lose pressure) or 'down' (gain pressure)

  // Constants
  static const double _psiPerFoot = 0.433;
  static const double _feetPerPsi = 2.31;

  // Calculations
  double get _pressureChange => _elevation * _psiPerFoot;

  double get _resultPressure {
    if (_direction == 'up') {
      return _basePressure - _pressureChange;
    } else {
      return _basePressure + _pressureChange;
    }
  }

  double get _elevationFromPressure => _pressure * _feetPerPsi;

  String get _pressureStatus {
    if (_resultPressure < 15) return 'BELOW CODE MINIMUM';
    if (_resultPressure < 20) return 'Low - May need boost';
    if (_resultPressure > 80) return 'HIGH - PRV required';
    if (_resultPressure > 60) return 'Good pressure';
    return 'Adequate pressure';
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
          'Static Pressure Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModeSelector(colors),
          const SizedBox(height: 16),
          _buildResultCard(colors),
          const SizedBox(height: 16),
          if (_mode == 'elevation') ...[
            _buildDirectionCard(colors),
            const SizedBox(height: 16),
            _buildBasePressureCard(colors),
            const SizedBox(height: 16),
            _buildElevationCard(colors),
          ] else ...[
            _buildPressureInputCard(colors),
          ],
          const SizedBox(height: 16),
          _buildQuickReference(colors),
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
            'CALCULATION MODE',
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
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _mode = 'elevation');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _mode == 'elevation' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.arrowUpDown,
                          color: _mode == 'elevation'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Elevation → PSI',
                          style: TextStyle(
                            color: _mode == 'elevation'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _mode = 'pressure');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _mode == 'pressure' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.gauge,
                          color: _mode == 'pressure'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PSI → Elevation',
                          style: TextStyle(
                            color: _mode == 'pressure'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_mode == 'pressure') {
      return _buildElevationResultCard(colors);
    }

    final statusColor = _resultPressure < 15
        ? colors.accentError
        : _resultPressure > 80
            ? colors.accentWarning
            : colors.accentSuccess;

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
            '${_resultPressure.toStringAsFixed(1)} PSI',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Pressure at ${_direction == 'up' ? 'Top' : 'Bottom'}',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _pressureStatus,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
                _buildResultRow(colors, 'Base Pressure', '${_basePressure.toStringAsFixed(1)} PSI'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Elevation Change', '${_elevation.toStringAsFixed(1)} ft ${_direction == 'up' ? '↑' : '↓'}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pressure Change', '${_direction == 'up' ? '-' : '+'}${_pressureChange.toStringAsFixed(2)} PSI'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Final Pressure', '${_resultPressure.toStringAsFixed(1)} PSI', highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationResultCard(ZaftoColors colors) {
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
            '${_elevationFromPressure.toStringAsFixed(1)} ft',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Elevation (Head)',
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
                _buildResultRow(colors, 'Pressure', '${_pressure.toStringAsFixed(2)} PSI'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Conversion', '2.31 ft per PSI'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Elevation', '${_elevationFromPressure.toStringAsFixed(1)} feet', highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionCard(ZaftoColors colors) {
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
            'DIRECTION FROM BASE',
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
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _direction = 'up');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _direction == 'up' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.arrowUp,
                          color: _direction == 'up'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Up (Lose PSI)',
                          style: TextStyle(
                            color: _direction == 'up'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _direction = 'down');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _direction == 'down' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.arrowDown,
                          color: _direction == 'down'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Down (Gain PSI)',
                          style: TextStyle(
                            color: _direction == 'down'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasePressureCard(ZaftoColors colors) {
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
            'BASE PRESSURE (PSI)',
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
                '${_basePressure.toStringAsFixed(0)} PSI',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
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
                    value: _basePressure,
                    min: 20,
                    max: 100,
                    divisions: 80,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _basePressure = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Pressure at reference point (meter, ground floor)',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationCard(ZaftoColors colors) {
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
            'ELEVATION CHANGE (FEET)',
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
                '${_elevation.toStringAsFixed(0)} ft',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
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
                    value: _elevation,
                    min: 0,
                    max: 200,
                    divisions: 200,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _elevation = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Vertical distance from base reference',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureInputCard(ZaftoColors colors) {
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
            'PRESSURE (PSI)',
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
                '${_pressure.toStringAsFixed(2)} PSI',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
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
                    value: _pressure,
                    min: 0,
                    max: 100,
                    divisions: 200,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _pressure = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Convert PSI to equivalent feet of head',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReference(ZaftoColors colors) {
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
            'QUICK REFERENCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildRefRow(colors, '1 PSI', '2.31 feet of head'),
          _buildRefRow(colors, '1 foot', '0.433 PSI'),
          _buildRefRow(colors, '10 feet (1 story)', '4.33 PSI'),
          _buildRefRow(colors, '20 feet (2 stories)', '8.66 PSI'),
          _buildRefRow(colors, '30 feet (3 stories)', '12.99 PSI'),
          _buildRefRow(colors, '100 feet', '43.30 PSI'),
        ],
      ),
    );
  }

  Widget _buildRefRow(ZaftoColors colors, String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            '=',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
          ),
          Expanded(
            child: Text(
              right,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              textAlign: TextAlign.right,
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
                'IPC 2024 Section 604',
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
            '• Min fixture pressure: 15 PSI (8 for some)\n'
            '• Max static: 80 PSI (PRV required)\n'
            '• Water weighs 62.4 lb/cu ft\n'
            '• 1 cu ft = 7.48 gallons\n'
            '• Account for friction losses\n'
            '• Test gauge at meter for actual',
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
