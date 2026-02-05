import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// HVAC Capacitor Sizing Calculator - Design System v2.6
/// Run and start capacitor selection for motors
class CapacitorSizingScreen extends ConsumerStatefulWidget {
  const CapacitorSizingScreen({super.key});
  @override
  ConsumerState<CapacitorSizingScreen> createState() => _CapacitorSizingScreenState();
}

class _CapacitorSizingScreenState extends ConsumerState<CapacitorSizingScreen> {
  String _motorType = 'compressor';
  double _motorHp = 3;
  double _voltage = 230;
  double _rla = 15;
  String _capacitorType = 'run';
  bool _isDualCapacitor = false;

  double? _calculatedMfd;
  String? _recommendedCapacitor;
  double? _voltagRating;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    double calculatedMfd;
    String recommendedCapacitor;
    double voltageRating;
    String recommendation;

    // Voltage rating should be at least 1.5x line voltage for run caps
    // 2x for start caps due to back EMF
    if (_capacitorType == 'run') {
      voltageRating = _voltage <= 240 ? 370 : 440;
    } else {
      voltageRating = _voltage <= 240 ? 330 : 440;
    }

    if (_capacitorType == 'run') {
      // Run capacitor sizing formulas vary by application
      // General rule: 1.5 to 2.5 MFD per HP for compressors
      // Fan motors: typically 2-10 MFD depending on size

      if (_motorType == 'compressor') {
        // Compressor run caps: typically 30-50 MFD for residential
        calculatedMfd = _motorHp * 12; // Rough estimate
        if (calculatedMfd < 20) calculatedMfd = 20;
        if (calculatedMfd > 60) calculatedMfd = 60;
      } else if (_motorType == 'condenser_fan') {
        // Condenser fan motors: typically 3-10 MFD
        calculatedMfd = _motorHp * 8;
        if (calculatedMfd < 3) calculatedMfd = 3;
        if (calculatedMfd > 10) calculatedMfd = 10;
      } else {
        // Blower motors: typically 5-15 MFD
        calculatedMfd = _motorHp * 10;
        if (calculatedMfd < 5) calculatedMfd = 5;
        if (calculatedMfd > 15) calculatedMfd = 15;
      }

      // Match to common sizes
      final commonSizes = [3, 4, 5, 6, 7.5, 10, 12.5, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60];
      calculatedMfd = commonSizes.firstWhere((s) => s >= calculatedMfd, orElse: () => 60).toDouble();

      if (_isDualCapacitor) {
        recommendedCapacitor = '${calculatedMfd.toStringAsFixed(0)}+5 MFD Dual Run';
      } else {
        recommendedCapacitor = '${calculatedMfd.toStringAsFixed(0)} MFD Run';
      }

      recommendation = 'Run capacitor stays in circuit continuously. Replace with same MFD or within 10%. Voltage can be higher but not lower.';

    } else {
      // Start capacitor sizing
      // Much larger than run caps, provides starting torque
      // Typical: 88-108, 108-130, 130-156, 145-175, 189-227, 233-280, 270-324, 340-408, 430-516 MFD

      if (_motorType == 'compressor') {
        calculatedMfd = _rla * 10; // Very rough starting point
        if (calculatedMfd < 88) calculatedMfd = 88;
        if (calculatedMfd > 516) calculatedMfd = 516;
      } else {
        calculatedMfd = _motorHp * 40;
        if (calculatedMfd < 88) calculatedMfd = 88;
        if (calculatedMfd > 324) calculatedMfd = 324;
      }

      // Match to common start cap ranges
      String rangeStr;
      if (calculatedMfd <= 108) { rangeStr = '88-108'; calculatedMfd = 98; }
      else if (calculatedMfd <= 130) { rangeStr = '108-130'; calculatedMfd = 119; }
      else if (calculatedMfd <= 156) { rangeStr = '130-156'; calculatedMfd = 143; }
      else if (calculatedMfd <= 175) { rangeStr = '145-175'; calculatedMfd = 160; }
      else if (calculatedMfd <= 227) { rangeStr = '189-227'; calculatedMfd = 208; }
      else if (calculatedMfd <= 280) { rangeStr = '233-280'; calculatedMfd = 256; }
      else if (calculatedMfd <= 324) { rangeStr = '270-324'; calculatedMfd = 297; }
      else if (calculatedMfd <= 408) { rangeStr = '340-408'; calculatedMfd = 374; }
      else { rangeStr = '430-516'; calculatedMfd = 473; }

      recommendedCapacitor = '$rangeStr MFD Start';
      recommendation = 'Start capacitor cycles out via relay. Must use potential relay or hard start kit. Replace with same range or verify compatibility.';
    }

    // Motor-specific notes
    if (_motorType == 'compressor' && _capacitorType == 'start') {
      recommendation += ' Hard start kit may be needed for older compressors or high ambient conditions.';
    }

    setState(() {
      _calculatedMfd = calculatedMfd;
      _recommendedCapacitor = recommendedCapacitor;
      _voltagRating = voltageRating;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _motorType = 'compressor';
      _motorHp = 3;
      _voltage = 230;
      _rla = 15;
      _capacitorType = 'run';
      _isDualCapacitor = false;
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
        title: Text('Capacitor Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MOTOR'),
              const SizedBox(height: 12),
              _buildMotorTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Motor HP', value: _motorHp, min: 0.25, max: 10, unit: ' HP', decimals: 2, onChanged: (v) { setState(() => _motorHp = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Voltage', value: _voltage, min: 115, max: 460, unit: 'V', onChanged: (v) { setState(() => _voltage = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'RLA (Rated Load Amps)', value: _rla, min: 1, max: 50, unit: 'A', onChanged: (v) { setState(() => _rla = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CAPACITOR TYPE'),
              const SizedBox(height: 12),
              _buildCapacitorTypeSelector(colors),
              if (_capacitorType == 'run') ...[
                const SizedBox(height: 12),
                _buildCheckboxRow(colors, 'Dual Run Capacitor (compressor + fan)', _isDualCapacitor, (v) { setState(() => _isDualCapacitor = v); _calculate(); }),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'CAPACITOR SELECTION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildCapacitorTable(colors),
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
        Icon(LucideIcons.battery, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Run caps: continuous duty, exact MFD match. Start caps: intermittent duty, can use same or higher MFD range.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMotorTypeSelector(ZaftoColors colors) {
    final types = [
      ('compressor', 'Compressor'),
      ('condenser_fan', 'Condenser Fan'),
      ('blower', 'Blower Motor'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _motorType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _motorType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCapacitorTypeSelector(ZaftoColors colors) {
    final types = [
      ('run', 'Run Capacitor', 'Continuous duty, oil-filled'),
      ('start', 'Start Capacitor', 'Intermittent, electrolytic'),
    ];
    return Column(
      children: types.map((t) {
        final selected = _capacitorType == t.$1;
        return GestureDetector(
          onTap: () { setState(() => _capacitorType = t.$1); _calculate(); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Row(children: [
              Icon(selected ? LucideIcons.checkCircle : LucideIcons.circle, color: selected ? Colors.white : colors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 12)),
              ])),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderDefault, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_recommendedCapacitor == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_calculatedMfd?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('MFD (microfarads)', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text(_recommendedCapacitor ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Min Voltage', '${_voltagRating?.toStringAsFixed(0)} VAC')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Type', _capacitorType == 'run' ? 'Oil-Filled' : 'Electrolytic')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Shape', _capacitorType == 'run' ? 'Oval/Round' : 'Cylindrical')),
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

  Widget _buildCapacitorTable(ZaftoColors colors) {
    final data = _capacitorType == 'run'
        ? [('Condenser Fan', '3-10 MFD'), ('Blower Motor', '5-15 MFD'), ('Compressor', '30-60 MFD'), ('Dual Run', '35-60+5 MFD')]
        : [('88-108 MFD', '~1/4-1/3 HP'), ('130-156 MFD', '~1/2 HP'), ('189-227 MFD', '~1 HP'), ('270-324 MFD', '~2-3 HP')];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_capacitorType == 'run' ? 'COMMON RUN CAPACITORS' : 'COMMON START CAPACITORS', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...data.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(d.$1, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              Text(d.$2, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
