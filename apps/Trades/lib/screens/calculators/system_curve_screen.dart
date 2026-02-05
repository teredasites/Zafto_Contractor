import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// System Curve Calculator - Design System v2.6
/// Duct/pipe system curve and operating point
class SystemCurveScreen extends ConsumerStatefulWidget {
  const SystemCurveScreen({super.key});
  @override
  ConsumerState<SystemCurveScreen> createState() => _SystemCurveScreenState();
}

class _SystemCurveScreenState extends ConsumerState<SystemCurveScreen> {
  double _designFlow = 1000;
  double _designPressure = 2.0;
  double _actualFlow = 800;
  String _systemType = 'duct';

  double? _actualPressure;
  double? _systemConstant;
  double? _flowRatio;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // System curve: Pressure varies with flow squared
    // P2 = P1 × (Q2/Q1)²
    // System constant K = P / Q²

    final systemConstant = _designPressure / math.pow(_designFlow, 2);
    final actualPressure = systemConstant * math.pow(_actualFlow, 2);
    final flowRatio = _actualFlow / _designFlow;

    String recommendation;
    recommendation = 'System curve: P = ${systemConstant.toStringAsExponential(2)} × Q². ';

    if (flowRatio < 0.5) {
      recommendation += 'Low flow (${(flowRatio * 100).toStringAsFixed(0)}% of design). Check for restrictions, closed dampers, or pump/fan issues.';
    } else if (flowRatio < 0.8) {
      recommendation += 'Moderate flow reduction. System may be throttled or partially obstructed.';
    } else if (flowRatio > 1.2) {
      recommendation += 'Flow exceeds design by ${((flowRatio - 1) * 100).toStringAsFixed(0)}%. Check for bypass or removed restrictions.';
    } else {
      recommendation += 'Flow near design point. System operating normally.';
    }

    if (_systemType == 'duct') {
      recommendation += ' Duct system: Pressure varies as velocity squared. Adding filters/coils increases K.';
    } else if (_systemType == 'pipe') {
      recommendation += ' Piping: Friction loss per 100 ft varies with velocity. Check valve positions.';
    } else {
      recommendation += ' Chilled water: Primary-secondary uses ΔP sensor. Variable flow saves energy.';
    }

    recommendation += ' Operating at ${actualPressure.toStringAsFixed(2)} ${_systemType == 'duct' ? '"WC' : 'ft HD'} at current flow.';

    setState(() {
      _actualPressure = actualPressure;
      _systemConstant = systemConstant;
      _flowRatio = flowRatio;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _designFlow = 1000;
      _designPressure = 2.0;
      _actualFlow = 800;
      _systemType = 'duct';
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
        title: Text('System Curve', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM TYPE'),
              const SizedBox(height: 12),
              _buildSystemTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DESIGN POINT'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Flow', _designFlow, 100, 5000, _systemType == 'duct' ? ' CFM' : ' GPM', (v) { setState(() => _designFlow = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Pressure', _designPressure, 0.5, 10, _systemType == 'duct' ? '"WC' : ' ft', (v) { setState(() => _designPressure = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ACTUAL FLOW'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Current Flow', value: _actualFlow, min: 100, max: 5000, unit: _systemType == 'duct' ? ' CFM' : ' GPM', onChanged: (v) { setState(() => _actualFlow = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'OPERATING POINT'),
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
        Icon(LucideIcons.trendingUp, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('System curve: P ∝ Q². Pressure at any flow = Design P × (Actual/Design)². Intersection with fan/pump curve = operating point.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    final types = [('duct', 'Duct System'), ('pipe', 'Piping'), ('chw', 'Chilled Water')];
    return Row(
      children: types.map((t) {
        final selected = _systemType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _systemType = t.$1); _calculate(); },
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

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
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
    if (_actualPressure == null) return const SizedBox.shrink();

    final flowRatio = _flowRatio ?? 1.0;
    final isLow = flowRatio < 0.8;
    final isHigh = flowRatio > 1.2;
    final statusColor = isLow ? Colors.orange : (isHigh ? Colors.red : Colors.green);
    final status = isLow ? 'BELOW DESIGN' : (isHigh ? 'ABOVE DESIGN' : 'AT DESIGN');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_actualPressure?.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text(_systemType == 'duct' ? '"WC at Current Flow' : 'ft Head at Current Flow', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('$status (${(flowRatio * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          // System curve visualization
          Container(
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: CustomPaint(
              size: const Size(double.infinity, 76),
              painter: _SystemCurvePainter(
                designFlow: _designFlow,
                designPressure: _designPressure,
                actualFlow: _actualFlow,
                actualPressure: _actualPressure!,
                accentColor: colors.accentPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Design Flow', '${_designFlow.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Actual Flow', '${_actualFlow.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Flow Ratio', '${(flowRatio * 100).toStringAsFixed(0)}%')),
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

class _SystemCurvePainter extends CustomPainter {
  final double designFlow;
  final double designPressure;
  final double actualFlow;
  final double actualPressure;
  final Color accentColor;

  _SystemCurvePainter({
    required this.designFlow,
    required this.designPressure,
    required this.actualFlow,
    required this.actualPressure,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final k = designPressure / math.pow(designFlow, 2);
    final maxFlow = designFlow * 1.3;
    final maxPressure = k * math.pow(maxFlow, 2);

    for (int i = 0; i <= 50; i++) {
      final flow = (i / 50) * maxFlow;
      final pressure = k * math.pow(flow, 2);
      final x = (flow / maxFlow) * size.width;
      final y = size.height - (pressure / maxPressure) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw operating point
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final opX = (actualFlow / maxFlow) * size.width;
    final opY = size.height - (actualPressure / maxPressure) * size.height;
    canvas.drawCircle(Offset(opX, opY), 6, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
