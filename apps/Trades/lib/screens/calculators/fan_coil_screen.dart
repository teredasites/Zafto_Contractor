import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Fan Coil Unit Calculator - Design System v2.6
/// 2-pipe and 4-pipe fan coil unit sizing
class FanCoilScreen extends ConsumerStatefulWidget {
  const FanCoilScreen({super.key});
  @override
  ConsumerState<FanCoilScreen> createState() => _FanCoilScreenState();
}

class _FanCoilScreenState extends ConsumerState<FanCoilScreen> {
  double _coolingLoad = 12000; // BTU/h
  double _heatingLoad = 15000;
  double _roomCfm = 400;
  String _pipeConfig = '4_pipe';
  String _mountType = 'horizontal';
  double _chwSupplyTemp = 45;
  double _hwSupplyTemp = 140;

  double? _coolingGpm;
  double? _heatingGpm;
  String? _nominalSize;
  double? _sensibleCapacity;
  double? _totalCapacity;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Coil sizing
    // Cooling: GPM = BTU / (500 × ΔT)
    // Typical CHW: 10°F rise across coil
    final coolingDeltaT = 10.0;
    final coolingGpm = _coolingLoad / (500 * coolingDeltaT);

    // Heating: GPM = BTU / (500 × ΔT)
    // Typical HW: 20°F drop across coil
    final heatingDeltaT = 20.0;
    final heatingGpm = _heatingLoad / (500 * heatingDeltaT);

    // Sensible heat ratio (assume 0.75 typical)
    final sensibleCapacity = _coolingLoad * 0.75;
    final totalCapacity = _coolingLoad.toDouble();

    // Nominal size based on CFM
    String nominalSize;
    if (_roomCfm <= 200) {
      nominalSize = '200 CFM';
    } else if (_roomCfm <= 300) {
      nominalSize = '300 CFM';
    } else if (_roomCfm <= 400) {
      nominalSize = '400 CFM';
    } else if (_roomCfm <= 600) {
      nominalSize = '600 CFM';
    } else if (_roomCfm <= 800) {
      nominalSize = '800 CFM';
    } else if (_roomCfm <= 1000) {
      nominalSize = '1000 CFM';
    } else {
      nominalSize = '1200+ CFM';
    }

    String recommendation;
    if (_pipeConfig == '4_pipe') {
      recommendation = '4-pipe system: Simultaneous heating and cooling. Separate CHW and HW coils.';
    } else if (_pipeConfig == '2_pipe') {
      recommendation = '2-pipe system: Changeover between heating and cooling. Single coil.';
    } else {
      recommendation = '2-pipe with electric heat: CHW cooling with electric reheat backup.';
    }

    if (_mountType == 'horizontal') {
      recommendation += ' Horizontal mount: Above ceiling, concealed. Drain pan required.';
    } else if (_mountType == 'vertical') {
      recommendation += ' Vertical mount: Floor or closet installation. Check clearances.';
    } else {
      recommendation += ' Console mount: Under window, exposed. No drain pump needed.';
    }

    if (coolingGpm < 0.5) {
      recommendation += ' Low CHW flow - verify coil selection for low flow operation.';
    }

    setState(() {
      _coolingGpm = coolingGpm;
      _heatingGpm = heatingGpm;
      _nominalSize = nominalSize;
      _sensibleCapacity = sensibleCapacity;
      _totalCapacity = totalCapacity;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coolingLoad = 12000;
      _heatingLoad = 15000;
      _roomCfm = 400;
      _pipeConfig = '4_pipe';
      _mountType = 'horizontal';
      _chwSupplyTemp = 45;
      _hwSupplyTemp = 140;
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
        title: Text('Fan Coil Unit', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOM LOAD'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Cooling Load', value: _coolingLoad, min: 3000, max: 48000, unit: ' BTU', displayK: true, onChanged: (v) { setState(() => _coolingLoad = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Heating Load', value: _heatingLoad, min: 3000, max: 60000, unit: ' BTU', displayK: true, onChanged: (v) { setState(() => _heatingLoad = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Room CFM', value: _roomCfm, min: 100, max: 1500, unit: ' CFM', onChanged: (v) { setState(() => _roomCfm = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONFIGURATION'),
              const SizedBox(height: 12),
              _buildPipeConfigSelector(colors),
              const SizedBox(height: 12),
              _buildMountTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WATER TEMPS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'CHW Supply', _chwSupplyTemp, 40, 55, '°F', (v) { setState(() => _chwSupplyTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'HW Supply', _hwSupplyTemp, 100, 180, '°F', (v) { setState(() => _hwSupplyTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FCU SELECTION'),
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
        Icon(LucideIcons.fan, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Fan coil units: 4-pipe for simultaneous H/C. Size coil GPM for load at design conditions.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildPipeConfigSelector(ZaftoColors colors) {
    final configs = [
      ('4_pipe', '4-Pipe'),
      ('2_pipe', '2-Pipe'),
      ('2_pipe_elec', '2-Pipe + Elec'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pipe Configuration', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: configs.map((c) {
            final selected = _pipeConfig == c.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _pipeConfig = c.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: c != configs.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(c.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMountTypeSelector(ZaftoColors colors) {
    final mounts = [
      ('horizontal', 'Horizontal'),
      ('vertical', 'Vertical'),
      ('console', 'Console'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mount Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: mounts.map((m) {
            final selected = _mountType == m.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _mountType = m.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: m != mounts.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_nominalSize == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_nominalSize!, style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
          Text('Nominal Unit Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.snowflake, color: Colors.blue, size: 18),
                  const SizedBox(height: 4),
                  Text('Cooling', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  Text('${_coolingGpm?.toStringAsFixed(2)} GPM', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.flame, color: Colors.orange, size: 18),
                  const SizedBox(height: 4),
                  Text('Heating', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  Text('${_heatingGpm?.toStringAsFixed(2)} GPM', style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Sensible', '${(_sensibleCapacity! / 1000).toStringAsFixed(1)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total', '${(_totalCapacity! / 1000).toStringAsFixed(1)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'SHR', '0.75')),
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
