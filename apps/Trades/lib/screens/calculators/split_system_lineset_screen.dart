import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Split System Lineset Calculator - Design System v2.6
/// Line size and charge adjustment for mini-splits and split systems
class SplitSystemLinesetScreen extends ConsumerStatefulWidget {
  const SplitSystemLinesetScreen({super.key});
  @override
  ConsumerState<SplitSystemLinesetScreen> createState() => _SplitSystemLinesetScreenState();
}

class _SplitSystemLinesetScreenState extends ConsumerState<SplitSystemLinesetScreen> {
  double _systemBtu = 24000;
  double _linesetLength = 25;
  double _verticalRise = 10;
  String _systemType = 'mini_split';
  String _refrigerant = 'r410a';
  double _factoryCharge = 25; // ft pre-charged

  String? _liquidLineSize;
  String? _suctionLineSize;
  double? _additionalCharge;
  double? _totalCharge;
  String? _maxLength;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Line sizing based on capacity
    String liquidLine;
    String suctionLine;

    if (_systemBtu <= 12000) {
      liquidLine = '1/4" OD';
      suctionLine = '3/8" OD';
    } else if (_systemBtu <= 18000) {
      liquidLine = '1/4" OD';
      suctionLine = '1/2" OD';
    } else if (_systemBtu <= 24000) {
      liquidLine = '3/8" OD';
      suctionLine = '5/8" OD';
    } else if (_systemBtu <= 36000) {
      liquidLine = '3/8" OD';
      suctionLine = '3/4" OD';
    } else {
      liquidLine = '3/8" OD';
      suctionLine = '7/8" OD';
    }

    // Max lineset length
    double maxLength;
    if (_systemType == 'mini_split') {
      maxLength = _systemBtu <= 18000 ? 50 : 75;
    } else {
      maxLength = 75; // Traditional split
    }

    // Charge adjustment
    // R-410A: approximately 0.6 oz per foot of liquid line over factory charge
    // Varies by manufacturer
    double chargePerFoot;
    if (_refrigerant == 'r410a') {
      if (liquidLine == '1/4" OD') {
        chargePerFoot = 0.3; // oz/ft
      } else if (liquidLine == '3/8" OD') {
        chargePerFoot = 0.6;
      } else {
        chargePerFoot = 0.9;
      }
    } else {
      // R-22
      if (liquidLine == '1/4" OD') {
        chargePerFoot = 0.25;
      } else if (liquidLine == '3/8" OD') {
        chargePerFoot = 0.5;
      } else {
        chargePerFoot = 0.75;
      }
    }

    // Calculate additional charge needed
    double additionalLength = _linesetLength - _factoryCharge;
    if (additionalLength < 0) additionalLength = 0;

    final additionalChargeOz = additionalLength * chargePerFoot;
    final totalChargeOz = (_factoryCharge * chargePerFoot) + additionalChargeOz;

    String recommendation;
    if (_linesetLength > maxLength) {
      recommendation = 'Lineset exceeds manufacturer maximum. Capacity and efficiency will be reduced. Consider relocating unit.';
    } else if (_linesetLength < 10) {
      recommendation = 'Very short lineset - verify minimum length per manufacturer (usually 10 ft). May need to coil excess.';
    } else {
      recommendation = 'Lineset length within limits. Add ${additionalChargeOz.toStringAsFixed(1)} oz ${_refrigerant.toUpperCase()} for length over ${_factoryCharge.toStringAsFixed(0)} ft.';
    }

    if (_verticalRise > 30) {
      recommendation += ' Significant vertical rise - verify within manufacturer limits and ensure oil return.';
    }

    if (_systemType == 'mini_split') {
      recommendation += ' Mini-split: Use flare connections with torque wrench. Check for leaks with nitrogen before charging.';
    }

    setState(() {
      _liquidLineSize = liquidLine;
      _suctionLineSize = suctionLine;
      _additionalCharge = additionalChargeOz;
      _totalCharge = totalChargeOz;
      _maxLength = '${maxLength.toStringAsFixed(0)} ft';
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemBtu = 24000;
      _linesetLength = 25;
      _verticalRise = 10;
      _systemType = 'mini_split';
      _refrigerant = 'r410a';
      _factoryCharge = 25;
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
        title: Text('Split System Lineset', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSliderRow(colors, label: 'System Capacity', value: _systemBtu, min: 9000, max: 60000, unit: ' BTU', displayK: true, onChanged: (v) { setState(() => _systemBtu = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSystemTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Refrigerant', options: const ['R-410A', 'R-22'], selectedIndex: _refrigerant == 'r410a' ? 0 : 1, onChanged: (i) { setState(() => _refrigerant = i == 0 ? 'r410a' : 'r22'); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LINESET'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Lineset Length', value: _linesetLength, min: 5, max: 100, unit: ' ft', onChanged: (v) { setState(() => _linesetLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Vertical Rise', value: _verticalRise, min: 0, max: 50, unit: ' ft', onChanged: (v) { setState(() => _verticalRise = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Factory Charge Length', value: _factoryCharge, min: 15, max: 50, unit: ' ft', onChanged: (v) { setState(() => _factoryCharge = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'LINE SIZES & CHARGE'),
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
        Expanded(child: Text('Line size by capacity. Add refrigerant for length over factory pre-charge. Always verify manufacturer specs.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    final types = [
      ('mini_split', 'Mini-Split', 'Ductless'),
      ('split', 'Split System', 'Ducted'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _systemType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _systemType = t.$1); _calculate(); },
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
    if (_liquidLineSize == null) return const SizedBox.shrink();

    final withinLimits = _linesetLength <= double.parse(_maxLength!.split(' ').first);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('LIQUID', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_liquidLineSize!, style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('Uninsulated', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('SUCTION', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_suctionLineSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('Insulated', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: withinLimits ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('Max Length: $_maxLength', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Additional Charge', '${_additionalCharge?.toStringAsFixed(1)} oz')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total Length', '${_linesetLength.toStringAsFixed(0)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Vertical', '${_verticalRise.toStringAsFixed(0)} ft')),
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
