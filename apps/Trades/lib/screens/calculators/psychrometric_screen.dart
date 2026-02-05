import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Psychrometric Calculator - Design System v2.6
/// Complete air properties from any two known values
class PsychrometricScreen extends ConsumerStatefulWidget {
  const PsychrometricScreen({super.key});
  @override
  ConsumerState<PsychrometricScreen> createState() => _PsychrometricScreenState();
}

class _PsychrometricScreenState extends ConsumerState<PsychrometricScreen> {
  double _dryBulb = 75;
  double _relativeHumidity = 50;
  double _altitude = 0;

  double? _wetBulb;
  double? _dewPoint;
  double? _humidityRatio;
  double? _enthalpy;
  double? _specificVolume;
  double? _vaporPressure;
  String? _comfortZone;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Constants
    final tDb = _dryBulb;
    final rh = _relativeHumidity / 100;

    // Barometric pressure at altitude (simplified)
    final pAtm = 14.696 * math.pow((1 - 6.8753e-6 * _altitude), 5.2559);

    // Saturation vapor pressure (Magnus formula approximation)
    final tC = (tDb - 32) * 5 / 9;
    final pSat = 0.61078 * math.exp((17.27 * tC) / (tC + 237.3)) * 0.145038; // Convert kPa to psi

    // Actual vapor pressure
    final pV = rh * pSat;

    // Humidity ratio (lb water / lb dry air)
    final w = 0.622 * pV / (pAtm - pV);

    // Dew point (simplified)
    final alpha = math.log(rh) + (17.27 * tC) / (tC + 237.3);
    final dewPointC = (237.3 * alpha) / (17.27 - alpha);
    final dewPoint = dewPointC * 9 / 5 + 32;

    // Wet bulb (approximation)
    final wetBulb = tDb * math.atan(0.151977 * math.sqrt(rh * 100 + 8.313659)) +
        math.atan(tDb + rh * 100) -
        math.atan(rh * 100 - 1.676331) +
        0.00391838 * math.pow(rh * 100, 1.5) * math.atan(0.023101 * rh * 100) -
        4.686035;

    // Enthalpy (BTU/lb)
    final h = 0.240 * tDb + w * (1061 + 0.444 * tDb);

    // Specific volume (cu ft / lb)
    final v = 0.370486 * (tDb + 459.67) * (1 + 1.6078 * w) / pAtm;

    // Grains per pound
    final grains = w * 7000;

    // Comfort zone check
    String comfortZone;
    if (tDb >= 68 && tDb <= 76 && _relativeHumidity >= 30 && _relativeHumidity <= 60) {
      comfortZone = 'Comfort Zone';
    } else if (tDb < 68) {
      comfortZone = 'Too Cool';
    } else if (tDb > 76) {
      comfortZone = 'Too Warm';
    } else if (_relativeHumidity < 30) {
      comfortZone = 'Too Dry';
    } else {
      comfortZone = 'Too Humid';
    }

    setState(() {
      _wetBulb = wetBulb;
      _dewPoint = dewPoint;
      _humidityRatio = grains;
      _enthalpy = h;
      _specificVolume = v;
      _vaporPressure = pV;
      _comfortZone = comfortZone;
    });
  }

  void _reset() {
    setState(() {
      _dryBulb = 75;
      _relativeHumidity = 50;
      _altitude = 0;
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
        title: Text('Psychrometrics', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'KNOWN VALUES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Dry Bulb Temperature', value: _dryBulb, min: 32, max: 120, unit: '\u00B0F', onChanged: (v) { setState(() => _dryBulb = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Relative Humidity', value: _relativeHumidity, min: 10, max: 100, unit: '%', onChanged: (v) { setState(() => _relativeHumidity = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Altitude', value: _altitude, min: 0, max: 10000, unit: ' ft', onChanged: (v) { setState(() => _altitude = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'AIR PROPERTIES'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildPropertiesGrid(colors),
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
        Icon(LucideIcons.thermometerSun, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Calculate all psychrometric properties from dry bulb and relative humidity. Essential for load calculations and coil sizing.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
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
    Color zoneColor;
    IconData zoneIcon;
    switch (_comfortZone) {
      case 'Comfort Zone':
        zoneColor = Colors.green;
        zoneIcon = LucideIcons.checkCircle;
        break;
      case 'Too Cool':
        zoneColor = Colors.blue;
        zoneIcon = LucideIcons.snowflake;
        break;
      case 'Too Warm':
        zoneColor = Colors.orange;
        zoneIcon = LucideIcons.sun;
        break;
      case 'Too Dry':
        zoneColor = Colors.amber;
        zoneIcon = LucideIcons.droplet;
        break;
      default:
        zoneColor = Colors.cyan;
        zoneIcon = LucideIcons.droplets;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(zoneIcon, color: zoneColor, size: 24),
            const SizedBox(width: 8),
            Text(_comfortZone ?? '', style: TextStyle(color: zoneColor, fontSize: 20, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.thermometer, color: Colors.blue, size: 20),
                  const SizedBox(height: 4),
                  Text('${_wetBulb?.toStringAsFixed(1)}\u00B0F', style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('Wet Bulb', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.droplet, color: Colors.cyan, size: 20),
                  const SizedBox(height: 4),
                  Text('${_dewPoint?.toStringAsFixed(1)}\u00B0F', style: TextStyle(color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('Dew Point', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.flame, color: Colors.purple, size: 20),
                  const SizedBox(height: 4),
                  Text('${_enthalpy?.toStringAsFixed(1)}', style: TextStyle(color: Colors.purple, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('BTU/lb', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPropertiesGrid(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALL PROPERTIES', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildPropertyRow(colors, 'Dry Bulb', '${_dryBulb.toStringAsFixed(1)}\u00B0F'),
          _buildPropertyRow(colors, 'Wet Bulb', '${_wetBulb?.toStringAsFixed(1)}\u00B0F'),
          _buildPropertyRow(colors, 'Dew Point', '${_dewPoint?.toStringAsFixed(1)}\u00B0F'),
          _buildPropertyRow(colors, 'Relative Humidity', '${_relativeHumidity.toStringAsFixed(0)}%'),
          _buildPropertyRow(colors, 'Humidity Ratio', '${_humidityRatio?.toStringAsFixed(1)} gr/lb'),
          _buildPropertyRow(colors, 'Enthalpy', '${_enthalpy?.toStringAsFixed(2)} BTU/lb'),
          _buildPropertyRow(colors, 'Specific Volume', '${_specificVolume?.toStringAsFixed(2)} ft\u00B3/lb'),
          _buildPropertyRow(colors, 'Vapor Pressure', '${_vaporPressure?.toStringAsFixed(3)} psi'),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
