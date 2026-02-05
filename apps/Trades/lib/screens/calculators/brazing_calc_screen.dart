import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Brazing Calculator - Design System v2.6
/// HVAC copper brazing rod selection and gas flow
class BrazingCalcScreen extends ConsumerStatefulWidget {
  const BrazingCalcScreen({super.key});
  @override
  ConsumerState<BrazingCalcScreen> createState() => _BrazingCalcScreenState();
}

class _BrazingCalcScreenState extends ConsumerState<BrazingCalcScreen> {
  double _pipeSize = 0.75;
  String _pipeType = 'copper_to_copper';
  String _rodType = 'silfos_15';
  String _application = 'refrigeration';
  int _jointCount = 10;
  bool _useNitrogenPurge = true;

  String? _recommendedRod;
  double? _tipSize;
  double? _nitrogenFlow;
  double? _rodConsumption;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Rod selection based on joint type
    String recommendedRod;
    double meltTemp;

    if (_pipeType == 'copper_to_copper') {
      if (_rodType == 'silfos_15') {
        recommendedRod = 'Sil-Fos 15 (BCuP-5)';
        meltTemp = 1190;
      } else if (_rodType == 'silfos_5') {
        recommendedRod = 'Sil-Fos 5 (BCuP-3)';
        meltTemp = 1300;
      } else {
        recommendedRod = 'Stay-Silv 45 (BAg-5)';
        meltTemp = 1125;
      }
    } else {
      // Copper to brass or steel requires flux and different alloy
      recommendedRod = 'Stay-Silv 45 with flux';
      meltTemp = 1125;
    }

    // Torch tip size based on pipe diameter
    double tipSize;
    if (_pipeSize <= 0.5) {
      tipSize = 2;
    } else if (_pipeSize <= 0.75) {
      tipSize = 3;
    } else if (_pipeSize <= 1.0) {
      tipSize = 4;
    } else if (_pipeSize <= 1.5) {
      tipSize = 5;
    } else {
      tipSize = 6;
    }

    // Nitrogen purge flow rate (CFH)
    // Rule of thumb: 3-5 CFH for small pipes, more for larger
    double nitrogenFlow;
    if (_pipeSize <= 0.5) {
      nitrogenFlow = 3;
    } else if (_pipeSize <= 1.0) {
      nitrogenFlow = 5;
    } else if (_pipeSize <= 2.0) {
      nitrogenFlow = 8;
    } else {
      nitrogenFlow = 12;
    }

    // Rod consumption estimate (inches per joint)
    double rodPerJoint;
    if (_pipeSize <= 0.5) {
      rodPerJoint = 1.0;
    } else if (_pipeSize <= 0.75) {
      rodPerJoint = 1.5;
    } else if (_pipeSize <= 1.0) {
      rodPerJoint = 2.0;
    } else if (_pipeSize <= 1.5) {
      rodPerJoint = 3.0;
    } else {
      rodPerJoint = 4.0;
    }

    final totalRodInches = rodPerJoint * _jointCount;
    final rodConsumption = totalRodInches / 18; // 18" per rod typical

    String recommendation;
    if (_pipeType == 'copper_to_copper') {
      recommendation = 'Copper to copper: Self-fluxing rod (Sil-Fos/Phos-Copper). No flux needed.';
    } else {
      recommendation = 'Dissimilar metals: Use silver braze with flux. Clean thoroughly before and after.';
    }

    if (_useNitrogenPurge) {
      recommendation += ' Nitrogen purge: ${nitrogenFlow.toStringAsFixed(0)} CFH. Start flow before heating, continue until joint cools.';
    } else {
      recommendation += ' WARNING: Nitrogen purge recommended for refrigeration to prevent oxidation.';
    }

    if (_application == 'refrigeration') {
      recommendation += ' Refrigeration: Critical - oxide scale can contaminate system. Always purge.';
    }

    recommendation += ' Heat base metal until rod flows by capillary action. Tip size: #${tipSize.toStringAsFixed(0)}.';

    setState(() {
      _recommendedRod = recommendedRod;
      _tipSize = tipSize;
      _nitrogenFlow = nitrogenFlow;
      _rodConsumption = rodConsumption;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _pipeSize = 0.75;
      _pipeType = 'copper_to_copper';
      _rodType = 'silfos_15';
      _application = 'refrigeration';
      _jointCount = 10;
      _useNitrogenPurge = true;
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
        title: Text('Brazing Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'JOINT TYPE'),
              const SizedBox(height: 12),
              _buildPipeTypeSelector(colors),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PIPE SIZE'),
              const SizedBox(height: 12),
              _buildPipeSizeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Number of Joints', value: _jointCount.toDouble(), min: 1, max: 50, unit: '', onChanged: (v) { setState(() => _jointCount = v.round()); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROD & OPTIONS'),
              const SizedBox(height: 12),
              _buildRodTypeSelector(colors),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Nitrogen purge', _useNitrogenPurge, (v) { setState(() => _useNitrogenPurge = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'RECOMMENDATIONS'),
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
        Expanded(child: Text('Brazing: Use Sil-Fos for copper-to-copper (no flux). Nitrogen purge critical for refrigeration.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildPipeTypeSelector(ZaftoColors colors) {
    final types = [
      ('copper_to_copper', 'Cu to Cu'),
      ('copper_to_brass', 'Cu to Brass'),
      ('copper_to_steel', 'Cu to Steel'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _pipeType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _pipeType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [('refrigeration', 'Refrigeration'), ('plumbing', 'Plumbing')];
    return Row(
      children: apps.map((a) {
        final selected = _application == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _application = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPipeSizeSelector(ZaftoColors colors) {
    final sizes = [
      (0.375, '3/8"'),
      (0.5, '1/2"'),
      (0.625, '5/8"'),
      (0.75, '3/4"'),
      (0.875, '7/8"'),
      (1.125, '1-1/8"'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((s) {
        final selected = (_pipeSize - s.$1).abs() < 0.01;
        return GestureDetector(
          onTap: () { setState(() => _pipeSize = s.$1); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRodTypeSelector(ZaftoColors colors) {
    final rods = [
      ('silfos_15', 'Sil-Fos 15'),
      ('silfos_5', 'Sil-Fos 5'),
      ('silver_45', 'Silver 45'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Brazing Rod', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: rods.map((r) {
            final selected = _rodType == r.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _rodType = r.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: r != rods.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_recommendedRod == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_recommendedRod ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          Text('Recommended Rod', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.flame, color: colors.accentPrimary, size: 18),
                  const SizedBox(height: 4),
                  Text('Tip Size', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  Text('#${_tipSize?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.wind, color: colors.accentPrimary, size: 18),
                  const SizedBox(height: 4),
                  Text('N2 Flow', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  Text('${_nitrogenFlow?.toStringAsFixed(0)} CFH', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.package, color: colors.textSecondary, size: 18),
                  const SizedBox(height: 4),
                  Text('Rods', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  Text('${_rodConsumption?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _useNitrogenPurge ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_useNitrogenPurge ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: _useNitrogenPurge ? Colors.green : Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }
}
