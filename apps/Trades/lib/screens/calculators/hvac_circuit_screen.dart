import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// HVAC Circuit Calculator - Design System v2.6
/// A/C and heat pump circuit sizing per NEC 440
class HvacCircuitScreen extends ConsumerStatefulWidget {
  const HvacCircuitScreen({super.key});
  @override
  ConsumerState<HvacCircuitScreen> createState() => _HvacCircuitScreenState();
}

class _HvacCircuitScreenState extends ConsumerState<HvacCircuitScreen> {
  String _equipmentType = 'ac'; // ac, heat_pump, mini_split
  int _voltage = 240;
  int _phase = 1;
  double _rla = 15.0; // Rated Load Amps
  double _mca = 0; // Minimum Circuit Ampacity (if nameplate available)
  double _mopd = 0; // Maximum Overcurrent Protection (if nameplate available)
  bool _useNameplate = false;
  double _distanceFeet = 50;
  String _conductorMaterial = 'copper';

  // NEC 440.4(B) - Branch circuit sizing
  // MCA = 1.25 × RLA (or use nameplate MCA)
  double get _calculatedMCA => _useNameplate && _mca > 0 ? _mca : _rla * 1.25;

  // NEC 440.22 - OCPD sizing
  // Max OCPD = 2.25 × RLA (or use nameplate MOPD)
  double get _maxOCPD => _useNameplate && _mopd > 0 ? _mopd : _rla * 2.25;

  // Standard breaker sizes
  static const List<int> _standardBreakers = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200];

  int get _recommendedBreaker {
    final maxSize = _maxOCPD.ceil();
    // Find the standard size at or below max
    for (final size in _standardBreakers.reversed) {
      if (size <= maxSize) return size;
    }
    return _standardBreakers.first;
  }

  // Wire sizing based on MCA per NEC 310.16
  static const Map<int, Map<String, int>> _wireSizing = {
    15: {'copper': 14, 'aluminum': 12},
    20: {'copper': 12, 'aluminum': 10},
    25: {'copper': 10, 'aluminum': 8},
    30: {'copper': 10, 'aluminum': 8},
    35: {'copper': 8, 'aluminum': 6},
    40: {'copper': 8, 'aluminum': 6},
    45: {'copper': 6, 'aluminum': 4},
    50: {'copper': 6, 'aluminum': 4},
    55: {'copper': 6, 'aluminum': 4},
    60: {'copper': 6, 'aluminum': 4},
    65: {'copper': 4, 'aluminum': 2},
    70: {'copper': 4, 'aluminum': 2},
    80: {'copper': 3, 'aluminum': 1},
    90: {'copper': 2, 'aluminum': 0},
    100: {'copper': 1, 'aluminum': -1}, // -1 = 2/0
    110: {'copper': 0, 'aluminum': -2}, // -2 = 3/0
    125: {'copper': 0, 'aluminum': -2},
    150: {'copper': -1, 'aluminum': -3}, // -3 = 4/0
  };

  String _getWireSize(int amps) {
    int key = 15;
    for (final k in _wireSizing.keys) {
      if (amps >= k) key = k;
    }
    final size = _wireSizing[key]?[_conductorMaterial] ?? 10;
    if (size > 0) return '$size AWG';
    if (size == 0) return '1/0 AWG';
    if (size == -1) return '2/0 AWG';
    if (size == -2) return '3/0 AWG';
    return '4/0 AWG';
  }

  String get _wireSize => _getWireSize(_calculatedMCA.ceil());

  // Voltage drop calculation
  double get _voltageDrop {
    // Simplified voltage drop calculation
    // VD = (2 × K × I × L) / CM
    // K = 12.9 for copper, 21.2 for aluminum
    final k = _conductorMaterial == 'copper' ? 12.9 : 21.2;

    // Get circular mils for wire size
    final amps = _calculatedMCA.ceil();
    int key = 15;
    for (final k in _wireSizing.keys) {
      if (amps >= k) key = k;
    }
    final wireNum = _wireSizing[key]?[_conductorMaterial] ?? 10;

    // Circular mils by AWG
    final cmMap = <int, int>{
      14: 4110, 12: 6530, 10: 10380, 8: 16510, 6: 26240, 4: 41740,
      3: 52620, 2: 66360, 1: 83690, 0: 105600, -1: 133100, -2: 167800, -3: 211600,
    };
    final cm = cmMap[wireNum] ?? 10380;

    final vd = (2 * k * _calculatedMCA * _distanceFeet) / cm;
    return (vd / _voltage) * 100;
  }

  String get _voltageDropStatus {
    if (_voltageDrop <= 3) return 'Good';
    if (_voltageDrop <= 5) return 'Acceptable';
    return 'Excessive - upsize wire';
  }

  // Disconnect sizing per NEC 440.14
  int get _disconnectSize {
    final minSize = _rla * 1.15;
    for (final size in [30, 60, 100, 200]) {
      if (size >= minSize) return size;
    }
    return 200;
  }

  // Equipment type labels
  static const Map<String, String> _equipmentLabels = {
    'ac': 'Central A/C',
    'heat_pump': 'Heat Pump',
    'mini_split': 'Mini Split',
  };

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
        title: Text('HVAC Circuit', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEquipmentCard(colors),
          const SizedBox(height: 16),
          _buildVoltageCard(colors),
          const SizedBox(height: 16),
          _buildNameplateCard(colors),
          const SizedBox(height: 16),
          _buildDistanceCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildBreakdownCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EQUIPMENT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipmentLabels.entries.map((e) {
              final isSelected = _equipmentType == e.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _equipmentType = e.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.value,
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

  Widget _buildVoltageCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VOLTAGE / PHASE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'v': 120, 'p': 1, 'label': '120V 1Ø'},
              {'v': 208, 'p': 1, 'label': '208V 1Ø'},
              {'v': 240, 'p': 1, 'label': '240V 1Ø'},
              {'v': 208, 'p': 3, 'label': '208V 3Ø'},
              {'v': 480, 'p': 3, 'label': '480V 3Ø'},
            ].map((config) {
              final isSelected = _voltage == config['v'] && _phase == config['p'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _voltage = config['v'] as int;
                    _phase = config['p'] as int;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    config['label'] as String,
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

  Widget _buildNameplateCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('USE NAMEPLATE VALUES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              Switch(
                value: _useNameplate,
                onChanged: (v) => setState(() => _useNameplate = v),
                activeColor: colors.accentPrimary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('RLA (Rated Load Amps)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _rla,
                  min: 5,
                  max: 100,
                  divisions: 95,
                  activeColor: colors.accentPrimary,
                  inactiveColor: colors.bgBase,
                  onChanged: (v) => setState(() => _rla = v),
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _rla.toStringAsFixed(1),
                  style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (_useNameplate) ...[
            const SizedBox(height: 16),
            Text('MCA (Min Circuit Ampacity)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _mca,
                    min: 0,
                    max: 150,
                    divisions: 150,
                    activeColor: colors.accentPrimary,
                    inactiveColor: colors.bgBase,
                    onChanged: (v) => setState(() => _mca = v),
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _mca > 0 ? _mca.toStringAsFixed(0) : '--',
                    style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('MOPD (Max OCPD)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _mopd,
                    min: 0,
                    max: 200,
                    divisions: 40,
                    activeColor: colors.accentPrimary,
                    inactiveColor: colors.bgBase,
                    onChanged: (v) => setState(() => _mopd = v),
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _mopd > 0 ? _mopd.toStringAsFixed(0) : '--',
                    style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDistanceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ONE-WAY DISTANCE (feet)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _distanceFeet,
                  min: 10,
                  max: 300,
                  divisions: 58,
                  activeColor: colors.accentPrimary,
                  inactiveColor: colors.bgBase,
                  onChanged: (v) => setState(() => _distanceFeet = v),
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _distanceFeet.toStringAsFixed(0),
                  style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONDUCTOR MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMaterialOption(colors, 'copper', 'Copper')),
              const SizedBox(width: 12),
              Expanded(child: _buildMaterialOption(colors, 'aluminum', 'Aluminum')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialOption(ZaftoColors colors, String value, String label) {
    final isSelected = _conductorMaterial == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _conductorMaterial = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final vdOK = _voltageDrop <= 5;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('WIRE SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      _wireSize,
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(_conductorMaterial == 'copper' ? 'Copper' : 'Aluminum', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: colors.borderSubtle),
              Expanded(
                child: Column(
                  children: [
                    Text('BREAKER', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${_recommendedBreaker}A',
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('2-pole', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: vdOK ? colors.bgBase : const Color(0xFFE53935).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Voltage Drop', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                Row(
                  children: [
                    Text(
                      '${_voltageDrop.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: vdOK ? colors.accentPrimary : const Color(0xFFE53935),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vdOK ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE53935).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _voltageDropStatus,
                        style: TextStyle(
                          color: vdOK ? Colors.green : const Color(0xFFE53935),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CALCULATION BREAKDOWN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildCalcRow(colors, 'RLA (nameplate)', '${_rla.toStringAsFixed(1)} A', false),
          const SizedBox(height: 8),
          _buildCalcRow(colors, 'MCA (${_useNameplate && _mca > 0 ? "nameplate" : "1.25 × RLA"})', '${_calculatedMCA.toStringAsFixed(1)} A', true),
          const SizedBox(height: 8),
          _buildCalcRow(colors, 'Max OCPD (${_useNameplate && _mopd > 0 ? "nameplate" : "2.25 × RLA"})', '${_maxOCPD.toStringAsFixed(1)} A', false),
          const SizedBox(height: 8),
          _buildCalcRow(colors, 'Recommended Breaker', '${_recommendedBreaker}A', true),
          const SizedBox(height: 8),
          _buildCalcRow(colors, 'Min Disconnect', '${_disconnectSize}A', false),
        ],
      ),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, bool highlight) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('NEC CODE REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'NEC 440.4(B) - Branch circuit conductors sized for MCA from nameplate, or 125% of RLA.\n\n'
            'NEC 440.22 - Branch circuit OCPD shall not exceed MOPD on nameplate, or 225% of RLA.\n\n'
            'NEC 440.14 - Disconnect must be rated at least 115% of RLA.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
