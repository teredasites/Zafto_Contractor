import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// AC Tonnage Calculator - Design System v2.6
/// Convert BTU to tons and select equipment size
class AcTonnageScreen extends ConsumerStatefulWidget {
  const AcTonnageScreen({super.key});
  @override
  ConsumerState<AcTonnageScreen> createState() => _AcTonnageScreenState();
}

class _AcTonnageScreenState extends ConsumerState<AcTonnageScreen> {
  double _coolingBtu = 36000;
  String _inputMethod = 'btu';
  double _squareFeet = 1500;
  String _climate = 'moderate';

  double? _tons;
  String? _equipmentSize;
  double? _cfmRequired;
  double? _nominalBtu;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    double btu;

    if (_inputMethod == 'btu') {
      btu = _coolingBtu;
    } else {
      // Rule of thumb by climate
      double btuPerSqFt;
      switch (_climate) {
        case 'cool': btuPerSqFt = 18; break;
        case 'moderate': btuPerSqFt = 22; break;
        case 'warm': btuPerSqFt = 26; break;
        case 'hot': btuPerSqFt = 30; break;
        default: btuPerSqFt = 22;
      }
      btu = _squareFeet * btuPerSqFt;
    }

    final tons = btu / 12000;

    // Round to nearest standard size
    double nominalTons;
    String equipmentSize;
    if (tons <= 1.75) {
      nominalTons = 1.5;
      equipmentSize = '1.5 Ton (18,000 BTU)';
    } else if (tons <= 2.25) {
      nominalTons = 2.0;
      equipmentSize = '2 Ton (24,000 BTU)';
    } else if (tons <= 2.75) {
      nominalTons = 2.5;
      equipmentSize = '2.5 Ton (30,000 BTU)';
    } else if (tons <= 3.25) {
      nominalTons = 3.0;
      equipmentSize = '3 Ton (36,000 BTU)';
    } else if (tons <= 3.75) {
      nominalTons = 3.5;
      equipmentSize = '3.5 Ton (42,000 BTU)';
    } else if (tons <= 4.25) {
      nominalTons = 4.0;
      equipmentSize = '4 Ton (48,000 BTU)';
    } else if (tons <= 4.75) {
      nominalTons = 4.5;
      equipmentSize = '4.5 Ton (54,000 BTU)';
    } else if (tons <= 5.5) {
      nominalTons = 5.0;
      equipmentSize = '5 Ton (60,000 BTU)';
    } else {
      nominalTons = (tons).ceilToDouble();
      equipmentSize = '${nominalTons.toStringAsFixed(0)} Ton (${(nominalTons * 12000).toStringAsFixed(0)} BTU)';
    }

    final nominalBtu = nominalTons * 12000;
    final cfm = nominalTons * 400; // 400 CFM per ton

    String recommendation;
    final oversizing = (nominalBtu - btu) / btu * 100;
    if (oversizing > 25) {
      recommendation = 'Equipment may be oversized. Consider variable speed or smaller unit for humidity control.';
    } else if (oversizing < 0) {
      recommendation = 'Equipment undersized. Move to next size up or verify load calculation.';
    } else {
      recommendation = 'Good equipment match. Ensure ductwork supports ${cfm.toStringAsFixed(0)} CFM.';
    }

    setState(() {
      _tons = tons;
      _equipmentSize = equipmentSize;
      _cfmRequired = cfm;
      _nominalBtu = nominalBtu;
      _coolingBtu = btu;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coolingBtu = 36000;
      _inputMethod = 'btu';
      _squareFeet = 1500;
      _climate = 'moderate';
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
        title: Text('AC Tonnage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INPUT METHOD'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: '', options: const ['Enter BTU', 'Quick Estimate'], selectedIndex: _inputMethod == 'btu' ? 0 : 1, onChanged: (i) { setState(() => _inputMethod = i == 0 ? 'btu' : 'sqft'); _calculate(); }),
              const SizedBox(height: 24),
              if (_inputMethod == 'btu') ...[
                _buildSectionHeader(colors, 'COOLING LOAD'),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Cooling Load', value: _coolingBtu, min: 12000, max: 120000, unit: ' BTU', onChanged: (v) { setState(() => _coolingBtu = v); _calculate(); }),
              ] else ...[
                _buildSectionHeader(colors, 'QUICK ESTIMATE'),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Conditioned Area', value: _squareFeet, min: 500, max: 5000, unit: ' sq ft', onChanged: (v) { setState(() => _squareFeet = v); _calculate(); }),
                const SizedBox(height: 12),
                _buildSegmentedToggle(colors, label: 'Climate', options: const ['Cool', 'Moderate', 'Warm', 'Hot'], selectedIndex: ['cool', 'moderate', 'warm', 'hot'].indexOf(_climate), onChanged: (i) { setState(() => _climate = ['cool', 'moderate', 'warm', 'hot'][i]); _calculate(); }),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EQUIPMENT SIZING'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildTonnageChart(colors),
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
        Icon(LucideIcons.snowflake, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('1 ton = 12,000 BTU/hr. Select nearest standard size. Avoid oversizing which causes humidity issues.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    final displayValue = unit == ' BTU' ? '${(value / 1000).toStringAsFixed(0)}k$unit' : '${value.toStringAsFixed(0)}$unit';
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
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
        ],
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
    if (_tons == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_tons!.toStringAsFixed(2), style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('Tons Calculated', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text(_equipmentSize ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Load', '${(_coolingBtu / 1000).toStringAsFixed(0)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Nominal', '${(_nominalBtu! / 1000).toStringAsFixed(0)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Airflow', '${_cfmRequired?.toStringAsFixed(0)} CFM')),
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

  Widget _buildTonnageChart(ZaftoColors colors) {
    final sizes = [
      ('1.5', 18),
      ('2.0', 24),
      ('2.5', 30),
      ('3.0', 36),
      ('3.5', 42),
      ('4.0', 48),
      ('5.0', 60),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STANDARD SIZES', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((s) {
              final isSelected = _tons != null && _tons! >= (double.parse(s.$1) - 0.25) && _tons! < (double.parse(s.$1) + 0.5);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  Text('${s.$1}T', style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${s.$2}k', style: TextStyle(color: isSelected ? Colors.white70 : colors.textSecondary, fontSize: 11)),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
