import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Round to Rectangular Duct Calculator - Design System v2.6
/// Equivalent duct size conversions
class RoundToRectangularScreen extends ConsumerStatefulWidget {
  const RoundToRectangularScreen({super.key});
  @override
  ConsumerState<RoundToRectangularScreen> createState() => _RoundToRectangularScreenState();
}

class _RoundToRectangularScreenState extends ConsumerState<RoundToRectangularScreen> {
  String _conversionMode = 'roundToRect';
  int _roundDiameter = 10;
  int _rectWidth = 14;
  int _rectHeight = 8;
  double _targetAspect = 2.0;

  double? _equivalentArea;
  String? _result;
  double? _hydraulicDiameter;
  double? _aspectRatio;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    if (_conversionMode == 'roundToRect') {
      // Round to rectangular
      final roundArea = math.pi * math.pow(_roundDiameter / 2, 2);

      // For equivalent friction, use hydraulic diameter formula
      // D_eq = 1.3 × (a × b)^0.625 / (a + b)^0.25
      // Solving for rectangular dimensions with target aspect ratio
      final a = _targetAspect;
      // Area = width × height, height = width / aspect
      // Area = width² / aspect
      final width = math.sqrt(roundArea * a);
      final height = width / a;

      // Round to nearest whole inch
      final widthRounded = width.round();
      final heightRounded = height.round();

      // Actual area of rounded dimensions
      final rectArea = widthRounded * heightRounded;

      // Hydraulic diameter
      final hydDiam = 1.3 * math.pow(widthRounded * heightRounded, 0.625) / math.pow(widthRounded + heightRounded, 0.25);

      setState(() {
        _equivalentArea = roundArea;
        _result = '${widthRounded}" × ${heightRounded}"';
        _hydraulicDiameter = hydDiam;
        _aspectRatio = widthRounded / heightRounded;
        _recommendation = rectArea < roundArea * 0.95
            ? 'Rectangular slightly smaller. Consider next size up for same airflow.'
            : 'Good equivalent. Aspect ratio ${(widthRounded / heightRounded).toStringAsFixed(1)}:1.';
      });
    } else {
      // Rectangular to round
      final rectArea = _rectWidth * _rectHeight;
      final equivalentDiam = math.sqrt(4 * rectArea / math.pi);

      // Round to standard duct sizes
      int roundedDiam;
      if (equivalentDiam <= 4.5) {
        roundedDiam = 4;
      } else if (equivalentDiam <= 5.5) {
        roundedDiam = 5;
      } else if (equivalentDiam <= 6.5) {
        roundedDiam = 6;
      } else if (equivalentDiam <= 7.5) {
        roundedDiam = 7;
      } else if (equivalentDiam <= 8.5) {
        roundedDiam = 8;
      } else if (equivalentDiam <= 9.5) {
        roundedDiam = 9;
      } else if (equivalentDiam <= 10.5) {
        roundedDiam = 10;
      } else if (equivalentDiam <= 12) {
        roundedDiam = 12;
      } else if (equivalentDiam <= 14) {
        roundedDiam = 14;
      } else if (equivalentDiam <= 16) {
        roundedDiam = 16;
      } else if (equivalentDiam <= 18) {
        roundedDiam = 18;
      } else if (equivalentDiam <= 20) {
        roundedDiam = 20;
      } else if (equivalentDiam <= 22) {
        roundedDiam = 22;
      } else {
        roundedDiam = 24;
      }

      final roundArea = math.pi * math.pow(roundedDiam / 2, 2);
      final hydDiam = roundedDiam.toDouble();

      setState(() {
        _equivalentArea = rectArea.toDouble();
        _result = '$roundedDiam" round';
        _hydraulicDiameter = hydDiam;
        _aspectRatio = _rectWidth / _rectHeight;
        _recommendation = roundArea < rectArea * 0.95
            ? 'Round duct slightly smaller. Consider next size up.'
            : 'Good equivalent for similar airflow capacity.';
      });
    }
  }

  void _reset() {
    setState(() {
      _conversionMode = 'roundToRect';
      _roundDiameter = 10;
      _rectWidth = 14;
      _rectHeight = 8;
      _targetAspect = 2.0;
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
        title: Text('Duct Conversion', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONVERSION MODE'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: '', options: const ['Round → Rectangular', 'Rectangular → Round'], selectedIndex: _conversionMode == 'roundToRect' ? 0 : 1, onChanged: (i) { setState(() => _conversionMode = i == 0 ? 'roundToRect' : 'rectToRound'); _calculate(); }),
              const SizedBox(height: 24),
              if (_conversionMode == 'roundToRect') ...[
                _buildSectionHeader(colors, 'ROUND DUCT'),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Round Diameter', value: _roundDiameter.toDouble(), min: 4, max: 24, unit: '"', isInt: true, onChanged: (v) { setState(() => _roundDiameter = v.round()); _calculate(); }),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Target Aspect Ratio', value: _targetAspect, min: 1.0, max: 4.0, unit: ':1', decimals: 1, onChanged: (v) { setState(() => _targetAspect = v); _calculate(); }),
              ] else ...[
                _buildSectionHeader(colors, 'RECTANGULAR DUCT'),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Width', value: _rectWidth.toDouble(), min: 4, max: 36, unit: '"', isInt: true, onChanged: (v) { setState(() => _rectWidth = v.round()); _calculate(); }),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Height', value: _rectHeight.toDouble(), min: 4, max: 24, unit: '"', isInt: true, onChanged: (v) { setState(() => _rectHeight = v.round()); _calculate(); }),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EQUIVALENT SIZE'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildStandardSizesChart(colors),
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
        Icon(LucideIcons.arrowLeftRight, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Convert between round and rectangular duct with equivalent airflow capacity. Aspect ratio < 4:1 recommended.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(isInt ? '${value.round()}$unit' : '${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    return Container(
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
                child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_result == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_conversionMode == 'roundToRect') ...[
                _buildDuctIcon(colors, isRound: true, size: '$_roundDiameter"'),
                const SizedBox(width: 16),
                Icon(LucideIcons.arrowRight, color: colors.textSecondary),
                const SizedBox(width: 16),
                _buildDuctIcon(colors, isRound: false, size: _result ?? ''),
              ] else ...[
                _buildDuctIcon(colors, isRound: false, size: '${_rectWidth}" × ${_rectHeight}"'),
                const SizedBox(width: 16),
                Icon(LucideIcons.arrowRight, color: colors.textSecondary),
                const SizedBox(width: 16),
                _buildDuctIcon(colors, isRound: true, size: _result ?? ''),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Area', '${_equivalentArea?.toStringAsFixed(1)} sq in')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Hyd. Dia.', '${_hydraulicDiameter?.toStringAsFixed(1)}"')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Aspect', '${_aspectRatio?.toStringAsFixed(1)}:1')),
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

  Widget _buildDuctIcon(ZaftoColors colors, {required bool isRound, required String size}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: isRound ? BorderRadius.circular(40) : BorderRadius.circular(8),
        border: Border.all(color: colors.accentPrimary, width: 2),
      ),
      child: Column(children: [
        Icon(isRound ? LucideIcons.circle : LucideIcons.square, color: colors.accentPrimary, size: 24),
        const SizedBox(height: 4),
        Text(size, style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildStandardSizesChart(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMON EQUIVALENTS', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildEquivalentRow(colors, '6" round', '8" × 5"'),
          _buildEquivalentRow(colors, '8" round', '10" × 6"'),
          _buildEquivalentRow(colors, '10" round', '14" × 8"'),
          _buildEquivalentRow(colors, '12" round', '16" × 10"'),
          _buildEquivalentRow(colors, '14" round', '20" × 10"'),
        ],
      ),
    );
  }

  Widget _buildEquivalentRow(ZaftoColors colors, String round, String rect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(round, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        Icon(LucideIcons.arrowRight, color: colors.textSecondary, size: 14),
        Expanded(child: Text(rect, textAlign: TextAlign.end, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
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
