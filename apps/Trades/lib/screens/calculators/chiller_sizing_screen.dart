import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Chiller Sizing Calculator - Design System v2.6
/// Water chiller capacity and selection
class ChillerSizingScreen extends ConsumerStatefulWidget {
  const ChillerSizingScreen({super.key});
  @override
  ConsumerState<ChillerSizingScreen> createState() => _ChillerSizingScreenState();
}

class _ChillerSizingScreenState extends ConsumerState<ChillerSizingScreen> {
  double _coolingLoad = 100; // tons
  double _chilledWaterSupply = 44;
  double _chilledWaterReturn = 54;
  double _condenserWaterEntering = 85;
  String _chillerType = 'water_cooled';
  String _compressorType = 'centrifugal';
  double _diversityFactor = 0.85;

  double? _tonnage;
  double? _gpmEvap;
  double? _gpmCondenser;
  double? _kWPerTon;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Apply diversity factor
    final adjustedLoad = _coolingLoad * _diversityFactor;

    // Evaporator flow rate
    // GPM = (Tons × 24) / ΔT (for 10°F ΔT, GPM = 2.4 × Tons)
    final deltaT = _chilledWaterReturn - _chilledWaterSupply;
    final gpmEvap = (adjustedLoad * 24) / deltaT;

    // Condenser flow rate (for water-cooled)
    // Typically 3 GPM per ton
    final gpmCondenser = _chillerType == 'water_cooled' ? adjustedLoad * 3 : 0.0;

    // Efficiency (kW/ton) based on chiller type
    double kWPerTon;
    if (_chillerType == 'water_cooled') {
      switch (_compressorType) {
        case 'centrifugal':
          kWPerTon = 0.55 + ((_condenserWaterEntering - 85) * 0.015);
          break;
        case 'screw':
          kWPerTon = 0.65 + ((_condenserWaterEntering - 85) * 0.015);
          break;
        case 'scroll':
          kWPerTon = 0.75 + ((_condenserWaterEntering - 85) * 0.015);
          break;
        default:
          kWPerTon = 0.65;
      }
    } else {
      // Air-cooled: typically 1.0-1.3 kW/ton
      kWPerTon = _compressorType == 'scroll' ? 1.2 : 1.0;
    }

    String recommendation;
    if (adjustedLoad < 50) {
      recommendation = 'Small load: Consider multiple scroll chillers for redundancy and staging.';
    } else if (adjustedLoad < 200) {
      recommendation = 'Medium load: Screw or centrifugal chiller. Consider VFD for part-load efficiency.';
    } else {
      recommendation = 'Large load: Centrifugal with VFD recommended. Consider N+1 redundancy.';
    }

    if (_chillerType == 'water_cooled') {
      recommendation += ' Water-cooled: Size cooling tower for ${(adjustedLoad * 1.25).toStringAsFixed(0)} tons rejection.';
    } else {
      recommendation += ' Air-cooled: Allow adequate condenser air clearance per manufacturer.';
    }

    if (deltaT < 10) {
      recommendation += ' Low ΔT increases flow rate - verify pump sizing.';
    } else if (deltaT > 14) {
      recommendation += ' High ΔT improves efficiency but verify coil performance.';
    }

    if (_diversityFactor < 0.8) {
      recommendation += ' Low diversity: Verify simultaneous load assumptions.';
    }

    setState(() {
      _tonnage = adjustedLoad;
      _gpmEvap = gpmEvap;
      _gpmCondenser = gpmCondenser;
      _kWPerTon = kWPerTon;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _coolingLoad = 100;
      _chilledWaterSupply = 44;
      _chilledWaterReturn = 54;
      _condenserWaterEntering = 85;
      _chillerType = 'water_cooled';
      _compressorType = 'centrifugal';
      _diversityFactor = 0.85;
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
        title: Text('Chiller Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COOLING LOAD'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Peak Cooling Load', value: _coolingLoad, min: 10, max: 500, unit: ' tons', onChanged: (v) { setState(() => _coolingLoad = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Diversity Factor', value: _diversityFactor, min: 0.5, max: 1.0, unit: '', decimals: 2, onChanged: (v) { setState(() => _diversityFactor = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WATER TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'CHW Supply', _chilledWaterSupply, 40, 50, '°F', (v) { setState(() => _chilledWaterSupply = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'CHW Return', _chilledWaterReturn, 50, 60, '°F', (v) { setState(() => _chilledWaterReturn = v); _calculate(); })),
              ]),
              if (_chillerType == 'water_cooled') ...[
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Condenser Water Entering', value: _condenserWaterEntering, min: 75, max: 95, unit: '°F', onChanged: (v) { setState(() => _condenserWaterEntering = v); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CHILLER TYPE'),
              const SizedBox(height: 12),
              _buildChillerTypeSelector(colors),
              const SizedBox(height: 12),
              _buildCompressorTypeSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'CHILLER SELECTION'),
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
        Expanded(child: Text('Chiller sizing: Apply diversity factor to peak load. Standard CHW: 44°F supply, 54°F return (10°F ΔT).', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildChillerTypeSelector(ZaftoColors colors) {
    final types = [('water_cooled', 'Water-Cooled'), ('air_cooled', 'Air-Cooled')];
    return Row(
      children: types.map((t) {
        final selected = _chillerType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _chillerType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompressorTypeSelector(ZaftoColors colors) {
    final types = [('centrifugal', 'Centrifugal'), ('screw', 'Screw'), ('scroll', 'Scroll')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Compressor Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: types.map((t) {
            final selected = _compressorType == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _compressorType = t.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_tonnage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_tonnage?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Tons (with diversity)', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text('${_kWPerTon?.toStringAsFixed(2)} kW/ton', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Evap Flow', '${_gpmEvap?.toStringAsFixed(0)} GPM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Cond Flow', _chillerType == 'water_cooled' ? '${_gpmCondenser?.toStringAsFixed(0)} GPM' : 'N/A')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Input', '${((_tonnage ?? 0) * (_kWPerTon ?? 0)).toStringAsFixed(0)} kW')),
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
