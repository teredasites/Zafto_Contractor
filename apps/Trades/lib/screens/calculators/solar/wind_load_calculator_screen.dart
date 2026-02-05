import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wind Load Calculator - ASCE 7 wind load analysis
class WindLoadCalculatorScreen extends ConsumerStatefulWidget {
  const WindLoadCalculatorScreen({super.key});
  @override
  ConsumerState<WindLoadCalculatorScreen> createState() => _WindLoadCalculatorScreenState();
}

class _WindLoadCalculatorScreenState extends ConsumerState<WindLoadCalculatorScreen> {
  final _windSpeedController = TextEditingController(text: '115');
  final _buildingHeightController = TextEditingController(text: '25');
  final _tiltAngleController = TextEditingController(text: '20');
  final _panelAreaController = TextEditingController(text: '21.5');

  String _exposureCategory = 'B';
  String _riskCategory = 'II';

  double? _velocityPressure;
  double? _netUplift;
  double? _netDownforce;
  double? _designLoad;
  String? _recommendation;

  @override
  void dispose() {
    _windSpeedController.dispose();
    _buildingHeightController.dispose();
    _tiltAngleController.dispose();
    _panelAreaController.dispose();
    super.dispose();
  }

  void _calculate() {
    final windSpeed = double.tryParse(_windSpeedController.text);
    final buildingHeight = double.tryParse(_buildingHeightController.text);
    final tiltAngle = double.tryParse(_tiltAngleController.text);
    final panelArea = double.tryParse(_panelAreaController.text);

    if (windSpeed == null || buildingHeight == null || tiltAngle == null || panelArea == null) {
      setState(() {
        _velocityPressure = null;
        _netUplift = null;
        _netDownforce = null;
        _designLoad = null;
        _recommendation = null;
      });
      return;
    }

    // ASCE 7 simplified calculation
    // Velocity pressure: qz = 0.00256 * Kz * Kzt * Kd * V^2
    // Simplified: qz = 0.00256 * Kz * V^2 (assuming Kzt=1, Kd=0.85 for solar)

    // Exposure coefficient Kz (simplified based on height and exposure)
    double kz;
    if (_exposureCategory == 'B') {
      kz = buildingHeight <= 15 ? 0.57 : (buildingHeight <= 30 ? 0.70 : 0.81);
    } else if (_exposureCategory == 'C') {
      kz = buildingHeight <= 15 ? 0.85 : (buildingHeight <= 30 ? 0.98 : 1.09);
    } else {
      // Exposure D
      kz = buildingHeight <= 15 ? 1.03 : (buildingHeight <= 30 ? 1.16 : 1.27);
    }

    // Importance factor by risk category
    double iw;
    switch (_riskCategory) {
      case 'I':
        iw = 0.87;
        break;
      case 'II':
        iw = 1.0;
        break;
      case 'III':
        iw = 1.15;
        break;
      case 'IV':
        iw = 1.15;
        break;
      default:
        iw = 1.0;
    }

    // Velocity pressure (psf)
    final velocityPressure = 0.00256 * kz * 0.85 * math.pow(windSpeed, 2) * iw;

    // GCp coefficients for solar panels (simplified ASCE 7-22 approach)
    // These vary by tilt angle and panel position
    final tiltRad = tiltAngle * math.pi / 180;

    // Simplified net pressure coefficients
    // Uplift coefficient (negative = suction)
    final gcpUplift = -1.5 - (0.02 * tiltAngle); // More uplift at higher tilt
    // Downforce coefficient
    final gcpDownforce = 1.0 + (0.01 * tiltAngle);

    // Net design pressures (psf)
    final netUplift = velocityPressure * gcpUplift;
    final netDownforce = velocityPressure * gcpDownforce;

    // Design load per panel (lbs) - use absolute values for display
    final designLoad = netUplift.abs() * panelArea;

    String recommendation;
    if (velocityPressure > 35) {
      recommendation = 'High wind zone. Use heavy-duty mounts rated for ${(netUplift.abs()).toStringAsFixed(0)}+ psf uplift.';
    } else if (velocityPressure > 25) {
      recommendation = 'Moderate wind exposure. Verify mount uplift rating exceeds ${(netUplift.abs()).toStringAsFixed(0)} psf.';
    } else {
      recommendation = 'Standard wind zone. Most commercial mounts will be adequate.';
    }

    setState(() {
      _velocityPressure = velocityPressure;
      _netUplift = netUplift;
      _netDownforce = netDownforce;
      _designLoad = designLoad;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _windSpeedController.text = '115';
    _buildingHeightController.text = '25';
    _tiltAngleController.text = '20';
    _panelAreaController.text = '21.5';
    setState(() {
      _exposureCategory = 'B';
      _riskCategory = 'II';
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
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Wind Load Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'WIND PARAMETERS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Basic Wind Speed',
                      unit: 'mph',
                      hint: 'ASCE 7 map',
                      controller: _windSpeedController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Building Height',
                      unit: 'ft',
                      hint: 'To roof',
                      controller: _buildingHeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'EXPOSURE & RISK'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildExposureSelector(colors)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRiskSelector(colors)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ARRAY'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Tilt Angle',
                      unit: 'deg',
                      hint: 'Panel tilt',
                      controller: _tiltAngleController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Area',
                      unit: 'sq ft',
                      hint: 'Per panel',
                      controller: _panelAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_velocityPressure != null) ...[
                _buildSectionHeader(colors, 'WIND LOAD ANALYSIS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
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
              Icon(LucideIcons.wind, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Wind Load Calculator',
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
            'ASCE 7 based wind pressure calculations',
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

  Widget _buildExposureSelector(ZaftoColors colors) {
    final exposures = ['B', 'C', 'D'];
    final labels = {
      'B': 'B (Urban)',
      'C': 'C (Suburban)',
      'D': 'D (Coastal)',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _exposureCategory,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: exposures.map((exp) {
            return DropdownMenuItem(
              value: exp,
              child: Text(labels[exp]!),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _exposureCategory = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRiskSelector(ZaftoColors colors) {
    final risks = ['I', 'II', 'III', 'IV'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _riskCategory,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: risks.map((risk) {
            return DropdownMenuItem(
              value: risk,
              child: Text('Risk Cat. $risk'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _riskCategory = value);
              _calculate();
            }
          },
        ),
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
          Text('Velocity Pressure (qz)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _velocityPressure!.toStringAsFixed(1),
                style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  ' psf',
                  style: TextStyle(color: colors.textSecondary, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPressureTile(colors, 'Uplift', '${_netUplift!.toStringAsFixed(1)} psf', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPressureTile(colors, 'Downforce', '${_netDownforce!.toStringAsFixed(1)} psf', colors.accentInfo),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('Design Uplift Per Panel', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '${_designLoad!.toStringAsFixed(0)} lbs',
                  style: TextStyle(color: colors.accentWarning, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
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

  Widget _buildPressureTile(ZaftoColors colors, String label, String value, Color accentColor) {
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
