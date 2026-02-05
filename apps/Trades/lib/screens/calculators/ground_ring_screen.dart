import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Ground Ring Calculator - Design System v2.6
/// NEC 250.52(A)(4) - Perimeter grounding electrode
class GroundRingScreen extends ConsumerStatefulWidget {
  const GroundRingScreen({super.key});
  @override
  ConsumerState<GroundRingScreen> createState() => _GroundRingScreenState();
}

class _GroundRingScreenState extends ConsumerState<GroundRingScreen> {
  double _buildingLength = 60;
  double _buildingWidth = 40;
  int _serviceAmps = 200;
  double _soilResistivity = 100;

  double? _perimeter;
  double? _conductorLength;
  String? _minConductorSize;
  int? _groundRods;
  double? _estimatedResistance;
  String? _necReference;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Ground Ring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING DIMENSIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Length', value: _buildingLength, min: 20, max: 200, unit: ' ft', onChanged: (v) { setState(() => _buildingLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Width', value: _buildingWidth, min: 20, max: 200, unit: ' ft', onChanged: (v) { setState(() => _buildingWidth = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SERVICE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Service Size', value: _serviceAmps.toDouble(), min: 100, max: 2000, unit: ' A', onChanged: (v) { setState(() => _serviceAmps = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Soil Resistivity', value: _soilResistivity, min: 10, max: 1000, unit: ' Ω-m', onChanged: (v) { setState(() => _soilResistivity = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'GROUND RING DESIGN'),
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
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('NEC 250.52(A)(4) - Bare copper, min #2 AWG, 20 ft min', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round() ~/ 5, onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        _buildDiagram(colors),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildSpecCard(colors, '${_conductorLength?.toStringAsFixed(0) ?? '0'}', 'ft length'),
          _buildSpecCard(colors, _minConductorSize ?? '#2', 'AWG min'),
          _buildSpecCard(colors, '${_groundRods ?? 4}', 'ground rods'),
        ]),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Building perimeter', '${_perimeter?.toStringAsFixed(0) ?? '0'} ft'),
        _buildCalcRow(colors, 'Ring length (offset)', '${_conductorLength?.toStringAsFixed(0) ?? '0'} ft'),
        _buildCalcRow(colors, 'Min conductor', _minConductorSize ?? '#2 AWG bare Cu'),
        _buildCalcRow(colors, 'Ground rods', '${_groundRods ?? 4} @ 8 ft each'),
        _buildCalcRow(colors, 'Est. resistance', '${_estimatedResistance?.toStringAsFixed(1) ?? '0'} Ω'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.book, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('Requirements', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text('• Buried min 30" below grade\n• In direct contact with earth\n• Encircle building/structure\n• Min 20 ft in contact with soil', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDiagram(ZaftoColors colors) {
    return Container(
      height: 120,
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: CustomPaint(
        painter: _GroundRingPainter(colors, _buildingLength / (_buildingLength + _buildingWidth), _groundRods ?? 4),
        size: const Size.fromHeight(120),
      ),
    );
  }

  Widget _buildSpecCard(ZaftoColors colors, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    // Building perimeter
    final perimeter = 2 * (_buildingLength + _buildingWidth);

    // Ground ring typically 2-3 ft outside foundation
    final ringLength = 2 * ((_buildingLength + 4) + (_buildingWidth + 4));

    // Minimum conductor size per NEC 250.52(A)(4) is #2 AWG
    // Larger may be required based on service size per 250.66
    String conductor;
    if (_serviceAmps <= 100) conductor = '#8 AWG';
    else if (_serviceAmps <= 200) conductor = '#4 AWG';
    else if (_serviceAmps <= 400) conductor = '#2 AWG';
    else if (_serviceAmps <= 600) conductor = '#1/0 AWG';
    else if (_serviceAmps <= 800) conductor = '#2/0 AWG';
    else if (_serviceAmps <= 1000) conductor = '#3/0 AWG';
    else conductor = '#4/0 AWG';

    // Minimum #2 per 250.52(A)(4)
    if (_serviceAmps <= 400 && conductor != '#2 AWG') {
      conductor = '#2 AWG'; // Minimum for ground ring
    }

    // Ground rods - one at each corner minimum for good coverage
    // More for larger buildings
    int rods = 4; // Minimum 4 corners
    if (perimeter > 150) rods = 6;
    if (perimeter > 250) rods = 8;

    // Estimate ground resistance (simplified)
    // Ring electrode resistance ≈ ρ / (2π × ring radius)
    final avgDimension = ((_buildingLength + 4) + (_buildingWidth + 4)) / 2;
    final ringResistance = _soilResistivity / (2 * 3.14159 * (avgDimension * 0.3048));

    // Ground rods in parallel reduce resistance
    final rodResistance = _soilResistivity / (2 * 3.14159 * 2.4); // 8 ft rod
    final combinedRodResistance = rodResistance / rods;

    // Parallel combination
    final totalResistance = 1 / ((1 / ringResistance) + (1 / combinedRodResistance));

    setState(() {
      _perimeter = perimeter;
      _conductorLength = ringLength;
      _minConductorSize = conductor;
      _groundRods = rods;
      _estimatedResistance = totalResistance;
      _necReference = 'NEC 250.52(A)(4), 250.53(F)';
    });
  }

  void _reset() {
    setState(() {
      _buildingLength = 60;
      _buildingWidth = 40;
      _serviceAmps = 200;
      _soilResistivity = 100;
    });
    _calculate();
  }
}

class _GroundRingPainter extends CustomPainter {
  final ZaftoColors colors;
  final double aspectRatio;
  final int rods;

  _GroundRingPainter(this.colors, this.aspectRatio, this.rods);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.accentPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Building rectangle
    final buildingRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.5 * aspectRatio + size.width * 0.3,
      height: size.height * 0.5,
    );

    // Ground ring (slightly larger)
    final ringRect = buildingRect.inflate(15);

    // Draw building (filled)
    canvas.drawRect(buildingRect, Paint()..color = colors.textTertiary.withValues(alpha: 0.3));

    // Draw ground ring
    canvas.drawRect(ringRect, paint);

    // Draw ground rods as dots
    final rodPaint = Paint()..color = colors.accentPrimary;
    final corners = [ringRect.topLeft, ringRect.topRight, ringRect.bottomRight, ringRect.bottomLeft];
    for (int i = 0; i < rods && i < corners.length; i++) {
      canvas.drawCircle(corners[i], 5, rodPaint);
    }
    // Additional rods along sides if needed
    if (rods > 4) {
      canvas.drawCircle(Offset(ringRect.center.dx, ringRect.top), 5, rodPaint);
      canvas.drawCircle(Offset(ringRect.center.dx, ringRect.bottom), 5, rodPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
