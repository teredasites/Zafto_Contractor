import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Air Handler Sizing Calculator - Design System v2.6
/// Central air handling unit CFM and component sizing
class AhuSizingScreen extends ConsumerStatefulWidget {
  const AhuSizingScreen({super.key});
  @override
  ConsumerState<AhuSizingScreen> createState() => _AhuSizingScreenState();
}

class _AhuSizingScreenState extends ConsumerState<AhuSizingScreen> {
  double _coolingTons = 20;
  double _supplyAirTemp = 55;
  double _returnAirTemp = 75;
  double _outsideAirPercent = 20;
  String _ahuType = 'draw_through';
  String _filterType = 'merv13';

  double? _supplyCfm;
  double? _outsideAirCfm;
  double? _totalStaticPressure;
  String? _motorHp;
  String? _coilFaceVelocity;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // CFM calculation
    // CFM = (Tons × 12,000) / (1.08 × ΔT)
    final deltaT = _returnAirTemp - _supplyAirTemp;
    final supplyCfm = (_coolingTons * 12000) / (1.08 * deltaT);

    // Outside air CFM
    final outsideAirCfm = supplyCfm * (_outsideAirPercent / 100);

    // Estimate total static pressure (in. W.C.)
    double filterDrop;
    switch (_filterType) {
      case 'merv8': filterDrop = 0.15; break;
      case 'merv13': filterDrop = 0.30; break;
      case 'hepa': filterDrop = 1.0; break;
      default: filterDrop = 0.25;
    }

    // Typical component pressure drops
    final coolingCoil = 0.40;
    final heatingCoil = 0.20;
    final ductwork = 0.75;
    final diffusers = 0.10;
    final totalStatic = filterDrop + coolingCoil + heatingCoil + ductwork + diffusers;

    // Fan motor HP
    // HP = (CFM × TSP) / (6356 × efficiency)
    // Assume 65% fan efficiency
    final fanHp = (supplyCfm * totalStatic) / (6356 * 0.65);
    String motorHp;
    if (fanHp <= 0.75) motorHp = '1 HP';
    else if (fanHp <= 1.5) motorHp = '2 HP';
    else if (fanHp <= 2.5) motorHp = '3 HP';
    else if (fanHp <= 4) motorHp = '5 HP';
    else if (fanHp <= 6) motorHp = '7.5 HP';
    else if (fanHp <= 8) motorHp = '10 HP';
    else if (fanHp <= 12) motorHp = '15 HP';
    else if (fanHp <= 18) motorHp = '20 HP';
    else if (fanHp <= 24) motorHp = '25 HP';
    else motorHp = '${(fanHp / 5).ceil() * 5} HP';

    // Coil face velocity (target 450-550 fpm)
    // Assume 24" × 24" per 2000 CFM for coil face area
    final coilArea = supplyCfm / 500; // sq ft at 500 fpm
    final faceVelocity = supplyCfm / coilArea;
    final coilFaceVelocity = '${faceVelocity.toStringAsFixed(0)} fpm';

    String recommendation;
    if (_ahuType == 'draw_through') {
      recommendation = 'Draw-through: Fan downstream of coils. Better coil distribution. Standard configuration.';
    } else {
      recommendation = 'Blow-through: Fan upstream of coils. Higher coil velocity. Requires careful design.';
    }

    if (totalStatic > 3.0) {
      recommendation += ' High static (${totalStatic.toStringAsFixed(2)}" W.C.) - VFD recommended.';
    }

    if (_outsideAirPercent > 30) {
      recommendation += ' High OA% - consider energy recovery (ERV/HRV).';
    }

    if (_filterType == 'hepa') {
      recommendation += ' HEPA filters: High pressure drop. May need pre-filters.';
    }

    setState(() {
      _supplyCfm = supplyCfm;
      _outsideAirCfm = outsideAirCfm;
      _totalStaticPressure = totalStatic;
      _motorHp = motorHp;
      _coilFaceVelocity = coilFaceVelocity;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coolingTons = 20;
      _supplyAirTemp = 55;
      _returnAirTemp = 75;
      _outsideAirPercent = 20;
      _ahuType = 'draw_through';
      _filterType = 'merv13';
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
        title: Text('Air Handler (AHU)', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CAPACITY'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Cooling Capacity', value: _coolingTons, min: 5, max: 100, unit: ' tons', onChanged: (v) { setState(() => _coolingTons = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Outside Air %', value: _outsideAirPercent, min: 10, max: 100, unit: '%', onChanged: (v) { setState(() => _outsideAirPercent = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIR TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Supply Air', _supplyAirTemp, 50, 60, '°F', (v) { setState(() => _supplyAirTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Return Air', _returnAirTemp, 70, 80, '°F', (v) { setState(() => _returnAirTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONFIGURATION'),
              const SizedBox(height: 12),
              _buildAhuTypeSelector(colors),
              const SizedBox(height: 12),
              _buildFilterSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'AHU SIZING'),
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
        Icon(LucideIcons.airVent, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('AHU sizing: CFM based on cooling load and supply temp. 400-500 CFM/ton typical. Target 500 fpm coil face velocity.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildAhuTypeSelector(ZaftoColors colors) {
    final types = [('draw_through', 'Draw-Through'), ('blow_through', 'Blow-Through')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AHU Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: types.map((t) {
            final selected = _ahuType == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _ahuType = t.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterSelector(ZaftoColors colors) {
    final filters = [('merv8', 'MERV 8'), ('merv13', 'MERV 13'), ('hepa', 'HEPA')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filter Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: filters.map((f) {
            final selected = _filterType == f.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _filterType = f.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: f != filters.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(f.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
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
    if (_supplyCfm == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_supplyCfm?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('CFM Supply Air', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('Motor: $_motorHp', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Outside Air', '${_outsideAirCfm?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Static', '${_totalStaticPressure?.toStringAsFixed(2)}" WC')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Coil Vel.', _coilFaceVelocity ?? '')),
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
