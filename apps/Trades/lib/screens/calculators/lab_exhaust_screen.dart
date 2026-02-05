import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Lab Exhaust Calculator - Design System v2.6
/// Fume hood and laboratory exhaust sizing
class LabExhaustScreen extends ConsumerStatefulWidget {
  const LabExhaustScreen({super.key});
  @override
  ConsumerState<LabExhaustScreen> createState() => _LabExhaustScreenState();
}

class _LabExhaustScreenState extends ConsumerState<LabExhaustScreen> {
  double _hoodWidth = 6; // feet
  double _sashHeight = 18; // inches (fully open)
  double _faceVelocity = 100; // fpm
  int _hoodCount = 2;
  String _hoodType = 'conventional';
  String _hazardLevel = 'moderate';

  double? _hoodCfm;
  double? _totalExhaust;
  double? _makeupAir;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Hood face opening area = width × sash height
    final faceArea = _hoodWidth * (_sashHeight / 12); // sq ft

    // CFM = Face Area × Face Velocity
    final hoodCfm = faceArea * _faceVelocity;

    // Adjust for hood type
    double typeMultiplier;
    switch (_hoodType) {
      case 'conventional':
        typeMultiplier = 1.0;
        break;
      case 'bypass':
        typeMultiplier = 1.15; // Maintains min flow at low sash
        break;
      case 'vav':
        typeMultiplier = 0.6; // Variable, assume 60% average
        break;
      case 'high_perf':
        typeMultiplier = 0.8; // Low-flow design
        break;
      default:
        typeMultiplier = 1.0;
    }

    final adjustedCfm = hoodCfm * typeMultiplier;

    // Total exhaust for all hoods
    final totalExhaust = adjustedCfm * _hoodCount;

    // Makeup air (typically 100% of exhaust, minus some recirculation)
    final makeupAir = totalExhaust * 0.95;

    String recommendation;
    recommendation = '${_hoodCount} fume hood${_hoodCount > 1 ? 's' : ''}: ${adjustedCfm.toStringAsFixed(0)} CFM each, ${totalExhaust.toStringAsFixed(0)} CFM total exhaust. ';

    // Face velocity recommendations
    switch (_hazardLevel) {
      case 'low':
        if (_faceVelocity < 60) {
          recommendation += 'Low hazard: 60-80 fpm acceptable. Current OK.';
        } else {
          recommendation += 'Low hazard: ${_faceVelocity.toStringAsFixed(0)} fpm OK. Could reduce to 60-80 fpm.';
        }
        break;
      case 'moderate':
        if (_faceVelocity < 80 || _faceVelocity > 120) {
          recommendation += 'WARNING: Moderate hazard needs 80-120 fpm. Current: ${_faceVelocity.toStringAsFixed(0)} fpm.';
        } else {
          recommendation += 'Moderate hazard: ${_faceVelocity.toStringAsFixed(0)} fpm within 80-120 fpm range. Good.';
        }
        break;
      case 'high':
        if (_faceVelocity < 100) {
          recommendation += 'WARNING: High hazard needs 100-150 fpm. Current: ${_faceVelocity.toStringAsFixed(0)} fpm too low.';
        } else {
          recommendation += 'High hazard: ${_faceVelocity.toStringAsFixed(0)} fpm meets 100-150 fpm requirement.';
        }
        break;
    }

    switch (_hoodType) {
      case 'conventional':
        recommendation += ' Conventional hood: Constant volume. Simple but energy intensive.';
        break;
      case 'bypass':
        recommendation += ' Bypass hood: Maintains min flow when sash closed. Better than conventional.';
        break;
      case 'vav':
        recommendation += ' VAV hood: Variable air volume. 40-60% energy savings. Requires controller.';
        break;
      case 'high_perf':
        recommendation += ' High-performance: Low-flow design (60-80 fpm). Verify containment per ASHRAE 110.';
        break;
    }

    recommendation += ' ANSI/ASHRAE 110 testing required for certification. Stack discharge: 3000 fpm min, 10 ft above roof.';

    if (_hoodCount > 4) {
      recommendation += ' Multiple hoods: Consider manifolded exhaust with diversity factor (0.7-0.8).';
    }

    setState(() {
      _hoodCfm = adjustedCfm;
      _totalExhaust = totalExhaust;
      _makeupAir = makeupAir;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _hoodWidth = 6;
      _sashHeight = 18;
      _faceVelocity = 100;
      _hoodCount = 2;
      _hoodType = 'conventional';
      _hazardLevel = 'moderate';
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
        title: Text('Lab Exhaust', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'FUME HOOD TYPE'),
              const SizedBox(height: 12),
              _buildHoodTypeSelector(colors),
              const SizedBox(height: 12),
              _buildHazardSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HOOD DIMENSIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Width', _hoodWidth, 3, 10, ' ft', (v) { setState(() => _hoodWidth = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Sash', _sashHeight, 6, 30, '"', (v) { setState(() => _sashHeight = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW PARAMETERS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Face Vel', _faceVelocity, 60, 150, ' fpm', (v) { setState(() => _faceVelocity = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Qty', _hoodCount.toDouble(), 1, 10, ' hoods', (v) { setState(() => _hoodCount = v.round()); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EXHAUST REQUIREMENTS'),
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
        Icon(LucideIcons.flaskConical, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Fume hood: CFM = Face Area × Velocity. Low hazard 60-80 fpm, moderate 80-120 fpm, high 100-150 fpm. ASHRAE 110 test.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildHoodTypeSelector(ZaftoColors colors) {
    final types = [('conventional', 'Convent.'), ('bypass', 'Bypass'), ('vav', 'VAV'), ('high_perf', 'Hi-Perf')];
    return Row(
      children: types.map((t) {
        final selected = _hoodType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _hoodType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHazardSelector(ZaftoColors colors) {
    final levels = [('low', 'Low Hazard'), ('moderate', 'Moderate'), ('high', 'High Hazard')];
    return Row(
      children: levels.map((l) {
        final selected = _hazardLevel == l.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _hazardLevel = l.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: l != levels.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_totalExhaust == null) return const SizedBox.shrink();

    final velocityOk = (_hazardLevel == 'low' && _faceVelocity >= 60) ||
        (_hazardLevel == 'moderate' && _faceVelocity >= 80 && _faceVelocity <= 120) ||
        (_hazardLevel == 'high' && _faceVelocity >= 100);
    final statusColor = velocityOk ? Colors.green : Colors.orange;
    final status = velocityOk ? 'FACE VELOCITY OK' : 'CHECK FACE VELOCITY';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_totalExhaust?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('CFM Total Exhaust', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Per Hood', '${_hoodCfm?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Makeup Air', '${_makeupAir?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Face Vel', '${_faceVelocity.toStringAsFixed(0)} fpm')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(velocityOk ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: velocityOk ? Colors.green : Colors.orange, size: 16),
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
