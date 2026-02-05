import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Airflow Hood Calculator - Design System v2.6
/// Capture hood CFM measurement and balancing
class AirflowHoodScreen extends ConsumerStatefulWidget {
  const AirflowHoodScreen({super.key});
  @override
  ConsumerState<AirflowHoodScreen> createState() => _AirflowHoodScreenState();
}

class _AirflowHoodScreenState extends ConsumerState<AirflowHoodScreen> {
  double _hoodReading = 350;
  double _designCfm = 400;
  double _kFactor = 1.0;
  String _grillType = 'perforated';
  String _measurementType = 'supply';
  double _hoodSize = 2; // sq ft

  double? _actualCfm;
  double? _percentDesign;
  double? _faceVelocity;
  String? _balanceStatus;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Apply K-factor correction
    // K-factors vary by grill type
    double kCorrection;
    switch (_grillType) {
      case 'perforated': kCorrection = 1.0; break;
      case 'linear': kCorrection = 0.95; break;
      case 'louver': kCorrection = 0.90; break;
      case 'stamped': kCorrection = 0.85; break;
      default: kCorrection = 1.0;
    }

    final actualCfm = _hoodReading * _kFactor * kCorrection;
    final percentDesign = (actualCfm / _designCfm) * 100;

    // Face velocity
    final faceVelocity = actualCfm / _hoodSize;

    // Balance status
    String balanceStatus;
    if (percentDesign >= 95 && percentDesign <= 105) {
      balanceStatus = 'Balanced (±5%)';
    } else if (percentDesign >= 90 && percentDesign <= 110) {
      balanceStatus = 'Acceptable (±10%)';
    } else if (percentDesign < 90) {
      balanceStatus = 'Low Flow';
    } else {
      balanceStatus = 'High Flow';
    }

    String recommendation;
    if (_measurementType == 'supply') {
      recommendation = 'Supply diffuser: Center hood, seal edges. Multiple readings for large diffusers.';
    } else {
      recommendation = 'Return/exhaust: May have low velocity - verify hood captures full flow.';
    }

    if (percentDesign < 80) {
      recommendation += ' Low flow: Check damper position, duct restrictions, dirty filter.';
    } else if (percentDesign > 120) {
      recommendation += ' High flow: Partially close damper. Check if other branches are blocked.';
    }

    if (_grillType == 'linear' || _grillType == 'louver') {
      recommendation += ' Directional grill: May need multiple positions for accurate average.';
    }

    if (faceVelocity > 600 && _measurementType == 'supply') {
      recommendation += ' High velocity may cause drafts and noise. Consider larger diffuser.';
    }

    setState(() {
      _actualCfm = actualCfm;
      _percentDesign = percentDesign;
      _faceVelocity = faceVelocity;
      _balanceStatus = balanceStatus;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _hoodReading = 350;
      _designCfm = 400;
      _kFactor = 1.0;
      _grillType = 'perforated';
      _measurementType = 'supply';
      _hoodSize = 2;
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
        title: Text('Airflow Hood', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MEASUREMENT'),
              const SizedBox(height: 12),
              _buildMeasurementTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Hood Reading', value: _hoodReading, min: 50, max: 1000, unit: ' CFM', onChanged: (v) { setState(() => _hoodReading = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Design CFM', value: _designCfm, min: 50, max: 1000, unit: ' CFM', onChanged: (v) { setState(() => _designCfm = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CORRECTIONS'),
              const SizedBox(height: 12),
              _buildGrillTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'K-Factor', value: _kFactor, min: 0.8, max: 1.2, unit: '', decimals: 2, onChanged: (v) { setState(() => _kFactor = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Grill Area', value: _hoodSize, min: 0.5, max: 6, unit: ' sq ft', decimals: 1, onChanged: (v) { setState(() => _hoodSize = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'RESULTS'),
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
        Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Capture hood measurement: Center over diffuser, seal edges. Apply K-factor for grill type. Target ±10% of design.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMeasurementTypeSelector(ZaftoColors colors) {
    final types = [('supply', 'Supply'), ('return', 'Return/Exhaust')];
    return Row(
      children: types.map((t) {
        final selected = _measurementType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _measurementType = t.$1); _calculate(); },
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
    );
  }

  Widget _buildGrillTypeSelector(ZaftoColors colors) {
    final grills = [
      ('perforated', 'Perf'),
      ('linear', 'Linear'),
      ('louver', 'Louver'),
      ('stamped', 'Stamped'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grill Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: grills.map((g) {
            final selected = _grillType == g.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _grillType = g.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: g != grills.last ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(g.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
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
    if (_actualCfm == null) return const SizedBox.shrink();

    final isGood = _percentDesign! >= 90 && _percentDesign! <= 110;
    final isIdeal = _percentDesign! >= 95 && _percentDesign! <= 105;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_actualCfm?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('CFM Actual', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: isIdeal ? Colors.green : (isGood ? Colors.orange : Colors.red), borderRadius: BorderRadius.circular(20)),
            child: Text('${_percentDesign?.toStringAsFixed(1)}% of Design', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Text(_balanceStatus ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Design', '${_designCfm.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Face Vel.', '${_faceVelocity?.toStringAsFixed(0)} fpm')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Deviation', '${(_actualCfm! - _designCfm).toStringAsFixed(0)} CFM')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.clipboardCheck, color: colors.textSecondary, size: 16),
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
