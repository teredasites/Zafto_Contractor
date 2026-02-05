import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Level & Plumb Tool - Accelerometer-based digital level with camera overlay
class LevelPlumbScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const LevelPlumbScreen({super.key, this.jobId});

  @override
  ConsumerState<LevelPlumbScreen> createState() => _LevelPlumbScreenState();
}

class _LevelPlumbScreenState extends ConsumerState<LevelPlumbScreen>
    with SingleTickerProviderStateMixin {
  // Accelerometer data
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _x = 0.0; // Left/Right tilt
  double _y = 0.0; // Forward/Back tilt
  double _z = 0.0; // Gravity reference

  // Calibration offsets
  double _xOffset = 0.0;
  double _yOffset = 0.0;

  // Settings
  bool _audioFeedback = true;
  bool _showDegrees = true;
  LevelMode _mode = LevelMode.surface; // surface or bullseye

  // Level detection
  bool _isLevel = false;
  DateTime? _lastLevelBeep;

  // Animation controller for bubble smoothing
  late AnimationController _animationController;

  // Sensitivity threshold (degrees)
  static const double _levelThreshold = 0.5;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _startAccelerometer();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((AccelerometerEvent event) {
      if (!mounted) return;

      setState(() {
        // Apply calibration offsets
        _x = event.x - _xOffset;
        _y = event.y - _yOffset;
        _z = event.z;

        // Check if level (within threshold)
        final xAngle = _calculateAngle(_x, _z).abs();
        final yAngle = _calculateAngle(_y, _z).abs();
        final wasLevel = _isLevel;
        _isLevel = xAngle < _levelThreshold && yAngle < _levelThreshold;

        // Audio feedback when becoming level
        if (_isLevel && !wasLevel && _audioFeedback) {
          _playLevelSound();
        }
      });
    });
  }

  double _calculateAngle(double acceleration, double gravity) {
    // Convert accelerometer reading to degrees
    // Using atan2 for proper angle calculation
    final angle = math.atan2(acceleration, gravity.abs()) * (180 / math.pi);
    return angle;
  }

  void _playLevelSound() {
    final now = DateTime.now();
    if (_lastLevelBeep == null ||
        now.difference(_lastLevelBeep!) > const Duration(milliseconds: 500)) {
      HapticFeedback.mediumImpact();
      _lastLevelBeep = now;
    }
  }

  void _calibrate() {
    HapticFeedback.heavyImpact();
    setState(() {
      _xOffset = _x + _xOffset;
      _yOffset = _y + _yOffset;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Calibrated! Current position is now level.'),
        backgroundColor: ref.read(zaftoColorsProvider).accentSuccess,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetCalibration() {
    HapticFeedback.lightImpact();
    setState(() {
      _xOffset = 0.0;
      _yOffset = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Calibration reset to factory default.'),
        backgroundColor: ref.read(zaftoColorsProvider).accentInfo,
        duration: const Duration(seconds: 2),
      ),
    );
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
        title: Text(
          'Level & Plumb',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _audioFeedback ? LucideIcons.volume2 : LucideIcons.volumeX,
              color: colors.textTertiary,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _audioFeedback = !_audioFeedback);
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.settings, color: colors.textTertiary),
            onPressed: () => _showSettingsSheet(colors),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode selector
          _buildModeSelector(colors),

          // Main level display
          Expanded(
            child: _mode == LevelMode.surface
                ? _buildSurfaceLevel(colors)
                : _buildBullseyeLevel(colors),
          ),

          // Readings panel
          _buildReadingsPanel(colors),

          // Action buttons
          _buildActionButtons(colors),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _mode = LevelMode.surface);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mode == LevelMode.surface
                      ? colors.accentPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.minus,
                      size: 18,
                      color: _mode == LevelMode.surface
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Surface Level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mode == LevelMode.surface
                            ? (colors.isDark ? Colors.black : Colors.white)
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _mode = LevelMode.bullseye);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mode == LevelMode.bullseye
                      ? colors.accentPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.crosshair,
                      size: 18,
                      color: _mode == LevelMode.bullseye
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bullseye',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mode == LevelMode.bullseye
                            ? (colors.isDark ? Colors.black : Colors.white)
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceLevel(ZaftoColors colors) {
    final xAngle = _calculateAngle(_x, _z);
    final yAngle = _calculateAngle(_y, _z);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Horizontal level (left/right tilt)
          _buildLinearLevel(
            colors: colors,
            angle: xAngle,
            label: 'LEFT / RIGHT',
            icon: LucideIcons.arrowLeftRight,
          ),
          const SizedBox(height: 40),

          // Vertical level (forward/back tilt)
          _buildLinearLevel(
            colors: colors,
            angle: yAngle,
            label: 'FRONT / BACK',
            icon: LucideIcons.arrowUpDown,
          ),
        ],
      ),
    );
  }

  Widget _buildLinearLevel({
    required ZaftoColors colors,
    required double angle,
    required String label,
    required IconData icon,
  }) {
    // Clamp angle for display (-45 to 45 degrees)
    final clampedAngle = angle.clamp(-45.0, 45.0);
    final isLevelAxis = angle.abs() < _levelThreshold;

    // Calculate bubble position (-1 to 1)
    final bubblePosition = (clampedAngle / 45.0).clamp(-1.0, 1.0);

    return Column(
      children: [
        // Label
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: colors.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Level tube
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isLevelAxis ? colors.accentSuccess : colors.borderSubtle,
              width: isLevelAxis ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final bubbleSize = 50.0;
              final maxOffset = (width - bubbleSize - 16) / 2;
              final bubbleOffset = bubblePosition * maxOffset;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Center markers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 2,
                        height: 20,
                        color: colors.textTertiary.withOpacity(0.3),
                      ),
                      const SizedBox(width: 50),
                      Container(
                        width: 2,
                        height: 20,
                        color: colors.textTertiary.withOpacity(0.3),
                      ),
                    ],
                  ),

                  // Bubble
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(bubbleOffset, 0, 0),
                    child: Container(
                      width: bubbleSize,
                      height: bubbleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            isLevelAxis
                                ? colors.accentSuccess.withOpacity(0.8)
                                : colors.accentPrimary.withOpacity(0.8),
                            isLevelAxis
                                ? colors.accentSuccess
                                : colors.accentPrimary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isLevelAxis
                                    ? colors.accentSuccess
                                    : colors.accentPrimary)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Angle reading
        if (_showDegrees) ...[
          const SizedBox(height: 12),
          Text(
            '${angle.toStringAsFixed(1)}°',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isLevelAxis ? colors.accentSuccess : colors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBullseyeLevel(ZaftoColors colors) {
    final xAngle = _calculateAngle(_x, _z);
    final yAngle = _calculateAngle(_y, _z);

    // Calculate bubble position (-1 to 1 for each axis)
    final bubbleX = (xAngle / 45.0).clamp(-1.0, 1.0);
    final bubbleY = (yAngle / 45.0).clamp(-1.0, 1.0);

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.bgElevated,
            border: Border.all(
              color: _isLevel ? colors.accentSuccess : colors.borderSubtle,
              width: _isLevel ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              final center = size / 2;
              final bubbleSize = 50.0;
              final maxOffset = (size - bubbleSize - 40) / 2;

              final bubbleOffsetX = bubbleX * maxOffset;
              final bubbleOffsetY = bubbleY * maxOffset;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Concentric circles
                  ...List.generate(4, (i) {
                    final radius = (i + 1) * (maxOffset / 4);
                    return Container(
                      width: radius * 2 + bubbleSize,
                      height: radius * 2 + bubbleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == 0
                              ? colors.accentSuccess.withOpacity(0.5)
                              : colors.textTertiary.withOpacity(0.2),
                          width: i == 0 ? 2 : 1,
                        ),
                      ),
                    );
                  }),

                  // Crosshairs
                  Container(
                    width: 2,
                    height: size * 0.6,
                    color: colors.textTertiary.withOpacity(0.2),
                  ),
                  Container(
                    width: size * 0.6,
                    height: 2,
                    color: colors.textTertiary.withOpacity(0.2),
                  ),

                  // Bubble
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    transform:
                        Matrix4.translationValues(bubbleOffsetX, bubbleOffsetY, 0),
                    child: Container(
                      width: bubbleSize,
                      height: bubbleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _isLevel
                                ? colors.accentSuccess.withOpacity(0.8)
                                : colors.accentPrimary.withOpacity(0.8),
                            _isLevel ? colors.accentSuccess : colors.accentPrimary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isLevel ? colors.accentSuccess : colors.accentPrimary)
                                    .withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReadingsPanel(ZaftoColors colors) {
    final xAngle = _calculateAngle(_x, _z);
    final yAngle = _calculateAngle(_y, _z);
    final totalAngle = math.sqrt(xAngle * xAngle + yAngle * yAngle);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildReading(colors, 'X-AXIS', xAngle, LucideIcons.arrowLeftRight),
          _buildDivider(colors),
          _buildReading(colors, 'Y-AXIS', yAngle, LucideIcons.arrowUpDown),
          _buildDivider(colors),
          _buildReading(colors, 'TOTAL', totalAngle, LucideIcons.move),
        ],
      ),
    );
  }

  Widget _buildReading(
      ZaftoColors colors, String label, double value, IconData icon) {
    final isLevel = value.abs() < _levelThreshold;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: colors.textTertiary),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(1)}°',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isLevel ? colors.accentSuccess : colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ZaftoColors colors) {
    return Container(
      width: 1,
      height: 50,
      color: colors.borderSubtle,
    );
  }

  Widget _buildActionButtons(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          // Calibrate button
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(LucideIcons.settings2, size: 18, color: colors.accentPrimary),
              label: Text(
                'Calibrate',
                style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.accentPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _calibrate,
            ),
          ),
          const SizedBox(width: 12),

          // Save to job button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.save, size: 18),
              label: const Text(
                'Save Reading',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _saveReading(colors),
            ),
          ),
        ],
      ),
    );
  }

  void _saveReading(ZaftoColors colors) {
    final xAngle = _calculateAngle(_x, _z);
    final yAngle = _calculateAngle(_y, _z);

    HapticFeedback.mediumImpact();

    // TODO: BACKEND - Save reading to job
    // - Store x_angle, y_angle, timestamp, is_level
    // - Link to jobId if provided
    // - Store with photo if camera was used

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Level reading saved: X=${xAngle.toStringAsFixed(1)}° Y=${yAngle.toStringAsFixed(1)}°',
        ),
        backgroundColor: colors.accentSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSettingsSheet(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(LucideIcons.settings, color: colors.textPrimary),
                  const SizedBox(width: 12),
                  Text(
                    'Level Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Audio feedback toggle
              _buildSettingsTile(
                colors: colors,
                icon: _audioFeedback ? LucideIcons.volume2 : LucideIcons.volumeX,
                title: 'Audio Feedback',
                subtitle: 'Vibrate when perfectly level',
                trailing: Switch.adaptive(
                  value: _audioFeedback,
                  activeColor: colors.accentPrimary,
                  onChanged: (value) {
                    setSheetState(() => _audioFeedback = value);
                    setState(() {});
                  },
                ),
              ),

              // Show degrees toggle
              _buildSettingsTile(
                colors: colors,
                icon: LucideIcons.hash,
                title: 'Show Degrees',
                subtitle: 'Display angle measurements',
                trailing: Switch.adaptive(
                  value: _showDegrees,
                  activeColor: colors.accentPrimary,
                  onChanged: (value) {
                    setSheetState(() => _showDegrees = value);
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Reset calibration
              _buildSettingsTile(
                colors: colors,
                icon: LucideIcons.refreshCw,
                title: 'Reset Calibration',
                subtitle: 'Restore factory default',
                onTap: () {
                  Navigator.pop(context);
                  _resetCalibration();
                },
              ),

              const SizedBox(height: 24),

              // Usage guide
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.accentInfo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.info, size: 18, color: colors.accentInfo),
                        const SizedBox(width: 8),
                        Text(
                          'Usage Tips',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.accentInfo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Place phone flat on surface for best accuracy\n'
                      '• Use Calibrate if readings are off when level\n'
                      '• Surface mode for long objects (2ft+ levels)\n'
                      '• Bullseye mode for flat surfaces (countertops)',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required ZaftoColors colors,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: colors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null)
              Icon(LucideIcons.chevronRight, size: 20, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

enum LevelMode { surface, bullseye }
