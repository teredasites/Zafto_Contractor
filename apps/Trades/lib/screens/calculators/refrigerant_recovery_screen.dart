import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Refrigerant Recovery Calculator - Design System v2.6
/// EPA 608 recovery requirements and tank sizing
class RefrigerantRecoveryScreen extends ConsumerStatefulWidget {
  const RefrigerantRecoveryScreen({super.key});
  @override
  ConsumerState<RefrigerantRecoveryScreen> createState() => _RefrigerantRecoveryScreenState();
}

class _RefrigerantRecoveryScreenState extends ConsumerState<RefrigerantRecoveryScreen> {
  double _systemCharge = 25; // lbs
  String _refrigerantType = 'r410a';
  String _equipmentType = 'residential_ac';
  String _recoveryMethod = 'liquid';
  double _tankCapacity = 30;

  double? _minRecovery;
  double? _recoveryPercent;
  double? _tankFillMax;
  String? _epaRequirement;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // EPA 608 recovery requirements
    double recoveryPercent;
    String epaRequirement;

    // Recovery requirements vary by equipment type and refrigerant charge
    if (_equipmentType == 'residential_ac' || _equipmentType == 'small_commercial') {
      if (_systemCharge < 200) {
        // Small appliances with less than 200 lbs
        if (_recoveryMethod == 'liquid' || _recoveryMethod == 'vapor') {
          recoveryPercent = 90;
          epaRequirement = 'EPA 608: 90% recovery required';
        } else {
          recoveryPercent = 80;
          epaRequirement = 'EPA 608: 80% recovery (non-isolated)';
        }
      } else {
        recoveryPercent = 90;
        epaRequirement = 'EPA 608: 90% recovery (high-pressure, >200 lbs)';
      }
    } else if (_equipmentType == 'chiller') {
      recoveryPercent = 95;
      epaRequirement = 'EPA 608: 95% recovery required for chillers';
    } else {
      // MVAC
      recoveryPercent = 90;
      epaRequirement = 'EPA 609: MVAC recovery requirements apply';
    }

    final minRecovery = _systemCharge * (recoveryPercent / 100);

    // Tank capacity check
    // Recovery tanks should not exceed 80% fill
    // Adjust for refrigerant density
    double densityFactor;
    switch (_refrigerantType) {
      case 'r22': densityFactor = 1.0; break;
      case 'r410a': densityFactor = 1.08; break;
      case 'r134a': densityFactor = 1.05; break;
      case 'r404a': densityFactor = 1.1; break;
      default: densityFactor = 1.0;
    }

    final tankFillMax = _tankCapacity * 0.8 * densityFactor;

    String recommendation;
    if (_systemCharge > tankFillMax) {
      recommendation = 'System charge exceeds single tank capacity. Multiple tanks required or larger recovery cylinder.';
    } else {
      recommendation = 'Tank has adequate capacity. Fill to max ${tankFillMax.toStringAsFixed(1)} lbs.';
    }

    if (_refrigerantType == 'r22') {
      recommendation += ' R-22 phaseout: Cannot be recharged in new equipment. Recover for proper disposal or reclaim.';
    } else if (_refrigerantType == 'r410a') {
      recommendation += ' R-410A: High pressure refrigerant. Use rated recovery machine and tanks.';
    }

    if (_recoveryMethod == 'liquid') {
      recommendation += ' Liquid recovery: Faster but watch for tank overfill. Monitor scale weight.';
    } else if (_recoveryMethod == 'push_pull') {
      recommendation += ' Push-pull: Best for large charges. Requires second tank.';
    }

    recommendation += ' Always weigh tank before and after. Never exceed 80% fill.';

    setState(() {
      _minRecovery = minRecovery;
      _recoveryPercent = recoveryPercent;
      _tankFillMax = tankFillMax;
      _epaRequirement = epaRequirement;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemCharge = 25;
      _refrigerantType = 'r410a';
      _equipmentType = 'residential_ac';
      _recoveryMethod = 'liquid';
      _tankCapacity = 30;
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
        title: Text('Refrigerant Recovery', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSliderRow(colors, label: 'System Charge', value: _systemCharge, min: 1, max: 200, unit: ' lbs', onChanged: (v) { setState(() => _systemCharge = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildRefrigerantSelector(colors),
              const SizedBox(height: 12),
              _buildEquipmentTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RECOVERY'),
              const SizedBox(height: 12),
              _buildRecoveryMethodSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Recovery Tank Size', value: _tankCapacity, min: 10, max: 125, unit: ' lbs', onChanged: (v) { setState(() => _tankCapacity = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EPA REQUIREMENTS'),
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
        Icon(LucideIcons.recycle, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('EPA 608 recovery: 80-95% required. Never exceed 80% tank fill. Weigh before and after.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildRefrigerantSelector(ZaftoColors colors) {
    final refrigerants = [
      ('r22', 'R-22'),
      ('r410a', 'R-410A'),
      ('r134a', 'R-134a'),
      ('r404a', 'R-404A'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Refrigerant Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: refrigerants.map((r) {
            final selected = _refrigerantType == r.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _refrigerantType = r.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: r != refrigerants.last ? 6 : 0),
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

  Widget _buildEquipmentTypeSelector(ZaftoColors colors) {
    final types = [
      ('residential_ac', 'Residential'),
      ('small_commercial', 'Sm. Commercial'),
      ('chiller', 'Chiller'),
      ('mvac', 'MVAC'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipment Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: types.map((t) {
            final selected = _equipmentType == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _equipmentType = t.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: t != types.last ? 6 : 0),
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
        ),
      ],
    );
  }

  Widget _buildRecoveryMethodSelector(ZaftoColors colors) {
    final methods = [
      ('liquid', 'Liquid'),
      ('vapor', 'Vapor'),
      ('push_pull', 'Push-Pull'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recovery Method', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: methods.map((m) {
            final selected = _recoveryMethod == m.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _recoveryMethod = m.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: m != methods.last ? 8 : 0),
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
    if (_minRecovery == null) return const SizedBox.shrink();

    final tankOk = _systemCharge <= _tankFillMax!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_epaRequirement ?? '', style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w600))),
          ),
          Text('${_recoveryPercent?.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Minimum Recovery Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: tankOk ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(tankOk ? 'Tank OK' : 'Multiple Tanks Needed', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Min Recover', '${_minRecovery?.toStringAsFixed(1)} lbs')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Tank Max', '${_tankFillMax?.toStringAsFixed(1)} lbs')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'System', '${_systemCharge.toStringAsFixed(0)} lbs')),
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
