import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Glycol Freeze Protection Calculator - Design System v2.6
/// Antifreeze concentration and system effects
class GlycolFreezeScreen extends ConsumerStatefulWidget {
  const GlycolFreezeScreen({super.key});
  @override
  ConsumerState<GlycolFreezeScreen> createState() => _GlycolFreezeScreenState();
}

class _GlycolFreezeScreenState extends ConsumerState<GlycolFreezeScreen> {
  double _freezeProtection = 10; // degrees F
  double _systemVolume = 100; // gallons
  String _glycolType = 'propylene';
  String _application = 'hvac';

  double? _glycolPercent;
  double? _glycolGallons;
  double? _specificHeat;
  double? _viscosityFactor;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Glycol concentration for freeze protection
    // Simplified lookup - actual varies with glycol manufacturer
    Map<int, double> propyleneFreeze = {
      32: 0, 25: 15, 20: 20, 15: 25, 10: 30, 5: 35, 0: 40, -10: 45, -20: 50, -30: 55, -40: 60,
    };
    Map<int, double> ethyleneFreeze = {
      32: 0, 25: 12, 20: 17, 15: 22, 10: 27, 5: 32, 0: 37, -10: 42, -20: 47, -30: 52, -40: 57,
    };

    final freezeMap = _glycolType == 'propylene' ? propyleneFreeze : ethyleneFreeze;

    // Find required concentration
    double glycolPercent = 0;
    for (final entry in freezeMap.entries) {
      if (entry.key <= _freezeProtection) {
        glycolPercent = entry.value;
        break;
      }
      glycolPercent = entry.value;
    }

    // Glycol volume needed
    final glycolGallons = _systemVolume * glycolPercent / 100;

    // Specific heat reduction (water = 1.0)
    // Approximately: Cp = 1.0 - 0.005 × %glycol
    final specificHeat = 1.0 - (0.005 * glycolPercent);

    // Viscosity increase factor (rough approximation)
    // At 50°F, viscosity roughly doubles at 50% glycol
    final viscosityFactor = 1 + (glycolPercent / 100);

    String recommendation;
    recommendation = '${glycolPercent.toStringAsFixed(0)}% ${_glycolType == 'propylene' ? 'propylene' : 'ethylene'} glycol for ${_freezeProtection.toStringAsFixed(0)}°F protection. ';
    recommendation += 'Need ${glycolGallons.toStringAsFixed(0)} gallons glycol for ${_systemVolume.toStringAsFixed(0)} gallon system. ';

    if (_glycolType == 'propylene') {
      recommendation += 'Propylene glycol: Food-safe, HVAC preferred. Slightly higher viscosity than ethylene.';
    } else {
      recommendation += 'Ethylene glycol: Better heat transfer but TOXIC. Use only in closed systems with no food contact.';
    }

    // System effects
    recommendation += ' Heat transfer reduced ~${((1 - specificHeat) * 100).toStringAsFixed(0)}%. ';

    if (glycolPercent > 50) {
      recommendation += 'WARNING: >50% concentration significantly impacts heat transfer and pump performance. Consider burst protection only.';
    } else if (glycolPercent > 35) {
      recommendation += 'High concentration: Verify coil capacity adequate. May need to increase flow rate.';
    }

    switch (_application) {
      case 'hvac':
        recommendation += ' HVAC: Size coils for glycol. Increase pump head 10-20% for viscosity.';
        break;
      case 'solar':
        recommendation += ' Solar: High temp glycol required. Check max temp rating. Replace every 3-5 years.';
        break;
      case 'ground_source':
        recommendation += ' Ground source: 20-25% typical. Lower concentration OK due to ground temp.';
        break;
      case 'snow_melt':
        recommendation += ' Snow melt: 50% common for exposed systems. Annual testing recommended.';
        break;
    }

    recommendation += ' Test concentration annually with refractometer. Top up with premix, not straight glycol.';

    setState(() {
      _glycolPercent = glycolPercent;
      _glycolGallons = glycolGallons;
      _specificHeat = specificHeat;
      _viscosityFactor = viscosityFactor;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _freezeProtection = 10;
      _systemVolume = 100;
      _glycolType = 'propylene';
      _application = 'hvac';
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
        title: Text('Glycol Freeze', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'GLYCOL TYPE'),
              const SizedBox(height: 12),
              _buildGlycolTypeSelector(colors),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PROTECTION REQUIRED'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Freeze Protection', value: _freezeProtection, min: -40, max: 32, unit: '°F', onChanged: (v) { setState(() => _freezeProtection = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM VOLUME'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total System Volume', value: _systemVolume, min: 10, max: 1000, unit: ' gal', onChanged: (v) { setState(() => _systemVolume = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'GLYCOL REQUIREMENTS'),
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
        Icon(LucideIcons.snowflake, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Propylene glycol: Food-safe HVAC use. Ethylene: Better thermal but toxic. Each 10% glycol reduces heat transfer ~5%.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildGlycolTypeSelector(ZaftoColors colors) {
    final types = [('propylene', 'Propylene (Safe)'), ('ethylene', 'Ethylene (Toxic)')];
    return Row(
      children: types.map((t) {
        final selected = _glycolType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _glycolType = t.$1); _calculate(); },
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

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [('hvac', 'HVAC'), ('solar', 'Solar'), ('ground_source', 'Geo'), ('snow_melt', 'Snow Melt')];
    return Row(
      children: apps.map((a) {
        final selected = _application == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _application = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
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
    if (_glycolPercent == null) return const SizedBox.shrink();

    final isHigh = _glycolPercent! > 50;
    final statusColor = isHigh ? Colors.orange : Colors.green;
    final status = isHigh ? 'HIGH CONCENTRATION' : 'NORMAL RANGE';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_glycolPercent?.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Glycol Concentration', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('${_glycolGallons?.toStringAsFixed(0)} gallons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
              Text('Glycol Required', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Freeze Point', '${_freezeProtection.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Cp Factor', '${_specificHeat?.toStringAsFixed(2)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Viscosity', '${_viscosityFactor?.toStringAsFixed(2)}×')),
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
