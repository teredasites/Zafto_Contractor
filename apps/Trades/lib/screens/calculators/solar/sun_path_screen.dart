import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sun Path Calculator - Solar altitude and azimuth by date/time
class SunPathScreen extends ConsumerStatefulWidget {
  const SunPathScreen({super.key});
  @override
  ConsumerState<SunPathScreen> createState() => _SunPathScreenState();
}

class _SunPathScreenState extends ConsumerState<SunPathScreen> {
  final _latitudeController = TextEditingController(text: '41.5');
  final _longitudeController = TextEditingController(text: '-72.7');

  int _month = DateTime.now().month;
  int _hour = 12;

  double? _solarAltitude;
  double? _solarAzimuth;
  double? _solarNoon;
  double? _dayLength;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final lat = double.tryParse(_latitudeController.text);
    final lon = double.tryParse(_longitudeController.text);

    if (lat == null || lon == null) {
      setState(() {
        _solarAltitude = null;
        _solarAzimuth = null;
        _solarNoon = null;
        _dayLength = null;
      });
      return;
    }

    // Day of year approximation for middle of selected month
    final dayOfYear = (_month - 1) * 30 + 15;

    // Declination angle (approximate)
    final declination = 23.45 * math.sin(2 * math.pi * (284 + dayOfYear) / 365);
    final decRad = declination * math.pi / 180;
    final latRad = lat * math.pi / 180;

    // Hour angle
    final hourAngle = ((_hour - 12) * 15).toDouble();
    final hourAngleRad = hourAngle * math.pi / 180;

    // Solar altitude
    final sinAlt = math.sin(latRad) * math.sin(decRad) +
        math.cos(latRad) * math.cos(decRad) * math.cos(hourAngleRad);
    final altitude = math.asin(sinAlt) * 180 / math.pi;

    // Solar azimuth
    final cosAz = (math.sin(decRad) - math.sin(latRad) * sinAlt) /
        (math.cos(latRad) * math.cos(altitude * math.pi / 180));
    var azimuth = math.acos(cosAz.clamp(-1.0, 1.0)) * 180 / math.pi;
    if (_hour > 12) azimuth = 360 - azimuth;
    azimuth = (azimuth + 180) % 360; // Convert to compass bearing

    // Day length (hours)
    final cosHa = -math.tan(latRad) * math.tan(decRad);
    double dayLength;
    if (cosHa <= -1) {
      dayLength = 24; // Polar day
    } else if (cosHa >= 1) {
      dayLength = 0; // Polar night
    } else {
      dayLength = 2 * math.acos(cosHa) * 180 / math.pi / 15;
    }

    // Solar noon (approximate - not accounting for equation of time)
    final solarNoon = 12 - (lon / 15);

    setState(() {
      _solarAltitude = altitude;
      _solarAzimuth = azimuth;
      _solarNoon = solarNoon;
      _dayLength = dayLength;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _latitudeController.text = '41.5';
    _longitudeController.text = '-72.7';
    setState(() {
      _month = DateTime.now().month;
      _hour = 12;
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
        title: Text('Sun Path', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOCATION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Latitude',
                      unit: '°',
                      hint: 'N positive',
                      controller: _latitudeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Longitude',
                      unit: '°',
                      hint: 'W negative',
                      controller: _longitudeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DATE & TIME'),
              const SizedBox(height: 12),
              _buildMonthSelector(colors),
              const SizedBox(height: 12),
              _buildHourSlider(colors),
              const SizedBox(height: 32),
              if (_solarAltitude != null) ...[
                _buildSectionHeader(colors, 'SUN POSITION'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildDayInfo(colors),
              ],
            ],
          ),
        ),
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

  Widget _buildMonthSelector(ZaftoColors colors) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
          Text('Month: ${months[_month - 1]}', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(12, (i) {
              final isSelected = _month == i + 1;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _month = i + 1);
                  _calculate();
                },
                child: Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.fillDefault,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    months[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHourSlider(ZaftoColors colors) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Time of Day', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              Text('${_hour.toString().padLeft(2, '0')}:00', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.fillDefault,
              thumbColor: colors.accentPrimary,
            ),
            child: Slider(
              value: _hour.toDouble(),
              min: 5,
              max: 20,
              divisions: 15,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _hour = v.round());
                _calculate();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 AM', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              Text('Noon', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              Text('8 PM', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final altitude = _solarAltitude!;
    final isAboveHorizon = altitude > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAboveHorizon ? colors.accentPrimary.withValues(alpha: 0.3) : colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPositionTile(
                  colors,
                  'Altitude',
                  '${altitude.toStringAsFixed(1)}°',
                  isAboveHorizon ? colors.accentWarning : colors.textTertiary,
                  LucideIcons.arrowUp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPositionTile(
                  colors,
                  'Azimuth',
                  '${_solarAzimuth!.toStringAsFixed(1)}°',
                  colors.accentInfo,
                  LucideIcons.compass,
                ),
              ),
            ],
          ),
          if (!isAboveHorizon) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.moonStar, size: 14, color: colors.accentError),
                  const SizedBox(width: 8),
                  Text('Sun below horizon', style: TextStyle(color: colors.accentError, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionTile(ZaftoColors colors, String label, String value, Color accentColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDayInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildInfoRow(colors, 'Day Length', '${_dayLength!.toStringAsFixed(1)} hours'),
          const SizedBox(height: 8),
          _buildInfoRow(colors, 'Solar Noon (approx)', '${_solarNoon!.toStringAsFixed(1).replaceAll('.', ':')}0'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
