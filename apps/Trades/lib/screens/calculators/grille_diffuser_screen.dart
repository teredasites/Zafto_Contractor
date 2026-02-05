import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Grille & Diffuser Calculator - Design System v2.6
/// Air terminal device selection and throw calculation
class GrilleDiffuserScreen extends ConsumerStatefulWidget {
  const GrilleDiffuserScreen({super.key});
  @override
  ConsumerState<GrilleDiffuserScreen> createState() => _GrilleDiffuserScreenState();
}

class _GrilleDiffuserScreenState extends ConsumerState<GrilleDiffuserScreen> {
  double _airflow = 200; // CFM
  double _neckSize = 10; // inches
  double _throwDistance = 12; // feet (required throw to wall/obstacle)
  String _diffuserType = 'ceiling_4way';
  String _application = 'cooling';

  double? _neckVelocity;
  double? _calculatedThrow;
  double? _nc;
  String? _recommendedSize;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Neck velocity = CFM / Area
    final neckArea = math.pi * math.pow(_neckSize / 24, 2); // sq ft for round
    final neckVelocity = _airflow / neckArea;

    // Throw estimate (simplified - varies by diffuser)
    // T50 throw approximately: T = 0.8 × sqrt(CFM) for ceiling diffuser
    double throwFactor;
    switch (_diffuserType) {
      case 'ceiling_4way':
        throwFactor = 0.9;
        break;
      case 'ceiling_2way':
        throwFactor = 1.1;
        break;
      case 'slot':
        throwFactor = 1.2;
        break;
      case 'round':
        throwFactor = 1.0;
        break;
      case 'grille':
        throwFactor = 0.7;
        break;
      default:
        throwFactor = 0.9;
    }
    final calculatedThrow = throwFactor * math.sqrt(_airflow) * 0.8;

    // NC level estimate based on velocity
    double nc;
    if (neckVelocity < 500) {
      nc = 20;
    } else if (neckVelocity < 700) {
      nc = 25;
    } else if (neckVelocity < 900) {
      nc = 30;
    } else if (neckVelocity < 1100) {
      nc = 35;
    } else {
      nc = 40;
    }

    // Recommended size
    String recommendedSize;
    if (neckVelocity > 900) {
      recommendedSize = 'Increase to ${(_neckSize + 2).toStringAsFixed(0)}"';
    } else if (neckVelocity < 400) {
      recommendedSize = 'Could reduce to ${math.max(6, _neckSize - 2).toStringAsFixed(0)}"';
    } else {
      recommendedSize = '${_neckSize.toStringAsFixed(0)}" OK';
    }

    String recommendation;
    recommendation = 'Neck velocity: ${neckVelocity.toStringAsFixed(0)} fpm. T50 throw: ${calculatedThrow.toStringAsFixed(1)} ft. NC: ~${nc.toStringAsFixed(0)}. ';

    // Velocity check
    if (neckVelocity > 1000) {
      recommendation += 'WARNING: High velocity will cause noise and drafts. Size up. ';
    } else if (neckVelocity < 300) {
      recommendation += 'Low velocity may cause poor mixing. Check throw. ';
    }

    // Throw check
    if (calculatedThrow < _throwDistance * 0.75) {
      recommendation += 'Throw may not reach ${_throwDistance.toStringAsFixed(0)} ft. Increase CFM or use higher induction device.';
    } else if (calculatedThrow > _throwDistance * 1.5) {
      recommendation += 'Throw exceeds need. May cause drafts at wall. Consider reducing CFM.';
    } else {
      recommendation += 'Throw adequate for ${_throwDistance.toStringAsFixed(0)} ft requirement.';
    }

    switch (_diffuserType) {
      case 'ceiling_4way':
        recommendation += ' 4-way: General offices. Covers square area. Mount centered in zone.';
        break;
      case 'ceiling_2way':
        recommendation += ' 2-way: Along walls or corridors. Longer throw, narrower pattern.';
        break;
      case 'slot':
        recommendation += ' Linear slot: Perimeter, VAV. Excellent for modern interiors. Coanda effect.';
        break;
      case 'round':
        recommendation += ' Round: Conference rooms, lobbies. Radial pattern. Adjustable.';
        break;
      case 'grille':
        recommendation += ' Grille: Return air or supply in ceiling. Lower throw than diffusers.';
        break;
    }

    if (_application == 'cooling') {
      recommendation += ' Cooling: Horizontal throw OK. T50 to ¾ distance to wall.';
    } else {
      recommendation += ' Heating: Consider perimeter slot or floor diffuser. Warm air rises.';
    }

    setState(() {
      _neckVelocity = neckVelocity;
      _calculatedThrow = calculatedThrow;
      _nc = nc;
      _recommendedSize = recommendedSize;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _airflow = 200;
      _neckSize = 10;
      _throwDistance = 12;
      _diffuserType = 'ceiling_4way';
      _application = 'cooling';
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
        title: Text('Grille & Diffuser', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DIFFUSER TYPE'),
              const SizedBox(height: 12),
              _buildDiffuserTypeSelector(colors),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW & SIZE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Airflow', _airflow, 50, 1000, ' CFM', (v) { setState(() => _airflow = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Neck Size', _neckSize, 6, 24, '"', (v) { setState(() => _neckSize = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'THROW REQUIREMENT'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Required Throw', value: _throwDistance, min: 5, max: 30, unit: ' ft', onChanged: (v) { setState(() => _throwDistance = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SELECTION ANALYSIS'),
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
        Expanded(child: Text('Diffuser neck velocity 500-900 fpm. Throw (T50) = distance to 50 fpm terminal velocity. NC<30 for offices.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildDiffuserTypeSelector(ZaftoColors colors) {
    final types = [('ceiling_4way', '4-Way'), ('ceiling_2way', '2-Way'), ('slot', 'Slot'), ('round', 'Round'), ('grille', 'Grille')];
    return Row(
      children: types.map((t) {
        final selected = _diffuserType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _diffuserType = t.$1); _calculate(); },
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

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [('cooling', 'Cooling'), ('heating', 'Heating')];
    return Row(
      children: apps.map((a) {
        final selected = _application == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _application = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
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
    if (_neckVelocity == null) return const SizedBox.shrink();

    final velocityOk = _neckVelocity! >= 400 && _neckVelocity! <= 900;
    final statusColor = velocityOk ? Colors.green : (_neckVelocity! < 400 ? Colors.orange : Colors.red);
    final status = velocityOk ? 'VELOCITY OK' : (_neckVelocity! < 400 ? 'LOW VELOCITY' : 'HIGH VELOCITY');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_neckVelocity?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('fpm Neck Velocity', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Throw T50', '${_calculatedThrow?.toStringAsFixed(1)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'NC Level', '~${_nc?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Size', _recommendedSize ?? '')),
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
