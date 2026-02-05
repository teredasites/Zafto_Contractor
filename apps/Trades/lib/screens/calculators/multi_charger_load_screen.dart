import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Multi-Charger Load Calculator - Design System v2.6
/// EV load management and power sharing calculations
class MultiChargerLoadScreen extends ConsumerStatefulWidget {
  const MultiChargerLoadScreen({super.key});
  @override
  ConsumerState<MultiChargerLoadScreen> createState() => _MultiChargerLoadScreenState();
}

class _MultiChargerLoadScreenState extends ConsumerState<MultiChargerLoadScreen> {
  int _chargerCount = 4;
  double _chargerKw = 7.7;
  double _availableCapacity = 50;
  String _managementType = 'static';
  double _diversityFactor = 0.7;

  double? _totalConnectedLoad;
  double? _managedLoad;
  double? _perChargerOutput;
  double? _utilization;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Total connected load (all chargers at full power)
    final totalConnected = _chargerCount * _chargerKw;

    double managedLoad;
    double perCharger;

    if (_managementType == 'static') {
      // Static load sharing - divide available evenly
      perCharger = _availableCapacity / _chargerCount;
      if (perCharger > _chargerKw) perCharger = _chargerKw;
      managedLoad = perCharger * _chargerCount;
    } else if (_managementType == 'dynamic') {
      // Dynamic load management with diversity factor
      managedLoad = totalConnected * _diversityFactor;
      if (managedLoad > _availableCapacity) managedLoad = _availableCapacity;
      perCharger = managedLoad / _chargerCount;
    } else {
      // First-come-first-served (sequential)
      final fullChargers = (_availableCapacity / _chargerKw).floor();
      final remainingKw = _availableCapacity - (fullChargers * _chargerKw);
      if (fullChargers >= _chargerCount) {
        managedLoad = _chargerCount * _chargerKw;
        perCharger = _chargerKw;
      } else {
        managedLoad = (fullChargers * _chargerKw) + remainingKw;
        perCharger = managedLoad / _chargerCount; // Average
      }
    }

    final utilization = (managedLoad / _availableCapacity) * 100;

    String recommendation;
    if (totalConnected <= _availableCapacity) {
      recommendation = 'Available capacity supports all chargers at full power. Load management optional.';
    } else if (perCharger >= 6) {
      recommendation = 'Good per-charger output. Most EVs will charge adequately overnight.';
    } else if (perCharger >= 3.3) {
      recommendation = 'Reduced charging speed. Acceptable for overnight charging, may be slow for daytime top-ups.';
    } else {
      recommendation = 'Very limited per-charger power. Consider adding capacity or reducing charger count.';
    }

    if (_managementType == 'dynamic') {
      recommendation += ' Dynamic management requires smart EVSE with communication capability.';
    }

    setState(() {
      _totalConnectedLoad = totalConnected;
      _managedLoad = managedLoad;
      _perChargerOutput = perCharger;
      _utilization = utilization;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _chargerCount = 4;
      _chargerKw = 7.7;
      _availableCapacity = 50;
      _managementType = 'static';
      _diversityFactor = 0.7;
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
        title: Text('Multi-Charger Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CHARGER CONFIGURATION'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Number of Chargers', value: _chargerCount.toDouble(), min: 2, max: 20, unit: '', isInt: true, onChanged: (v) { setState(() => _chargerCount = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Charger Rating', options: const ['3.3kW', '7.7kW', '11kW', '19.2kW'], selectedIndex: [3.3, 7.7, 11.0, 19.2].indexOf(_chargerKw), onChanged: (i) { setState(() => _chargerKw = [3.3, 7.7, 11.0, 19.2][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AVAILABLE CAPACITY'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Available kW', value: _availableCapacity, min: 10, max: 200, unit: ' kW', onChanged: (v) { setState(() => _availableCapacity = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD MANAGEMENT'),
              const SizedBox(height: 12),
              _buildManagementSelector(colors),
              if (_managementType == 'dynamic') ...[
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Diversity Factor', value: _diversityFactor, min: 0.4, max: 1.0, unit: '', decimals: 2, onChanged: (v) { setState(() => _diversityFactor = v); _calculate(); }),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'LOAD ANALYSIS'),
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
        Icon(LucideIcons.share2, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Calculate load sharing for multiple EV chargers. Balance charger count against available electrical capacity.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(isInt ? '${value.round()}$unit' : (decimals > 0 ? '${value.toStringAsFixed(decimals)}$unit' : '${value.round()}$unit'), style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementSelector(ZaftoColors colors) {
    final options = [
      ('static', 'Static', 'Equal power split'),
      ('dynamic', 'Dynamic', 'Smart load sharing'),
      ('sequential', 'Sequential', 'First-come priority'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Management Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: options.map((o) {
            final selected = _managementType == o.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _managementType = o.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: o != options.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Column(children: [
                    Text(o.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(o.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 9)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_managedLoad == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_perChargerOutput?.toStringAsFixed(1)} kW', style: TextStyle(color: colors.textPrimary, fontSize: 42, fontWeight: FontWeight.w700)),
          Text('Per Charger Output', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Total Connected', '${_totalConnectedLoad?.toStringAsFixed(0)} kW')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Managed Load', '${_managedLoad?.toStringAsFixed(1)} kW')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Utilization', '${_utilization?.toStringAsFixed(0)}%')),
          ]),
          const SizedBox(height: 16),
          _buildCapacityBar(colors),
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

  Widget _buildCapacityBar(ZaftoColors colors) {
    final connectedRatio = (_totalConnectedLoad ?? 0) / (_availableCapacity > 0 ? _availableCapacity : 1);
    final managedRatio = (_managedLoad ?? 0) / (_availableCapacity > 0 ? _availableCapacity : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Capacity Usage', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          Text('${_availableCapacity.toStringAsFixed(0)} kW available', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(height: 12, decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(
              widthFactor: connectedRatio.clamp(0, 1),
              child: Container(height: 12, decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6))),
            ),
            FractionallySizedBox(
              widthFactor: managedRatio.clamp(0, 1),
              child: Container(height: 12, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(6))),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text('Managed', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
          const SizedBox(width: 12),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text('Full load (unmanaged)', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
        ]),
      ],
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
