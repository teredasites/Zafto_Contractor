import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Audio/Video Wire Calculator - Design System v2.6
/// Speaker wire and AV cable sizing
class AudioVideoWireScreen extends ConsumerStatefulWidget {
  const AudioVideoWireScreen({super.key});
  @override
  ConsumerState<AudioVideoWireScreen> createState() => _AudioVideoWireScreenState();
}

class _AudioVideoWireScreenState extends ConsumerState<AudioVideoWireScreen> {
  String _wireType = 'speaker';
  double _runLength = 50;
  int _speakerImpedance = 8;
  int _amplifierPower = 100;

  String? _recommendedGauge;
  double? _resistanceLoss;
  double? _powerLossPercent;
  String? _recommendation;
  bool? _isOptimal;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    if (_wireType == 'speaker') {
      _calculateSpeakerWire();
    } else {
      _calculateVideoWire();
    }
  }

  void _calculateSpeakerWire() {
    // Speaker wire sizing based on damping factor
    // Target: Wire resistance < 5% of speaker impedance
    final maxResistance = _speakerImpedance * 0.05;
    final runLengthFt = _runLength;

    // Resistance per 1000ft (ohms)
    final wireGauges = {
      '18 AWG': 6.385,
      '16 AWG': 4.016,
      '14 AWG': 2.525,
      '12 AWG': 1.588,
      '10 AWG': 0.999,
    };

    String selectedGauge = '18 AWG';
    double wireResistance = 0;

    for (final entry in wireGauges.entries) {
      wireResistance = (entry.value * runLengthFt * 2) / 1000;
      if (wireResistance <= maxResistance) {
        selectedGauge = entry.key;
        break;
      }
    }

    final powerLoss = (wireResistance / (_speakerImpedance + wireResistance)) * 100;
    final isOptimal = wireResistance <= maxResistance;

    String recommendation;
    if (powerLoss < 2) {
      recommendation = 'Excellent - minimal power loss';
    } else if (powerLoss < 5) {
      recommendation = 'Good - acceptable for most applications';
    } else {
      recommendation = 'Consider larger gauge to reduce loss';
    }

    setState(() {
      _recommendedGauge = selectedGauge;
      _resistanceLoss = wireResistance;
      _powerLossPercent = powerLoss;
      _recommendation = recommendation;
      _isOptimal = isOptimal;
    });
  }

  void _calculateVideoWire() {
    // HDMI/Coax recommendations by distance
    String gauge;
    String recommendation;
    bool optimal;

    if (_runLength <= 25) {
      gauge = 'Standard HDMI';
      recommendation = 'Passive HDMI cable sufficient';
      optimal = true;
    } else if (_runLength <= 50) {
      gauge = 'Active HDMI';
      recommendation = 'Use active or fiber HDMI';
      optimal = true;
    } else if (_runLength <= 100) {
      gauge = 'Fiber HDMI';
      recommendation = 'Fiber optic HDMI required';
      optimal = true;
    } else {
      gauge = 'HDBaseT/SDI';
      recommendation = 'Use HDBaseT extender or SDI';
      optimal = false;
    }

    setState(() {
      _recommendedGauge = gauge;
      _resistanceLoss = null;
      _powerLossPercent = null;
      _recommendation = recommendation;
      _isOptimal = optimal;
    });
  }

  void _reset() {
    setState(() {
      _wireType = 'speaker';
      _runLength = 50;
      _speakerImpedance = 8;
      _amplifierPower = 100;
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
        title: Text('Audio/Video Wire', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'WIRE TYPE'),
              const SizedBox(height: 12),
              _buildWireTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PARAMETERS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Run Length', value: _runLength, min: 10, max: 200, unit: ' ft', onChanged: (v) { setState(() => _runLength = v); _calculate(); }),
              if (_wireType == 'speaker') ...[
                const SizedBox(height: 12),
                _buildSegmentedToggle(colors, label: 'Speaker Impedance', options: const ['4Ω', '6Ω', '8Ω', '16Ω'], selectedIndex: [4, 6, 8, 16].indexOf(_speakerImpedance), onChanged: (i) { setState(() => _speakerImpedance = [4, 6, 8, 16][i]); _calculate(); }),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Amplifier Power', value: _amplifierPower.toDouble(), min: 10, max: 500, unit: ' W', onChanged: (v) { setState(() => _amplifierPower = v.round()); _calculate(); }),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'RECOMMENDATION'),
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
        Icon(LucideIcons.speaker, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size speaker wire for <5% power loss. Video cables have fixed distance limits.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildWireTypeSelector(ZaftoColors colors) {
    final types = [
      ('speaker', 'Speaker Wire', LucideIcons.speaker),
      ('hdmi', 'HDMI/Video', LucideIcons.monitor),
    ];
    return Row(
      children: types.map((t) {
        final selected = _wireType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _wireType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Icon(t.$3, color: selected ? Colors.white : colors.textSecondary, size: 24),
                const SizedBox(height: 8),
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
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
            child: Text('${value.round()}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
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
    if (_recommendedGauge == null) return const SizedBox.shrink();
    final optimal = _isOptimal ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(optimal ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: optimal ? colors.accentPositive : colors.accentWarning, size: 24),
            const SizedBox(width: 8),
            Text(optimal ? 'OPTIMAL' : 'REVIEW', style: TextStyle(color: optimal ? colors.accentPositive : colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          Text(_recommendedGauge!, style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
          Text('Recommended', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          if (_wireType == 'speaker' && _resistanceLoss != null) ...[
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _buildResultItem(colors, 'Wire Resistance', '${_resistanceLoss!.toStringAsFixed(3)} Ω')),
              Container(width: 1, height: 40, color: colors.borderDefault),
              Expanded(child: _buildResultItem(colors, 'Power Loss', '${_powerLossPercent?.toStringAsFixed(1)}%')),
            ]),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
