import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ballasted System Weight Calculator - Flat roof ballast analysis
class BallastedSystemWeightScreen extends ConsumerStatefulWidget {
  const BallastedSystemWeightScreen({super.key});
  @override
  ConsumerState<BallastedSystemWeightScreen> createState() => _BallastedSystemWeightScreenState();
}

class _BallastedSystemWeightScreenState extends ConsumerState<BallastedSystemWeightScreen> {
  final _windSpeedController = TextEditingController(text: '115');
  final _buildingHeightController = TextEditingController(text: '30');
  final _tiltAngleController = TextEditingController(text: '10');
  final _numPanelsController = TextEditingController(text: '100');
  final _panelWeightController = TextEditingController(text: '45');
  final _roofCapacityController = TextEditingController(text: '15');

  String _exposureCategory = 'B';
  String _roofZone = 'Interior';

  double? _ballastPerPanel;
  double? _totalBallast;
  double? _systemLoadPsf;
  bool? _roofOk;
  String? _recommendation;

  @override
  void dispose() {
    _windSpeedController.dispose();
    _buildingHeightController.dispose();
    _tiltAngleController.dispose();
    _numPanelsController.dispose();
    _panelWeightController.dispose();
    _roofCapacityController.dispose();
    super.dispose();
  }

  void _calculate() {
    final windSpeed = double.tryParse(_windSpeedController.text);
    final buildingHeight = double.tryParse(_buildingHeightController.text);
    final tiltAngle = double.tryParse(_tiltAngleController.text);
    final numPanels = int.tryParse(_numPanelsController.text);
    final panelWeight = double.tryParse(_panelWeightController.text);
    final roofCapacity = double.tryParse(_roofCapacityController.text);

    if (windSpeed == null || buildingHeight == null || tiltAngle == null ||
        numPanels == null || panelWeight == null || roofCapacity == null) {
      setState(() {
        _ballastPerPanel = null;
        _totalBallast = null;
        _systemLoadPsf = null;
        _roofOk = null;
        _recommendation = null;
      });
      return;
    }

    // Standard panel area
    const panelAreaSqFt = 21.5; // ~77" x 40"

    // Exposure coefficient
    double kz;
    if (_exposureCategory == 'B') {
      kz = buildingHeight <= 15 ? 0.57 : (buildingHeight <= 30 ? 0.70 : 0.81);
    } else if (_exposureCategory == 'C') {
      kz = buildingHeight <= 15 ? 0.85 : (buildingHeight <= 30 ? 0.98 : 1.09);
    } else {
      kz = buildingHeight <= 15 ? 1.03 : (buildingHeight <= 30 ? 1.16 : 1.27);
    }

    // Wind pressure (psf)
    final windPressure = 0.00256 * kz * 0.85 * math.pow(windSpeed, 2);

    // GCp for ballasted system based on roof zone
    double gcpUplift;
    switch (_roofZone) {
      case 'Corner':
        gcpUplift = -2.8;
        break;
      case 'Edge':
        gcpUplift = -2.2;
        break;
      case 'Interior':
      default:
        gcpUplift = -1.4;
    }

    // Tilt factor - higher tilt = more uplift
    final tiltFactor = 1.0 + (tiltAngle / 45) * 0.5;

    // Net uplift per panel (lbs)
    final upliftPerPanel = windPressure * gcpUplift.abs() * panelAreaSqFt * tiltFactor;

    // Ballast required = Uplift - Panel Weight, with 1.5 safety factor
    // Friction coefficient ~0.4 for typical ballast on membrane
    const frictionCoef = 0.4;
    final ballastRequired = (upliftPerPanel * 1.5 / frictionCoef) - panelWeight;
    final ballastPerPanel = math.max(0, ballastRequired);

    // Total ballast
    final totalBallast = ballastPerPanel * numPanels;

    // System load on roof (psf)
    // Include panel, racking (~3 lbs/panel), and ballast
    final totalWeightPerPanel = panelWeight + 3 + ballastPerPanel;
    // Footprint area (ballast trays are larger than panel)
    final footprintArea = panelAreaSqFt * 1.3; // ~30% larger footprint
    final systemLoadPsf = totalWeightPerPanel / footprintArea;

    // Check roof capacity
    final roofOk = systemLoadPsf <= roofCapacity;

    String recommendation;
    if (!roofOk) {
      recommendation = 'Exceeds roof capacity. Reduce ballast or add supports. Consider penetrating mount.';
    } else if (systemLoadPsf > roofCapacity * 0.8) {
      recommendation = 'Near roof capacity limit. Get structural engineer approval.';
    } else if (ballastPerPanel > 60) {
      recommendation = 'High ballast required. Consider wind deflector or lower tilt.';
    } else {
      recommendation = 'Within limits. Standard ballasted installation suitable.';
    }

    setState(() {
      _ballastPerPanel = ballastPerPanel.toDouble();
      _totalBallast = totalBallast.toDouble();
      _systemLoadPsf = systemLoadPsf;
      _roofOk = roofOk;
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
    _buildingHeightController.text = '30';
    _tiltAngleController.text = '10';
    _numPanelsController.text = '100';
    _panelWeightController.text = '45';
    _roofCapacityController.text = '15';
    setState(() {
      _exposureCategory = 'B';
      _roofZone = 'Interior';
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
        title: Text('Ballasted System', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wind Speed',
                      unit: 'mph',
                      hint: 'ASCE 7',
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildExposureSelector(colors)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildZoneSelector(colors)),
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
                      hint: '5-15 typical',
                      controller: _tiltAngleController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Count',
                      unit: 'qty',
                      hint: 'Total',
                      controller: _numPanelsController,
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
                      label: 'Panel Weight',
                      unit: 'lbs',
                      hint: 'Per panel',
                      controller: _panelWeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Capacity',
                      unit: 'psf',
                      hint: 'Dead load',
                      controller: _roofCapacityController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_ballastPerPanel != null) ...[
                _buildSectionHeader(colors, 'BALLAST REQUIREMENTS'),
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
              Icon(LucideIcons.scale, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ballasted System Weight',
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
            'Calculate ballast for flat roof systems',
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
          items: ['B', 'C', 'D'].map((exp) {
            return DropdownMenuItem(value: exp, child: Text('Exp. $exp'));
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

  Widget _buildZoneSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _roofZone,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: ['Interior', 'Edge', 'Corner'].map((zone) {
            return DropdownMenuItem(value: zone, child: Text(zone));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _roofZone = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _roofOk! ? colors.accentSuccess : colors.accentError;

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
                child: _buildStatTile(colors, 'Ballast/Panel', '${_ballastPerPanel!.toStringAsFixed(0)} lbs', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Total Ballast', '${(_totalBallast! / 1000).toStringAsFixed(1)}k lbs', colors.accentInfo),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('System Load', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    Row(
                      children: [
                        Text('${_systemLoadPsf!.toStringAsFixed(1)} psf',
                            style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Icon(
                          _roofOk! ? LucideIcons.check : LucideIcons.alertTriangle,
                          size: 16,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Roof Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    Text('${_roofCapacityController.text} psf',
                        style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Concrete blocks needed', '${(_totalBallast! / 8).ceil()} (8lb ea)'),
                const SizedBox(height: 4),
                _buildResultRow(colors, 'Or pavers needed', '${(_totalBallast! / 18).ceil()} (18lb ea)'),
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
                Icon(LucideIcons.info, size: 16, color: _roofOk! ? colors.accentInfo : colors.accentError),
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
