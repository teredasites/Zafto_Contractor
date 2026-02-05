import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Evaporator Split Calculator - Design System v2.6
/// Temperature split diagnosis for evaporator coils
class EvaporatorSplitScreen extends ConsumerStatefulWidget {
  const EvaporatorSplitScreen({super.key});
  @override
  ConsumerState<EvaporatorSplitScreen> createState() => _EvaporatorSplitScreenState();
}

class _EvaporatorSplitScreenState extends ConsumerState<EvaporatorSplitScreen> {
  double _returnAirTemp = 75; // degrees F
  double _evapSatTemp = 40; // degrees F (from suction pressure)
  double _suctionLineTemp = 52; // degrees F
  double _supplyAirTemp = 55; // degrees F
  String _coilType = 'dx';
  String _application = 'comfort';

  double? _temperatureSplit;
  double? _superheat;
  double? _airDeltaT;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Temperature split = Return Air Temp - Evaporating Sat Temp
    final temperatureSplit = _returnAirTemp - _evapSatTemp;

    // Superheat
    final superheat = _suctionLineTemp - _evapSatTemp;

    // Air delta T
    final airDeltaT = _returnAirTemp - _supplyAirTemp;

    // Target split depends on application
    double targetSplit;
    switch (_application) {
      case 'comfort':
        targetSplit = 35; // 30-40°F typical for comfort cooling
        break;
      case 'refrigeration':
        targetSplit = 10; // 8-12°F for medium temp
        break;
      case 'low_temp':
        targetSplit = 12; // 10-15°F for low temp
        break;
      default:
        targetSplit = 35;
    }

    // Status determination
    String status;
    if (_application == 'comfort') {
      if (temperatureSplit < 25) {
        status = 'LOW SPLIT';
      } else if (temperatureSplit > 45) {
        status = 'HIGH SPLIT';
      } else {
        status = 'NORMAL';
      }
    } else {
      if (temperatureSplit < 6) {
        status = 'LOW SPLIT';
      } else if (temperatureSplit > 18) {
        status = 'HIGH SPLIT';
      } else {
        status = 'NORMAL';
      }
    }

    String recommendation;
    recommendation = 'Evaporator split: ${temperatureSplit.toStringAsFixed(0)}°F (Return ${_returnAirTemp.toStringAsFixed(0)}°F - Sat ${_evapSatTemp.toStringAsFixed(0)}°F). ';

    switch (_application) {
      case 'comfort':
        recommendation += 'Comfort cooling target: 30-40°F split. ';
        if (temperatureSplit < 25) {
          recommendation += 'LOW: May indicate high airflow, dirty filter restriction, or overcharge.';
        } else if (temperatureSplit > 45) {
          recommendation += 'HIGH: Check for low airflow, dirty coil, low charge, or restriction.';
        } else {
          recommendation += 'Split is normal for comfort application.';
        }
        break;
      case 'refrigeration':
        recommendation += 'Medium temp refrigeration target: 8-12°F split. ';
        if (temperatureSplit > 18) {
          recommendation += 'HIGH split reduces capacity. Check defrost, airflow.';
        }
        break;
      case 'low_temp':
        recommendation += 'Low temp target: 10-15°F split. ';
        if (temperatureSplit > 20) {
          recommendation += 'HIGH split affects capacity. Check ice buildup, defrost cycle.';
        }
        break;
    }

    recommendation += ' Superheat: ${superheat.toStringAsFixed(1)}°F. Air ΔT: ${airDeltaT.toStringAsFixed(0)}°F. ';

    if (superheat < 5) {
      recommendation += 'LOW superheat: Risk of liquid flood-back. Check expansion valve/charge.';
    } else if (superheat > 20) {
      recommendation += 'HIGH superheat: Check for low charge, restriction, or low load.';
    }

    if (airDeltaT < 15) {
      recommendation += ' Low air ΔT may indicate high airflow or low coil load.';
    } else if (airDeltaT > 25) {
      recommendation += ' High air ΔT may indicate low airflow.';
    }

    switch (_coilType) {
      case 'dx':
        recommendation += ' DX coil: Verify TXV operation and proper superheat.';
        break;
      case 'chilled_water':
        recommendation += ' Chilled water: Check water temp and flow. Clean strainer.';
        break;
    }

    recommendation += ' Lower evap temp = more energy. Raise setpoint where possible.';

    setState(() {
      _temperatureSplit = temperatureSplit;
      _superheat = superheat;
      _airDeltaT = airDeltaT;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _returnAirTemp = 75;
      _evapSatTemp = 40;
      _suctionLineTemp = 52;
      _supplyAirTemp = 55;
      _coilType = 'dx';
      _application = 'comfort';
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
        title: Text('Evaporator Split', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'APPLICATION'),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 12),
              _buildCoilTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIR TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Return Air', _returnAirTemp, 60, 90, '°F', (v) { setState(() => _returnAirTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Supply Air', _supplyAirTemp, 45, 70, '°F', (v) { setState(() => _supplyAirTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'REFRIGERANT TEMPS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Evap Sat', _evapSatTemp, 20, 55, '°F', (v) { setState(() => _evapSatTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Suction Line', _suctionLineTemp, 30, 70, '°F', (v) { setState(() => _suctionLineTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EVAPORATOR ANALYSIS'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
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
        Icon(LucideIcons.snowflake, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Evaporator split = Return Air - Sat Temp. Comfort: 30-40°F. Refrigeration: 8-15°F. Low split = poor heat absorption.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [('comfort', 'Comfort AC'), ('refrigeration', 'Med Temp'), ('low_temp', 'Low Temp')];
    return Row(
      children: apps.map((a) {
        final selected = _application == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _application = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoilTypeSelector(ZaftoColors colors) {
    final types = [('dx', 'DX (Refrigerant)'), ('chilled_water', 'Chilled Water')];
    return Row(
      children: types.map((t) {
        final selected = _coilType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _coilType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_temperatureSplit == null) return const SizedBox.shrink();

    Color statusColor;
    if (_status == 'NORMAL') {
      statusColor = Colors.green;
    } else if (_status == 'HIGH SPLIT' || _status == 'LOW SPLIT') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_temperatureSplit?.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Temperature Split', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Superheat', '${_superheat?.toStringAsFixed(1)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Air ΔT', '${_airDeltaT?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Supply', '${_supplyAirTemp.toStringAsFixed(0)}°F')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(statusColor == Colors.green ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
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
