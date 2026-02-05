import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Condenser Split Calculator - Design System v2.6
/// Temperature split diagnosis for air-cooled condensers
class CondenserSplitScreen extends ConsumerStatefulWidget {
  const CondenserSplitScreen({super.key});
  @override
  ConsumerState<CondenserSplitScreen> createState() => _CondenserSplitScreenState();
}

class _CondenserSplitScreenState extends ConsumerState<CondenserSplitScreen> {
  double _outdoorTemp = 85; // degrees F
  double _condensingSatTemp = 115; // degrees F (from head pressure)
  double _liquidLineTemp = 100; // degrees F
  String _condenserType = 'air_cooled';
  String _refrigerant = 'r410a';

  double? _temperatureSplit;
  double? _subcooling;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Temperature split = Condensing Sat Temp - Outdoor Temp
    final temperatureSplit = _condensingSatTemp - _outdoorTemp;

    // Subcooling
    final subcooling = _condensingSatTemp - _liquidLineTemp;

    // Target split depends on condenser type
    double targetSplit;
    switch (_condenserType) {
      case 'air_cooled':
        targetSplit = 30; // 25-35°F typical for air-cooled
        break;
      case 'water_cooled':
        targetSplit = 10; // 8-12°F for water-cooled
        break;
      case 'evap_cooled':
        targetSplit = 15; // 12-18°F for evaporative
        break;
      default:
        targetSplit = 30;
    }

    // Status determination
    String status;
    if (_condenserType == 'air_cooled') {
      if (temperatureSplit < 20) {
        status = 'LOW SPLIT (Good)';
      } else if (temperatureSplit > 40) {
        status = 'HIGH SPLIT';
      } else {
        status = 'NORMAL';
      }
    } else if (_condenserType == 'water_cooled') {
      if (temperatureSplit < 6) {
        status = 'LOW SPLIT';
      } else if (temperatureSplit > 15) {
        status = 'HIGH SPLIT';
      } else {
        status = 'NORMAL';
      }
    } else {
      if (temperatureSplit < 10) {
        status = 'LOW SPLIT';
      } else if (temperatureSplit > 25) {
        status = 'HIGH SPLIT';
      } else {
        status = 'NORMAL';
      }
    }

    String recommendation;
    recommendation = 'Condenser split: ${temperatureSplit.toStringAsFixed(0)}°F (Sat ${_condensingSatTemp.toStringAsFixed(0)}°F - OA ${_outdoorTemp.toStringAsFixed(0)}°F). ';

    switch (_condenserType) {
      case 'air_cooled':
        recommendation += 'Air-cooled target: 25-35°F split. ';
        if (temperatureSplit > 40) {
          recommendation += 'HIGH: Check for dirty coil, low airflow, condenser fan failure, or recirculation.';
        } else if (temperatureSplit < 20) {
          recommendation += 'LOW: Excellent heat rejection. May indicate low charge or cool ambient.';
        } else {
          recommendation += 'Split is normal for air-cooled condenser.';
        }
        break;
      case 'water_cooled':
        recommendation += 'Water-cooled target: 8-12°F split. ';
        if (temperatureSplit > 15) {
          recommendation += 'HIGH: Check water flow, entering water temp, tube fouling.';
        } else {
          recommendation += 'Split OK for water-cooled.';
        }
        break;
      case 'evap_cooled':
        recommendation += 'Evaporative target: 12-18°F above wet bulb. ';
        if (temperatureSplit > 25) {
          recommendation += 'HIGH: Check spray distribution, pad condition, or airflow.';
        } else {
          recommendation += 'Split OK for evaporative condenser.';
        }
        break;
    }

    recommendation += ' Subcooling: ${subcooling.toStringAsFixed(1)}°F. ';

    if (subcooling < 5) {
      recommendation += 'LOW subcooling may indicate undercharge or high head.';
    } else if (subcooling > 20) {
      recommendation += 'HIGH subcooling may indicate overcharge or restriction.';
    }

    // High head pressure effects
    if (_condensingSatTemp > 130) {
      recommendation += ' WARNING: High condensing temp. Each 1°F above normal = ~1% capacity loss and higher power.';
    }

    recommendation += ' Clean condenser coils annually. Check fan amp draw and blade pitch.';

    setState(() {
      _temperatureSplit = temperatureSplit;
      _subcooling = subcooling;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _outdoorTemp = 85;
      _condensingSatTemp = 115;
      _liquidLineTemp = 100;
      _condenserType = 'air_cooled';
      _refrigerant = 'r410a';
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
        title: Text('Condenser Split', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONDENSER TYPE'),
              const SizedBox(height: 12),
              _buildCondenserTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Outdoor', _outdoorTemp, 50, 115, '°F', (v) { setState(() => _outdoorTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Cond Sat', _condensingSatTemp, 80, 150, '°F', (v) { setState(() => _condensingSatTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LIQUID LINE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Liquid Line Temperature', value: _liquidLineTemp, min: 70, max: 140, unit: '°F', onChanged: (v) { setState(() => _liquidLineTemp = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'CONDENSER ANALYSIS'),
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
        Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Condenser split = Sat Temp - Ambient. Air-cooled: 25-35°F. Water-cooled: 8-12°F. High split = poor heat rejection.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCondenserTypeSelector(ZaftoColors colors) {
    final types = [('air_cooled', 'Air-Cooled'), ('water_cooled', 'Water-Cooled'), ('evap_cooled', 'Evaporative')];
    return Row(
      children: types.map((t) {
        final selected = _condenserType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _condenserType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
    if (_temperatureSplit == null) return const SizedBox.shrink();

    Color statusColor;
    if (_status == 'NORMAL' || _status == 'LOW SPLIT (Good)') {
      statusColor = Colors.green;
    } else if (_status == 'HIGH SPLIT') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
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
            Expanded(child: _buildResultItem(colors, 'Outdoor', '${_outdoorTemp.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Cond Sat', '${_condensingSatTemp.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Subcooling', '${_subcooling?.toStringAsFixed(1)}°F')),
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
