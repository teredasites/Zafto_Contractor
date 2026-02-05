import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Row Spacing Calculator - Ground mount inter-row spacing
class RowSpacingScreen extends ConsumerStatefulWidget {
  const RowSpacingScreen({super.key});
  @override
  ConsumerState<RowSpacingScreen> createState() => _RowSpacingScreenState();
}

class _RowSpacingScreenState extends ConsumerState<RowSpacingScreen> {
  final _latitudeController = TextEditingController(text: '41.5');
  final _panelHeightController = TextEditingController(text: '6.5');
  final _tiltAngleController = TextEditingController(text: '30');

  double? _minSpacing;
  double? _recommendedSpacing;
  double? _gcr;
  String? _shadeStatus;

  @override
  void dispose() {
    _latitudeController.dispose();
    _panelHeightController.dispose();
    _tiltAngleController.dispose();
    super.dispose();
  }

  void _calculate() {
    final latitude = double.tryParse(_latitudeController.text);
    final panelHeight = double.tryParse(_panelHeightController.text);
    final tiltAngle = double.tryParse(_tiltAngleController.text);

    if (latitude == null || panelHeight == null || tiltAngle == null) {
      setState(() {
        _minSpacing = null;
        _recommendedSpacing = null;
        _gcr = null;
        _shadeStatus = null;
      });
      return;
    }

    // Calculate winter solstice solar altitude at solar noon
    // Declination at winter solstice = -23.45°
    const winterDeclination = -23.45;
    final latRad = latitude * math.pi / 180;
    final decRad = winterDeclination * math.pi / 180;

    // Solar altitude at noon on winter solstice
    final solarAltitude = 90 - latitude + winterDeclination;
    final altRad = solarAltitude * math.pi / 180;

    // Panel dimensions
    final tiltRad = tiltAngle * math.pi / 180;
    final panelVertical = panelHeight * math.sin(tiltRad);
    final panelHorizontal = panelHeight * math.cos(tiltRad);

    // Shadow length = panel vertical / tan(solar altitude)
    final shadowLength = panelVertical / math.tan(altRad);

    // Minimum spacing = shadow length + panel horizontal projection
    final minSpacing = shadowLength + panelHorizontal;

    // Recommended spacing adds 10% buffer
    final recommended = minSpacing * 1.1;

    // Ground Coverage Ratio (GCR) = panel width / row spacing
    final gcr = (panelHorizontal / recommended) * 100;

    // Status
    String status;
    if (solarAltitude < 15) {
      status = 'Very low winter sun - consider longer spacing';
    } else if (solarAltitude < 25) {
      status = 'Low winter sun - spacing critical';
    } else {
      status = 'Good winter sun angle';
    }

    setState(() {
      _minSpacing = minSpacing;
      _recommendedSpacing = recommended;
      _gcr = gcr;
      _shadeStatus = status;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _latitudeController.text = '41.5';
    _panelHeightController.text = '6.5';
    _tiltAngleController.text = '30';
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
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Row Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
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
              _buildSectionHeader(colors, 'SITE & PANEL DATA'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Latitude',
                unit: '°',
                hint: 'Site latitude',
                controller: _latitudeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Panel Height',
                unit: 'ft',
                hint: 'Module dimension',
                controller: _panelHeightController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Tilt Angle',
                unit: '°',
                hint: 'From horizontal',
                controller: _tiltAngleController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_minSpacing != null) ...[
                _buildSectionHeader(colors, 'ROW SPACING RESULTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildDiagram(colors),
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
            'Spacing = Shadow + Panel Projection',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on winter solstice (worst case) shading',
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
          _buildResultRow(colors, 'Recommended Spacing', '${_recommendedSpacing!.toStringAsFixed(1)} ft', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Minimum (no buffer)', '${_minSpacing!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Ground Coverage Ratio', '${_gcr!.toStringAsFixed(1)}%'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _shadeStatus!,
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

  Widget _buildDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Text('ROW LAYOUT REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _RowSpacingDiagramPainter(colors: colors),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(colors, colors.accentPrimary, 'Panel'),
              _buildLegendItem(colors, colors.accentWarning.withValues(alpha: 0.5), 'Shadow'),
              _buildLegendItem(colors, colors.accentInfo, 'Spacing'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.alertTriangle, size: 14, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GCR below 30% may indicate oversized spacing. GCR above 50% may cause winter shading.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ZaftoColors colors, Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ],
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

class _RowSpacingDiagramPainter extends CustomPainter {
  final ZaftoColors colors;

  _RowSpacingDiagramPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final panelPaint = Paint()..color = colors.accentPrimary;
    final shadowPaint = Paint()..color = colors.accentWarning.withValues(alpha: 0.5);
    final spacingPaint = Paint()
      ..color = colors.accentInfo
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw ground line
    canvas.drawLine(
      Offset(0, size.height - 10),
      Offset(size.width, size.height - 10),
      Paint()..color = colors.textTertiary..strokeWidth = 1,
    );

    // Draw two rows of panels with shadows
    const panelWidth = 60.0;
    const panelHeight = 50.0;
    const spacing = 120.0;

    for (var i = 0; i < 2; i++) {
      final x = 30.0 + i * spacing;
      final y = size.height - 10 - panelHeight;

      // Shadow (triangle)
      final shadowPath = Path()
        ..moveTo(x + panelWidth, size.height - 10)
        ..lineTo(x + panelWidth + 40, size.height - 10)
        ..lineTo(x + panelWidth, y + 10)
        ..close();
      canvas.drawPath(shadowPath, shadowPaint);

      // Panel (rectangle at angle)
      canvas.drawRect(Rect.fromLTWH(x, y, panelWidth, panelHeight * 0.2), panelPaint);

      // Panel face (tilted)
      final panelPath = Path()
        ..moveTo(x, y + panelHeight * 0.2)
        ..lineTo(x + panelWidth, y + panelHeight * 0.2)
        ..lineTo(x + panelWidth, y - panelHeight * 0.3)
        ..lineTo(x, y)
        ..close();
      canvas.drawPath(panelPath, panelPaint);
    }

    // Draw spacing indicator
    final spacingY = size.height - 25;
    canvas.drawLine(Offset(30 + panelWidth, spacingY), Offset(30 + spacing, spacingY), spacingPaint);

    // Arrows
    canvas.drawLine(Offset(30 + panelWidth, spacingY - 5), Offset(30 + panelWidth + 5, spacingY), spacingPaint);
    canvas.drawLine(Offset(30 + panelWidth, spacingY + 5), Offset(30 + panelWidth + 5, spacingY), spacingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
