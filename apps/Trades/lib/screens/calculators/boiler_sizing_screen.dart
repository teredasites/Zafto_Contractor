import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Boiler Sizing Calculator - Design System v2.6
/// Hot water and steam boiler BTU sizing
class BoilerSizingScreen extends ConsumerStatefulWidget {
  const BoilerSizingScreen({super.key});
  @override
  ConsumerState<BoilerSizingScreen> createState() => _BoilerSizingScreenState();
}

class _BoilerSizingScreenState extends ConsumerState<BoilerSizingScreen> {
  double _heatLossBtu = 80000;
  double _dhwLoad = 20000;
  double _efficiency = 90;
  String _boilerType = 'modcon';
  String _application = 'heating';
  double _deltaT = 20;

  double? _totalLoad;
  double? _inputRequired;
  double? _outputRequired;
  double? _gpmFlow;
  String? _recommendedSize;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Total load
    double totalOutput;
    if (_application == 'heating') {
      totalOutput = _heatLossBtu;
    } else if (_application == 'combi') {
      totalOutput = _heatLossBtu + _dhwLoad;
    } else {
      totalOutput = _dhwLoad;
    }

    // Input = Output / Efficiency
    final inputRequired = totalOutput / (_efficiency / 100);

    // GPM flow rate: GPM = BTU / (500 × ΔT)
    final gpm = totalOutput / (500 * _deltaT);

    // Round to standard boiler sizes
    double nominalInput;
    String recommendedSize;
    if (inputRequired <= 60000) {
      nominalInput = 50000;
      recommendedSize = '50,000 BTU';
    } else if (inputRequired <= 80000) {
      nominalInput = 75000;
      recommendedSize = '75,000 BTU';
    } else if (inputRequired <= 110000) {
      nominalInput = 100000;
      recommendedSize = '100,000 BTU';
    } else if (inputRequired <= 135000) {
      nominalInput = 125000;
      recommendedSize = '125,000 BTU';
    } else if (inputRequired <= 165000) {
      nominalInput = 150000;
      recommendedSize = '150,000 BTU';
    } else if (inputRequired <= 210000) {
      nominalInput = 200000;
      recommendedSize = '200,000 BTU';
    } else if (inputRequired <= 280000) {
      nominalInput = 250000;
      recommendedSize = '250,000 BTU';
    } else {
      nominalInput = ((inputRequired / 50000).ceil() * 50000).toDouble();
      recommendedSize = '${(nominalInput / 1000).toStringAsFixed(0)}k BTU';
    }

    String recommendation;
    if (_boilerType == 'modcon') {
      recommendation = 'Mod-con (modulating condensing) boiler. Requires condensate drain. Best efficiency at low return temps.';
    } else if (_boilerType == 'standard') {
      recommendation = 'Standard efficiency boiler. No condensate handling needed. Higher operating cost.';
    } else {
      recommendation = 'Cast iron boiler. Very durable, good for steam or high-mass systems.';
    }

    if (_application == 'combi') {
      recommendation += ' Combi includes tankless DHW. Verify DHW flow rate meets demand.';
    }

    if (gpm > 20) {
      recommendation += ' High flow rate - verify pump sizing.';
    }

    setState(() {
      _totalLoad = totalOutput;
      _inputRequired = inputRequired;
      _outputRequired = totalOutput;
      _gpmFlow = gpm;
      _recommendedSize = recommendedSize;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _heatLossBtu = 80000;
      _dhwLoad = 20000;
      _efficiency = 90;
      _boilerType = 'modcon';
      _application = 'heating';
      _deltaT = 20;
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
        title: Text('Boiler Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSegmentedToggle(colors, label: '', options: const ['Heating Only', 'Combi (Heat+DHW)', 'DHW Only'], selectedIndex: ['heating', 'combi', 'dhw'].indexOf(_application), onChanged: (i) { setState(() => _application = ['heating', 'combi', 'dhw'][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD REQUIREMENTS'),
              const SizedBox(height: 12),
              if (_application != 'dhw')
                _buildSliderRow(colors, label: 'Space Heating Load', value: _heatLossBtu, min: 20000, max: 300000, unit: ' BTU/hr', onChanged: (v) { setState(() => _heatLossBtu = v); _calculate(); }),
              if (_application != 'dhw') const SizedBox(height: 12),
              if (_application != 'heating')
                _buildSliderRow(colors, label: 'DHW Load', value: _dhwLoad, min: 10000, max: 100000, unit: ' BTU/hr', onChanged: (v) { setState(() => _dhwLoad = v); _calculate(); }),
              if (_application != 'heating') const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Design ΔT', value: _deltaT, min: 10, max: 40, unit: '\u00B0F', onChanged: (v) { setState(() => _deltaT = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BOILER TYPE'),
              const SizedBox(height: 12),
              _buildBoilerTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'AFUE Efficiency', value: _efficiency, min: 80, max: 98, unit: '%', onChanged: (v) { setState(() => _efficiency = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'BOILER SIZING'),
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
        Expanded(child: Text('Size boiler to heat loss + DHW. Mod-con: 90-98% AFUE. Standard: 80-85% AFUE.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildBoilerTypeSelector(ZaftoColors colors) {
    final options = [
      ('modcon', 'Mod-Con', '90-98%'),
      ('standard', 'Standard', '80-85%'),
      ('castiron', 'Cast Iron', '82-86%'),
    ];
    return Row(
      children: options.map((o) {
        final selected = _boilerType == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _boilerType = o.$1); _calculate(); },
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
    return Container(
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
              Text(_recommendedSize ?? '', style: TextStyle(color: Colors.orange, fontSize: 22, fontWeight: FontWeight.w700)),
              Text('Recommended Boiler', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
            Expanded(child: _buildResultItem(colors, 'Flow Rate', '${_gpmFlow?.toStringAsFixed(1)} GPM')),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'AFUE', '${_efficiency.toStringAsFixed(0)}%')),
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
