import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Condenser Temperature Differential Calculator - Design System v2.6
/// Diagnose condenser coil performance via TD/split
class CondenserTdScreen extends ConsumerStatefulWidget {
  const CondenserTdScreen({super.key});
  @override
  ConsumerState<CondenserTdScreen> createState() => _CondenserTdScreenState();
}

class _CondenserTdScreenState extends ConsumerState<CondenserTdScreen> {
  double _outdoorAmbient = 95;
  double _dischargeSatTemp = 125;
  String _condenserType = 'air_cooled';
  String _refrigerant = 'r410a';
  double _condensingTemp = 0;

  double? _actualTd;
  double? _targetTd;
  double? _deviation;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Condenser TD (Split) = Saturated Discharge (Condensing) Temp - Ambient
    final actualTd = _dischargeSatTemp - _outdoorAmbient;

    // Target TD varies by condenser type
    double targetTd;
    double minTd;
    double maxTd;

    switch (_condenserType) {
      case 'air_cooled':
        targetTd = 30;
        minTd = 25;
        maxTd = 35;
        break;
      case 'water_cooled':
        targetTd = 15;
        minTd = 10;
        maxTd = 20;
        break;
      case 'evaporative':
        targetTd = 20;
        minTd = 15;
        maxTd = 25;
        break;
      default:
        targetTd = 30;
        minTd = 25;
        maxTd = 35;
    }

    final deviation = actualTd - targetTd;

    String status;
    if (actualTd >= minTd && actualTd <= maxTd) {
      status = 'NORMAL';
    } else if (actualTd > maxTd) {
      status = 'HIGH TD - Check Condenser';
    } else {
      status = 'LOW TD';
    }

    String recommendation;
    if (actualTd > maxTd) {
      recommendation = 'High condenser TD indicates: Dirty condenser coil, failed fan motor, blocked airflow, refrigerant overcharge, non-condensables.';
    } else if (actualTd < minTd) {
      recommendation = 'Low condenser TD may indicate: Low refrigerant charge, low ambient operation, faulty discharge sensor.';
    } else {
      recommendation = 'Condenser TD within normal range. Heat rejection operating efficiently.';
    }

    if (_condenserType == 'air_cooled') {
      recommendation += ' Air-cooled target: 25-35°F TD above ambient. Clean coils improve capacity 10-15%.';
    } else if (_condenserType == 'water_cooled') {
      recommendation += ' Water-cooled: Check entering water temp and flow rate. 3 GPM per ton typical.';
    }

    // Refrigerant-specific notes
    if (_refrigerant == 'r410a') {
      recommendation += ' R-410A: Higher pressures - verify discharge pressure matches sat temp.';
    }

    setState(() {
      _actualTd = actualTd;
      _targetTd = targetTd;
      _deviation = deviation;
      _condensingTemp = _dischargeSatTemp;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _outdoorAmbient = 95;
      _dischargeSatTemp = 125;
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
        title: Text('Condenser TD', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 12),
              _buildRefrigerantSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor Ambient', value: _outdoorAmbient, min: 60, max: 120, unit: '°F', onChanged: (v) { setState(() => _outdoorAmbient = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Sat. Discharge Temp', value: _dischargeSatTemp, min: 80, max: 160, unit: '°F', onChanged: (v) { setState(() => _dischargeSatTemp = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TD ANALYSIS'),
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
        Icon(LucideIcons.thermometerSun, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Condenser TD = Sat. Discharge - Ambient. Air-cooled target: 25-35°F. High TD = dirty coil or airflow issue.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCondenserTypeSelector(ZaftoColors colors) {
    final types = [('air_cooled', 'Air-Cooled'), ('water_cooled', 'Water'), ('evaporative', 'Evap')];
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
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRefrigerantSelector(ZaftoColors colors) {
    final refs = [('r410a', 'R-410A'), ('r22', 'R-22'), ('r134a', 'R-134a')];
    return Row(
      children: refs.map((r) {
        final selected = _refrigerant == r.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _refrigerant = r.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: r != refs.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_actualTd == null) return const SizedBox.shrink();

    final isNormal = _status == 'NORMAL';
    final isHigh = (_actualTd ?? 0) > (_targetTd ?? 30);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_actualTd?.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Condenser TD (Split)', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isNormal ? Colors.green : (isHigh ? Colors.red : Colors.orange), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Target', '${_targetTd?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Deviation', '${_deviation?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Cond. Temp', '${_condensingTemp.toStringAsFixed(0)}°F')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isHigh ? Colors.red.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isNormal ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isNormal ? Colors.green : (isHigh ? Colors.red : Colors.orange), size: 16),
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
