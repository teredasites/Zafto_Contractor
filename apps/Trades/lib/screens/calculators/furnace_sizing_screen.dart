import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Furnace Sizing Calculator - Design System v2.6
/// Gas furnace BTU input/output sizing
class FurnaceSizingScreen extends ConsumerStatefulWidget {
  const FurnaceSizingScreen({super.key});
  @override
  ConsumerState<FurnaceSizingScreen> createState() => _FurnaceSizingScreenState();
}

class _FurnaceSizingScreenState extends ConsumerState<FurnaceSizingScreen> {
  double _heatLossBtu = 60000;
  double _efficiency = 95;
  String _furnaceType = 'twostage';
  String _fuelType = 'naturalgas';

  double? _outputRequired;
  double? _inputRequired;
  String? _recommendedSize;
  double? _cfmRequired;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Output = Heat loss (what house needs)
    final outputRequired = _heatLossBtu;

    // Input = Output / Efficiency
    final inputRequired = outputRequired / (_efficiency / 100);

    // Round to standard furnace sizes
    double nominalInput;
    String recommendedSize;
    if (inputRequired <= 45000) {
      nominalInput = 40000;
      recommendedSize = '40,000 BTU Input';
    } else if (inputRequired <= 55000) {
      nominalInput = 50000;
      recommendedSize = '50,000 BTU Input';
    } else if (inputRequired <= 65000) {
      nominalInput = 60000;
      recommendedSize = '60,000 BTU Input';
    } else if (inputRequired <= 75000) {
      nominalInput = 70000;
      recommendedSize = '70,000 BTU Input';
    } else if (inputRequired <= 85000) {
      nominalInput = 80000;
      recommendedSize = '80,000 BTU Input';
    } else if (inputRequired <= 95000) {
      nominalInput = 90000;
      recommendedSize = '90,000 BTU Input';
    } else if (inputRequired <= 105000) {
      nominalInput = 100000;
      recommendedSize = '100,000 BTU Input';
    } else if (inputRequired <= 115000) {
      nominalInput = 110000;
      recommendedSize = '110,000 BTU Input';
    } else {
      nominalInput = 120000;
      recommendedSize = '120,000 BTU Input';
    }

    // CFM (roughly 1 CFM per 30 BTU output for 50°F rise)
    final cfm = outputRequired / 30;

    String recommendation;
    if (_furnaceType == 'singlestage') {
      recommendation = 'Single-stage furnace. Simple and reliable, but may cycle frequently.';
    } else if (_furnaceType == 'twostage') {
      recommendation = 'Two-stage furnace recommended. Better comfort and efficiency at part load.';
    } else {
      recommendation = 'Modulating furnace provides best comfort. Pairs well with variable speed blower.';
    }

    if (_efficiency >= 95) {
      recommendation += ' High-efficiency condensing furnace requires condensate drain.';
    }

    setState(() {
      _outputRequired = outputRequired;
      _inputRequired = inputRequired;
      _recommendedSize = recommendedSize;
      _cfmRequired = cfm;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _heatLossBtu = 60000;
      _efficiency = 95;
      _furnaceType = 'twostage';
      _fuelType = 'naturalgas';
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
        title: Text('Furnace Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'HEAT LOSS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Design Heat Loss', value: _heatLossBtu, min: 20000, max: 150000, unit: ' BTU/hr', onChanged: (v) { setState(() => _heatLossBtu = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FURNACE TYPE'),
              const SizedBox(height: 12),
              _buildFurnaceTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'AFUE Efficiency', value: _efficiency, min: 80, max: 98, unit: '%', onChanged: (v) { setState(() => _efficiency = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Fuel Type', options: const ['Natural Gas', 'Propane'], selectedIndex: _fuelType == 'naturalgas' ? 0 : 1, onChanged: (i) { setState(() => _fuelType = i == 0 ? 'naturalgas' : 'propane'); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FURNACE SIZING'),
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
        Icon(LucideIcons.flame, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Furnace OUTPUT must meet heat loss. INPUT = OUTPUT ÷ AFUE. 95%+ is condensing.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFurnaceTypeSelector(ZaftoColors colors) {
    final options = [
      ('singlestage', 'Single Stage', '80-95% AFUE'),
      ('twostage', 'Two Stage', '92-97% AFUE'),
      ('modulating', 'Modulating', '95-98% AFUE'),
    ];
    return Row(
      children: options.map((o) {
        final selected = _furnaceType == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _furnaceType = o.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: o != options.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Text(o.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(o.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 10)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    final displayValue = unit == ' BTU/hr' ? '${(value / 1000).toStringAsFixed(0)}k$unit' : '${value.toStringAsFixed(0)}$unit';
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
    if (_inputRequired == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text(_recommendedSize ?? '', style: TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.w700)),
              Text('Recommended Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Output Needed', '${(_outputRequired! / 1000).toStringAsFixed(0)}k BTU')),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Input Required', '${(_inputRequired! / 1000).toStringAsFixed(0)}k BTU')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'AFUE', '${_efficiency.toStringAsFixed(0)}%')),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Airflow', '${_cfmRequired?.toStringAsFixed(0)} CFM')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.lightbulb, color: colors.accentWarning, size: 16),
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
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
