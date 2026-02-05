import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Gas Pipe Sizing Calculator - Design System v2.6
/// Natural gas and propane pipe sizing per NFGC
class GasPipeSizingScreen extends ConsumerStatefulWidget {
  const GasPipeSizingScreen({super.key});
  @override
  ConsumerState<GasPipeSizingScreen> createState() => _GasPipeSizingScreenState();
}

class _GasPipeSizingScreenState extends ConsumerState<GasPipeSizingScreen> {
  double _totalBtu = 200000;
  double _pipeLength = 50;
  String _gasType = 'natural';
  String _pressureType = 'low';
  double _specificGravity = 0.60;
  double _inletPressure = 0.5; // WC for low pressure

  String? _pipeSize;
  double? _pressureDrop;
  double? _capacityCfh;
  String? _pipeMaterial;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Convert BTU to CFH (cubic feet per hour)
    // Natural gas: ~1,000 BTU per cubic foot
    // Propane: ~2,500 BTU per cubic foot
    final btuPerCf = _gasType == 'natural' ? 1000.0 : 2500.0;
    final cfhRequired = _totalBtu / btuPerCf;

    // Specific gravity adjustment
    // Natural gas ~0.60, propane ~1.52
    final sg = _gasType == 'natural' ? 0.60 : 1.52;

    // Pipe sizing tables from NFGC
    // Low pressure (< 2 PSI, typically 1/2 PSI WC)
    // Based on 0.5" WC pressure drop

    String pipeSize;
    double capacityCfh;

    // Simplified pipe capacity table for Schedule 40 steel pipe
    // At 50 ft length, 0.5" WC pressure drop, SG 0.60
    // Adjust for actual length using inverse square root relationship

    final lengthFactor = math.sqrt(50 / _pipeLength);

    // Base capacities at 50 ft
    final pipeCapacities = [
      ('1/2"', 20.0),
      ('3/4"', 52.0),
      ('1"', 98.0),
      ('1-1/4"', 199.0),
      ('1-1/2"', 310.0),
      ('2"', 619.0),
      ('2-1/2"', 938.0),
      ('3"', 1661.0),
    ];

    // Find smallest pipe that handles the load
    pipeSize = pipeCapacities.last.$1;
    capacityCfh = pipeCapacities.last.$2 * lengthFactor;

    for (final pipe in pipeCapacities) {
      final adjustedCapacity = pipe.$2 * lengthFactor * math.sqrt(0.60 / sg);
      if (adjustedCapacity >= cfhRequired) {
        pipeSize = pipe.$1;
        capacityCfh = adjustedCapacity;
        break;
      }
    }

    // Pressure drop (for low pressure systems, limited to 0.5" WC)
    final pressureDrop = _pressureType == 'low' ? 0.5 : 3.5;

    // Pipe material recommendation
    String pipeMaterial;
    if (_pressureType == 'low') {
      pipeMaterial = 'Black steel pipe, CSST, or approved PE for exterior';
    } else {
      pipeMaterial = 'Black steel pipe or approved CSST rated for pressure';
    }

    String recommendation;
    if (_gasType == 'natural') {
      recommendation = 'Natural gas: Verify inlet pressure from meter (typically 7" WC to 1/4 PSI). ';
    } else {
      recommendation = 'Propane: Higher specific gravity requires larger pipe. Verify regulator settings. ';
    }

    if (_pipeLength > 100) {
      recommendation += 'Long run - consider running larger main and branching. ';
    }

    if (cfhRequired > 500) {
      recommendation += 'High capacity - verify meter size adequate for load. ';
    }

    recommendation += 'All joints: Use yellow Teflon tape or approved pipe dope. Pressure test before use.';

    setState(() {
      _pipeSize = pipeSize;
      _pressureDrop = pressureDrop;
      _capacityCfh = capacityCfh;
      _pipeMaterial = pipeMaterial;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _totalBtu = 200000;
      _pipeLength = 50;
      _gasType = 'natural';
      _pressureType = 'low';
      _specificGravity = 0.60;
      _inletPressure = 0.5;
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
        title: Text('Gas Pipe Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'GAS TYPE'),
              const SizedBox(height: 12),
              _buildGasTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Pressure System', options: const ['Low (<2 PSI)', 'Medium (2-5 PSI)'], selectedIndex: _pressureType == 'low' ? 0 : 1, onChanged: (i) { setState(() => _pressureType = i == 0 ? 'low' : 'medium'); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD & PIPING'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total BTU Load', value: _totalBtu, min: 20000, max: 500000, unit: ' BTU', displayK: true, onChanged: (v) { setState(() => _totalBtu = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Pipe Length', value: _pipeLength, min: 10, max: 200, unit: ' ft', onChanged: (v) { setState(() => _pipeLength = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PIPE SIZE'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildCapacityTable(colors),
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
        Icon(LucideIcons.flame, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size gas pipe per NFGC tables. Natural gas ~1000 BTU/cf, propane ~2500 BTU/cf. Max 0.5" WC drop for low pressure.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildGasTypeSelector(ZaftoColors colors) {
    final types = [
      ('natural', 'Natural Gas', 'SG 0.60'),
      ('propane', 'Propane (LP)', 'SG 1.52'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _gasType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _gasType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 11)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool displayK = false, required ValueChanged<double> onChanged}) {
    final displayValue = displayK ? '${(value / 1000).toStringAsFixed(0)}k$unit' : '${value.toStringAsFixed(0)}$unit';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(displayValue, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_pipeSize == null) return const SizedBox.shrink();

    final cfhRequired = _totalBtu / (_gasType == 'natural' ? 1000.0 : 2500.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_pipeSize!, style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Minimum Pipe Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text('Schedule 40 Black Steel', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Required', '${cfhRequired.toStringAsFixed(0)} CFH')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Capacity', '${_capacityCfh?.toStringAsFixed(0)} CFH')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Max Drop', '${_pressureDrop}" WC')),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MATERIALS', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_pipeMaterial ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityTable(ZaftoColors colors) {
    final data = _gasType == 'natural'
        ? [('1/2"', '20'), ('3/4"', '52'), ('1"', '98'), ('1-1/4"', '199'), ('1-1/2"', '310'), ('2"', '619')]
        : [('1/2"', '13'), ('3/4"', '33'), ('1"', '62'), ('1-1/4"', '127'), ('1-1/2"', '198'), ('2"', '395')];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CAPACITY TABLE @ 50 FT (CFH)', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...data.map((d) {
            final isSelected = _pipeSize == d.$1;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(d.$1, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                Text('${d.$2} CFH', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              ]),
            );
          }),
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
