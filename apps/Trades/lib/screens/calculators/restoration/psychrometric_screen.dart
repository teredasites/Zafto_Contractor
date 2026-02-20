import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Psychrometric Calculator — Grains Per Pound & Dew Point
///
/// Calculates psychrometric properties critical for drying decisions:
/// GPP (Grains Per Pound), dew point, vapor pressure, and specific humidity.
///
/// GPP is the primary metric restoration professionals use to determine
/// dehumidifier performance and drying progress.
///
/// References: ASHRAE Fundamentals Ch. 1, IICRC S500 Drying Goals
class PsychrometricScreen extends ConsumerStatefulWidget {
  const PsychrometricScreen({super.key});
  @override
  ConsumerState<PsychrometricScreen> createState() => _PsychrometricScreenState();
}

class _PsychrometricScreenState extends ConsumerState<PsychrometricScreen> {
  double _dryBulbF = 72;
  double _relativeHumidity = 50;

  // Saturation vapor pressure (psi) using Magnus formula
  // Input in °F, converted to °C internally
  double _satVaporPressure(double tempF) {
    final tempC = (tempF - 32) * 5 / 9;
    // Magnus formula: Ps = 6.1078 × 10^(7.5T / (237.3+T)) in hPa
    final psHpa = 6.1078 * math.pow(10, (7.5 * tempC) / (237.3 + tempC));
    // Convert hPa to psi (1 hPa = 0.0145038 psi)
    return psHpa * 0.0145038;
  }

  // Actual vapor pressure (psi)
  double get _vaporPressure => _satVaporPressure(_dryBulbF) * (_relativeHumidity / 100);

  // Humidity ratio (lb water / lb dry air) at standard atmospheric pressure (14.696 psi)
  double get _humidityRatio {
    final pv = _vaporPressure;
    const patm = 14.696; // standard atmospheric pressure psi
    return 0.62198 * pv / (patm - pv);
  }

  // Grains per pound (1 lb = 7000 grains)
  double get _gpp => _humidityRatio * 7000;

  // Dew point temperature (°F) — using Magnus inverse
  double get _dewPointF {
    final tempC = (_dryBulbF - 32) * 5 / 9;
    final gamma = math.log((_relativeHumidity / 100) *
        math.pow(10, (7.5 * tempC) / (237.3 + tempC))) /
        math.ln10;
    final dewC = 237.3 * gamma / (7.5 - gamma);
    return dewC * 9 / 5 + 32;
  }

  // Wet bulb temperature approximation (Stull 2011 formula)
  double get _wetBulbF {
    final t = (_dryBulbF - 32) * 5 / 9; // °C
    final rh = _relativeHumidity;
    // Stull (2011) empirical formula - accurate ±0.3°C for common ranges
    final twC = t * math.atan(0.151977 * math.sqrt(rh + 8.313659)) +
        math.atan(t + rh) -
        math.atan(rh - 1.676331) +
        0.00391838 * math.pow(rh, 1.5) * math.atan(0.023101 * rh) -
        4.686035;
    return twC * 9 / 5 + 32;
  }

  // Specific enthalpy (BTU/lb dry air)
  double get _enthalpy => 0.240 * _dryBulbF + _humidityRatio * (1061 + 0.444 * _dryBulbF);

  // Specific volume (cu ft / lb dry air)
  double get _specificVolume {
    final tRankine = _dryBulbF + 459.67;
    const patm = 14.696;
    final pv = _vaporPressure;
    return 0.370486 * tRankine * (1 + 1.6078 * _humidityRatio) / (patm - pv + pv);
  }

  // GPP target for drying (IICRC: typically 40-50 GPP for aggressive drying)
  String get _dryingAssessment {
    if (_gpp < 40) return 'Excellent drying conditions — aggressive removal rate';
    if (_gpp < 55) return 'Good drying conditions — standard equipment effective';
    if (_gpp < 70) return 'Moderate conditions — may need additional dehumidification';
    if (_gpp < 90) return 'Poor drying conditions — LGR dehumidifiers recommended';
    return 'Very poor conditions — desiccant dehumidifier or supplemental heat needed';
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
        title: Text(
          'Psychrometric Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildInputCard(colors),
          const SizedBox(height: 16),
          _buildDryingAssessment(colors),
          const SizedBox(height: 16),
          _buildGppGuide(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${_gpp.toStringAsFixed(1)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Grains Per Pound (GPP)',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Dry Bulb', '${_dryBulbF.toStringAsFixed(1)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Wet Bulb', '${_wetBulbF.toStringAsFixed(1)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Dew Point', '${_dewPointF.toStringAsFixed(1)}°F'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: colors.borderSubtle),
                ),
                _buildResultRow(colors, 'Vapor Pressure', '${_vaporPressure.toStringAsFixed(4)} psi'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Humidity Ratio', '${(_humidityRatio * 1000).toStringAsFixed(2)} gr/lb×10⁻³'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Enthalpy', '${_enthalpy.toStringAsFixed(1)} BTU/lb'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Specific Vol.', '${_specificVolume.toStringAsFixed(2)} ft³/lb'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMBIENT CONDITIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dry Bulb Temperature', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_dryBulbF.toStringAsFixed(0)}°F',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _dryBulbF,
              min: 40,
              max: 120,
              divisions: 80,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _dryBulbF = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Relative Humidity', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_relativeHumidity.toStringAsFixed(0)}%',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _relativeHumidity,
              min: 5,
              max: 100,
              divisions: 95,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _relativeHumidity = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDryingAssessment(ZaftoColors colors) {
    final assessColor = _gpp < 55
        ? Colors.green
        : _gpp < 70
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: assessColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, color: assessColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'DRYING ASSESSMENT',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _dryingAssessment,
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGppGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GPP REFERENCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildGppRow(colors, '< 40 GPP', 'Aggressive drying', Colors.green),
          const SizedBox(height: 6),
          _buildGppRow(colors, '40-55 GPP', 'Standard drying', Colors.blue),
          const SizedBox(height: 6),
          _buildGppRow(colors, '55-70 GPP', 'Supplemental dehu needed', Colors.orange),
          const SizedBox(height: 6),
          _buildGppRow(colors, '70-90 GPP', 'LGR dehumidifier', Colors.deepOrange),
          const SizedBox(height: 6),
          _buildGppRow(colors, '> 90 GPP', 'Desiccant or heat drying', Colors.red),
          const SizedBox(height: 12),
          Text(
            'Drying goal: achieve GPP in affected area 7-10 GPP below unaffected area.',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildGppRow(ZaftoColors colors, String range, String desc, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(range, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ASHRAE / IICRC S500',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• GPP = primary drying metric for restorers\n'
            '• Magnus formula for saturation vapor pressure\n'
            '• Stull (2011) wet bulb approximation\n'
            '• Dew point = condensation temperature\n'
            '• Monitor GPP daily with thermo-hygrometer\n'
            '• Target: affected area GPP < unaffected - 7 GPP',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
