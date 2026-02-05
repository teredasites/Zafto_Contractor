import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Evaporator Temperature Differential Calculator - Design System v2.6
/// Diagnose evaporator coil performance via TD
class EvaporatorTdScreen extends ConsumerStatefulWidget {
  const EvaporatorTdScreen({super.key});
  @override
  ConsumerState<EvaporatorTdScreen> createState() => _EvaporatorTdScreenState();
}

class _EvaporatorTdScreenState extends ConsumerState<EvaporatorTdScreen> {
  double _returnAirTemp = 75;
  double _suctionSatTemp = 40;
  String _applicationType = 'comfort_cooling';
  String _coilType = 'dx';
  double _targetTd = 35;

  double? _actualTd;
  double? _deviation;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Evaporator TD = Return Air Temp - Saturated Suction Temp
    final actualTd = _returnAirTemp - _suctionSatTemp;

    // Target TD varies by application
    double targetTd;
    double minTd;
    double maxTd;

    switch (_applicationType) {
      case 'comfort_cooling':
        targetTd = 35;
        minTd = 30;
        maxTd = 40;
        break;
      case 'low_humidity':
        targetTd = 25;
        minTd = 20;
        maxTd = 30;
        break;
      case 'medium_temp_refrig':
        targetTd = 20;
        minTd = 15;
        maxTd = 25;
        break;
      case 'low_temp_refrig':
        targetTd = 15;
        minTd = 10;
        maxTd = 20;
        break;
      default:
        targetTd = 35;
        minTd = 30;
        maxTd = 40;
    }

    final deviation = actualTd - targetTd;

    String status;
    if (actualTd >= minTd && actualTd <= maxTd) {
      status = 'NORMAL';
    } else if (actualTd > maxTd) {
      status = 'HIGH TD';
    } else {
      status = 'LOW TD';
    }

    String recommendation;
    if (actualTd > maxTd) {
      recommendation = 'High TD indicates: Low refrigerant charge, restricted metering device, dirty evaporator coil, low airflow.';
    } else if (actualTd < minTd) {
      recommendation = 'Low TD indicates: High refrigerant charge, metering device flooding, high airflow, dirty condenser.';
    } else {
      recommendation = 'TD within normal range for this application. Coil operating properly.';
    }

    if (_coilType == 'dx') {
      recommendation += ' DX coil: Check superheat at coil outlet. Should be 8-12°F for TXV, 15-20°F for piston.';
    } else if (_coilType == 'chilled_water') {
      recommendation += ' Chilled water: Check supply water temp and flow rate.';
    }

    if (_applicationType == 'comfort_cooling') {
      recommendation += ' Comfort cooling TD of 35°F maximizes latent capacity for dehumidification.';
    }

    setState(() {
      _actualTd = actualTd;
      _targetTd = targetTd;
      _deviation = deviation;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _returnAirTemp = 75;
      _suctionSatTemp = 40;
      _applicationType = 'comfort_cooling';
      _coilType = 'dx';
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
        title: Text('Evaporator TD', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Return Air Temp', value: _returnAirTemp, min: 50, max: 100, unit: '°F', onChanged: (v) { setState(() => _returnAirTemp = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Sat. Suction Temp', value: _suctionSatTemp, min: 10, max: 60, unit: '°F', onChanged: (v) { setState(() => _suctionSatTemp = v); _calculate(); }),
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
        Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('TD = Return Air - Sat. Suction. Standard comfort cooling: 35°F TD. Higher TD = more dehumidification.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [
      ('comfort_cooling', 'Comfort'),
      ('low_humidity', 'Low RH'),
      ('medium_temp_refrig', 'Med Temp'),
      ('low_temp_refrig', 'Low Temp'),
    ];
    return Row(
      children: apps.map((a) {
        final selected = _applicationType == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _applicationType = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
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
    final types = [('dx', 'DX Coil'), ('chilled_water', 'Chilled Water')];
    return Row(
      children: types.map((t) {
        final selected = _coilType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _coilType = t.$1); _calculate(); },
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_actualTd?.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Evaporator TD', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isNormal ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Target', '${_targetTd.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Deviation', '${_deviation?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Sat Suct', '${_suctionSatTemp.toStringAsFixed(0)}°F')),
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
