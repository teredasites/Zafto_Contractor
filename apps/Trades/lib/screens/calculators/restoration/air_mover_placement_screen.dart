import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Air Mover Placement Calculator — IICRC S500
///
/// Calculates optimal air mover quantity, position angles, and placement
/// pattern based on room dimensions, water damage class, and surface types.
///
/// References: IICRC S500-2021 Section 12.3 (Evaporation), RIA Best Practices
class AirMoverPlacementScreen extends ConsumerStatefulWidget {
  const AirMoverPlacementScreen({super.key});
  @override
  ConsumerState<AirMoverPlacementScreen> createState() => _AirMoverPlacementScreenState();
}

class _AirMoverPlacementScreenState extends ConsumerState<AirMoverPlacementScreen> {
  double _roomLength = 20;
  double _roomWidth = 15;
  double _ceilingHeight = 8;
  int _damageClass = 2; // 1-4
  String _wallConfig = 'perimeter'; // perimeter, parallel, focus
  bool _hasWetCeiling = false;
  bool _hasCabinetry = false;
  bool _hasHardwood = false;

  double get _sqft => _roomLength * _roomWidth;
  double get _volume => _sqft * _ceilingHeight;
  double get _perimeterLF => 2 * (_roomLength + _roomWidth);

  /// IICRC S500: Air movers per linear foot of wall
  /// Class 1: 1 per 50 sqft (minimal evap needed)
  /// Class 2: 1 per 10-16 LF of affected wall
  /// Class 3: 1 per 7 LF of affected wall (floor + walls to 24")
  /// Class 4: Specialty placement — focused drying positions
  int get _airMoverCount {
    double base;
    switch (_damageClass) {
      case 1:
        base = _sqft / 100;
        break;
      case 2:
        base = _perimeterLF / 13; // midpoint of 10-16 LF range
        break;
      case 3:
        base = _perimeterLF / 7;
        break;
      case 4:
        base = _sqft / 40; // focused positions on specialty materials
        break;
      default:
        base = _perimeterLF / 13;
    }

    // Adjustments for conditions
    if (_hasWetCeiling) base += (_sqft / 200); // extra movers aimed at ceiling
    if (_hasCabinetry) base += 2; // toe-kicks and interior cabinet drying
    if (_hasHardwood) base += (_sqft / 150); // dense material needs more airflow

    return math.max(2, base.ceil());
  }

  /// CFM needed for adequate air exchange
  /// IICRC target: 4-6 air changes per hour for drying
  double get _targetCFM {
    final acph = _damageClass >= 3 ? 6.0 : 4.0;
    return (_volume * acph) / 60;
  }

  /// Recommended placement angle
  String get _placementAngle {
    return switch (_damageClass) {
      1 => '45° at wall junction — direct airflow along baseboard',
      2 => '45° angle toward walls — create vortex pattern',
      3 => '15-20° aimed at floor — maximize surface evaporation',
      4 => 'Direct aim at wet materials — cavity drying focus',
      _ => '45° standard angle',
    };
  }

  String get _placementPattern {
    return switch (_wallConfig) {
      'perimeter' => 'Place movers every ${(_perimeterLF / _airMoverCount).toStringAsFixed(1)} LF around perimeter walls. Angle at 45° to create circular airflow pattern.',
      'parallel' => 'Align movers in parallel rows across the room. Space ${(_roomWidth / (_airMoverCount / 2).ceil()).toStringAsFixed(1)} ft apart.',
      'focus' => 'Concentrate movers on the most saturated area. Stack airflow toward dehumidifier intake.',
      _ => 'Standard perimeter placement.',
    };
  }

  /// Estimated drying setup time
  int get _setupMinutes => _airMoverCount * 3 + 15; // ~3 min each + travel/staging

  void _reset() {
    setState(() {
      _roomLength = 20;
      _roomWidth = 15;
      _ceilingHeight = 8;
      _damageClass = 2;
      _wallConfig = 'perimeter';
      _hasWetCeiling = false;
      _hasCabinetry = false;
      _hasHardwood = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Air Mover Placement', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(colors, 'Room Dimensions'),
              _sliderRow(colors, 'Length', _roomLength, 5, 100, 'ft', (v) => setState(() => _roomLength = v)),
              _sliderRow(colors, 'Width', _roomWidth, 5, 80, 'ft', (v) => setState(() => _roomWidth = v)),
              _sliderRow(colors, 'Ceiling', _ceilingHeight, 7, 20, 'ft', (v) => setState(() => _ceilingHeight = v)),
              const SizedBox(height: 16),
              _sectionLabel(colors, 'IICRC Water Damage Class'),
              _classSelector(colors),
              const SizedBox(height: 16),
              _sectionLabel(colors, 'Placement Strategy'),
              _strategySelector(colors),
              const SizedBox(height: 16),
              _sectionLabel(colors, 'Conditions'),
              _checkRow(colors, 'Wet ceiling', _hasWetCeiling, (v) => setState(() => _hasWetCeiling = v)),
              _checkRow(colors, 'Cabinetry present', _hasCabinetry, (v) => setState(() => _hasCabinetry = v)),
              _checkRow(colors, 'Hardwood flooring', _hasHardwood, (v) => setState(() => _hasHardwood = v)),
              const SizedBox(height: 24),
              _resultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary, letterSpacing: 0.5)),
    );
  }

  Widget _sliderRow(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 60, child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        Expanded(child: Slider(value: value, min: min, max: max, divisions: ((max - min) * 2).round(), onChanged: onChanged, activeColor: colors.accentPrimary)),
        SizedBox(width: 60, child: Text('${value.toStringAsFixed(1)} $unit', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _classSelector(ZaftoColors colors) {
    final classes = {1: 'Class 1 — Least damage', 2: 'Class 2 — Significant', 3: 'Class 3 — Greatest', 4: 'Class 4 — Specialty'};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: classes.entries.map((e) {
        final selected = _damageClass == e.key;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _damageClass = e.key); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary)),
          ),
        );
      }).toList(),
    );
  }

  Widget _strategySelector(ZaftoColors colors) {
    final strategies = {'perimeter': 'Perimeter', 'parallel': 'Parallel Rows', 'focus': 'Focused Area'};
    return Row(
      children: strategies.entries.map((e) {
        final selected = _wallConfig == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _wallConfig = e.key); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.fillDefault,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _checkRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), activeColor: colors.accentPrimary, side: BorderSide(color: colors.borderSubtle)),
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      ]),
    );
  }

  Widget _resultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLACEMENT PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.accentPrimary, letterSpacing: 1)),
          const SizedBox(height: 12),
          _resultRow(colors, 'Air Movers Needed', '$_airMoverCount units'),
          _resultRow(colors, 'Target CFM', '${_targetCFM.toStringAsFixed(0)} CFM'),
          _resultRow(colors, 'Room Area', '${_sqft.toStringAsFixed(0)} sq ft'),
          _resultRow(colors, 'Room Volume', '${_volume.toStringAsFixed(0)} cu ft'),
          _resultRow(colors, 'Perimeter', '${_perimeterLF.toStringAsFixed(0)} LF'),
          _resultRow(colors, 'Setup Time', '~$_setupMinutes min'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Angle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentInfo)),
                const SizedBox(height: 4),
                Text(_placementAngle, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
                const SizedBox(height: 8),
                Text('Pattern', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentInfo)),
                const SizedBox(height: 4),
                Text(_placementPattern, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
