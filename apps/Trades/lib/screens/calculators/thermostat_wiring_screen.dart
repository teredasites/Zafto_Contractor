import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Thermostat Wiring Guide - Design System v2.6
/// Terminal designations and wire color codes
class ThermostatWiringScreen extends ConsumerStatefulWidget {
  const ThermostatWiringScreen({super.key});
  @override
  ConsumerState<ThermostatWiringScreen> createState() => _ThermostatWiringScreenState();
}

class _ThermostatWiringScreenState extends ConsumerState<ThermostatWiringScreen> {
  String _systemType = 'gas_furnace_ac';
  bool _hasHumidifier = false;
  bool _hasDehumidifier = false;
  bool _hasVentilator = false;
  bool _hasTwoStage = false;
  bool _hasCommonWire = true;

  List<Map<String, String>>? _wireList;
  int? _minWires;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    List<Map<String, String>> wires = [];

    // R - Power (always needed)
    wires.add({'terminal': 'R', 'color': 'Red', 'function': '24V Power from transformer'});

    // C - Common
    if (_hasCommonWire) {
      wires.add({'terminal': 'C', 'color': 'Blue', 'function': '24V Common (neutral)'});
    }

    switch (_systemType) {
      case 'gas_furnace_ac':
        wires.add({'terminal': 'G', 'color': 'Green', 'function': 'Fan (blower)'});
        wires.add({'terminal': 'Y', 'color': 'Yellow', 'function': 'Cooling (compressor)'});
        wires.add({'terminal': 'W', 'color': 'White', 'function': 'Heat (gas valve)'});
        if (_hasTwoStage) {
          wires.add({'terminal': 'W2', 'color': 'Brown', 'function': '2nd stage heat'});
          wires.add({'terminal': 'Y2', 'color': 'Lt Blue', 'function': '2nd stage cooling'});
        }
        break;

      case 'heat_pump':
        wires.add({'terminal': 'G', 'color': 'Green', 'function': 'Fan (blower)'});
        wires.add({'terminal': 'Y', 'color': 'Yellow', 'function': 'Compressor'});
        wires.add({'terminal': 'O/B', 'color': 'Orange', 'function': 'Reversing valve'});
        wires.add({'terminal': 'W/Aux', 'color': 'White', 'function': 'Aux/Emergency heat'});
        if (_hasTwoStage) {
          wires.add({'terminal': 'W2', 'color': 'Brown', 'function': '2nd stage aux heat'});
        }
        break;

      case 'electric_heat':
        wires.add({'terminal': 'G', 'color': 'Green', 'function': 'Fan (blower)'});
        wires.add({'terminal': 'W', 'color': 'White', 'function': 'Electric heat stage 1'});
        if (_hasTwoStage) {
          wires.add({'terminal': 'W2', 'color': 'Brown', 'function': 'Electric heat stage 2'});
        }
        break;

      case 'cooling_only':
        wires.add({'terminal': 'G', 'color': 'Green', 'function': 'Fan (blower)'});
        wires.add({'terminal': 'Y', 'color': 'Yellow', 'function': 'Cooling (compressor)'});
        if (_hasTwoStage) {
          wires.add({'terminal': 'Y2', 'color': 'Lt Blue', 'function': '2nd stage cooling'});
        }
        break;

      case 'heat_only':
        wires.add({'terminal': 'G', 'color': 'Green', 'function': 'Fan (blower)'});
        wires.add({'terminal': 'W', 'color': 'White', 'function': 'Heat'});
        break;

      case 'boiler':
        wires.add({'terminal': 'W', 'color': 'White', 'function': 'Heat call to boiler'});
        break;
    }

    // Accessories
    if (_hasHumidifier) {
      wires.add({'terminal': 'HUM', 'color': 'Brown', 'function': 'Humidifier control'});
    }
    if (_hasDehumidifier) {
      wires.add({'terminal': 'DEHUM', 'color': 'Tan', 'function': 'Dehumidifier control'});
    }
    if (_hasVentilator) {
      wires.add({'terminal': 'VENT', 'color': 'Pink', 'function': 'Ventilator/ERV control'});
    }

    final minWires = wires.length;

    String recommendation;
    if (!_hasCommonWire) {
      recommendation = 'No C wire: Smart thermostats may need power extender kit or run new wire. Battery backup unreliable.';
    } else {
      recommendation = 'C wire present - full smart thermostat compatibility.';
    }

    if (_systemType == 'heat_pump') {
      recommendation += ' Heat pump: O energizes reversing valve in COOLING (Carrier/Trane). B energizes in HEATING (Rheem/Ruud). Check equipment.';
    }

    recommendation += ' Standard colors shown - always verify at equipment. Use 18/x thermostat wire minimum.';

    if (minWires > 5) {
      recommendation += ' ${minWires} conductors needed - use 18/8 cable for future expansion.';
    }

    setState(() {
      _wireList = wires;
      _minWires = minWires;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemType = 'gas_furnace_ac';
      _hasHumidifier = false;
      _hasDehumidifier = false;
      _hasVentilator = false;
      _hasTwoStage = false;
      _hasCommonWire = true;
    });
    _calculate();
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
        title: Text('Thermostat Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM TYPE'),
              const SizedBox(height: 12),
              _buildSystemSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'OPTIONS'),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'C Wire (Common)', _hasCommonWire, (v) { setState(() => _hasCommonWire = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Two-Stage System', _hasTwoStage, (v) { setState(() => _hasTwoStage = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Humidifier', _hasHumidifier, (v) { setState(() => _hasHumidifier = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Dehumidifier', _hasDehumidifier, (v) { setState(() => _hasDehumidifier = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Ventilator/ERV', _hasVentilator, (v) { setState(() => _hasVentilator = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'WIRING DIAGRAM'),
              const SizedBox(height: 12),
              _buildWiringCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.plug, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Standard wire colors shown. Always verify at equipment terminals. Turn off power before wiring.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSystemSelector(ZaftoColors colors) {
    final systems = [
      ('gas_furnace_ac', 'Gas + A/C'),
      ('heat_pump', 'Heat Pump'),
      ('electric_heat', 'Electric'),
    ];
    final systems2 = [
      ('cooling_only', 'Cool Only'),
      ('heat_only', 'Heat Only'),
      ('boiler', 'Boiler'),
    ];

    return Column(children: [
      Row(
        children: systems.map((s) {
          final selected = _systemType == s.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _systemType = s.$1); _calculate(); },
              child: Container(
                margin: EdgeInsets.only(right: s != systems.last ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Center(child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 8),
      Row(
        children: systems2.map((s) {
          final selected = _systemType == s.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _systemType = s.$1); _calculate(); },
              child: Container(
                margin: EdgeInsets.only(right: s != systems2.last ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Center(child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderDefault, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
      ),
    );
  }

  Widget _buildWiringCard(ZaftoColors colors) {
    if (_wireList == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${_minWires} Wires Minimum', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          ..._wireList!.map((wire) => _buildWireRow(colors, wire)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildWireRow(ZaftoColors colors, Map<String, String> wire) {
    Color wireColor;
    switch (wire['color']) {
      case 'Red': wireColor = Colors.red; break;
      case 'Blue': wireColor = Colors.blue; break;
      case 'Green': wireColor = Colors.green; break;
      case 'Yellow': wireColor = Colors.yellow.shade700; break;
      case 'White': wireColor = Colors.grey.shade300; break;
      case 'Orange': wireColor = Colors.orange; break;
      case 'Brown': wireColor = Colors.brown; break;
      case 'Lt Blue': wireColor = Colors.lightBlue; break;
      case 'Pink': wireColor = Colors.pink; break;
      case 'Tan': wireColor = Colors.brown.shade200; break;
      default: wireColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4)),
          child: Center(child: Text(wire['terminal']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12))),
        ),
        const SizedBox(width: 12),
        Container(width: 24, height: 24, decoration: BoxDecoration(color: wireColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault))),
        const SizedBox(width: 12),
        Expanded(child: Text(wire['function']!, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }
}
