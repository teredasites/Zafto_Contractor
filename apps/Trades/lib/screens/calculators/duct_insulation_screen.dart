import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Duct Insulation Calculator - Design System v2.6
/// R-value and condensation prevention
class DuctInsulationScreen extends ConsumerStatefulWidget {
  const DuctInsulationScreen({super.key});
  @override
  ConsumerState<DuctInsulationScreen> createState() => _DuctInsulationScreenState();
}

class _DuctInsulationScreenState extends ConsumerState<DuctInsulationScreen> {
  double _supplyAirTemp = 55;
  double _ambientTemp = 90;
  double _ambientRh = 50;
  double _ductWidth = 12; // inches
  double _ductHeight = 8;
  double _ductLength = 50; // feet
  String _ductLocation = 'unconditioned';
  String _ductMaterial = 'metal';

  double? _rValueNeeded;
  double? _heatGain;
  double? _condensationRisk;
  String? _insulationType;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Surface area of rectangular duct
    final perimeter = 2 * (_ductWidth + _ductHeight) / 12; // feet
    final surfaceArea = perimeter * _ductLength;

    // Temperature difference
    final deltaT = _ambientTemp - _supplyAirTemp;

    // Minimum R-value requirements (IECC)
    double minRValue;
    if (_ductLocation == 'conditioned') {
      minRValue = 0; // No insulation required in conditioned space
    } else if (_ductLocation == 'unconditioned') {
      minRValue = deltaT > 25 ? 8.0 : 6.0;
    } else { // outdoor
      minRValue = 8.0;
    }

    // Heat gain without insulation (BTU/h)
    // Q = U * A * ΔT, where U ≈ 1.0 for uninsulated metal duct
    final uUninsulated = _ductMaterial == 'metal' ? 1.0 : 0.8;
    final heatGainUninsulated = uUninsulated * surfaceArea * deltaT;

    // Heat gain with recommended insulation
    final uInsulated = 1 / minRValue;
    final heatGainInsulated = minRValue > 0 ? uInsulated * surfaceArea * deltaT : 0.0;

    // Condensation check
    // Calculate dew point
    final a = 17.27;
    final b = 237.7;
    final tC = (_ambientTemp - 32) * 5 / 9;
    final gamma = math.log(_ambientRh / 100) + (a * tC) / (b + tC);
    final dewPointC = (b * gamma) / (a - gamma);
    final dewPoint = dewPointC * 9 / 5 + 32;

    // Condensation risk if duct surface < dew point
    final condensationRisk = _supplyAirTemp < dewPoint ? 100.0 :
        (dewPoint - _supplyAirTemp + 10) / 10 * 100;

    String insulationType;
    if (minRValue >= 8) {
      insulationType = 'R-8 (2" fiberglass wrap)';
    } else if (minRValue >= 6) {
      insulationType = 'R-6 (1.5" fiberglass wrap)';
    } else if (minRValue > 0) {
      insulationType = 'R-4.2 (1" fiberglass wrap)';
    } else {
      insulationType = 'None required';
    }

    String recommendation;
    if (_ductLocation == 'conditioned') {
      recommendation = 'Ducts in conditioned space: Insulation optional but helps with noise reduction.';
    } else {
      recommendation = 'Unconditioned space: R-${minRValue.toStringAsFixed(0)} minimum per code. ';
      recommendation += 'Heat gain without insulation: ${heatGainUninsulated.toStringAsFixed(0)} BTU/h.';
    }

    if (condensationRisk > 50) {
      recommendation += ' CONDENSATION RISK: Ambient dew point (${dewPoint.toStringAsFixed(0)}°F) near supply temp. Use vapor barrier facing or insulated flex duct.';
    }

    if (_ductMaterial == 'flex') {
      recommendation += ' Flex duct: Use insulated type (R-4.2 to R-8). Keep runs short and straight.';
    }

    recommendation += ' Seal all joints before insulating. Inspect for damage after installation.';

    setState(() {
      _rValueNeeded = minRValue;
      _heatGain = heatGainUninsulated;
      _condensationRisk = condensationRisk.clamp(0.0, 100.0);
      _insulationType = insulationType;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _supplyAirTemp = 55;
      _ambientTemp = 90;
      _ambientRh = 50;
      _ductWidth = 12;
      _ductHeight = 8;
      _ductLength = 50;
      _ductLocation = 'unconditioned';
      _ductMaterial = 'metal';
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
        title: Text('Duct Insulation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DUCT LOCATION'),
              const SizedBox(height: 12),
              _buildLocationSelector(colors),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DUCT SIZE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Width', _ductWidth, 4, 36, '"', (v) { setState(() => _ductWidth = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Height', _ductHeight, 4, 24, '"', (v) { setState(() => _ductHeight = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Length', _ductLength, 10, 200, ' ft', (v) { setState(() => _ductLength = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Supply Air', _supplyAirTemp, 45, 65, '°F', (v) { setState(() => _supplyAirTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Ambient', _ambientTemp, 60, 130, '°F', (v) { setState(() => _ambientTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ambient RH', value: _ambientRh, min: 20, max: 90, unit: '%', onChanged: (v) { setState(() => _ambientRh = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'INSULATION REQUIREMENTS'),
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
        Icon(LucideIcons.layers, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('IECC requires R-6 to R-8 for ducts in unconditioned spaces. Vapor barrier critical for condensation prevention.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildLocationSelector(ZaftoColors colors) {
    final locations = [('conditioned', 'Conditioned'), ('unconditioned', 'Unconditioned'), ('outdoor', 'Outdoor')];
    return Row(
      children: locations.map((l) {
        final selected = _ductLocation == l.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _ductLocation = l.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: l != locations.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(l.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = [('metal', 'Sheet Metal'), ('flex', 'Flex Duct'), ('board', 'Duct Board')];
    return Row(
      children: materials.map((m) {
        final selected = _ductMaterial == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _ductMaterial = m.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: m != materials.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(m.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
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
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
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
    if (_rValueNeeded == null) return const SizedBox.shrink();

    final condensationRisk = _condensationRisk ?? 0;
    final hasRisk = condensationRisk > 50;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('R-${_rValueNeeded?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Minimum Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_insulationType ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          ),
          if (hasRisk) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(LucideIcons.droplets, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text('Condensation Risk: ${condensationRisk.toStringAsFixed(0)}%', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Heat Gain', '${_heatGain?.toStringAsFixed(0)} BTU/h')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Delta T', '${(_ambientTemp - _supplyAirTemp).toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Location', _ductLocation)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(hasRisk ? LucideIcons.alertTriangle : LucideIcons.info, color: hasRisk ? Colors.orange : colors.textSecondary, size: 16),
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
