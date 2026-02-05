import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Compressor Capacity Calculator - Design System v2.6
/// Refrigeration compressor sizing and performance analysis
class CompressorCapacityScreen extends ConsumerStatefulWidget {
  const CompressorCapacityScreen({super.key});
  @override
  ConsumerState<CompressorCapacityScreen> createState() => _CompressorCapacityScreenState();
}

class _CompressorCapacityScreenState extends ConsumerState<CompressorCapacityScreen> {
  double _evapTemp = 40; // degrees F
  double _condTemp = 105; // degrees F
  double _requiredCapacity = 60000; // BTU/hr
  double _superheat = 10; // degrees F
  String _refrigerant = 'r410a';
  String _compressorType = 'scroll';

  double? _compressionRatio;
  double? _massFlow;
  double? _bhp;
  double? _eer;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Saturation pressures (simplified lookup)
    Map<String, double> evapPressure = {
      'r410a': 118 + (_evapTemp - 40) * 2.5,
      'r22': 69 + (_evapTemp - 40) * 1.5,
      'r134a': 37 + (_evapTemp - 40) * 0.9,
      'r404a': 62 + (_evapTemp - 40) * 1.4,
    };

    Map<String, double> condPressure = {
      'r410a': 340 + (_condTemp - 105) * 5,
      'r22': 196 + (_condTemp - 105) * 3,
      'r134a': 138 + (_condTemp - 105) * 2.5,
      'r404a': 260 + (_condTemp - 105) * 4,
    };

    final pEvap = evapPressure[_refrigerant] ?? 118;
    final pCond = condPressure[_refrigerant] ?? 340;
    final compressionRatio = pCond / pEvap;

    // Refrigerant effect (simplified BTU/lb)
    Map<String, double> refEffect = {
      'r410a': 70,
      'r22': 75,
      'r134a': 60,
      'r404a': 50,
    };

    final re = refEffect[_refrigerant] ?? 70;

    // Mass flow = Capacity / Refrigerant Effect
    final massFlow = _requiredCapacity / re; // lbs/hr

    // Compressor BHP (simplified)
    // BHP ≈ Capacity × (CR - 1) / (EER × 3412)
    double compressorEff;
    switch (_compressorType) {
      case 'scroll':
        compressorEff = 0.75;
        break;
      case 'reciprocating':
        compressorEff = 0.70;
        break;
      case 'screw':
        compressorEff = 0.72;
        break;
      case 'centrifugal':
        compressorEff = 0.80;
        break;
      default:
        compressorEff = 0.75;
    }

    final bhp = _requiredCapacity * (compressionRatio - 1) / (compressorEff * 3412 * 3);
    final kW = bhp * 0.746;
    final eer = _requiredCapacity / (kW * 1000);

    String recommendation;
    recommendation = 'Compression ratio: ${compressionRatio.toStringAsFixed(2)}. ';

    if (compressionRatio > 4.5) {
      recommendation += 'WARNING: High ratio (>${compressionRatio.toStringAsFixed(1)}). Consider two-stage or cascade system.';
    } else if (compressionRatio > 3.5) {
      recommendation += 'Moderate ratio. Single stage OK but verify compressor limits.';
    } else {
      recommendation += 'Good compression ratio for efficient operation.';
    }

    recommendation += ' Mass flow: ${massFlow.toStringAsFixed(0)} lb/hr. Power: ${kW.toStringAsFixed(1)} kW, EER: ${eer.toStringAsFixed(1)}. ';

    switch (_compressorType) {
      case 'scroll':
        recommendation += 'Scroll: Quiet, efficient, reliable. Standard for residential/light commercial.';
        break;
      case 'reciprocating':
        recommendation += 'Reciprocating: Wide capacity range. Good for varying loads with unloaders.';
        break;
      case 'screw':
        recommendation += 'Screw: Large capacity (20-400 tons). Good part-load efficiency with VFD.';
        break;
      case 'centrifugal':
        recommendation += 'Centrifugal: Largest capacity (100-10,000 tons). Best efficiency at full load.';
        break;
    }

    switch (_refrigerant) {
      case 'r410a':
        recommendation += ' R-410A: High pressure refrigerant. A2L safety classification.';
        break;
      case 'r22':
        recommendation += ' R-22: Phased out. Service only. Consider retrofit to R-407C or R-410A.';
        break;
      case 'r134a':
        recommendation += ' R-134A: Medium pressure. Centrifugal chillers. Being replaced by R-513A.';
        break;
      case 'r404a':
        recommendation += ' R-404A: High GWP. Low/medium temp refrigeration. Transitioning to R-448A/R-449A.';
        break;
    }

    if (_superheat < 8) {
      recommendation += ' Low superheat: Risk of liquid flood-back. Increase to 10-15°F.';
    } else if (_superheat > 20) {
      recommendation += ' High superheat: Reduced capacity. Check charge and expansion device.';
    }

    setState(() {
      _compressionRatio = compressionRatio;
      _massFlow = massFlow;
      _bhp = bhp;
      _eer = eer;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _evapTemp = 40;
      _condTemp = 105;
      _requiredCapacity = 60000;
      _superheat = 10;
      _refrigerant = 'r410a';
      _compressorType = 'scroll';
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
        title: Text('Compressor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COMPRESSOR TYPE'),
              const SizedBox(height: 12),
              _buildCompressorTypeSelector(colors),
              const SizedBox(height: 12),
              _buildRefrigerantSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'OPERATING CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Evap T', _evapTemp, 20, 55, '°F', (v) { setState(() => _evapTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Cond T', _condTemp, 90, 130, '°F', (v) { setState(() => _condTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CAPACITY'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Capacity', _requiredCapacity, 12000, 500000, ' BTU', (v) { setState(() => _requiredCapacity = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Superheat', _superheat, 5, 25, '°F', (v) { setState(() => _superheat = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'PERFORMANCE ANALYSIS'),
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
        Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Compression ratio = Pcond/Pevap. Keep <4:1 for single stage. Verify compressor envelope at operating conditions.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCompressorTypeSelector(ZaftoColors colors) {
    final types = [('scroll', 'Scroll'), ('reciprocating', 'Recip'), ('screw', 'Screw'), ('centrifugal', 'Centrif')];
    return Row(
      children: types.map((t) {
        final selected = _compressorType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _compressorType = t.$1); _calculate(); },
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

  Widget _buildRefrigerantSelector(ZaftoColors colors) {
    final refs = [('r410a', 'R-410A'), ('r22', 'R-22'), ('r134a', 'R-134A'), ('r404a', 'R-404A')];
    return Row(
      children: refs.map((r) {
        final selected = _refrigerant == r.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _refrigerant = r.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: r != refs.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_compressionRatio == null) return const SizedBox.shrink();

    final ratioOk = _compressionRatio! <= 4.0;
    final statusColor = ratioOk ? Colors.green : (_compressionRatio! <= 5.0 ? Colors.orange : Colors.red);
    final status = ratioOk ? 'RATIO OK' : (_compressionRatio! <= 5.0 ? 'HIGH RATIO' : 'EXCESSIVE RATIO');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_compressionRatio?.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Compression Ratio', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Power', '${_bhp?.toStringAsFixed(1)} BHP')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'EER', '${_eer?.toStringAsFixed(1)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Mass Flow', '${_massFlow?.toStringAsFixed(0)} lb/hr')),
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
