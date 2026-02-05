import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Expansion Tank Calculator - Design System v2.6
/// Hydronic system expansion tank sizing
class ExpansionTankScreen extends ConsumerStatefulWidget {
  const ExpansionTankScreen({super.key});
  @override
  ConsumerState<ExpansionTankScreen> createState() => _ExpansionTankScreenState();
}

class _ExpansionTankScreenState extends ConsumerState<ExpansionTankScreen> {
  double _systemVolume = 50;
  double _coldFillTemp = 50;
  double _maxOperatingTemp = 180;
  double _fillPressure = 12;
  double _reliefPressure = 30;
  String _fluidType = 'water';
  int _glycolPercent = 0;

  double? _expansionVolume;
  double? _tankSize;
  double? _acceptanceFactor;
  double? _prechargeePsi;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Water expansion coefficient (simplified)
    // Water expands ~4% from 50°F to 200°F
    // More precise: use specific volume tables

    // Expansion factor based on temperature rise
    final deltaT = _maxOperatingTemp - _coldFillTemp;

    // Expansion coefficient varies with glycol
    double expansionCoeff;
    if (_fluidType == 'water') {
      // Water: approximately 0.00023 per °F above 40°F
      expansionCoeff = 0.00023;
    } else {
      // Glycol solutions expand more
      if (_glycolPercent <= 20) {
        expansionCoeff = 0.00026;
      } else if (_glycolPercent <= 35) {
        expansionCoeff = 0.00030;
      } else {
        expansionCoeff = 0.00035;
      }
    }

    // Expansion volume = System volume × expansion coefficient × ΔT
    final expansionVolume = _systemVolume * expansionCoeff * deltaT;

    // Acceptance factor = (Po - Pf) / Po
    // Where Po = relief pressure, Pf = fill pressure
    // Convert to absolute: add 14.7 psi
    final poAbs = _reliefPressure + 14.7;
    final pfAbs = _fillPressure + 14.7;
    final acceptanceFactor = (poAbs - pfAbs) / poAbs;

    // Tank size = Expansion volume / Acceptance factor
    // Add 10% safety margin
    final tankSize = (expansionVolume / acceptanceFactor) * 1.10;

    // Precharge pressure should equal static fill pressure
    final prechargePsi = _fillPressure;

    // Recommendation
    String recommendation;
    if (tankSize < 2) {
      recommendation = 'Small system - 2 gallon tank minimum. Mount vertically with connection at bottom.';
    } else if (tankSize < 5) {
      recommendation = 'Residential size. Ensure precharge matches static fill pressure before adding water.';
    } else if (tankSize < 15) {
      recommendation = 'Medium system. Consider separate tank with isolation valve for service.';
    } else {
      recommendation = 'Large system. May need multiple tanks. Verify bladder/diaphragm type matches system.';
    }

    if (_fluidType == 'glycol') {
      recommendation += ' Glycol systems: check tank compatibility with glycol. Some bladders degrade.';
    }

    if (_maxOperatingTemp > 200) {
      recommendation += ' High temp system: verify tank rated for operating temperature.';
    }

    setState(() {
      _expansionVolume = expansionVolume;
      _tankSize = tankSize;
      _acceptanceFactor = acceptanceFactor;
      _prechargeePsi = prechargePsi;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemVolume = 50;
      _coldFillTemp = 50;
      _maxOperatingTemp = 180;
      _fillPressure = 12;
      _reliefPressure = 30;
      _fluidType = 'water';
      _glycolPercent = 0;
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
        title: Text('Expansion Tank', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSliderRow(colors, label: 'System Volume', value: _systemVolume, min: 10, max: 200, unit: ' gal', onChanged: (v) { setState(() => _systemVolume = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Fluid Type', options: const ['Water', 'Glycol'], selectedIndex: _fluidType == 'water' ? 0 : 1, onChanged: (i) { setState(() => _fluidType = i == 0 ? 'water' : 'glycol'); _calculate(); }),
              if (_fluidType == 'glycol') ...[
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Glycol %', value: _glycolPercent.toDouble(), min: 10, max: 50, unit: '%', onChanged: (v) { setState(() => _glycolPercent = v.round()); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Cold Fill Temp', value: _coldFillTemp, min: 40, max: 80, unit: '\u00B0F', onChanged: (v) { setState(() => _coldFillTemp = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Max Operating Temp', value: _maxOperatingTemp, min: 140, max: 250, unit: '\u00B0F', onChanged: (v) { setState(() => _maxOperatingTemp = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PRESSURES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Fill Pressure', value: _fillPressure, min: 5, max: 25, unit: ' PSI', onChanged: (v) { setState(() => _fillPressure = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Relief Valve', value: _reliefPressure, min: 15, max: 50, unit: ' PSI', onChanged: (v) { setState(() => _reliefPressure = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TANK SIZING'),
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
        Icon(LucideIcons.container, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Tank absorbs water expansion during heating. Precharge must equal static fill pressure. Size for max temp rise.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
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
    if (_tankSize == null) return const SizedBox.shrink();

    // Round up to common tank sizes
    int recommendedTankGallons;
    if (_tankSize! <= 2) {
      recommendedTankGallons = 2;
    } else if (_tankSize! <= 4.5) {
      recommendedTankGallons = 5;
    } else if (_tankSize! <= 8) {
      recommendedTankGallons = 8;
    } else if (_tankSize! <= 10) {
      recommendedTankGallons = 10;
    } else if (_tankSize! <= 15) {
      recommendedTankGallons = 15;
    } else if (_tankSize! <= 20) {
      recommendedTankGallons = 20;
    } else if (_tankSize! <= 30) {
      recommendedTankGallons = 30;
    } else {
      recommendedTankGallons = 40;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('$recommendedTankGallons', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Gallon Tank', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('(Calculated: ${_tankSize?.toStringAsFixed(1)} gal)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Expansion', '${_expansionVolume?.toStringAsFixed(2)} gal')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Accept. Factor', '${(_acceptanceFactor! * 100).toStringAsFixed(0)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Precharge', '${_prechargeePsi?.toStringAsFixed(0)} PSI')),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TEMPERATURE RISE', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${_coldFillTemp.toStringAsFixed(0)}\u00B0F \u2192 ${_maxOperatingTemp.toStringAsFixed(0)}\u00B0F (\u0394${(_maxOperatingTemp - _coldFillTemp).toStringAsFixed(0)}\u00B0F)', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),
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
