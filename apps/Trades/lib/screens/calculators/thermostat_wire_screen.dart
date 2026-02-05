import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Thermostat Wire Calculator - Design System v2.6
/// Wire count and type for HVAC control circuits
class ThermostatWireScreen extends ConsumerStatefulWidget {
  const ThermostatWireScreen({super.key});
  @override
  ConsumerState<ThermostatWireScreen> createState() => _ThermostatWireScreenState();
}

class _ThermostatWireScreenState extends ConsumerState<ThermostatWireScreen> {
  bool _hasHeat = true;
  bool _hasCool = true;
  bool _hasFan = true;
  bool _isHeatPump = false;
  bool _has2Stage = false;
  bool _hasHumidifier = false;
  bool _hasDehumidifier = false;
  bool _hasErv = false;
  String _commonWire = 'included';
  double _wireRun = 50;

  int? _minimumWires;
  int? _recommendedWires;
  String? _wireDesignation;
  List<Map<String, String>>? _wireList;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Count required wires
    final wires = <Map<String, String>>[];

    // R - 24V power (always required)
    wires.add({'terminal': 'R', 'color': 'Red', 'function': '24V Power'});

    // C - Common (highly recommended for smart stats)
    if (_commonWire == 'included') {
      wires.add({'terminal': 'C', 'color': 'Blue', 'function': 'Common (24V return)'});
    }

    if (_hasHeat) {
      if (_isHeatPump) {
        wires.add({'terminal': 'Y', 'color': 'Yellow', 'function': 'Compressor (heat/cool)'});
        wires.add({'terminal': 'O/B', 'color': 'Orange', 'function': 'Reversing valve'});
        wires.add({'terminal': 'W/AUX', 'color': 'White', 'function': 'Aux/Emergency heat'});
      } else {
        wires.add({'terminal': 'W', 'color': 'White', 'function': 'Heat call'});
        if (_has2Stage) {
          wires.add({'terminal': 'W2', 'color': 'Brown', 'function': 'Stage 2 heat'});
        }
      }
    }

    if (_hasCool && !_isHeatPump) {
      wires.add({'terminal': 'Y', 'color': 'Yellow', 'function': 'Cooling call'});
      if (_has2Stage) {
        wires.add({'terminal': 'Y2', 'color': 'Light Blue', 'function': 'Stage 2 cool'});
      }
    }

    if (_hasFan) {
      wires.add({'terminal': 'G', 'color': 'Green', 'function': 'Fan call'});
    }

    if (_hasHumidifier) {
      wires.add({'terminal': 'HUM', 'color': 'Tan', 'function': 'Humidifier'});
    }

    if (_hasDehumidifier) {
      wires.add({'terminal': 'DEHUM', 'color': 'Gray', 'function': 'Dehumidifier'});
    }

    if (_hasErv) {
      wires.add({'terminal': 'ERV', 'color': 'Pink', 'function': 'ERV/HRV control'});
    }

    final minimumWires = wires.length;

    // Recommend +2 spare wires
    int recommendedWires;
    if (minimumWires <= 4) {
      recommendedWires = 5;
    } else if (minimumWires <= 6) {
      recommendedWires = 8;
    } else {
      recommendedWires = 10;
    }

    // Wire designation
    String wireDesignation;
    if (recommendedWires <= 4) {
      wireDesignation = '18/4 Thermostat Wire';
    } else if (recommendedWires <= 5) {
      wireDesignation = '18/5 Thermostat Wire';
    } else if (recommendedWires <= 6) {
      wireDesignation = '18/6 Thermostat Wire';
    } else if (recommendedWires <= 8) {
      wireDesignation = '18/8 Thermostat Wire';
    } else {
      wireDesignation = '18/10 Thermostat Wire';
    }

    // Recommendation
    String recommendation = '';
    if (_wireRun > 100) {
      recommendation = 'Long run (>100 ft): Consider 16 gauge wire for reduced voltage drop. ';
    }

    if (_commonWire != 'included') {
      recommendation += 'Smart thermostats require C wire. Add-a-wire adapter available if no spare. ';
    }

    if (_isHeatPump) {
      recommendation += 'Heat pump: Verify O vs B terminal based on brand (Carrier/Bryant = O for cooling, Rheem = B for heating). ';
    }

    if (recommendation.isEmpty) {
      recommendation = 'Standard installation. Run extra conductors for future upgrades. Color coding per industry standard.';
    }

    setState(() {
      _minimumWires = minimumWires;
      _recommendedWires = recommendedWires;
      _wireDesignation = wireDesignation;
      _wireList = wires;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _hasHeat = true;
      _hasCool = true;
      _hasFan = true;
      _isHeatPump = false;
      _has2Stage = false;
      _hasHumidifier = false;
      _hasDehumidifier = false;
      _hasErv = false;
      _commonWire = 'included';
      _wireRun = 50;
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
        title: Text('Thermostat Wire', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildCheckboxRow(colors, 'Heat', _hasHeat, (v) { setState(() => _hasHeat = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Cooling', _hasCool, (v) { setState(() => _hasCool = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Fan Control', _hasFan, (v) { setState(() => _hasFan = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Heat Pump System', _isHeatPump, (v) { setState(() => _isHeatPump = v); _calculate(); }),
              _buildCheckboxRow(colors, '2-Stage Heat/Cool', _has2Stage, (v) { setState(() => _has2Stage = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ACCESSORIES'),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Humidifier', _hasHumidifier, (v) { setState(() => _hasHumidifier = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Dehumidifier', _hasDehumidifier, (v) { setState(() => _hasDehumidifier = v); _calculate(); }),
              _buildCheckboxRow(colors, 'ERV/HRV', _hasErv, (v) { setState(() => _hasErv = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Common Wire (C)', options: const ['Included', 'Not Needed'], selectedIndex: _commonWire == 'included' ? 0 : 1, onChanged: (i) { setState(() => _commonWire = i == 0 ? 'included' : 'not_needed'); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Wire Run Length', value: _wireRun, min: 10, max: 200, unit: ' ft', onChanged: (v) { setState(() => _wireRun = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'WIRE SELECTION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildWireTable(colors),
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
        Expanded(child: Text('18 AWG thermostat cable. Always include C wire for smart stats. Run 2 extra conductors for future needs.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_wireDesignation == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('$_recommendedWires', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Conductor Cable', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text(_wireDesignation ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Minimum', '$_minimumWires wires')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Recommended', '$_recommendedWires wires')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Spare', '${_recommendedWires! - _minimumWires!} wires')),
          ]),
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

  Widget _buildWireTable(ZaftoColors colors) {
    if (_wireList == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRE CONNECTIONS', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._wireList!.map((w) => _buildWireRow(colors, w['terminal']!, w['color']!, w['function']!)),
        ],
      ),
    );
  }

  Widget _buildWireRow(ZaftoColors colors, String terminal, String colorName, String function) {
    Color wireColor;
    switch (colorName.toLowerCase()) {
      case 'red': wireColor = Colors.red; break;
      case 'blue': wireColor = Colors.blue; break;
      case 'yellow': wireColor = Colors.yellow.shade700; break;
      case 'orange': wireColor = Colors.orange; break;
      case 'white': wireColor = Colors.grey.shade300; break;
      case 'green': wireColor = Colors.green; break;
      case 'brown': wireColor = Colors.brown; break;
      case 'light blue': wireColor = Colors.lightBlue; break;
      case 'tan': wireColor = Colors.brown.shade200; break;
      case 'gray': wireColor = Colors.grey; break;
      case 'pink': wireColor = Colors.pink.shade200; break;
      default: wireColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: wireColor,
            shape: BoxShape.circle,
            border: colorName.toLowerCase() == 'white' ? Border.all(color: Colors.grey) : null,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 50, child: Text(terminal, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(child: Text(function, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
