import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Data Center Cooling Calculator - Design System v2.6
/// IT load cooling, PUE, and precision cooling requirements
class DataCenterCoolingScreen extends ConsumerStatefulWidget {
  const DataCenterCoolingScreen({super.key});
  @override
  ConsumerState<DataCenterCoolingScreen> createState() => _DataCenterCoolingScreenState();
}

class _DataCenterCoolingScreenState extends ConsumerState<DataCenterCoolingScreen> {
  double _itLoad = 100; // kW
  double _targetPue = 1.5;
  double _rackCount = 20;
  double _supplyTemp = 65; // degrees F (ASHRAE A1 range)
  String _coolingType = 'crac';
  String _redundancy = 'n_plus_1';

  double? _coolingLoad;
  double? _totalPower;
  double? _kWPerRack;
  double? _cfmRequired;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // IT load converts directly to cooling (1 kW IT = 3412 BTU/hr)
    final coolingBtu = _itLoad * 3412;
    final coolingTons = coolingBtu / 12000;

    // Total facility power based on PUE
    final totalPower = _itLoad * _targetPue;
    final coolingPower = totalPower - _itLoad;

    // Power per rack
    final kWPerRack = _itLoad / _rackCount;

    // Airflow required (using 15-20°F delta typical)
    final deltaT = 18.0; // degrees F
    final cfmRequired = (coolingBtu) / (1.08 * deltaT);

    String recommendation;
    recommendation = 'IT Load: ${_itLoad.toStringAsFixed(0)} kW = ${coolingTons.toStringAsFixed(1)} tons cooling. ';

    if (_targetPue <= 1.2) {
      recommendation += 'Aggressive PUE target. Requires free cooling, hot aisle containment.';
    } else if (_targetPue <= 1.5) {
      recommendation += 'Good PUE target. Achievable with economizer and containment.';
    } else {
      recommendation += 'PUE ${_targetPue.toStringAsFixed(2)}: Legacy efficiency. Modern facilities target 1.2-1.4.';
    }

    switch (_coolingType) {
      case 'crac':
        recommendation += ' CRAC units: Traditional raised floor. Size for ${(coolingTons * 1.2).toStringAsFixed(0)} tons with safety factor.';
        break;
      case 'crah':
        recommendation += ' CRAH (chilled water): Better efficiency than DX. Requires chilled water plant.';
        break;
      case 'inrow':
        recommendation += ' In-row cooling: Direct to rack. Best for high-density >10 kW/rack.';
        break;
      case 'rear_door':
        recommendation += ' Rear door heat exchanger: Neutral air. 20-35 kW/rack capable.';
        break;
    }

    if (kWPerRack > 15) {
      recommendation += ' HIGH DENSITY (${kWPerRack.toStringAsFixed(1)} kW/rack): Requires containment and supplemental cooling.';
    } else if (kWPerRack > 8) {
      recommendation += ' Medium density. Hot/cold aisle containment recommended.';
    } else {
      recommendation += ' Low density: Standard CRAC with raised floor adequate.';
    }

    switch (_redundancy) {
      case 'n':
        recommendation += ' N redundancy: No backup. Single point of failure.';
        break;
      case 'n_plus_1':
        recommendation += ' N+1: Standard redundancy. One backup unit.';
        break;
      case '2n':
        recommendation += ' 2N: Full redundancy. Two independent systems.';
        break;
    }

    // ASHRAE temperature compliance
    if (_supplyTemp < 64.4 || _supplyTemp > 80.6) {
      recommendation += ' Supply temp outside ASHRAE A1 recommended range (64-81°F).';
    }

    recommendation += ' Total facility power: ${totalPower.toStringAsFixed(0)} kW. Cooling power: ${coolingPower.toStringAsFixed(0)} kW.';

    setState(() {
      _coolingLoad = coolingTons;
      _totalPower = totalPower;
      _kWPerRack = kWPerRack;
      _cfmRequired = cfmRequired;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _itLoad = 100;
      _targetPue = 1.5;
      _rackCount = 20;
      _supplyTemp = 65;
      _coolingType = 'crac';
      _redundancy = 'n_plus_1';
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
        title: Text('Data Center', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COOLING SYSTEM'),
              const SizedBox(height: 12),
              _buildCoolingTypeSelector(colors),
              const SizedBox(height: 12),
              _buildRedundancySelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'IT LOAD & EFFICIENCY'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'IT Load', _itLoad, 10, 1000, ' kW', (v) { setState(() => _itLoad = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Target PUE', _targetPue, 1.1, 2.5, '', (v) { setState(() => _targetPue = v); _calculate(); }, decimals: 2)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LAYOUT'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Racks', _rackCount, 5, 100, '', (v) { setState(() => _rackCount = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Supply T', _supplyTemp, 55, 80, '°F', (v) { setState(() => _supplyTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'COOLING REQUIREMENTS'),
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
        Icon(LucideIcons.server, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('PUE = Total Power / IT Power. Industry avg 1.58, best <1.2. ASHRAE A1: 64-81°F supply. 1 kW IT = 3412 BTU/hr cooling.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCoolingTypeSelector(ZaftoColors colors) {
    final types = [('crac', 'CRAC'), ('crah', 'CRAH'), ('inrow', 'In-Row'), ('rear_door', 'Rear Door')];
    return Row(
      children: types.map((t) {
        final selected = _coolingType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _coolingType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
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
    );
  }

  Widget _buildRedundancySelector(ZaftoColors colors) {
    final levels = [('n', 'N'), ('n_plus_1', 'N+1'), ('2n', '2N')];
    return Row(
      children: levels.map((l) {
        final selected = _redundancy == l.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _redundancy = l.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: l != levels.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(l.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_coolingLoad == null) return const SizedBox.shrink();

    final densityOk = _kWPerRack! <= 10;
    final statusColor = densityOk ? Colors.green : (_kWPerRack! <= 15 ? Colors.orange : Colors.red);
    final status = densityOk ? 'STANDARD DENSITY' : (_kWPerRack! <= 15 ? 'MEDIUM DENSITY' : 'HIGH DENSITY');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_coolingLoad?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Tons Cooling Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('$status (${_kWPerRack?.toStringAsFixed(1)} kW/rack)', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('${_cfmRequired?.toStringAsFixed(0)} CFM', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
              Text('Airflow Required', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'IT Power', '${_itLoad.toStringAsFixed(0)} kW')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total Power', '${_totalPower?.toStringAsFixed(0)} kW')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'PUE', '${_targetPue.toStringAsFixed(2)}')),
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

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
