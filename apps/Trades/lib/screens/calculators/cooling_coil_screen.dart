import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Cooling Coil Calculator - Design System v2.6
/// Coil capacity and leaving air conditions
class CoolingCoilScreen extends ConsumerStatefulWidget {
  const CoolingCoilScreen({super.key});
  @override
  ConsumerState<CoolingCoilScreen> createState() => _CoolingCoilScreenState();
}

class _CoolingCoilScreenState extends ConsumerState<CoolingCoilScreen> {
  double _cfm = 1200;
  double _enteringDb = 80;
  double _enteringWb = 67;
  double _leavingDb = 55;
  double _totalCapacity = 36000; // BTU/h
  String _coilType = 'dx';

  double? _sensibleCapacity;
  double? _latentCapacity;
  double? _shr;
  double? _moistureRemoved;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Total capacity from inputs
    // Q = 4.5 × CFM × Δh (enthalpy change)

    // Simplified calculation
    // Sensible: Qs = 1.08 × CFM × ΔT
    final sensibleCapacity = 1.08 * _cfm * (_enteringDb - _leavingDb);

    // Latent from total - sensible
    final latentCapacity = _totalCapacity - sensibleCapacity;

    // Sensible Heat Ratio
    final shr = sensibleCapacity / _totalCapacity;

    // Moisture removal (pints/hour)
    // 1 BTU/h latent ≈ 0.00085 lb/h water
    // 1 pint = 1.04 lb
    final moistureRemoved = (latentCapacity * 0.00085 / 1.04) * 8; // pints/day

    String recommendation;
    if (shr > 0.85) {
      recommendation = 'High SHR (${(shr * 100).toStringAsFixed(0)}%): Mostly sensible cooling. Good for low humidity applications.';
    } else if (shr > 0.70) {
      recommendation = 'Normal SHR (${(shr * 100).toStringAsFixed(0)}%): Balanced sensible/latent. Typical comfort cooling.';
    } else {
      recommendation = 'Low SHR (${(shr * 100).toStringAsFixed(0)}%): High latent load. Good for humid climates or high occupancy.';
    }

    if (_coilType == 'dx') {
      recommendation += ' DX coil: Check superheat and subcooling. Verify face velocity 400-500 fpm.';
    } else {
      recommendation += ' Chilled water: Check entering/leaving water temp (typically 42-54°F). 3 GPM/ton flow.';
    }

    if (_leavingDb < 50) {
      recommendation += ' Very low leaving temp may cause condensate freezing. Check coil design.';
    }

    if (latentCapacity < 0) {
      recommendation += ' WARNING: Calculated latent is negative. Check inputs - total capacity may be understated.';
    }

    recommendation += ' Remove ${moistureRemoved.toStringAsFixed(1)} pints/day at rated conditions.';

    setState(() {
      _sensibleCapacity = sensibleCapacity;
      _latentCapacity = latentCapacity > 0 ? latentCapacity : 0;
      _shr = shr.clamp(0, 1);
      _moistureRemoved = moistureRemoved > 0 ? moistureRemoved : 0;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _cfm = 1200;
      _enteringDb = 80;
      _enteringWb = 67;
      _leavingDb = 55;
      _totalCapacity = 36000;
      _coilType = 'dx';
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
        title: Text('Cooling Coil', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COIL TYPE'),
              const SizedBox(height: 12),
              _buildCoilTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Airflow', value: _cfm, min: 400, max: 5000, unit: ' CFM', onChanged: (v) { setState(() => _cfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total Capacity', value: _totalCapacity / 1000, min: 12, max: 150, unit: 'k BTU/h', onChanged: (v) { setState(() => _totalCapacity = v * 1000); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIR CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Entering DB', _enteringDb, 70, 95, '°F', (v) { setState(() => _enteringDb = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Leaving DB', _leavingDb, 45, 65, '°F', (v) { setState(() => _leavingDb = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Entering WB', value: _enteringWb, min: 60, max: 80, unit: '°F', onChanged: (v) { setState(() => _enteringWb = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'COIL PERFORMANCE'),
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
        Icon(LucideIcons.thermometerSnowflake, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Cooling coil splits capacity into sensible (temperature) and latent (moisture). SHR = Sensible/Total.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCoilTypeSelector(ZaftoColors colors) {
    final types = [('dx', 'DX (Refrigerant)'), ('chw', 'Chilled Water')];
    return Row(
      children: types.map((t) {
        final selected = _coilType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _coilType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
    if (_sensibleCapacity == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${((_shr ?? 0) * 100).toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Sensible Heat Ratio', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('${(_sensibleCapacity! / 1000).toStringAsFixed(1)}k', style: TextStyle(color: Colors.blue.shade700, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Sensible BTU/h', style: TextStyle(color: Colors.blue.shade600, fontSize: 10)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('${(_latentCapacity! / 1000).toStringAsFixed(1)}k', style: TextStyle(color: Colors.cyan.shade700, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Latent BTU/h', style: TextStyle(color: Colors.cyan.shade600, fontSize: 10)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Total', '${(_totalCapacity / 1000).toStringAsFixed(0)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Moisture', '${_moistureRemoved?.toStringAsFixed(1)} pt/day')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Delta T', '${(_enteringDb - _leavingDb).toStringAsFixed(0)}°F')),
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
