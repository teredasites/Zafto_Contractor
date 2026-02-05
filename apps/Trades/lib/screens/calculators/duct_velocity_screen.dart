import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Duct Velocity Calculator - Design System v2.6
/// Calculate FPM velocity in ductwork
class DuctVelocityScreen extends ConsumerStatefulWidget {
  const DuctVelocityScreen({super.key});
  @override
  ConsumerState<DuctVelocityScreen> createState() => _DuctVelocityScreenState();
}

class _DuctVelocityScreenState extends ConsumerState<DuctVelocityScreen> {
  double _cfm = 400;
  String _ductShape = 'round';
  int _roundDiameter = 8;
  int _rectWidth = 12;
  int _rectHeight = 8;
  String _ductLocation = 'supply';

  double? _ductArea;
  double? _velocity;
  String? _noiseLevel;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    double areaSqIn;
    if (_ductShape == 'round') {
      areaSqIn = math.pi * math.pow(_roundDiameter / 2, 2);
    } else {
      areaSqIn = (_rectWidth * _rectHeight).toDouble();
    }

    final areaSqFt = areaSqIn / 144;
    final velocity = _cfm / areaSqFt; // FPM

    // Noise level based on velocity
    String noiseLevel;
    if (velocity < 500) {
      noiseLevel = 'Very Quiet';
    } else if (velocity < 700) {
      noiseLevel = 'Quiet';
    } else if (velocity < 900) {
      noiseLevel = 'Moderate';
    } else if (velocity < 1200) {
      noiseLevel = 'Noticeable';
    } else {
      noiseLevel = 'Loud';
    }

    // Recommended velocity ranges
    double minVel, maxVel;
    switch (_ductLocation) {
      case 'supply':
        minVel = 600;
        maxVel = 900;
        break;
      case 'return':
        minVel = 400;
        maxVel = 700;
        break;
      case 'maintrunk':
        minVel = 700;
        maxVel = 1200;
        break;
      case 'branch':
        minVel = 500;
        maxVel = 800;
        break;
      default:
        minVel = 500;
        maxVel = 900;
    }

    String recommendation;
    if (velocity < minVel) {
      recommendation = 'Velocity below recommended range (${minVel.toStringAsFixed(0)}-${maxVel.toStringAsFixed(0)} FPM). Duct may be oversized.';
    } else if (velocity > maxVel) {
      recommendation = 'Velocity above recommended range. May cause noise issues. Consider larger duct.';
    } else {
      recommendation = 'Velocity within recommended range for ${_ductLocation.replaceAll('maintrunk', 'main trunk')} duct.';
    }

    if (velocity > 1000 && _ductLocation != 'maintrunk') {
      recommendation += ' Consider adding turning vanes at elbows to reduce noise.';
    }

    setState(() {
      _ductArea = areaSqIn;
      _velocity = velocity;
      _noiseLevel = noiseLevel;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _cfm = 400;
      _ductShape = 'round';
      _roundDiameter = 8;
      _rectWidth = 12;
      _rectHeight = 8;
      _ductLocation = 'supply';
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
        title: Text('Duct Velocity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'AIRFLOW'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'CFM', value: _cfm, min: 50, max: 2000, unit: ' CFM', onChanged: (v) { setState(() => _cfm = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DUCT SIZE'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Duct Shape', options: const ['Round', 'Rectangular'], selectedIndex: _ductShape == 'round' ? 0 : 1, onChanged: (i) { setState(() => _ductShape = i == 0 ? 'round' : 'rectangular'); _calculate(); }),
              const SizedBox(height: 12),
              if (_ductShape == 'round')
                _buildSliderRow(colors, label: 'Diameter', value: _roundDiameter.toDouble(), min: 4, max: 24, unit: '"', isInt: true, onChanged: (v) { setState(() => _roundDiameter = v.round()); _calculate(); })
              else ...[
                _buildSliderRow(colors, label: 'Width', value: _rectWidth.toDouble(), min: 4, max: 36, unit: '"', isInt: true, onChanged: (v) { setState(() => _rectWidth = v.round()); _calculate(); }),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Height', value: _rectHeight.toDouble(), min: 4, max: 24, unit: '"', isInt: true, onChanged: (v) { setState(() => _rectHeight = v.round()); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DUCT LOCATION'),
              const SizedBox(height: 12),
              _buildLocationSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'VELOCITY'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildVelocityGuide(colors),
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
        Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Velocity = CFM ÷ Area. Higher velocity = more noise. Balance airflow needs with acoustics.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildLocationSelector(ZaftoColors colors) {
    final options = [
      ('supply', 'Supply'),
      ('return', 'Return'),
      ('maintrunk', 'Main Trunk'),
      ('branch', 'Branch'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final selected = _ductLocation == o.$1;
        return GestureDetector(
          onTap: () { setState(() => _ductLocation = o.$1); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Text(o.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(isInt ? '${value.round()}$unit' : '${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_velocity == null) return const SizedBox.shrink();

    Color velocityColor;
    if (_velocity! < 500) {
      velocityColor = Colors.green;
    } else if (_velocity! < 900) {
      velocityColor = colors.accentPrimary;
    } else if (_velocity! < 1200) {
      velocityColor = Colors.orange;
    } else {
      velocityColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_velocity?.toStringAsFixed(0)}', style: TextStyle(color: velocityColor, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('FPM', style: TextStyle(color: colors.textSecondary, fontSize: 18)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: velocityColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(_noiseLevel ?? '', style: TextStyle(color: velocityColor, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Duct Area', '${_ductArea?.toStringAsFixed(1)} sq in')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'CFM', '${_cfm.toStringAsFixed(0)}')),
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

  Widget _buildVelocityGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECOMMENDED VELOCITIES', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildGuideRow(colors, 'Main Trunk', '700-1200 FPM'),
          _buildGuideRow(colors, 'Supply Branch', '600-900 FPM'),
          _buildGuideRow(colors, 'Return Duct', '400-700 FPM'),
          _buildGuideRow(colors, 'Bedroom Supply', '< 600 FPM'),
        ],
      ),
    );
  }

  Widget _buildGuideRow(ZaftoColors colors, String location, String velocity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(location, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(velocity, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
