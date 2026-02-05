import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wind Uplift Calculator - Calculate roof wind uplift pressures
class WindUpliftScreen extends ConsumerStatefulWidget {
  const WindUpliftScreen({super.key});
  @override
  ConsumerState<WindUpliftScreen> createState() => _WindUpliftScreenState();
}

class _WindUpliftScreenState extends ConsumerState<WindUpliftScreen> {
  final _windSpeedController = TextEditingController(text: '110');
  final _buildingHeightController = TextEditingController(text: '25');

  String _exposureCategory = 'B';
  String _roofZone = 'Field';

  double? _velocityPressure;
  double? _upliftPressure;
  double? _cornerPressure;
  String? _fastenerRequirement;

  @override
  void dispose() {
    _windSpeedController.dispose();
    _buildingHeightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final windSpeed = double.tryParse(_windSpeedController.text);
    final buildingHeight = double.tryParse(_buildingHeightController.text);

    if (windSpeed == null || buildingHeight == null) {
      setState(() {
        _velocityPressure = null;
        _upliftPressure = null;
        _cornerPressure = null;
        _fastenerRequirement = null;
      });
      return;
    }

    // Velocity pressure: qz = 0.00256 × Kz × Kzt × Kd × V²
    // Simplified: assuming Kzt = 1.0 (flat terrain), Kd = 0.85 (components)

    // Exposure coefficient Kz (varies with height and exposure)
    double kz;
    if (buildingHeight <= 15) {
      kz = _exposureCategory == 'B' ? 0.57 : (_exposureCategory == 'C' ? 0.85 : 1.03);
    } else if (buildingHeight <= 30) {
      kz = _exposureCategory == 'B' ? 0.70 : (_exposureCategory == 'C' ? 0.94 : 1.10);
    } else {
      kz = _exposureCategory == 'B' ? 0.81 : (_exposureCategory == 'C' ? 1.04 : 1.16);
    }

    final velocityPressure = 0.00256 * kz * 1.0 * 0.85 * math.pow(windSpeed, 2);

    // External pressure coefficient varies by zone
    double gcpNeg; // Negative (uplift) coefficient
    switch (_roofZone) {
      case 'Field':
        gcpNeg = -1.0;
        break;
      case 'Edge':
        gcpNeg = -1.8;
        break;
      case 'Corner':
        gcpNeg = -2.8;
        break;
      default:
        gcpNeg = -1.0;
    }

    // Internal pressure coefficient (enclosed building)
    const gcpInt = 0.18;

    // Net uplift pressure
    final upliftPressure = velocityPressure * (gcpNeg - gcpInt);

    // Corner zone is always worst case
    final cornerPressure = velocityPressure * (-2.8 - gcpInt);

    // Fastener requirement estimate
    String fastenerRequirement;
    if (upliftPressure.abs() < 30) {
      fastenerRequirement = 'Standard 4-nail pattern';
    } else if (upliftPressure.abs() < 50) {
      fastenerRequirement = 'Enhanced 6-nail pattern';
    } else {
      fastenerRequirement = 'High-wind rated system required';
    }

    setState(() {
      _velocityPressure = velocityPressure;
      _upliftPressure = upliftPressure;
      _cornerPressure = cornerPressure;
      _fastenerRequirement = fastenerRequirement;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _windSpeedController.text = '110';
    _buildingHeightController.text = '25';
    setState(() {
      _exposureCategory = 'B';
      _roofZone = 'Field';
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
        title: Text('Wind Uplift', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'WIND CONDITIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wind Speed',
                      unit: 'mph',
                      hint: 'Design speed',
                      controller: _windSpeedController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Building Height',
                      unit: 'ft',
                      hint: 'Mean roof',
                      controller: _buildingHeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildExposureSelector(colors),
              const SizedBox(height: 12),
              _buildZoneSelector(colors),
              const SizedBox(height: 32),
              if (_upliftPressure != null) ...[
                _buildSectionHeader(colors, 'UPLIFT PRESSURES'),
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
                'Wind Uplift Calculator',
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
            'ASCE 7 roof wind uplift pressures',
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
    return Row(
      children: exposures.map((exp) {
        final isSelected = _exposureCategory == exp;
        String label;
        switch (exp) {
          case 'B':
            label = 'B - Urban';
            break;
          case 'C':
            label = 'C - Open';
            break;
          case 'D':
            label = 'D - Coastal';
            break;
          default:
            label = exp;
        }
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _exposureCategory = exp);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: exp != exposures.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildZoneSelector(ZaftoColors colors) {
    final zones = ['Field', 'Edge', 'Corner'];
    return Row(
      children: zones.map((zone) {
        final isSelected = _roofZone == zone;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _roofZone = zone);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: zone != zones.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                zone,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Velocity Pressure (qz)', '${_velocityPressure!.toStringAsFixed(1)} PSF'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'ZONE UPLIFT', '${_upliftPressure!.toStringAsFixed(1)} PSF', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Corner Zone', '${_cornerPressure!.toStringAsFixed(1)} PSF'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FASTENING REQUIREMENT', style: TextStyle(color: colors.accentWarning, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(_fastenerRequirement!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                    'Corner and edge zones require enhanced fastening. Consult manufacturer specs for high-wind rated systems.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? colors.accentPrimary : colors.textPrimary,
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
