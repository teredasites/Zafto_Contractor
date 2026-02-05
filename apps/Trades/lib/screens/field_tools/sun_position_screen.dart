import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Sun Position Calculator - Solar angles for panel/skylight placement
class SunPositionScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const SunPositionScreen({super.key, this.jobId});

  @override
  ConsumerState<SunPositionScreen> createState() => _SunPositionScreenState();
}

class _SunPositionScreenState extends ConsumerState<SunPositionScreen> {
  // Location
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLoadingLocation = true;

  // Date/Time
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Calculated values
  double? _sunAltitude;
  double? _sunAzimuth;
  DateTime? _sunrise;
  DateTime? _sunset;
  DateTime? _solarNoon;
  double? _daylightHours;

  // Manual coordinate input
  bool _showManualInput = false;
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final cameraService = ref.read(fieldCameraServiceProvider);
    final location = await cameraService.getCurrentLocation();

    if (location != null && mounted) {
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _address = location.address;
        _isLoadingLocation = false;
        _latController.text = location.latitude.toStringAsFixed(6);
        _lonController.text = location.longitude.toStringAsFixed(6);
      });
      _calculateSunPosition();
    } else if (mounted) {
      // Default to Hartford, CT if location unavailable
      setState(() {
        _latitude = 41.7658;
        _longitude = -72.6734;
        _address = 'Hartford, CT (Default)';
        _isLoadingLocation = false;
        _latController.text = '41.765800';
        _lonController.text = '-72.673400';
      });
      _calculateSunPosition();
    }
  }

  void _calculateSunPosition() {
    if (_latitude == null || _longitude == null) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Calculate sun position
    final position = _SunCalculator.calculatePosition(_latitude!, _longitude!, dateTime);
    final times = _SunCalculator.calculateTimes(_latitude!, _longitude!, _selectedDate);

    setState(() {
      _sunAltitude = position.altitude;
      _sunAzimuth = position.azimuth;
      _sunrise = times.sunrise;
      _sunset = times.sunset;
      _solarNoon = times.solarNoon;
      if (_sunrise != null && _sunset != null) {
        _daylightHours = _sunset!.difference(_sunrise!).inMinutes / 60.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sun Position', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.info, color: colors.textTertiary),
            onPressed: () => _showUsageGuide(colors),
          ),
        ],
      ),
      body: _isLoadingLocation
          ? _buildLoadingState(colors)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Location Card
                _buildLocationCard(colors),
                const SizedBox(height: 16),

                // Date/Time Selector
                _buildDateTimeSelector(colors),
                const SizedBox(height: 20),

                // Sun Position Display
                if (_sunAltitude != null && _sunAzimuth != null) ...[
                  _buildSunPositionCard(colors),
                  const SizedBox(height: 16),

                  // Sun Path Visual
                  _buildSunPathVisual(colors),
                  const SizedBox(height: 16),

                  // Day Info
                  _buildDayInfoCard(colors),
                  const SizedBox(height: 16),

                  // Trade Applications
                  _buildTradeApplications(colors),
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildLoadingState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colors.accentPrimary),
          const SizedBox(height: 20),
          Text('Getting location...', style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ZaftoColors colors) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.mapPin, color: colors.accentPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _address ?? 'Current Location',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_latitude?.toStringAsFixed(4)}°, ${_longitude?.toStringAsFixed(4)}°',
                      style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _showManualInput ? LucideIcons.chevronUp : LucideIcons.edit,
                  color: colors.textTertiary,
                  size: 18,
                ),
                onPressed: () => setState(() => _showManualInput = !_showManualInput),
              ),
            ],
          ),

          // Manual input
          if (_showManualInput) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      labelStyle: TextStyle(color: colors.textTertiary, fontSize: 12),
                      filled: true,
                      fillColor: colors.fillDefault,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lonController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      labelStyle: TextStyle(color: colors.textTertiary, fontSize: 12),
                      filled: true,
                      fillColor: colors.fillDefault,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(LucideIcons.locateFixed, size: 16, color: colors.accentPrimary),
                    label: Text('Use GPS', style: TextStyle(color: colors.accentPrimary, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.accentPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      setState(() => _isLoadingLocation = true);
                      _fetchLocation();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.calculator, size: 16),
                    label: const Text('Calculate', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      final lat = double.tryParse(_latController.text);
                      final lon = double.tryParse(_lonController.text);
                      if (lat != null && lon != null) {
                        setState(() {
                          _latitude = lat;
                          _longitude = lon;
                          _address = 'Custom Location';
                          _showManualInput = false;
                        });
                        _calculateSunPosition();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(colors),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 18, color: colors.accentPrimary),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectTime(colors),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, size: 18, color: colors.accentPrimary),
                  const SizedBox(width: 10),
                  Text(
                    _formatTime(_selectedTime),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedDate = DateTime.now();
              _selectedTime = TimeOfDay.now();
            });
            _calculateSunPosition();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.refreshCw, size: 18, color: colors.accentPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSunPositionCard(ZaftoColors colors) {
    final isAboveHorizon = _sunAltitude! > 0;
    final azimuthDirection = _getCompassDirection(_sunAzimuth!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAboveHorizon
              ? [Colors.orange.shade700, Colors.amber.shade600]
              : [Colors.indigo.shade800, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Sun icon
          Icon(
            isAboveHorizon ? LucideIcons.sun : LucideIcons.moon,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),

          // Main readings
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('ALTITUDE', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      '${_sunAltitude!.toStringAsFixed(1)}°',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      isAboveHorizon ? 'Above Horizon' : 'Below Horizon',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
              Expanded(
                child: Column(
                  children: [
                    Text('AZIMUTH', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      '${_sunAzimuth!.toStringAsFixed(1)}°',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      azimuthDirection,
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunPathVisual(ZaftoColors colors) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: CustomPaint(
        painter: _SunPathPainter(
          altitude: _sunAltitude!,
          azimuth: _sunAzimuth!,
          colors: colors,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildDayInfoCard(ZaftoColors colors) {
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
            children: [
              _buildTimeInfo(colors, 'Sunrise', _sunrise, LucideIcons.sunrise, Colors.orange),
              _buildTimeInfo(colors, 'Solar Noon', _solarNoon, LucideIcons.sun, Colors.amber),
              _buildTimeInfo(colors, 'Sunset', _sunset, LucideIcons.sunset, Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.clock, size: 18, color: colors.accentInfo),
                const SizedBox(width: 8),
                Text(
                  'Daylight: ${_daylightHours?.toStringAsFixed(1) ?? '--'} hours',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentInfo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(ZaftoColors colors, String label, DateTime? time, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 8),
          Text(
            time != null ? _formatDateTime(time) : '--:--',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildTradeApplications(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.wrench, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'TRADE APPLICATIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildApplicationTile(colors, LucideIcons.panelTop, 'Solar Panel Angle',
              'Optimal tilt: ${(90 - (_sunAltitude ?? 0)).abs().toStringAsFixed(1)}° from horizontal'),
          _buildApplicationTile(colors, LucideIcons.square, 'Skylight Placement',
              'Sun direction: ${_getCompassDirection(_sunAzimuth ?? 0)} at ${_sunAzimuth?.toStringAsFixed(0)}°'),
          _buildApplicationTile(colors, LucideIcons.thermometer, 'Heat Load Timing',
              'Peak sun intensity around ${_solarNoon != null ? _formatDateTime(_solarNoon!) : 'noon'}'),
          _buildApplicationTile(colors, LucideIcons.camera, 'Photo Documentation',
              _sunAltitude != null && _sunAltitude! > 15 ? 'Good lighting conditions' : 'Low angle - use fill flash'),
        ],
      ),
    );
  }

  Widget _buildApplicationTile(ZaftoColors colors, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                Text(value, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _selectDate(ZaftoColors colors) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.accentPrimary,
            surface: colors.bgElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _calculateSunPosition();
    }
  }

  Future<void> _selectTime(ZaftoColors colors) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.accentPrimary,
            surface: colors.bgElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      _calculateSunPosition();
    }
  }

  void _showUsageGuide(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to Use', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 16),
            _buildGuideItem(colors, LucideIcons.panelTop, 'Solar Installation',
                'Use altitude angle to determine optimal panel tilt. Azimuth shows which direction to face panels.'),
            _buildGuideItem(colors, LucideIcons.square, 'Skylight Planning',
                'Track sun path throughout the day to position skylights for maximum natural light.'),
            _buildGuideItem(colors, LucideIcons.thermometer, 'HVAC Load Calculation',
                'Know when peak solar heat gain occurs to size cooling equipment properly.'),
            _buildGuideItem(colors, LucideIcons.camera, 'Photo Documentation',
                'Altitude above 15° provides good lighting. Early morning/late afternoon creates harsh shadows.'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(ZaftoColors colors, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.accentPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 12, color: colors.textTertiary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getCompassDirection(double azimuth) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((azimuth + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}

// ============================================================
// SUN CALCULATOR
// ============================================================

class _SunCalculator {
  static _SunPosition calculatePosition(double latitude, double longitude, DateTime dateTime) {
    // Convert to radians
    final latRad = latitude * math.pi / 180;

    // Day of year
    final dayOfYear = dateTime.difference(DateTime(dateTime.year, 1, 1)).inDays + 1;

    // Fractional year (radians)
    final gamma = 2 * math.pi / 365 * (dayOfYear - 1 + (dateTime.hour - 12) / 24);

    // Equation of time (minutes)
    final eqTime = 229.18 * (0.000075 + 0.001868 * math.cos(gamma) - 0.032077 * math.sin(gamma) - 0.014615 * math.cos(2 * gamma) - 0.040849 * math.sin(2 * gamma));

    // Solar declination (radians)
    final decl = 0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma) - 0.006758 * math.cos(2 * gamma) + 0.000907 * math.sin(2 * gamma) - 0.002697 * math.cos(3 * gamma) + 0.00148 * math.sin(3 * gamma);

    // Time offset (minutes)
    final timeOffset = eqTime + 4 * longitude - 60 * dateTime.timeZoneOffset.inHours;

    // True solar time (minutes)
    final tst = dateTime.hour * 60 + dateTime.minute + dateTime.second / 60 + timeOffset;

    // Hour angle (degrees)
    final ha = (tst / 4) - 180;
    final haRad = ha * math.pi / 180;

    // Solar zenith angle
    final cosZenith = math.sin(latRad) * math.sin(decl) + math.cos(latRad) * math.cos(decl) * math.cos(haRad);
    final zenith = math.acos(cosZenith.clamp(-1.0, 1.0));
    final altitude = 90 - (zenith * 180 / math.pi);

    // Solar azimuth angle
    final cosAzimuth = (math.sin(latRad) * math.cos(zenith) - math.sin(decl)) / (math.cos(latRad) * math.sin(zenith));
    var azimuth = math.acos(cosAzimuth.clamp(-1.0, 1.0)) * 180 / math.pi;
    if (ha > 0) azimuth = 360 - azimuth;

    return _SunPosition(altitude: altitude, azimuth: azimuth);
  }

  static _SunTimes calculateTimes(double latitude, double longitude, DateTime date) {
    final latRad = latitude * math.pi / 180;
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final gamma = 2 * math.pi / 365 * (dayOfYear - 1);

    // Equation of time
    final eqTime = 229.18 * (0.000075 + 0.001868 * math.cos(gamma) - 0.032077 * math.sin(gamma) - 0.014615 * math.cos(2 * gamma) - 0.040849 * math.sin(2 * gamma));

    // Solar declination
    final decl = 0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma) - 0.006758 * math.cos(2 * gamma) + 0.000907 * math.sin(2 * gamma) - 0.002697 * math.cos(3 * gamma) + 0.00148 * math.sin(3 * gamma);

    // Hour angle at sunrise/sunset
    final cosHa = -math.tan(latRad) * math.tan(decl);

    if (cosHa.abs() > 1) {
      // No sunrise or sunset (polar day/night)
      return _SunTimes(sunrise: null, sunset: null, solarNoon: null);
    }

    final ha = math.acos(cosHa) * 180 / math.pi;

    // Solar noon (minutes from midnight UTC)
    final solarNoonMinutes = 720 - 4 * longitude - eqTime;

    // Sunrise and sunset (minutes from midnight)
    final sunriseMinutes = solarNoonMinutes - ha * 4;
    final sunsetMinutes = solarNoonMinutes + ha * 4;

    // Adjust for timezone
    final tzOffset = date.timeZoneOffset.inMinutes;

    DateTime minutesToDateTime(double minutes) {
      final adjustedMinutes = (minutes + tzOffset).round();
      final hours = (adjustedMinutes ~/ 60) % 24;
      final mins = adjustedMinutes % 60;
      return DateTime(date.year, date.month, date.day, hours, mins);
    }

    return _SunTimes(
      sunrise: minutesToDateTime(sunriseMinutes),
      sunset: minutesToDateTime(sunsetMinutes),
      solarNoon: minutesToDateTime(solarNoonMinutes),
    );
  }
}

class _SunPosition {
  final double altitude;
  final double azimuth;

  const _SunPosition({required this.altitude, required this.azimuth});
}

class _SunTimes {
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? solarNoon;

  const _SunTimes({this.sunrise, this.sunset, this.solarNoon});
}

// ============================================================
// SUN PATH PAINTER
// ============================================================

class _SunPathPainter extends CustomPainter {
  final double altitude;
  final double azimuth;
  final ZaftoColors colors;

  _SunPathPainter({required this.altitude, required this.azimuth, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.85;
    final radius = size.width * 0.4;

    // Draw horizon line
    final horizonPaint = Paint()
      ..color = colors.textTertiary.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      horizonPaint,
    );

    // Draw arc path
    final arcPaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final arcRect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);
    canvas.drawArc(arcRect, math.pi, math.pi, false, arcPaint);

    // Draw cardinal directions
    final textStyle = TextStyle(color: colors.textTertiary, fontSize: 12);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, Offset position) {
      textPainter.text = TextSpan(text: text, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, position - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    drawLabel('E', Offset(20, centerY - 10));
    drawLabel('S', Offset(centerX, centerY - radius - 15));
    drawLabel('W', Offset(size.width - 20, centerY - 10));

    // Draw sun position
    if (altitude > 0) {
      // Convert altitude and azimuth to position on arc
      // Azimuth: 90=E, 180=S, 270=W
      final normalizedAzimuth = (azimuth - 90) / 180; // 0 to 1 across the arc
      final angle = math.pi * (1 - normalizedAzimuth);
      final altitudeRatio = altitude / 90;

      final sunX = centerX + radius * math.cos(angle);
      final sunY = centerY - radius * altitudeRatio * math.sin(angle);

      // Sun glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.orange.withOpacity(0.4), Colors.orange.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 30));
      canvas.drawCircle(Offset(sunX, sunY), 30, glowPaint);

      // Sun
      final sunPaint = Paint()..color = Colors.orange;
      canvas.drawCircle(Offset(sunX, sunY), 12, sunPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
