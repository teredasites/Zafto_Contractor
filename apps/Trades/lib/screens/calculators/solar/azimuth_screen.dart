import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Azimuth Calculator - Optimal solar panel orientation
class AzimuthScreen extends ConsumerStatefulWidget {
  const AzimuthScreen({super.key});
  @override
  ConsumerState<AzimuthScreen> createState() => _AzimuthScreenState();
}

class _AzimuthScreenState extends ConsumerState<AzimuthScreen> {
  final _latitudeController = TextEditingController();

  String _hemisphere = 'Northern';
  double? _optimalAzimuth;
  String? _direction;
  String? _explanation;

  @override
  void dispose() {
    _latitudeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final latitude = double.tryParse(_latitudeController.text);

    if (latitude == null) {
      setState(() {
        _optimalAzimuth = null;
        _direction = null;
        _explanation = null;
      });
      return;
    }

    // Optimal azimuth depends on hemisphere
    // Northern hemisphere: True South (180°)
    // Southern hemisphere: True North (0° or 360°)
    double azimuth;
    String direction;
    String explanation;

    if (_hemisphere == 'Northern') {
      azimuth = 180;
      direction = 'True South';
      explanation = 'Panels face south to maximize sun exposure throughout the day';
    } else {
      azimuth = 0;
      direction = 'True North';
      explanation = 'Panels face north in southern hemisphere for optimal exposure';
    }

    setState(() {
      _optimalAzimuth = azimuth;
      _direction = direction;
      _explanation = explanation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _latitudeController.clear();
    setState(() {
      _hemisphere = 'Northern';
      _optimalAzimuth = null;
      _direction = null;
      _explanation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Azimuth', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOCATION'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Latitude',
                unit: '°',
                hint: 'e.g., 41.5 for CT',
                controller: _latitudeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              _buildHemisphereToggle(colors),
              const SizedBox(height: 32),
              if (_optimalAzimuth != null) ...[
                _buildSectionHeader(colors, 'OPTIMAL ORIENTATION'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildCompassDiagram(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            'Azimuth = Compass direction panels face',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '0° = North, 90° = East, 180° = South, 270° = West',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildHemisphereToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hemisphere', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: ['Northern', 'Southern'].map((h) {
              final isSelected = _hemisphere == h;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: h == 'Northern' ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _hemisphere = h);
                      _calculate();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
                      ),
                      child: Text(
                        h,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Optimal Azimuth', '${_optimalAzimuth!.toStringAsFixed(0)}°', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Direction', _direction!),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _explanation!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Text('COMPASS REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(150, 150),
              painter: _CompassPainter(
                colors: colors,
                optimalAzimuth: _optimalAzimuth ?? 180,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Deviations from optimal: ±15° = ~2% loss, ±30° = ~5% loss',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? colors.accentPrimary : colors.textPrimary,
            fontSize: isPrimary ? 24 : 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CompassPainter extends CustomPainter {
  final ZaftoColors colors;
  final double optimalAzimuth;

  _CompassPainter({required this.colors, required this.optimalAzimuth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw compass circle
    final circlePaint = Paint()
      ..color = colors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw cardinal directions
    final textStyle = TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600);
    final directions = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};

    directions.forEach((dir, angle) {
      final radians = (angle - 90) * math.pi / 180;
      final x = center.dx + (radius + 15) * math.cos(radians);
      final y = center.dy + (radius + 15) * math.sin(radians);

      final textSpan = TextSpan(text: dir, style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    });

    // Draw optimal direction indicator
    final optimalRadians = (optimalAzimuth - 90) * math.pi / 180;
    final arrowPaint = Paint()
      ..color = colors.accentPrimary
      ..style = PaintingStyle.fill;

    final arrowTip = Offset(
      center.dx + radius * 0.7 * math.cos(optimalRadians),
      center.dy + radius * 0.7 * math.sin(optimalRadians),
    );

    canvas.drawCircle(arrowTip, 8, arrowPaint);
    canvas.drawLine(center, arrowTip, Paint()..color = colors.accentPrimary..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
