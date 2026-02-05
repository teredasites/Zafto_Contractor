import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Refrigerant Charge Calculator - Design System v2.6
/// Superheat/subcooling based charging verification
class RefrigerantChargeScreen extends ConsumerStatefulWidget {
  const RefrigerantChargeScreen({super.key});
  @override
  ConsumerState<RefrigerantChargeScreen> createState() => _RefrigerantChargeScreenState();
}

class _RefrigerantChargeScreenState extends ConsumerState<RefrigerantChargeScreen> {
  String _meteringDevice = 'txv';
  String _refrigerant = 'r410a';

  // Measured values
  double _suctionPressure = 118;
  double _suctionTemp = 55;
  double _liquidPressure = 350;
  double _liquidTemp = 95;
  double _outdoorTemp = 95;
  double _indoorWetBulb = 67;

  double? _superheat;
  double? _subcooling;
  double? _satSuctionTemp;
  double? _satLiquidTemp;
  String? _chargeStatus;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Saturation temperatures based on refrigerant and pressure
    // R-410A PT chart (simplified)
    double satSuctionTemp;
    double satLiquidTemp;

    if (_refrigerant == 'r410a') {
      // R-410A saturation temps (approximate)
      satSuctionTemp = _getSatTempR410A(_suctionPressure);
      satLiquidTemp = _getSatTempR410A(_liquidPressure);
    } else if (_refrigerant == 'r22') {
      satSuctionTemp = _getSatTempR22(_suctionPressure);
      satLiquidTemp = _getSatTempR22(_liquidPressure);
    } else if (_refrigerant == 'r32') {
      satSuctionTemp = _getSatTempR32(_suctionPressure);
      satLiquidTemp = _getSatTempR32(_liquidPressure);
    } else {
      satSuctionTemp = _getSatTempR134a(_suctionPressure);
      satLiquidTemp = _getSatTempR134a(_liquidPressure);
    }

    // Calculate superheat and subcooling
    final superheat = _suctionTemp - satSuctionTemp;
    final subcooling = satLiquidTemp - _liquidTemp;

    // Determine charge status
    String chargeStatus;
    String recommendation;

    if (_meteringDevice == 'txv') {
      // TXV systems: Check subcooling (typically 10-15°F)
      if (subcooling < 5) {
        chargeStatus = 'UNDERCHARGED';
        recommendation = 'Low subcooling indicates undercharge. Add refrigerant in small amounts, verify subcooling increases.';
      } else if (subcooling > 20) {
        chargeStatus = 'OVERCHARGED';
        recommendation = 'High subcooling indicates overcharge or condenser issue. Check for restricted airflow or recover excess charge.';
      } else if (subcooling >= 8 && subcooling <= 15) {
        chargeStatus = 'PROPER CHARGE';
        recommendation = 'Subcooling in optimal range. System charge verified.';
      } else {
        chargeStatus = 'CHECK SYSTEM';
        recommendation = 'Subcooling slightly out of range. Verify conditions and recheck.';
      }

      // Also verify superheat is reasonable
      if (superheat < 5) {
        recommendation += ' WARNING: Low superheat may indicate liquid floodback to compressor.';
      } else if (superheat > 25) {
        recommendation += ' Note: High superheat may indicate low charge, TXV issue, or low airflow.';
      }

    } else {
      // Fixed orifice (piston): Check superheat
      // Target superheat varies with conditions
      // Simplified target: ~10-20°F at typical conditions

      if (superheat < 5) {
        chargeStatus = 'OVERCHARGED';
        recommendation = 'Low superheat indicates overcharge or high indoor load. Recover refrigerant or check conditions.';
      } else if (superheat > 25) {
        chargeStatus = 'UNDERCHARGED';
        recommendation = 'High superheat indicates undercharge. Add refrigerant, verify superheat decreases.';
      } else if (superheat >= 8 && superheat <= 20) {
        chargeStatus = 'PROPER CHARGE';
        recommendation = 'Superheat in acceptable range. Verify subcooling for overall system health.';
      } else {
        chargeStatus = 'CHECK CONDITIONS';
        recommendation = 'Superheat slightly out of range. Verify outdoor temp and indoor wet bulb match test conditions.';
      }
    }

    // Add refrigerant-specific notes
    if (_refrigerant == 'r410a') {
      recommendation += ' R-410A: Charge in liquid state only. Typical suction: 100-130 PSIG at 75°F.';
    } else if (_refrigerant == 'r22') {
      recommendation += ' R-22 (phaseout): Typical suction: 68-76 PSIG at 75°F.';
    }

    setState(() {
      _superheat = superheat;
      _subcooling = subcooling;
      _satSuctionTemp = satSuctionTemp;
      _satLiquidTemp = satLiquidTemp;
      _chargeStatus = chargeStatus;
      _recommendation = recommendation;
    });
  }

  double _getSatTempR410A(double psig) {
    // R-410A PT approximation (psig to °F)
    // Simplified curve fit
    if (psig <= 50) return -10 + (psig - 30) * 0.8;
    if (psig <= 100) return 25 + (psig - 50) * 0.5;
    if (psig <= 150) return 50 + (psig - 100) * 0.4;
    if (psig <= 250) return 70 + (psig - 150) * 0.25;
    if (psig <= 400) return 95 + (psig - 250) * 0.15;
    return 117 + (psig - 400) * 0.1;
  }

  double _getSatTempR22(double psig) {
    // R-22 PT approximation
    if (psig <= 30) return -20 + (psig - 10) * 1.0;
    if (psig <= 70) return 10 + (psig - 30) * 0.75;
    if (psig <= 120) return 40 + (psig - 70) * 0.4;
    if (psig <= 200) return 60 + (psig - 120) * 0.25;
    return 80 + (psig - 200) * 0.15;
  }

  double _getSatTempR32(double psig) {
    // R-32 similar to R-410A but slightly different
    if (psig <= 50) return -15 + (psig - 30) * 0.9;
    if (psig <= 100) return 20 + (psig - 50) * 0.55;
    if (psig <= 200) return 47 + (psig - 100) * 0.3;
    if (psig <= 350) return 77 + (psig - 200) * 0.2;
    return 107 + (psig - 350) * 0.12;
  }

  double _getSatTempR134a(double psig) {
    // R-134a PT approximation
    if (psig <= 10) return 0 + psig * 2;
    if (psig <= 30) return 20 + (psig - 10) * 1.5;
    if (psig <= 60) return 50 + (psig - 30) * 1.0;
    if (psig <= 100) return 80 + (psig - 60) * 0.5;
    return 100 + (psig - 100) * 0.3;
  }

  void _reset() {
    setState(() {
      _meteringDevice = 'txv';
      _refrigerant = 'r410a';
      _suctionPressure = 118;
      _suctionTemp = 55;
      _liquidPressure = 350;
      _liquidTemp = 95;
      _outdoorTemp = 95;
      _indoorWetBulb = 67;
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
        title: Text('Refrigerant Charge', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSegmentedToggle(colors, label: 'Metering Device', options: const ['TXV', 'Piston/Orifice'], selectedIndex: _meteringDevice == 'txv' ? 0 : 1, onChanged: (i) { setState(() => _meteringDevice = i == 0 ? 'txv' : 'piston'); _calculate(); }),
              const SizedBox(height: 12),
              _buildRefrigerantSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SUCTION LINE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Suction Pressure', value: _suctionPressure, min: 50, max: 200, unit: ' PSIG', onChanged: (v) { setState(() => _suctionPressure = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Suction Temp', value: _suctionTemp, min: 30, max: 80, unit: '\u00B0F', onChanged: (v) { setState(() => _suctionTemp = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LIQUID LINE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Liquid Pressure', value: _liquidPressure, min: 200, max: 500, unit: ' PSIG', onChanged: (v) { setState(() => _liquidPressure = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Liquid Temp', value: _liquidTemp, min: 70, max: 130, unit: '\u00B0F', onChanged: (v) { setState(() => _liquidTemp = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'CHARGE ANALYSIS'),
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
        Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('TXV systems: Check subcooling (10-15°F). Piston systems: Check superheat (10-20°F at design conditions).', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildRefrigerantSelector(ZaftoColors colors) {
    final refs = ['R-410A', 'R-22', 'R-32', 'R-134a'];
    final refIds = ['r410a', 'r22', 'r32', 'r134a'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Refrigerant', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: refs.asMap().entries.map((e) {
            final selected = _refrigerant == refIds[e.key];
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _refrigerant = refIds[e.key]); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: e.key < refs.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
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
    if (_superheat == null) return const SizedBox.shrink();

    Color statusColor;
    if (_chargeStatus == 'PROPER CHARGE') {
      statusColor = Colors.green;
    } else if (_chargeStatus == 'CHECK SYSTEM' || _chargeStatus == 'CHECK CONDITIONS') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    final primaryMetric = _meteringDevice == 'txv' ? _subcooling : _superheat;
    final primaryLabel = _meteringDevice == 'txv' ? 'Subcooling' : 'Superheat';
    final secondaryMetric = _meteringDevice == 'txv' ? _superheat : _subcooling;
    final secondaryLabel = _meteringDevice == 'txv' ? 'Superheat' : 'Subcooling';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(_chargeStatus ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: Column(children: [
                Text('${primaryMetric?.toStringAsFixed(1)}°F', style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text(primaryLabel, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Text(_meteringDevice == 'txv' ? '(Target: 10-15°F)' : '(Target: 10-20°F)', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ]),
            ),
            Container(width: 1, height: 80, color: colors.borderDefault),
            Expanded(
              child: Column(children: [
                Text('${secondaryMetric?.toStringAsFixed(1)}°F', style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text(secondaryLabel, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SATURATION TEMPS', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Suction Sat:', style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                Text('${_satSuctionTemp?.toStringAsFixed(1)}°F', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Liquid Sat:', style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                Text('${_satLiquidTemp?.toStringAsFixed(1)}°F', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }
}
