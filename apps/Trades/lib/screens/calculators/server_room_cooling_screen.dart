import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Server Room / Data Center Cooling Calculator - Design System v2.6
/// Precision cooling load for IT equipment
class ServerRoomCoolingScreen extends ConsumerStatefulWidget {
  const ServerRoomCoolingScreen({super.key});
  @override
  ConsumerState<ServerRoomCoolingScreen> createState() => _ServerRoomCoolingScreenState();
}

class _ServerRoomCoolingScreenState extends ConsumerState<ServerRoomCoolingScreen> {
  double _totalKw = 20;
  double _roomSqFt = 400;
  double _ceilingHeight = 10;
  bool _hasUps = true;
  double _upsEfficiency = 95;
  bool _hasLighting = true;
  int _peopleCount = 1;
  double _ambientTemp = 95;
  String _coolingType = 'crac';

  double? _equipmentBtu;
  double? _envelopeBtu;
  double? _miscBtu;
  double? _totalBtu;
  double? _totalTons;
  double? _sensibleRatio;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // IT Equipment heat load
    // 1 kW = 3,412 BTU/hr
    var equipmentBtu = _totalKw * 3412;

    // UPS losses (heat from inefficiency)
    if (_hasUps) {
      final upsLoss = _totalKw * ((100 - _upsEfficiency) / 100);
      equipmentBtu += upsLoss * 3412;
    }

    // Envelope load (walls, ceiling)
    // Server rooms should be well insulated, but still have some transmission
    final volume = _roomSqFt * _ceilingHeight;
    final surfaceArea = 2 * _roomSqFt + (4 * 20 * _ceilingHeight); // Rough estimate
    // Target 68-72°F, ambient varies
    final deltaT = _ambientTemp - 70;
    // U-factor ~0.05 for well-insulated walls
    final envelopeBtu = surfaceArea * 0.05 * deltaT;

    // Miscellaneous loads
    var miscBtu = 0.0;
    if (_hasLighting) {
      // Assume 1 W/sq ft LED
      miscBtu += _roomSqFt * 3.41;
    }
    // People load (250 BTU/hr sensible per person in cool room)
    miscBtu += _peopleCount * 250;

    // Total cooling load
    final totalBtu = equipmentBtu + (envelopeBtu > 0 ? envelopeBtu : 0) + miscBtu;
    final totalTons = totalBtu / 12000;

    // Sensible Heat Ratio (server rooms are nearly all sensible)
    final sensibleRatio = 0.95; // Very high for data centers

    // Watts per square foot (density check)
    final wattsPerSqFt = (_totalKw * 1000) / _roomSqFt;

    String recommendation;
    if (_coolingType == 'crac') {
      recommendation = 'CRAC unit: Floor-standing precision cooling with raised floor air distribution. Maintain 68-72°F, <50% RH.';
    } else if (_coolingType == 'inrow') {
      recommendation = 'In-row cooling: Close-coupled to racks for high density. Best for hot/cold aisle containment.';
    } else {
      recommendation = 'Mini-split: For small server closets only. Ensure adequate sensible capacity and redundancy.';
    }

    if (wattsPerSqFt > 150) {
      recommendation += ' High density (>${wattsPerSqFt.toStringAsFixed(0)} W/sq ft). Consider in-row or rear-door cooling.';
    } else if (wattsPerSqFt > 75) {
      recommendation += ' Medium-high density. Hot/cold aisle containment recommended.';
    }

    if (!_hasUps) {
      recommendation += ' Note: No UPS heat load included. Add UPS losses if present.';
    }

    setState(() {
      _equipmentBtu = equipmentBtu;
      _envelopeBtu = envelopeBtu > 0 ? envelopeBtu : 0;
      _miscBtu = miscBtu;
      _totalBtu = totalBtu;
      _totalTons = totalTons;
      _sensibleRatio = sensibleRatio;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _totalKw = 20;
      _roomSqFt = 400;
      _ceilingHeight = 10;
      _hasUps = true;
      _upsEfficiency = 95;
      _hasLighting = true;
      _peopleCount = 1;
      _ambientTemp = 95;
      _coolingType = 'crac';
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
        title: Text('Server Room Cooling', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'IT EQUIPMENT'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total IT Load', value: _totalKw, min: 1, max: 100, unit: ' kW', onChanged: (v) { setState(() => _totalKw = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Include UPS Heat Load', _hasUps, (v) { setState(() => _hasUps = v); _calculate(); }),
              if (_hasUps) ...[
                const SizedBox(height: 8),
                _buildSliderRow(colors, label: 'UPS Efficiency', value: _upsEfficiency, min: 85, max: 99, unit: '%', onChanged: (v) { setState(() => _upsEfficiency = v); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Room Area', value: _roomSqFt, min: 50, max: 2000, unit: ' sq ft', onChanged: (v) { setState(() => _roomSqFt = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 8, max: 14, unit: ' ft', onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ambient Temp (Outside)', value: _ambientTemp, min: 70, max: 110, unit: '\u00B0F', onChanged: (v) { setState(() => _ambientTemp = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Lighting', _hasLighting, (v) { setState(() => _hasLighting = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'COOLING TYPE'),
              const SizedBox(height: 12),
              _buildCoolingTypeSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'COOLING REQUIREMENT'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildLoadBreakdown(colors),
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
        Icon(LucideIcons.server, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('1 kW IT load = 3,412 BTU/hr cooling. Add UPS losses. Precision cooling maintains 68-72°F, <50% RH.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCoolingTypeSelector(ZaftoColors colors) {
    final types = [
      ('crac', 'CRAC Unit', 'Floor-standing, raised floor'),
      ('inrow', 'In-Row', 'Close-coupled to racks'),
      ('minisplit', 'Mini-Split', 'Small closets only'),
    ];
    return Column(
      children: types.map((t) {
        final selected = _coolingType == t.$1;
        return GestureDetector(
          onTap: () { setState(() => _coolingType = t.$1); _calculate(); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Row(children: [
              Icon(selected ? LucideIcons.checkCircle : LucideIcons.circle, color: selected ? Colors.white : colors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 11)),
              ])),
            ]),
          ),
        );
      }).toList(),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_totalBtu == null) return const SizedBox.shrink();

    final wattsPerSqFt = (_totalKw * 1000) / _roomSqFt;

    Color densityColor;
    String densityLabel;
    if (wattsPerSqFt > 150) {
      densityColor = Colors.red;
      densityLabel = 'High Density';
    } else if (wattsPerSqFt > 75) {
      densityColor = Colors.orange;
      densityLabel = 'Medium-High';
    } else if (wattsPerSqFt > 30) {
      densityColor = colors.accentPrimary;
      densityLabel = 'Medium';
    } else {
      densityColor = Colors.green;
      densityLabel = 'Low Density';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Column(children: [
                Text('${(_totalBtu! / 1000).toStringAsFixed(0)}k', style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text('BTU/hr', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
            Container(width: 1, height: 60, color: colors.borderDefault),
            Expanded(
              child: Column(children: [
                Text('${_totalTons?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text('Tons', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: densityColor, borderRadius: BorderRadius.circular(20)),
            child: Text('${wattsPerSqFt.toStringAsFixed(0)} W/sq ft - $densityLabel', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'IT Load', '${_totalKw.toStringAsFixed(0)} kW')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'SHR', '${(_sensibleRatio! * 100).toStringAsFixed(0)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Volume', '${(_roomSqFt * _ceilingHeight).toStringAsFixed(0)} cu ft')),
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

  Widget _buildLoadBreakdown(ZaftoColors colors) {
    final loads = [
      ('IT Equipment + UPS', _equipmentBtu!),
      ('Envelope (walls/ceiling)', _envelopeBtu!),
      ('Misc (lights, people)', _miscBtu!),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOAD BREAKDOWN (BTU/HR)', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...loads.map((l) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(l.$1, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              Text('${(l.$2 / 1000).toStringAsFixed(1)}k', style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          )),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('TOTAL', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(_totalBtu! / 1000).toStringAsFixed(1)}k BTU/hr', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
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
