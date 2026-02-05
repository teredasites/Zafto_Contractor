import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Refrigerant Leak Rate Calculator - Design System v2.6
/// EPA 608 leak rate compliance calculations
class RefrigerantLeakRateScreen extends ConsumerStatefulWidget {
  const RefrigerantLeakRateScreen({super.key});
  @override
  ConsumerState<RefrigerantLeakRateScreen> createState() => _RefrigerantLeakRateScreenState();
}

class _RefrigerantLeakRateScreenState extends ConsumerState<RefrigerantLeakRateScreen> {
  double _systemCharge = 50; // lbs
  double _refrigerantAdded = 5; // lbs in 12 months
  String _equipmentType = 'commercial_ac';
  String _refrigerantType = 'r410a';
  int _monthsTracking = 12;

  double? _annualizedLeakRate;
  double? _allowableRate;
  bool? _exceedsLimit;
  String? _epaRequirement;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Annualize the leak rate if tracking period is not 12 months
    final annualizedLoss = _refrigerantAdded * (12 / _monthsTracking);
    final leakRatePercent = (annualizedLoss / _systemCharge) * 100;

    // EPA 608 leak rate thresholds
    double allowableRate;
    String epaRequirement;

    switch (_equipmentType) {
      case 'commercial_ac':
      case 'industrial_process':
        allowableRate = 30;
        epaRequirement = 'EPA 608: Commercial/Industrial - 30% annual leak rate trigger';
        break;
      case 'comfort_cooling':
        allowableRate = 20;
        epaRequirement = 'EPA 608: Comfort Cooling - 20% annual leak rate trigger';
        break;
      case 'refrigeration':
        allowableRate = 30;
        epaRequirement = 'EPA 608: Commercial Refrigeration - 30% annual leak rate trigger';
        break;
      default:
        allowableRate = 30;
        epaRequirement = 'EPA 608: Standard - 30% annual leak rate trigger';
    }

    final exceedsLimit = leakRatePercent > allowableRate;

    String recommendation;
    if (exceedsLimit) {
      recommendation = 'LEAK RATE EXCEEDS EPA LIMIT. You have 30 days to repair or retrofit/retire. Document all repairs and verify fix with follow-up leak test.';
    } else if (leakRatePercent > allowableRate * 0.75) {
      recommendation = 'Approaching EPA leak rate threshold. Proactively locate and repair leaks to avoid compliance issues.';
    } else if (leakRatePercent > 10) {
      recommendation = 'Moderate leak detected. Schedule leak search. Common leak points: service valves, flare connections, Schrader cores.';
    } else if (leakRatePercent > 0) {
      recommendation = 'Minor leak rate. Monitor and record refrigerant additions. Leak search recommended at next service.';
    } else {
      recommendation = 'No measurable leak. Continue monitoring and record all refrigerant additions.';
    }

    if (_systemCharge >= 50) {
      recommendation += ' Systems ≥50 lbs require leak repair records for 3 years.';
    }

    if (_refrigerantType == 'r22') {
      recommendation += ' R-22 phaseout: Consider system retrofit or replacement.';
    }

    setState(() {
      _annualizedLeakRate = leakRatePercent;
      _allowableRate = allowableRate;
      _exceedsLimit = exceedsLimit;
      _epaRequirement = epaRequirement;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemCharge = 50;
      _refrigerantAdded = 5;
      _equipmentType = 'commercial_ac';
      _refrigerantType = 'r410a';
      _monthsTracking = 12;
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
        title: Text('Leak Rate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'EQUIPMENT'),
              const SizedBox(height: 12),
              _buildEquipmentTypeSelector(colors),
              const SizedBox(height: 12),
              _buildRefrigerantSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM DATA'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System Charge', value: _systemCharge, min: 5, max: 500, unit: ' lbs', onChanged: (v) { setState(() => _systemCharge = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Refrigerant Added', value: _refrigerantAdded, min: 0, max: 100, unit: ' lbs', onChanged: (v) { setState(() => _refrigerantAdded = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Tracking Period', value: _monthsTracking.toDouble(), min: 1, max: 24, unit: ' months', onChanged: (v) { setState(() => _monthsTracking = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EPA COMPLIANCE'),
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
        Icon(LucideIcons.alertTriangle, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('EPA 608: Track all refrigerant additions. Exceeding leak rate triggers mandatory repair within 30 days.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildEquipmentTypeSelector(ZaftoColors colors) {
    final types = [
      ('commercial_ac', 'Comm. A/C'),
      ('comfort_cooling', 'Comfort'),
      ('refrigeration', 'Refrig'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _equipmentType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _equipmentType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildRefrigerantSelector(ZaftoColors colors) {
    final refs = [('r410a', 'R-410A'), ('r22', 'R-22'), ('r134a', 'R-134a'), ('r404a', 'R-404A')];
    return Row(
      children: refs.map((r) {
        final selected = _refrigerantType == r.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _refrigerantType = r.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: r != refs.last ? 6 : 0),
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
    if (_annualizedLeakRate == null) return const SizedBox.shrink();

    final exceedsLimit = _exceedsLimit ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_annualizedLeakRate?.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Annual Leak Rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: exceedsLimit ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(exceedsLimit ? 'EXCEEDS EPA LIMIT' : 'WITHIN LIMITS', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(_epaRequirement ?? '', style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Added', '${_refrigerantAdded.toStringAsFixed(0)} lbs')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Charge', '${_systemCharge.toStringAsFixed(0)} lbs')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Limit', '${_allowableRate?.toStringAsFixed(0)}%')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: exceedsLimit ? Colors.red.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(exceedsLimit ? LucideIcons.alertTriangle : LucideIcons.checkCircle, color: exceedsLimit ? Colors.red : Colors.green, size: 16),
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
