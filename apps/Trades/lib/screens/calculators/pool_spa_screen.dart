import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Pool/Spa Wiring Calculator - Design System v2.6
/// Requirements per NEC 680
class PoolSpaScreen extends ConsumerStatefulWidget {
  const PoolSpaScreen({super.key});
  @override
  ConsumerState<PoolSpaScreen> createState() => _PoolSpaScreenState();
}

class _PoolSpaScreenState extends ConsumerState<PoolSpaScreen> {
  String _installationType = 'inground'; // inground, above_ground, spa, hot_tub
  bool _hasPumpMotor = true;
  bool _hasLighting = true;
  bool _hasHeater = false;
  double _pumpHp = 1.5;
  double _heaterKw = 0;
  int _lightCount = 2;
  int _lightWatts = 300;
  bool _lowVoltage = false;
  bool _hasGFCI = true;

  // NEC 680 bonding requirements
  static const Map<String, List<String>> _bondingRequirements = {
    'inground': [
      'All metal parts within 5 ft of water',
      'Metal parts of pool structure',
      'Metal fittings within/attached to pool',
      'Metal covers/enclosures',
      'Metal conduit and equipment',
      'Underwater lighting fixtures',
      'Motor frame (pump, filter)',
      'Metal deck/coping within 3 ft',
    ],
    'above_ground': [
      'Metal parts in contact with water',
      'Metal pool wall',
      'Metal fittings and accessories',
      'Pump motor frame',
      'Metal parts within 5 ft',
    ],
    'spa': [
      'All metal fittings in/on spa',
      'Metal parts within 5 ft',
      'Pump motor frame',
      'Control panel enclosure',
      'Heater frame (if metal)',
    ],
    'hot_tub': [
      'Metal parts within 5 ft',
      'Equipment frame and motor',
      'Metal fittings',
      'Control housing',
    ],
  };

  // GFCI requirements per NEC 680.22 & 680.44
  static const Map<String, String> _gfciRequirements = {
    'pump_motor': 'Pump motor receptacle - GFCI required',
    'lighting': 'Underwater lighting - GFCI required (all voltages)',
    'receptacles': 'Receptacles 6-20 ft from water edge - GFCI required',
    'heater': 'Electric heater circuit - GFCI required per 680.27(C)',
    'spa_equipment': 'All spa equipment - GFCI required',
  };

  // Distance requirements per NEC 680.22(A)
  static const Map<String, int> _distanceRequirements = {
    'receptacle_min': 6, // feet from water
    'receptacle_max': 20, // feet from water (at least one required)
    'luminaire_min': 12, // feet above water (indoor)
    'luminaire_outdoor': 5, // feet from water edge
    'switching_device': 5, // feet from water
    'overhead_wiring': 22, // feet above water (10-50kV)
    'underground_wiring': 5, // feet from pool (unless direct burial)
  };

  // Motor FLA estimates (typical pool pumps)
  static final Map<double, double> _pumpMotorFLA = {
    0.5: 5.8,
    0.75: 6.9,
    1.0: 8.0,
    1.5: 10.0,
    2.0: 12.0,
    2.5: 15.0,
    3.0: 17.0,
  };

  double get _pumpFLA => _pumpMotorFLA[_pumpHp] ?? _pumpHp * 8;

  // Calculate pump circuit
  double get _pumpMCA => _pumpFLA * 1.25;

  int get _pumpBreaker {
    final maxOCPD = _pumpFLA * 2.25;
    if (maxOCPD <= 15) return 15;
    if (maxOCPD <= 20) return 20;
    if (maxOCPD <= 25) return 25;
    if (maxOCPD <= 30) return 30;
    return 40;
  }

  String get _pumpWireSize {
    final amps = _pumpMCA;
    if (amps <= 15) return '14 AWG';
    if (amps <= 20) return '12 AWG';
    if (amps <= 30) return '10 AWG';
    return '8 AWG';
  }

  // Lighting circuit
  double get _lightingLoad => _lightCount * _lightWatts.toDouble();

  String get _lightingVoltage => _lowVoltage ? '12V' : '120V';

  String get _lightingNote => _lowVoltage
      ? 'Low voltage - transformer required (NEC 680.23(A)(2))'
      : 'Line voltage - listed for wet location required';

  // Heater circuit
  double get _heaterAmps => _heaterKw > 0 ? (_heaterKw * 1000) / 240 : 0;

  int get _heaterBreaker {
    final amps = _heaterAmps * 1.25;
    if (amps <= 20) return 20;
    if (amps <= 30) return 30;
    if (amps <= 40) return 40;
    if (amps <= 50) return 50;
    return 60;
  }

  String get _heaterWireSize {
    final amps = _heaterAmps * 1.25;
    if (amps <= 20) return '12 AWG';
    if (amps <= 30) return '10 AWG';
    if (amps <= 40) return '8 AWG';
    if (amps <= 55) return '6 AWG';
    return '4 AWG';
  }

  // Total load
  double get _totalLoad {
    double total = 0;
    if (_hasPumpMotor) total += _pumpFLA * 240 / 1000; // kVA
    if (_hasLighting) total += _lightingLoad / 1000; // kW
    if (_hasHeater && _heaterKw > 0) total += _heaterKw;
    return total;
  }

  // Bonding conductor size per NEC 680.26(B)
  String get _bondingConductorSize {
    // For most residential pools: 8 AWG solid copper minimum
    // Larger commercial: sized per 250.122
    if (_totalLoad > 10) return '6 AWG solid copper';
    return '8 AWG solid copper';
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
        title: Text('Pool/Spa Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInstallationCard(colors),
          const SizedBox(height: 16),
          _buildEquipmentCard(colors),
          const SizedBox(height: 16),
          if (_hasPumpMotor) _buildPumpCard(colors),
          if (_hasPumpMotor) const SizedBox(height: 16),
          if (_hasLighting) _buildLightingCard(colors),
          if (_hasLighting) const SizedBox(height: 16),
          if (_hasHeater) _buildHeaterCard(colors),
          if (_hasHeater) const SizedBox(height: 16),
          _buildCircuitSummaryCard(colors),
          const SizedBox(height: 16),
          _buildBondingCard(colors),
          const SizedBox(height: 16),
          _buildDistancesCard(colors),
          const SizedBox(height: 16),
          _buildGFCICard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildInstallationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INSTALLATION TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'key': 'inground', 'label': 'In-Ground Pool'},
              {'key': 'above_ground', 'label': 'Above-Ground'},
              {'key': 'spa', 'label': 'Spa'},
              {'key': 'hot_tub', 'label': 'Hot Tub'},
            ].map((type) {
              final isSelected = _installationType == type['key'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _installationType = type['key']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type['label']!,
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

  Widget _buildEquipmentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EQUIPMENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildEquipmentToggle(colors, 'Pump Motor', _hasPumpMotor, (v) => setState(() => _hasPumpMotor = v)),
          const SizedBox(height: 8),
          _buildEquipmentToggle(colors, 'Underwater Lighting', _hasLighting, (v) => setState(() => _hasLighting = v)),
          const SizedBox(height: 8),
          _buildEquipmentToggle(colors, 'Electric Heater', _hasHeater, (v) => setState(() => _hasHeater = v)),
        ],
      ),
    );
  }

  Widget _buildEquipmentToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: colors.accentPrimary,
        ),
      ],
    );
  }

  Widget _buildPumpCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PUMP MOTOR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text('Horsepower', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0].map((hp) {
              final isSelected = _pumpHp == hp;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pumpHp = hp);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${hp} HP',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildInfoRow(colors, 'FLA (estimated)', '${_pumpFLA.toStringAsFixed(1)}A'),
                const SizedBox(height: 4),
                _buildInfoRow(colors, 'MCA', '${_pumpMCA.toStringAsFixed(1)}A'),
                const SizedBox(height: 4),
                _buildInfoRow(colors, 'Wire Size', _pumpWireSize),
                const SizedBox(height: 4),
                _buildInfoRow(colors, 'Breaker', '${_pumpBreaker}A 2-pole'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightingCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UNDERWATER LIGHTING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              Row(
                children: [
                  Text('Low Voltage', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _lowVoltage,
                    onChanged: (v) => setState(() => _lowVoltage = v),
                    activeColor: colors.accentPrimary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Number of Lights', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [1, 2, 3, 4, 6].map((count) {
              final isSelected = _lightCount == count;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _lightCount = count);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
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
          const SizedBox(height: 12),
          Text('Watts per Light', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [100, 200, 300, 400, 500].map((watts) {
              final isSelected = _lightWatts == watts;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _lightWatts = watts);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${watts}W',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildInfoRow(colors, 'Total Load', '${_lightingLoad.toStringAsFixed(0)}W'),
                const SizedBox(height: 4),
                _buildInfoRow(colors, 'Voltage', _lightingVoltage),
                const SizedBox(height: 8),
                Text(_lightingNote, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaterCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ELECTRIC HEATER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text('Heater Size (kW)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5.5, 11.0, 15.0, 18.0, 24.0, 36.0].map((kw) {
              final isSelected = _heaterKw == kw;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _heaterKw = kw);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${kw.toStringAsFixed(kw == kw.toInt() ? 0 : 1)} kW',
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
          if (_heaterKw > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildInfoRow(colors, 'Amps (240V)', '${_heaterAmps.toStringAsFixed(1)}A'),
                  const SizedBox(height: 4),
                  _buildInfoRow(colors, 'Wire Size', _heaterWireSize),
                  const SizedBox(height: 4),
                  _buildInfoRow(colors, 'Breaker', '${_heaterBreaker}A 2-pole'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircuitSummaryCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CIRCUIT SUMMARY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          if (_hasPumpMotor)
            _buildCircuitRow(colors, 'Pump Circuit', _pumpWireSize, '${_pumpBreaker}A', 'GFCI'),
          if (_hasLighting)
            _buildCircuitRow(colors, 'Lighting Circuit', '12 AWG', '20A', 'GFCI'),
          if (_hasHeater && _heaterKw > 0)
            _buildCircuitRow(colors, 'Heater Circuit', _heaterWireSize, '${_heaterBreaker}A', 'GFCI'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Connected Load', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                Text(
                  '${_totalLoad.toStringAsFixed(1)} kW',
                  style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitRow(ZaftoColors colors, String circuit, String wire, String breaker, String protection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(circuit, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
          Expanded(child: Text(wire, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          Expanded(child: Text(breaker, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(protection, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBondingCard(ZaftoColors colors) {
    final requirements = _bondingRequirements[_installationType] ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.link2, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('EQUIPOTENTIAL BONDING (NEC 680.26)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(LucideIcons.plug, color: colors.accentPrimary, size: 18),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonding Conductor', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text(_bondingConductorSize, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Items requiring bonding:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          ...requirements.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.check, color: Colors.green, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDistancesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('CLEARANCE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildDistanceRow(colors, 'Receptacles (min from water)', '6 ft', 'NEC 680.22(A)(1)'),
          _buildDistanceRow(colors, 'Receptacle required within', '20 ft', 'NEC 680.22(A)(3)'),
          _buildDistanceRow(colors, 'Switch devices from water', '5 ft', 'NEC 680.22(C)'),
          _buildDistanceRow(colors, 'Luminaires over water (indoor)', '12 ft', 'NEC 680.22(B)(1)'),
          _buildDistanceRow(colors, 'Luminaires from water (outdoor)', '5 ft', 'NEC 680.22(B)(2)'),
        ],
      ),
    );
  }

  Widget _buildDistanceRow(ZaftoColors colors, String item, String distance, String code) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 3, child: Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
          Text(distance, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(code, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGFCICard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shieldCheck, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text('GFCI PROTECTION REQUIRED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          ..._gfciRequirements.values.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(req, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Text(
            'All GFCI devices must be Class A (5mA trip threshold)',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
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
            'NEC Article 680 - Swimming Pools, Fountains, and Similar Installations\n\n'
            '680.21 - Motors\n'
            '680.22 - Area lighting, receptacles, switching devices\n'
            '680.23 - Underwater luminaires\n'
            '680.26 - Equipotential bonding\n'
            '680.27 - Specialized pool equipment',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
