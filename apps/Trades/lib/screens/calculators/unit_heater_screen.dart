import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Unit Heater Sizing Calculator - Design System v2.6
/// Garage, shop, and warehouse unit heater sizing
class UnitHeaterScreen extends ConsumerStatefulWidget {
  const UnitHeaterScreen({super.key});
  @override
  ConsumerState<UnitHeaterScreen> createState() => _UnitHeaterScreenState();
}

class _UnitHeaterScreenState extends ConsumerState<UnitHeaterScreen> {
  double _squareFeet = 800;
  double _ceilingHeight = 12;
  int _outdoorDesign = 10;
  int _indoorTarget = 55;
  String _insulationLevel = 'uninsulated';
  String _doorType = 'overhead';
  int _airChanges = 2;

  double? _cubicFeet;
  double? _heatingBtu;
  String? _recommendedUnit;
  double? _cfmRequired;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final volume = _squareFeet * _ceilingHeight;
    final deltaT = _indoorTarget - _outdoorDesign;

    // Insulation factor
    double heatLossCoeff;
    switch (_insulationLevel) {
      case 'uninsulated': heatLossCoeff = 1.5; break;
      case 'partial': heatLossCoeff = 1.0; break;
      case 'insulated': heatLossCoeff = 0.7; break;
      default: heatLossCoeff = 1.0;
    }

    // Door loss factor
    double doorFactor;
    switch (_doorType) {
      case 'overhead': doorFactor = 1.3; break;
      case 'rollup': doorFactor = 1.2; break;
      case 'standard': doorFactor = 1.0; break;
      default: doorFactor = 1.0;
    }

    // Heat loss calculation
    // BTU = Volume × ΔT × Factor × Air changes
    final envelopeHeat = volume * 0.133 * deltaT * heatLossCoeff;
    final infiltrationHeat = volume * _airChanges * 0.018 * deltaT * doorFactor;
    final totalBtu = envelopeHeat + infiltrationHeat;

    // CFM for throw
    final cfm = totalBtu / 30; // Rough estimate

    // Round to standard unit heater sizes
    String recommendedUnit;
    if (totalBtu <= 30000) {
      recommendedUnit = '30,000 BTU Unit Heater';
    } else if (totalBtu <= 45000) {
      recommendedUnit = '45,000 BTU Unit Heater';
    } else if (totalBtu <= 60000) {
      recommendedUnit = '60,000 BTU Unit Heater';
    } else if (totalBtu <= 75000) {
      recommendedUnit = '75,000 BTU Unit Heater';
    } else if (totalBtu <= 100000) {
      recommendedUnit = '100,000 BTU Unit Heater';
    } else if (totalBtu <= 125000) {
      recommendedUnit = '125,000 BTU Unit Heater';
    } else if (totalBtu <= 150000) {
      recommendedUnit = '150,000 BTU (or 2 smaller units)';
    } else if (totalBtu <= 200000) {
      recommendedUnit = '200,000 BTU (or multiple units)';
    } else {
      final units = (totalBtu / 100000).ceil();
      recommendedUnit = '$units × 100,000 BTU units';
    }

    String recommendation;
    if (_insulationLevel == 'uninsulated') {
      recommendation = 'Uninsulated space requires significantly more BTU. Consider insulating to reduce operating costs.';
    } else if (_doorType == 'overhead' && _airChanges > 2) {
      recommendation = 'Frequent door openings increase heat loss. Consider air curtain or vestibule.';
    } else {
      recommendation = 'Standard garage/shop application. Mount unit high for best heat distribution.';
    }

    if (totalBtu > 100000) {
      recommendation += ' Multiple smaller units often provide better coverage than one large unit.';
    }

    setState(() {
      _cubicFeet = volume;
      _heatingBtu = totalBtu;
      _recommendedUnit = recommendedUnit;
      _cfmRequired = cfm;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _squareFeet = 800;
      _ceilingHeight = 12;
      _outdoorDesign = 10;
      _indoorTarget = 55;
      _insulationLevel = 'uninsulated';
      _doorType = 'overhead';
      _airChanges = 2;
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
        title: Text('Unit Heater', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SPACE DIMENSIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Floor Area', value: _squareFeet, min: 200, max: 5000, unit: ' sq ft', onChanged: (v) { setState(() => _squareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 8, max: 30, unit: ' ft', onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DESIGN CONDITIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outdoor Design Temp', value: _outdoorDesign.toDouble(), min: -20, max: 40, unit: '\u00B0F', isInt: true, onChanged: (v) { setState(() => _outdoorDesign = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Indoor Target Temp', value: _indoorTarget.toDouble(), min: 40, max: 70, unit: '\u00B0F', isInt: true, onChanged: (v) { setState(() => _indoorTarget = v.round()); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BUILDING FACTORS'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Insulation', options: const ['Uninsulated', 'Partial', 'Insulated'], selectedIndex: ['uninsulated', 'partial', 'insulated'].indexOf(_insulationLevel), onChanged: (i) { setState(() => _insulationLevel = ['uninsulated', 'partial', 'insulated'][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Door Type', options: const ['Overhead', 'Roll-up', 'Standard'], selectedIndex: ['overhead', 'rollup', 'standard'].indexOf(_doorType), onChanged: (i) { setState(() => _doorType = ['overhead', 'rollup', 'standard'][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Air Changes/Hour', value: _airChanges.toDouble(), min: 0, max: 6, unit: ' ACH', isInt: true, onChanged: (v) { setState(() => _airChanges = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'UNIT HEATER SIZING'),
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
        Icon(LucideIcons.warehouse, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size gas unit heaters for garages, shops, warehouses. Account for infiltration from overhead doors.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(isInt ? '${value.round()}$unit' : '${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_heatingBtu == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${(_heatingBtu! / 1000).toStringAsFixed(0)}k', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('BTU Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_recommendedUnit ?? '', style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Volume', '${_cubicFeet?.toStringAsFixed(0)} cu ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'ΔT', '${_indoorTarget - _outdoorDesign}\u00B0F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'CFM', '${_cfmRequired?.toStringAsFixed(0)}')),
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
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
