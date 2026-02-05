import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Refrigerant Line Sizing Calculator - Design System v2.6
/// Suction, liquid, and discharge line sizing
class RefrigerantLineScreen extends ConsumerStatefulWidget {
  const RefrigerantLineScreen({super.key});
  @override
  ConsumerState<RefrigerantLineScreen> createState() => _RefrigerantLineScreenState();
}

class _RefrigerantLineScreenState extends ConsumerState<RefrigerantLineScreen> {
  double _systemTons = 3;
  double _lineLength = 50;
  double _elevation = 0;
  String _refrigerant = 'r410a';
  String _lineType = 'suction';

  String? _recommendedSize;
  double? _velocityFpm;
  double? _pressureDropPsi;
  String? _materialSpec;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Simplified line sizing based on tonnage and line type
    // Real sizing uses manufacturer data, but these are good field estimates

    String recommendedSize;
    double velocityFpm;
    double pressureDropPer100;
    String materialSpec;

    if (_lineType == 'suction') {
      // Suction line - largest, velocity 1000-4000 FPM
      if (_systemTons <= 1.5) {
        recommendedSize = '5/8" OD';
        velocityFpm = 1800;
      } else if (_systemTons <= 2.5) {
        recommendedSize = '3/4" OD';
        velocityFpm = 2200;
      } else if (_systemTons <= 3.5) {
        recommendedSize = '7/8" OD';
        velocityFpm = 2500;
      } else if (_systemTons <= 5) {
        recommendedSize = '1-1/8" OD';
        velocityFpm = 2800;
      } else {
        recommendedSize = '1-3/8" OD';
        velocityFpm = 3200;
      }
      pressureDropPer100 = 2.0; // PSI per 100 ft target
      materialSpec = 'ACR copper, Type L minimum. Insulate full length.';
    } else if (_lineType == 'liquid') {
      // Liquid line - smaller, velocity 100-300 FPM
      if (_systemTons <= 2) {
        recommendedSize = '1/4" OD';
        velocityFpm = 150;
      } else if (_systemTons <= 3.5) {
        recommendedSize = '3/8" OD';
        velocityFpm = 180;
      } else if (_systemTons <= 5) {
        recommendedSize = '3/8" OD';
        velocityFpm = 220;
      } else {
        recommendedSize = '1/2" OD';
        velocityFpm = 200;
      }
      pressureDropPer100 = 5.0; // Less critical
      materialSpec = 'ACR copper. Insulate if exposed to hot attic.';
    } else {
      // Discharge/hot gas line - medium, velocity 2000-3500 FPM
      if (_systemTons <= 2) {
        recommendedSize = '1/2" OD';
        velocityFpm = 2500;
      } else if (_systemTons <= 3.5) {
        recommendedSize = '5/8" OD';
        velocityFpm = 2800;
      } else if (_systemTons <= 5) {
        recommendedSize = '3/4" OD';
        velocityFpm = 3000;
      } else {
        recommendedSize = '7/8" OD';
        velocityFpm = 3200;
      }
      pressureDropPer100 = 3.0;
      materialSpec = 'ACR copper. Must handle high temp/pressure.';
    }

    // Adjust for length
    final totalPressureDrop = pressureDropPer100 * (_lineLength / 100);

    // Elevation adjustment (0.5 PSI per 10 ft vertical for R-410A suction)
    double elevationLoss = 0;
    if (_lineType == 'suction' && _elevation > 0) {
      elevationLoss = (_elevation / 10) * 0.5;
    }

    final finalPressureDrop = totalPressureDrop + elevationLoss;

    // Refrigerant-specific notes
    String refrigerantNote;
    switch (_refrigerant) {
      case 'r410a':
        refrigerantNote = 'R-410A: High pressure refrigerant. Use ACR copper rated for 700+ PSI.';
        break;
      case 'r22':
        refrigerantNote = 'R-22: Phased out. Replacement systems use R-410A or R-32.';
        break;
      case 'r32':
        refrigerantNote = 'R-32: Higher pressure than R-410A. Slightly flammable (A2L).';
        break;
      case 'r134a':
        refrigerantNote = 'R-134a: Lower pressure. Common in chillers and automotive.';
        break;
      default:
        refrigerantNote = '';
    }

    String recommendation = refrigerantNote;
    if (_lineLength > 75) {
      recommendation += ' Long line set - verify subcooling at indoor unit.';
    }
    if (_elevation > 20 && _lineType == 'suction') {
      recommendation += ' Significant elevation - may need oil trap every 20 ft.';
    }

    setState(() {
      _recommendedSize = recommendedSize;
      _velocityFpm = velocityFpm;
      _pressureDropPsi = finalPressureDrop;
      _materialSpec = materialSpec;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemTons = 3;
      _lineLength = 50;
      _elevation = 0;
      _refrigerant = 'r410a';
      _lineType = 'suction';
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
        title: Text('Refrigerant Lines', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System Capacity', value: _systemTons, min: 1, max: 10, unit: ' tons', decimals: 1, onChanged: (v) { setState(() => _systemTons = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Refrigerant', options: const ['R-410A', 'R-32', 'R-22', 'R-134a'], selectedIndex: ['r410a', 'r32', 'r22', 'r134a'].indexOf(_refrigerant), onChanged: (i) { setState(() => _refrigerant = ['r410a', 'r32', 'r22', 'r134a'][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LINE TYPE'),
              const SizedBox(height: 12),
              _buildLineTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LINE SET'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total Length', value: _lineLength, min: 15, max: 200, unit: ' ft', onChanged: (v) { setState(() => _lineLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Vertical Rise', value: _elevation, min: 0, max: 50, unit: ' ft', onChanged: (v) { setState(() => _elevation = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'LINE SIZING'),
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
        Icon(LucideIcons.pipette, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size refrigerant lines for proper velocity and pressure drop. Suction line most critical for oil return.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildLineTypeSelector(ZaftoColors colors) {
    final types = [
      ('suction', 'Suction', 'Low side vapor'),
      ('liquid', 'Liquid', 'High side liquid'),
      ('discharge', 'Discharge', 'Hot gas'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _lineType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _lineType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 10)),
              ]),
            ),
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
            child: Text(decimals > 0 ? '${value.toStringAsFixed(decimals)}$unit' : '${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_recommendedSize == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_recommendedSize!, style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
          Text('Recommended ${_lineType.substring(0, 1).toUpperCase()}${_lineType.substring(1)} Line', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Velocity', '${_velocityFpm?.toStringAsFixed(0)} FPM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Pressure Drop', '${_pressureDropPsi?.toStringAsFixed(1)} PSI')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Length', '${_lineLength.toStringAsFixed(0)} ft')),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MATERIAL', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_materialSpec ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 16),
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
