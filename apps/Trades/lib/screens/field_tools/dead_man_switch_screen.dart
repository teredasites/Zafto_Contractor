import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Dead Man Switch - Lone worker safety timer with emergency alert
class DeadManSwitchScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const DeadManSwitchScreen({super.key, this.jobId});

  @override
  ConsumerState<DeadManSwitchScreen> createState() => _DeadManSwitchScreenState();
}

class _DeadManSwitchScreenState extends ConsumerState<DeadManSwitchScreen> with TickerProviderStateMixin {
  // Timer state
  _SwitchState _state = _SwitchState.inactive;
  Duration _checkInInterval = const Duration(minutes: 15);
  Duration _graceGracePeriod = const Duration(seconds: 30);
  Duration _remainingTime = Duration.zero;
  Timer? _mainTimer;
  Timer? _graceTimer;
  Timer? _tickTimer;

  // Emergency contacts
  final List<_EmergencyContact> _contacts = [];
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isAddingContact = false;

  // Location
  String? _currentAddress;
  double? _latitude;
  double? _longitude;

  // Activity log
  final List<_ActivityLog> _activityLog = [];

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingTime = _checkInInterval;
    _fetchLocation();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _mainTimer?.cancel();
    _graceTimer?.cancel();
    _tickTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final cameraService = ref.read(fieldCameraServiceProvider);
    final location = await cameraService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentAddress = location.address;
        _latitude = location.latitude;
        _longitude = location.longitude;
      });
    }
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
          onPressed: () => _confirmExit(colors),
        ),
        title: Text('Dead Man Switch', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.settings, color: colors.textTertiary),
            onPressed: () => _showSettings(colors),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning/Info Banner
          _buildInfoBanner(colors),
          const SizedBox(height: 20),

          // Main Timer Display
          _buildTimerDisplay(colors),
          const SizedBox(height: 24),

          // Control Buttons
          _buildControlButtons(colors),
          const SizedBox(height: 24),

          // Emergency Contacts
          _buildEmergencyContacts(colors),
          const SizedBox(height: 24),

          // Activity Log
          _buildActivityLog(colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(ZaftoColors colors) {
    Color bannerColor;
    IconData bannerIcon;
    String bannerTitle;
    String bannerText;

    switch (_state) {
      case _SwitchState.inactive:
        bannerColor = colors.accentInfo;
        bannerIcon = LucideIcons.info;
        bannerTitle = 'Lone Worker Protection';
        bannerText = 'Set a check-in timer. If you don\'t respond, emergency contacts will be alerted with your location.';
        break;
      case _SwitchState.active:
        bannerColor = colors.accentSuccess;
        bannerIcon = LucideIcons.shield;
        bannerTitle = 'Timer Active';
        bannerText = 'You\'ll be prompted to check in when the timer expires. Keep your phone nearby.';
        break;
      case _SwitchState.warning:
        bannerColor = colors.accentWarning;
        bannerIcon = LucideIcons.alertTriangle;
        bannerTitle = 'Check-In Required!';
        bannerText = 'Tap the button below to confirm you\'re OK. Emergency alert in ${_remainingTime.inSeconds}s.';
        break;
      case _SwitchState.alerting:
        bannerColor = colors.accentError;
        bannerIcon = LucideIcons.alertOctagon;
        bannerTitle = 'EMERGENCY ALERT SENT';
        bannerText = 'Your emergency contacts have been notified with your last known location.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(bannerIcon, color: bannerColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bannerTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: bannerColor)),
                const SizedBox(height: 4),
                Text(bannerText, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(ZaftoColors colors) {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds.remainder(60);
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Color timerColor;
    switch (_state) {
      case _SwitchState.inactive:
        timerColor = colors.textTertiary;
        break;
      case _SwitchState.active:
        timerColor = colors.accentSuccess;
        break;
      case _SwitchState.warning:
        timerColor = colors.accentWarning;
        break;
      case _SwitchState.alerting:
        timerColor = colors.accentError;
        break;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _state == _SwitchState.warning ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: timerColor.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: timerColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _state == _SwitchState.inactive ? colors.textTertiary : timerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _state.label.toUpperCase(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: timerColor, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Timer
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    color: timerColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _state == _SwitchState.inactive ? 'Check-in interval' : 'Until next check-in',
                  style: TextStyle(fontSize: 14, color: colors.textTertiary),
                ),

                // Location info
                if (_currentAddress != null && _state != _SwitchState.inactive) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: colors.textTertiary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _currentAddress!,
                          style: TextStyle(fontSize: 12, color: colors.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButtons(ZaftoColors colors) {
    switch (_state) {
      case _SwitchState.inactive:
        return Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.play, size: 24),
              label: const Text('Start Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSuccess,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _contacts.isEmpty ? null : _startTimer,
            ),
            if (_contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Add at least one emergency contact to start',
                  style: TextStyle(fontSize: 12, color: colors.accentWarning),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );

      case _SwitchState.active:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(LucideIcons.stopCircle, color: colors.accentError),
                label: Text('Stop', style: TextStyle(color: colors.accentError, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.accentError),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _stopTimer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(LucideIcons.checkCircle, size: 22),
                label: const Text('Check In Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _checkIn,
              ),
            ),
          ],
        );

      case _SwitchState.warning:
        return ElevatedButton.icon(
          icon: const Icon(LucideIcons.checkCircle, size: 28),
          label: const Text('I\'M OK - CHECK IN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accentSuccess,
            foregroundColor: colors.isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _checkIn,
        );

      case _SwitchState.alerting:
        return Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.checkCircle, size: 24),
              label: const Text('I\'M OK - Cancel Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSuccess,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _cancelAlert,
            ),
            const SizedBox(height: 12),
            Text(
              'Emergency contacts have been notified',
              style: TextStyle(fontSize: 12, color: colors.accentError),
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }

  Widget _buildEmergencyContacts(ZaftoColors colors) {
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
              Icon(LucideIcons.userCircle, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'EMERGENCY CONTACTS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
              ),
              const Spacer(),
              Text(
                '${_contacts.length}/3',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contact list
          ..._contacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.accentPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                        Text(contact.phone, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                      ],
                    ),
                  ),
                  if (_state == _SwitchState.inactive)
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 18, color: colors.textTertiary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _contacts.removeAt(index));
                      },
                    ),
                ],
              ),
            );
          }),

          // Add contact
          if (_contacts.length < 3 && _state == _SwitchState.inactive)
            if (_isAddingContact)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: TextStyle(color: colors.textTertiary),
                            filled: true,
                            fillColor: colors.fillDefault,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Phone',
                            hintStyle: TextStyle(color: colors.textTertiary),
                            filled: true,
                            fillColor: colors.fillDefault,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
                        onPressed: () => setState(() {
                          _isAddingContact = false;
                          _nameController.clear();
                          _phoneController.clear();
                        }),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accentPrimary,
                          foregroundColor: colors.isDark ? Colors.black : Colors.white,
                        ),
                        onPressed: _addContact,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () => setState(() => _isAddingContact = true),
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderSubtle, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.userPlus, size: 18, color: colors.accentPrimary),
                      const SizedBox(width: 8),
                      Text('Add Emergency Contact', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.accentPrimary)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildActivityLog(ZaftoColors colors) {
    if (_activityLog.isEmpty) return const SizedBox.shrink();

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
              Icon(LucideIcons.history, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'ACTIVITY LOG',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._activityLog.reversed.take(5).map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(log.icon, size: 14, color: log.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(log.message, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    ),
                    Text(
                      _formatTime(log.timestamp),
                      style: TextStyle(fontSize: 11, color: colors.textTertiary),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _addContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isNotEmpty && phone.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _contacts.add(_EmergencyContact(name: name, phone: phone));
        _nameController.clear();
        _phoneController.clear();
        _isAddingContact = false;
      });
    }
  }

  void _startTimer() {
    if (_contacts.isEmpty) return;

    HapticFeedback.heavyImpact();
    _logActivity('Timer started', LucideIcons.play, Colors.green);
    _fetchLocation(); // Refresh location

    setState(() {
      _state = _SwitchState.active;
      _remainingTime = _checkInInterval;
    });

    _startTickTimer();
    _mainTimer = Timer(_checkInInterval, _onTimerExpired);
  }

  void _stopTimer() {
    HapticFeedback.mediumImpact();
    _logActivity('Timer stopped', LucideIcons.stopCircle, Colors.orange);

    _mainTimer?.cancel();
    _graceTimer?.cancel();
    _tickTimer?.cancel();
    _pulseController.stop();

    setState(() {
      _state = _SwitchState.inactive;
      _remainingTime = _checkInInterval;
    });
  }

  void _checkIn() {
    HapticFeedback.heavyImpact();
    _logActivity('Checked in', LucideIcons.checkCircle, Colors.green);
    _fetchLocation(); // Refresh location

    _mainTimer?.cancel();
    _graceTimer?.cancel();
    _pulseController.stop();

    setState(() {
      _state = _SwitchState.active;
      _remainingTime = _checkInInterval;
    });

    _mainTimer = Timer(_checkInInterval, _onTimerExpired);
  }

  void _onTimerExpired() {
    HapticFeedback.heavyImpact();
    _logActivity('Check-in required', LucideIcons.alertTriangle, Colors.orange);

    setState(() {
      _state = _SwitchState.warning;
      _remainingTime = _graceGracePeriod;
    });

    _pulseController.repeat(reverse: true);

    _graceTimer = Timer(_graceGracePeriod, _triggerAlert);
  }

  void _triggerAlert() {
    HapticFeedback.heavyImpact();
    _logActivity('EMERGENCY ALERT SENT', LucideIcons.alertOctagon, Colors.red);
    _pulseController.stop();

    setState(() {
      _state = _SwitchState.alerting;
    });

    // TODO: BACKEND - Send emergency alert
    // - SMS to all emergency contacts
    // - Include last known GPS coordinates
    // - Include job site info if available
    // - Push notification to contacts' apps
    // - Log incident for compliance
  }

  void _cancelAlert() {
    HapticFeedback.heavyImpact();
    _logActivity('Alert cancelled - user OK', LucideIcons.checkCircle, Colors.green);

    // TODO: BACKEND - Send "I'm OK" message to contacts

    setState(() {
      _state = _SwitchState.active;
      _remainingTime = _checkInInterval;
    });

    _mainTimer = Timer(_checkInInterval, _onTimerExpired);
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() => _remainingTime -= const Duration(seconds: 1));
      }
    });
  }

  void _logActivity(String message, IconData icon, Color color) {
    setState(() {
      _activityLog.add(_ActivityLog(
        message: message,
        timestamp: DateTime.now(),
        icon: icon,
        color: color,
      ));
    });
  }

  void _showSettings(ZaftoColors colors) {
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
            Text('Timer Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 20),
            Text('Check-in Interval', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 30, 60].map((minutes) {
                final isSelected = _checkInInterval.inMinutes == minutes;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _checkInInterval = Duration(minutes: minutes);
                      if (_state == _SwitchState.inactive) {
                        _remainingTime = _checkInInterval;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.accentPrimary : colors.fillDefault,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$minutes min',
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Grace Period', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [15, 30, 60].map((seconds) {
                final isSelected = _graceGracePeriod.inSeconds == seconds;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _graceGracePeriod = Duration(seconds: seconds));
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.accentPrimary : colors.fillDefault,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$seconds sec',
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmExit(ZaftoColors colors) {
    if (_state == _SwitchState.inactive) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Stop Timer?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'The dead man switch is active. Exiting will stop the timer.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Stop & Exit', style: TextStyle(color: colors.accentError)),
            onPressed: () {
              _stopTimer();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ============================================================
// ENUMS & DATA CLASSES
// ============================================================

enum _SwitchState {
  inactive('Inactive'),
  active('Active'),
  warning('Warning'),
  alerting('Alerting');

  final String label;
  const _SwitchState(this.label);
}

class _EmergencyContact {
  final String name;
  final String phone;

  const _EmergencyContact({required this.name, required this.phone});
}

class _ActivityLog {
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  const _ActivityLog({
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
