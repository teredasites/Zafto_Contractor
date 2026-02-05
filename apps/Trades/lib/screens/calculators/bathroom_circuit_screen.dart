import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Bathroom Circuit Planner - Design System v2.6
/// GFCI and circuit requirements per NEC 210.11(C)(3) & 210.8
class BathroomCircuitScreen extends ConsumerStatefulWidget {
  const BathroomCircuitScreen({super.key});
  @override
  ConsumerState<BathroomCircuitScreen> createState() => _BathroomCircuitScreenState();
}

class _BathroomCircuitScreenState extends ConsumerState<BathroomCircuitScreen> {
  int _bathroomCount = 2;
  bool _sharedCircuit = false; // Can share if multiple bathrooms, receptacles only
  bool _hasExhaustFan = true;
  bool _hasInWallHeater = false;
  bool _hasJetTub = false;
  bool _hasElectricFloorHeat = false;
  bool _hasTowelWarmer = false;
  double _floorHeatSqFt = 0;
  double _wallHeaterWatts = 1500;
  double _jetTubAmps = 10;

  // NEC 210.11(C)(3) - Bathroom branch circuit
  // At least one 20A circuit for receptacles
  // Can serve multiple bathrooms if ONLY receptacles

  List<Map<String, dynamic>> get _requiredCircuits {
    final circuits = <Map<String, dynamic>>[];

    // Receptacle circuit(s) - NEC 210.11(C)(3)
    if (_sharedCircuit && _bathroomCount <= 3) {
      circuits.add({
        'name': 'Bathroom Receptacles (shared)',
        'wire': '12 AWG',
        'breaker': '20A',
        'protection': 'GFCI',
        'code': 'NEC 210.11(C)(3)',
        'required': true,
        'notes': 'Serves receptacles in ${_bathroomCount} bathrooms only',
      });
    } else {
      for (var i = 1; i <= _bathroomCount; i++) {
        circuits.add({
          'name': 'Bathroom $i Receptacles',
          'wire': '12 AWG',
          'breaker': '20A',
          'protection': 'GFCI',
          'code': 'NEC 210.11(C)(3)',
          'required': true,
          'notes': 'Dedicated 20A circuit, GFCI required',
        });
      }
    }

    // Lighting circuits (can be shared with other loads)
    circuits.add({
      'name': 'Bathroom Lighting',
      'wire': '14 AWG',
      'breaker': '15A',
      'protection': 'Standard',
      'code': 'NEC 210.70(A)',
      'required': true,
      'notes': 'Can serve multiple bathrooms, switches required',
    });

    // Exhaust fan
    if (_hasExhaustFan) {
      circuits.add({
        'name': 'Exhaust Fan(s)',
        'wire': '14 AWG',
        'breaker': '15A',
        'protection': 'Standard',
        'code': 'NEC 210.23',
        'required': false,
        'notes': 'Can be on lighting circuit if continuous load ≤12A',
      });
    }

    // In-wall heater
    if (_hasInWallHeater) {
      final amps = _wallHeaterWatts / 240;
      final breaker = amps * 1.25 <= 20 ? 20 : 30;
      final wire = breaker == 20 ? '12 AWG' : '10 AWG';
      circuits.add({
        'name': 'In-Wall Heater',
        'wire': wire,
        'breaker': '${breaker}A',
        'protection': 'Dedicated',
        'code': 'NEC 424.3',
        'required': true,
        'notes': '${_wallHeaterWatts.toInt()}W heater, ${amps.toStringAsFixed(1)}A load',
      });
    }

    // Jetted tub
    if (_hasJetTub) {
      circuits.add({
        'name': 'Jetted Tub Motor',
        'wire': '12 AWG',
        'breaker': '20A',
        'protection': 'GFCI',
        'code': 'NEC 680.71',
        'required': true,
        'notes': 'GFCI required, readily accessible disconnect',
      });
    }

    // Electric floor heat
    if (_hasElectricFloorHeat && _floorHeatSqFt > 0) {
      // Typical floor heat: 12W per sq ft
      final watts = _floorHeatSqFt * 12;
      final amps = watts / 240;
      final breaker = amps * 1.25 <= 15 ? 15 : (amps * 1.25 <= 20 ? 20 : 30);
      final wire = breaker <= 15 ? '14 AWG' : (breaker <= 20 ? '12 AWG' : '10 AWG');
      circuits.add({
        'name': 'Electric Floor Heat',
        'wire': wire,
        'breaker': '${breaker}A',
        'protection': 'GFCI',
        'code': 'NEC 424.44',
        'required': true,
        'notes': '${_floorHeatSqFt.toInt()} sq ft, ~${watts.toInt()}W, GFCI required',
      });
    }

    // Towel warmer
    if (_hasTowelWarmer) {
      circuits.add({
        'name': 'Towel Warmer',
        'wire': '14 AWG',
        'breaker': '15A',
        'protection': 'GFCI',
        'code': 'NEC 422.5',
        'required': false,
        'notes': 'GFCI required within 6 ft of sink/tub',
      });
    }

    return circuits;
  }

  int get _totalCircuits => _requiredCircuits.length;

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
        title: Text('Bathroom Circuit Planner', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBathroomCountCard(colors),
          const SizedBox(height: 16),
          _buildEquipmentCard(colors),
          const SizedBox(height: 16),
          if (_hasInWallHeater) _buildHeaterCard(colors),
          if (_hasInWallHeater) const SizedBox(height: 16),
          if (_hasElectricFloorHeat) _buildFloorHeatCard(colors),
          if (_hasElectricFloorHeat) const SizedBox(height: 16),
          _buildSummaryCard(colors),
          const SizedBox(height: 16),
          _buildCircuitListCard(colors),
          const SizedBox(height: 16),
          _buildGFCICard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildBathroomCountCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NUMBER OF BATHROOMS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [1, 2, 3, 4, 5].map((count) {
              final isSelected = _bathroomCount == count;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _bathroomCount = count);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_bathroomCount > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share receptacle circuit?', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                      Text('Allowed per NEC 210.11(C)(3) Ex', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(
                  value: _sharedCircuit,
                  onChanged: (v) => setState(() => _sharedCircuit = v),
                  activeColor: colors.accentPrimary,
                ),
              ],
            ),
          ],
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
          Text('BATHROOM EQUIPMENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildToggle(colors, 'Exhaust Fan', _hasExhaustFan, (v) => setState(() => _hasExhaustFan = v)),
          _buildToggle(colors, 'In-Wall Heater', _hasInWallHeater, (v) => setState(() => _hasInWallHeater = v)),
          _buildToggle(colors, 'Jetted Tub/Whirlpool', _hasJetTub, (v) => setState(() => _hasJetTub = v)),
          _buildToggle(colors, 'Electric Floor Heat', _hasElectricFloorHeat, (v) => setState(() => _hasElectricFloorHeat = v)),
          _buildToggle(colors, 'Towel Warmer', _hasTowelWarmer, (v) => setState(() => _hasTowelWarmer = v)),
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
          Text('IN-WALL HEATER SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [750, 1000, 1500, 2000, 3000, 4000].map((watts) {
              final isSelected = _wallHeaterWatts == watts.toDouble();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _wallHeaterWatts = watts.toDouble());
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
                      fontSize: 13,
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

  Widget _buildFloorHeatCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FLOOR HEAT AREA (sq ft)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [25, 40, 60, 80, 100, 150].map((sqft) {
              final isSelected = _floorHeatSqFt == sqft.toDouble();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _floorHeatSqFt = sqft.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$sqft',
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
          const SizedBox(height: 8),
          Text('Typical: 12W per sq ft', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.accentPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text('TOTAL CIRCUITS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            '$_totalCircuits',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text('circuits', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.shieldCheck, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'All receptacle circuits require GFCI',
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitListCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CIRCUIT SCHEDULE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          ..._requiredCircuits.map((circuit) => _buildCircuitRow(colors, circuit)),
        ],
      ),
    );
  }

  Widget _buildCircuitRow(ZaftoColors colors, Map<String, dynamic> circuit) {
    final isGFCI = circuit['protection'] == 'GFCI';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  circuit['name'],
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              if (isGFCI)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'GFCI',
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSpec(colors, circuit['wire'], LucideIcons.plug),
              const SizedBox(width: 16),
              _buildSpec(colors, circuit['breaker'], LucideIcons.toggleRight),
            ],
          ),
          const SizedBox(height: 6),
          Text(circuit['notes'], style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSpec(ZaftoColors colors, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colors.textTertiary),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
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
              Text('GFCI REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildGFCIItem(colors, 'All bathroom receptacles', 'NEC 210.8(A)(1)'),
          _buildGFCIItem(colors, 'Equipment within 6 ft of sink/tub', 'NEC 422.5'),
          _buildGFCIItem(colors, 'Electric floor heating', 'NEC 424.44'),
          _buildGFCIItem(colors, 'Jetted tub motor', 'NEC 680.71'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.textTertiary, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GFCI protection can be at breaker or first receptacle in circuit',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGFCIItem(ZaftoColors colors, String item, String code) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 14),
              const SizedBox(width: 8),
              Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            ],
          ),
          Text(code, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
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
            'NEC 210.11(C)(3) - At least one 20A circuit required for bathroom receptacles.\n\n'
            'NEC 210.11(C)(3) Ex - A single 20A circuit may serve receptacles in multiple bathrooms if only receptacles.\n\n'
            'NEC 210.8(A)(1) - GFCI protection required for all 125V receptacles in bathrooms.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
