import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Inter-Row Shading Calculator - Winter solstice shadow analysis
class InterRowShadingScreen extends ConsumerStatefulWidget {
  const InterRowShadingScreen({super.key});
  @override
  ConsumerState<InterRowShadingScreen> createState() => _InterRowShadingScreenState();
}

class _InterRowShadingScreenState extends ConsumerState<InterRowShadingScreen> {
  final _latitudeController = TextEditingController(text: '41.5');
  final _rowSpacingController = TextEditingController(text: '12');
  final _panelHeightController = TextEditingController(text: '6.5');
  final _tiltAngleController = TextEditingController(text: '30');

  double? _winterSolarAltitude;
  double? _shadowLength;
  double? _shadeFreePeriod;
  String? _status;
  bool? _hasShading;

  @override
  void dispose() {
    _latitudeController.dispose();
    _rowSpacingController.dispose();
    _panelHeightController.dispose();
    _tiltAngleController.dispose();
    super.dispose();
  }

  void _calculate() {
    final latitude = double.tryParse(_latitudeController.text);
    final rowSpacing = double.tryParse(_rowSpacingController.text);
    final panelHeight = double.tryParse(_panelHeightController.text);
    final tiltAngle = double.tryParse(_tiltAngleController.text);

    if (latitude == null || rowSpacing == null || panelHeight == null || tiltAngle == null) {
      setState(() {
        _winterSolarAltitude = null;
        _shadowLength = null;
        _shadeFreePeriod = null;
        _status = null;
        _hasShading = null;
      });
      return;
    }

    // Winter solstice solar altitude at solar noon
    const winterDeclination = -23.45;
    final solarAltitude = 90 - latitude + winterDeclination;

    if (solarAltitude <= 0) {
      setState(() {
        _winterSolarAltitude = solarAltitude;
        _shadowLength = null;
        _shadeFreePeriod = 0;
        _status = 'Sun below horizon at winter solstice';
        _hasShading = true;
      });
      return;
    }

    final altRad = solarAltitude * math.pi / 180;
    final tiltRad = tiltAngle * math.pi / 180;

    // Panel vertical projection
    final panelVertical = panelHeight * math.sin(tiltRad);

    // Shadow length at solar noon
    final shadowLength = panelVertical / math.tan(altRad);

    // Check if shadow reaches next row
    final panelHorizontal = panelHeight * math.cos(tiltRad);
    final totalReach = shadowLength + panelHorizontal;
    final hasShading = totalReach > rowSpacing;

    // Estimate shade-free window (hours around solar noon)
    // Simplified: assumes shade-free when sun altitude is above critical angle
    double shadeFreePeriod;
    String status;

    if (!hasShading) {
      shadeFreePeriod = 6.0; // Full solar window
      status = 'No shading at solar noon - spacing adequate';
    } else {
      final overrun = totalReach - rowSpacing;
      final overrunPercent = (overrun / rowSpacing) * 100;
      if (overrunPercent > 30) {
        shadeFreePeriod = 2.0;
        status = 'Significant shading (${overrunPercent.toStringAsFixed(0)}% overrun)';
      } else if (overrunPercent > 15) {
        shadeFreePeriod = 3.5;
        status = 'Moderate shading (${overrunPercent.toStringAsFixed(0)}% overrun)';
      } else {
        shadeFreePeriod = 4.5;
        status = 'Minor shading (${overrunPercent.toStringAsFixed(0)}% overrun)';
      }
    }

    setState(() {
      _winterSolarAltitude = solarAltitude;
      _shadowLength = shadowLength;
      _shadeFreePeriod = shadeFreePeriod;
      _status = status;
      _hasShading = hasShading;
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
    _rowSpacingController.text = '12';
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
        title: Text('Inter-Row Shading', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SITE & ARRAY DATA'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Latitude',
                      unit: '°',
                      hint: 'Site latitude',
                      controller: _latitudeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Row Spacing',
                      unit: 'ft',
                      hint: 'Center to center',
                      controller: _rowSpacingController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Height',
                      unit: 'ft',
                      hint: 'Module dimension',
                      controller: _panelHeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Tilt Angle',
                      unit: '°',
                      hint: 'From horizontal',
                      controller: _tiltAngleController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_winterSolarAltitude != null) ...[
                _buildSectionHeader(colors, 'WINTER SOLSTICE ANALYSIS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildRecommendations(colors),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.snowflake, color: colors.accentInfo, size: 18),
              const SizedBox(width: 8),
              Text(
                'December 21 Analysis',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Check if row spacing prevents shading at worst-case conditions',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
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
    final hasShading = _hasShading!;
    final statusColor = hasShading ? colors.accentWarning : colors.accentSuccess;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Winter Sun', '${_winterSolarAltitude!.toStringAsFixed(1)}°', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Shadow Length', '${_shadowLength?.toStringAsFixed(1) ?? 'N/A'} ft', colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Shade-Free Window', '~${_shadeFreePeriod!.toStringAsFixed(1)} hrs/day'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  hasShading ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status!,
                    style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRecommendations(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESIGN GUIDANCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildGuideRow(colors, 'Target GCR', '30-40% for minimal shading'),
          _buildGuideRow(colors, 'Priority Hours', '9 AM - 3 PM shade-free ideal'),
          _buildGuideRow(colors, 'Tolerance', 'Some winter shade acceptable'),
          _buildGuideRow(colors, 'Annual Impact', 'Winter = ~10% of annual production'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.lightbulb, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Some inter-row shading in winter is often acceptable since winter production is already low. Optimize for annual output, not worst-case day.',
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

  Widget _buildGuideRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
