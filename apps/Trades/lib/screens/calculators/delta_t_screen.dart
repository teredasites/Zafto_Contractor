import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Delta T (Temperature Split) Calculator - Design System v2.6
/// Supply/return air temperature differential analysis
class DeltaTScreen extends ConsumerStatefulWidget {
  const DeltaTScreen({super.key});
  @override
  ConsumerState<DeltaTScreen> createState() => _DeltaTScreenState();
}

class _DeltaTScreenState extends ConsumerState<DeltaTScreen> {
  double _returnAirTemp = 75;
  double _supplyAirTemp = 55;
  String _mode = 'cooling';
  String _systemType = 'residential';
  double _humidity = 50;

  double? _deltaT;
  double? _targetDeltaT;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    double deltaT;
    double targetDeltaT;
    double minDeltaT;
    double maxDeltaT;

    if (_mode == 'cooling') {
      // Cooling: Return - Supply
      deltaT = _returnAirTemp - _supplyAirTemp;

      // Target varies by humidity - lower humidity = higher delta T acceptable
      if (_humidity > 60) {
        targetDeltaT = 18;
        minDeltaT = 16;
        maxDeltaT = 20;
      } else if (_humidity > 40) {
        targetDeltaT = 20;
        minDeltaT = 18;
        maxDeltaT = 22;
      } else {
        targetDeltaT = 22;
        minDeltaT = 20;
        maxDeltaT = 24;
      }
    } else {
      // Heating: Supply - Return
      deltaT = _supplyAirTemp - _returnAirTemp;

      switch (_systemType) {
        case 'residential':
          targetDeltaT = 45;
          minDeltaT = 35;
          maxDeltaT = 55;
          break;
        case 'heat_pump':
          targetDeltaT = 25;
          minDeltaT = 18;
          maxDeltaT = 32;
          break;
        case 'commercial':
          targetDeltaT = 40;
          minDeltaT = 30;
          maxDeltaT = 50;
          break;
        default:
          targetDeltaT = 45;
          minDeltaT = 35;
          maxDeltaT = 55;
      }
    }

    String status;
    if (deltaT >= minDeltaT && deltaT <= maxDeltaT) {
      status = 'NORMAL';
    } else if (deltaT > maxDeltaT) {
      status = _mode == 'cooling' ? 'HIGH - Low Airflow' : 'HIGH';
    } else {
      status = _mode == 'cooling' ? 'LOW - Check System' : 'LOW - Check Heat';
    }

    String recommendation;
    if (_mode == 'cooling') {
      if (deltaT > maxDeltaT) {
        recommendation = 'High delta T (${deltaT.toStringAsFixed(0)}°F) indicates low airflow. Check: dirty filter, blocked returns, closed registers, blower issue.';
      } else if (deltaT < minDeltaT) {
        recommendation = 'Low delta T indicates: low charge, dirty evaporator, high airflow, or metering device issue.';
      } else {
        recommendation = 'Delta T within normal range for ${_humidity.toStringAsFixed(0)}% RH conditions.';
      }
      recommendation += ' Standard cooling: 18-22°F delta T. Higher humidity = lower delta T target.';
    } else {
      if (deltaT > maxDeltaT) {
        recommendation = 'High heating delta T. May cause discomfort. Check airflow and limit settings.';
      } else if (deltaT < minDeltaT) {
        recommendation = 'Low heating delta T. Check: gas pressure, heat exchanger, burner operation, heat strips.';
      } else {
        recommendation = 'Heating delta T normal for $_systemType system.';
      }

      if (_systemType == 'heat_pump') {
        recommendation += ' Heat pump delta T is lower (18-32°F) than gas furnace due to lower supply temps.';
      }
    }

    setState(() {
      _deltaT = deltaT;
      _targetDeltaT = targetDeltaT;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _returnAirTemp = 75;
      _supplyAirTemp = _mode == 'cooling' ? 55 : 120;
      _mode = 'cooling';
      _systemType = 'residential';
      _humidity = 50;
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
        title: Text('Delta T', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODE'),
              const SizedBox(height: 12),
              _buildModeSelector(colors),
              const SizedBox(height: 12),
              if (_mode == 'heating') _buildSystemTypeSelector(colors),
              if (_mode == 'cooling') _buildSliderRow(colors, label: 'Indoor Humidity', value: _humidity, min: 30, max: 80, unit: '%', onChanged: (v) { setState(() => _humidity = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Return Air', _returnAirTemp, 60, 85, '°F', (v) { setState(() => _returnAirTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Supply Air', _supplyAirTemp, _mode == 'cooling' ? 40 : 90, _mode == 'cooling' ? 70 : 160, '°F', (v) { setState(() => _supplyAirTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'ANALYSIS'),
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
        Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Delta T = temp difference across coil. Cooling: 18-22°F typical. Heating: 35-55°F furnace, 18-32°F heat pump.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildModeSelector(ZaftoColors colors) {
    final modes = [('cooling', 'Cooling'), ('heating', 'Heating')];
    return Row(
      children: modes.map((m) {
        final selected = _mode == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _mode = m.$1;
                _supplyAirTemp = m.$1 == 'cooling' ? 55 : 120;
              });
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: m != modes.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? (m.$1 == 'cooling' ? Colors.blue : Colors.orange) : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? (m.$1 == 'cooling' ? Colors.blue : Colors.orange) : colors.borderDefault),
              ),
              child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    final types = [('residential', 'Gas Furnace'), ('heat_pump', 'Heat Pump'), ('commercial', 'Commercial')];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: types.map((t) {
          final selected = _systemType == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _systemType = t.$1); _calculate(); },
              child: Container(
                margin: EdgeInsets.only(right: t != types.last ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_deltaT == null) return const SizedBox.shrink();

    final isNormal = _status == 'NORMAL';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_deltaT?.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Temperature Split', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isNormal ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Target', '${_targetDeltaT?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Return', '${_returnAirTemp.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Supply', '${_supplyAirTemp.toStringAsFixed(0)}°F')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isNormal ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isNormal ? Colors.green : Colors.orange, size: 16),
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
