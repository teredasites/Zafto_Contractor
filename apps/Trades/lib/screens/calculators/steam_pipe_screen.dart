import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Steam Pipe Sizing Calculator - Design System v2.6
/// Low and medium pressure steam piping per ASME
class SteamPipeScreen extends ConsumerStatefulWidget {
  const SteamPipeScreen({super.key});
  @override
  ConsumerState<SteamPipeScreen> createState() => _SteamPipeScreenState();
}

class _SteamPipeScreenState extends ConsumerState<SteamPipeScreen> {
  double _steamLoad = 1000; // lbs/hr
  double _steamPressure = 15; // psig
  double _pipeLength = 100;
  String _pipeType = 'supply';
  String _pressureClass = 'low';

  String? _pipeSize;
  double? _velocity;
  double? _pressureDrop;
  String? _scheduleType;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Steam specific volume varies with pressure
    // At 15 psig: ~13.9 ft³/lb
    // At 100 psig: ~3.88 ft³/lb
    double specificVolume;
    if (_steamPressure <= 15) {
      specificVolume = 26.8 - (_steamPressure * 0.86);
    } else if (_steamPressure <= 50) {
      specificVolume = 13.9 - ((_steamPressure - 15) * 0.2);
    } else {
      specificVolume = 6.9 - ((_steamPressure - 50) * 0.06);
    }
    if (specificVolume < 2) specificVolume = 2;

    // Volume flow rate
    final volumeFlow = _steamLoad * specificVolume / 60; // cfm

    // Velocity limits
    // Supply: 6000-10000 fpm typical
    // Return/condensate: 3000-6000 fpm
    double maxVelocity;
    if (_pipeType == 'supply') {
      maxVelocity = _pressureClass == 'low' ? 6000 : 8000;
    } else if (_pipeType == 'return') {
      maxVelocity = 4000;
    } else {
      maxVelocity = 3000; // condensate
    }

    // Calculate minimum pipe area
    final minArea = volumeFlow / maxVelocity; // ft²
    final minDiameter = math.sqrt(minArea * 4 / math.pi) * 12; // inches

    // Select pipe size
    final pipeSizes = [
      (0.5, 0.622), (0.75, 0.824), (1.0, 1.049), (1.25, 1.380),
      (1.5, 1.610), (2.0, 2.067), (2.5, 2.469), (3.0, 3.068),
      (4.0, 4.026), (5.0, 5.047), (6.0, 6.065), (8.0, 7.981),
    ];

    String pipeSize = '8"';
    double actualDiameter = 7.981;
    for (final pipe in pipeSizes) {
      if (pipe.$2 >= minDiameter) {
        pipeSize = '${pipe.$1}"';
        actualDiameter = pipe.$2;
        break;
      }
    }

    // Actual velocity
    final actualArea = math.pi * math.pow(actualDiameter / 12 / 2, 2);
    final velocity = volumeFlow / actualArea;

    // Pressure drop (approximate)
    // Using simplified Darcy equation
    final pressureDrop = 0.01 * _pipeLength * math.pow(velocity / 1000, 2) / actualDiameter;

    // Schedule recommendation
    String scheduleType;
    if (_steamPressure <= 15) {
      scheduleType = 'Schedule 40 (Std)';
    } else if (_steamPressure <= 125) {
      scheduleType = 'Schedule 40 or 80';
    } else {
      scheduleType = 'Schedule 80 or higher';
    }

    String recommendation;
    if (_pipeType == 'supply') {
      recommendation = 'Steam supply: Pitch 1/4" per 10 ft in direction of flow. Use eccentric reducers.';
    } else if (_pipeType == 'return') {
      recommendation = 'Condensate return: Size for two-phase flow. Include adequate drainage.';
    } else {
      recommendation = 'Condensate line: Pitch toward receiver. Size traps for 2-3x load.';
    }

    if (_steamPressure > 50) {
      recommendation += ' High pressure: Check ASME B31.1 for additional requirements.';
    }

    if (velocity > maxVelocity * 0.9) {
      recommendation += ' Near velocity limit - consider upsizing for noise reduction.';
    }

    recommendation += ' Use welded fittings for pressure systems. All joints: Test at 1.5x operating pressure.';

    setState(() {
      _pipeSize = pipeSize;
      _velocity = velocity;
      _pressureDrop = pressureDrop;
      _scheduleType = scheduleType;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _steamLoad = 1000;
      _steamPressure = 15;
      _pipeLength = 100;
      _pipeType = 'supply';
      _pressureClass = 'low';
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
        title: Text('Steam Pipe Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'STEAM LOAD'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Steam Flow', value: _steamLoad, min: 100, max: 10000, unit: ' lbs/hr', onChanged: (v) { setState(() => _steamLoad = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Steam Pressure', value: _steamPressure, min: 2, max: 150, unit: ' psig', onChanged: (v) { setState(() => _steamPressure = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Pipe Length', value: _pipeLength, min: 10, max: 500, unit: ' ft', onChanged: (v) { setState(() => _pipeLength = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PIPE TYPE'),
              const SizedBox(height: 12),
              _buildPipeTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Pressure Class', options: const ['Low (<15 psig)', 'Medium (15-150)'], selectedIndex: _pressureClass == 'low' ? 0 : 1, onChanged: (i) { setState(() => _pressureClass = i == 0 ? 'low' : 'medium'); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PIPE SIZE'),
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
        Icon(LucideIcons.cloudDrizzle, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Steam pipe sizing per ASME B31.1. Supply: 6000-10000 fpm. Pitch for condensate drainage.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildPipeTypeSelector(ZaftoColors colors) {
    final types = [
      ('supply', 'Steam Supply'),
      ('return', 'Steam Return'),
      ('condensate', 'Condensate'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _pipeType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _pipeType = t.$1); _calculate(); },
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
            child: Text(_scheduleType ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Velocity', '${_velocity?.toStringAsFixed(0)} fpm')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Pressure Drop', '${_pressureDrop?.toStringAsFixed(2)} psi')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Load', '${_steamLoad.toStringAsFixed(0)} lbs/hr')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
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

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
