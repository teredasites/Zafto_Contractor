import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Thermal Storage Calculator - Design System v2.6
/// Ice and chilled water storage sizing
class ThermalStorageScreen extends ConsumerStatefulWidget {
  const ThermalStorageScreen({super.key});
  @override
  ConsumerState<ThermalStorageScreen> createState() => _ThermalStorageScreenState();
}

class _ThermalStorageScreenState extends ConsumerState<ThermalStorageScreen> {
  double _peakLoad = 500; // tons
  double _peakDuration = 6; // hours
  double _offPeakHours = 10; // hours available for charging
  double _electricRate = 0.15; // $/kWh
  double _demandCharge = 15; // $/kW
  String _storageType = 'ice';
  String _strategy = 'partial';

  double? _storageCapacity;
  double? _chillerSize;
  double? _tankVolume;
  double? _annualSavings;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Storage capacity needed
    double storageCapacity;
    double chillerSize;

    if (_strategy == 'full') {
      // Full storage: Store entire on-peak load
      storageCapacity = _peakLoad * _peakDuration; // ton-hours
      chillerSize = storageCapacity / _offPeakHours;
    } else if (_strategy == 'partial') {
      // Partial storage: Meet 50% of peak from storage
      storageCapacity = _peakLoad * _peakDuration * 0.5;
      chillerSize = _peakLoad * 0.6; // 60% of peak
    } else { // load_leveling
      // Size chiller for average load, storage for peaks
      final avgLoad = _peakLoad * 0.65;
      chillerSize = avgLoad;
      storageCapacity = (_peakLoad - avgLoad) * _peakDuration;
    }

    // Tank volume calculation
    double tankVolume;
    if (_storageType == 'ice') {
      // Ice: 144 BTU/lb latent heat
      // Approx 10 cu ft per ton-hour for internal melt
      tankVolume = storageCapacity * 10;
    } else if (_storageType == 'eutectic') {
      // Eutectic salt: 45-50 BTU/lb
      tankVolume = storageCapacity * 20;
    } else {
      // Chilled water: 15-20 BTU/lb (20°F ΔT)
      // 1 ton-hour = 12,000 BTU = 750 gallons at 16 BTU/gal
      tankVolume = (storageCapacity * 12000) / (16 * 7.48); // cu ft
    }

    // Annual savings estimate
    // Assume 20% reduction in demand charges and 30% cheaper off-peak power
    final peakKw = _peakLoad * 3.517; // kW per ton
    final demandSavings = _demandCharge * peakKw * 0.4 * 12; // 40% reduction, 12 months
    final energySavings = storageCapacity * 12 * 0.3 * _electricRate * 180; // 180 cooling days
    final annualSavings = demandSavings + energySavings;

    String recommendation;
    recommendation = '${_strategy == 'full' ? 'Full' : _strategy == 'partial' ? 'Partial' : 'Load-leveling'} storage: ${storageCapacity.toStringAsFixed(0)} ton-hours capacity. ';

    if (_storageType == 'ice') {
      recommendation += 'Ice storage: 144 BTU/lb. Requires glycol or secondary loop. Chiller must produce 25°F brine.';
    } else if (_storageType == 'eutectic') {
      recommendation += 'Eutectic salt: Phase change at ~47°F. Good for moderate temp applications.';
    } else {
      recommendation += 'Chilled water: Simpler system but larger tank. 20°F temperature differential typical.';
    }

    if (_strategy == 'full') {
      recommendation += ' Full storage: Highest demand savings but largest equipment.';
    } else if (_strategy == 'partial') {
      recommendation += ' Partial storage: Best ROI for most applications. Chiller runs during peak.';
    } else {
      recommendation += ' Load-leveling: Smallest chiller. Storage supplements peaks.';
    }

    recommendation += ' Estimated annual savings: \$${(annualSavings / 1000).toStringAsFixed(1)}k. Simple payback varies 3-7 years.';

    setState(() {
      _storageCapacity = storageCapacity;
      _chillerSize = chillerSize;
      _tankVolume = tankVolume;
      _annualSavings = annualSavings;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _peakLoad = 500;
      _peakDuration = 6;
      _offPeakHours = 10;
      _electricRate = 0.15;
      _demandCharge = 15;
      _storageType = 'ice';
      _strategy = 'partial';
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
        title: Text('Thermal Storage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'STORAGE TYPE'),
              const SizedBox(height: 12),
              _buildStorageTypeSelector(colors),
              const SizedBox(height: 12),
              _buildStrategySelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD PROFILE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Peak Load', _peakLoad, 100, 2000, ' ton', (v) { setState(() => _peakLoad = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Peak Hours', _peakDuration, 2, 12, ' hr', (v) { setState(() => _peakDuration = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Off-Peak Hours', value: _offPeakHours, min: 6, max: 14, unit: ' hr', onChanged: (v) { setState(() => _offPeakHours = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'UTILITY RATES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Electric', _electricRate, 0.05, 0.30, ' \$/kWh', (v) { setState(() => _electricRate = v); _calculate(); }, decimals: 2)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Demand', _demandCharge, 5, 30, ' \$/kW', (v) { setState(() => _demandCharge = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'STORAGE SIZING'),
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
        Expanded(child: Text('Thermal storage shifts cooling load to off-peak hours. Reduces demand charges and takes advantage of cheaper nighttime power.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildStorageTypeSelector(ZaftoColors colors) {
    final types = [('ice', 'Ice'), ('chilled_water', 'Chilled Water'), ('eutectic', 'Eutectic')];
    return Row(
      children: types.map((t) {
        final selected = _storageType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _storageType = t.$1); _calculate(); },
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

  Widget _buildStrategySelector(ZaftoColors colors) {
    final strategies = [('full', 'Full Storage'), ('partial', 'Partial'), ('load_leveling', 'Load Level')];
    return Row(
      children: strategies.map((s) {
        final selected = _strategy == s.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _strategy = s.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: s != strategies.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
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
    if (_storageCapacity == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_storageCapacity?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('Ton-Hours Storage', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('${_chillerSize?.toStringAsFixed(0)}', style: TextStyle(color: Colors.blue.shade700, fontSize: 20, fontWeight: FontWeight.w600)),
                  Text('Tons Chiller', style: TextStyle(color: Colors.blue.shade600, fontSize: 10)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('\$${(_annualSavings! / 1000).toStringAsFixed(1)}k', style: TextStyle(color: Colors.green.shade700, fontSize: 20, fontWeight: FontWeight.w600)),
                  Text('Annual Savings', style: TextStyle(color: Colors.green.shade600, fontSize: 10)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Tank Volume', '${(_tankVolume! / 1000).toStringAsFixed(1)}k cu ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Peak Load', '${_peakLoad.toStringAsFixed(0)} ton')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Strategy', _strategy.replaceAll('_', ' '))),
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
