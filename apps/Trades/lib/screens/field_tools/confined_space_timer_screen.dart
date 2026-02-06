import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';
import '../../services/compliance_service.dart';
import '../../models/compliance_record.dart';

/// Confined Space Timer - OSHA-compliant entry tracking with air monitoring reminders
class ConfinedSpaceTimerScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const ConfinedSpaceTimerScreen({super.key, this.jobId});

  @override
  ConsumerState<ConfinedSpaceTimerScreen> createState() => _ConfinedSpaceTimerScreenState();
}

class _ConfinedSpaceTimerScreenState extends ConsumerState<ConfinedSpaceTimerScreen> {
  // Entry state
  _EntryState _state = _EntryState.preEntry;
  DateTime? _entryTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _elapsedTimer;

  // Air monitoring
  Duration _airMonitorInterval = const Duration(minutes: 15);
  Duration _timeSinceLastMonitor = Duration.zero;
  Timer? _airMonitorTimer;
  final List<_AirReading> _airReadings = [];

  // Entry checklist
  final Map<_ChecklistItem, bool> _checklist = {
    for (var item in _ChecklistItem.values) item: false
  };

  // Personnel tracking
  final List<_Entrant> _entrants = [];
  final _entrantNameController = TextEditingController();
  String? _attendantName;
  String? _supervisorName;

  // Permit info
  final _permitController = TextEditingController();
  final _spaceDescriptionController = TextEditingController();
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _airMonitorTimer?.cancel();
    _entrantNameController.dispose();
    _permitController.dispose();
    _spaceDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final cameraService = ref.read(fieldCameraServiceProvider);
    final location = await cameraService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentAddress = location.address);
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
        title: Text('Confined Space', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (_state == _EntryState.active || _state == _EntryState.exited)
            IconButton(
              icon: Icon(LucideIcons.fileText, color: colors.accentPrimary),
              onPressed: () => _generateReport(colors),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // OSHA Compliance Banner
          _buildComplianceBanner(colors),
          const SizedBox(height: 20),

          // Status Card
          _buildStatusCard(colors),
          const SizedBox(height: 20),

          // Phase-specific content
          if (_state == _EntryState.preEntry) ...[
            _buildPreEntryChecklist(colors),
            const SizedBox(height: 20),
            _buildPermitInfo(colors),
            const SizedBox(height: 20),
            _buildPersonnelSetup(colors),
          ] else if (_state == _EntryState.active) ...[
            _buildActiveEntry(colors),
            const SizedBox(height: 20),
            _buildAirMonitoring(colors),
            const SizedBox(height: 20),
            _buildEntrantsList(colors),
          ] else if (_state == _EntryState.exited) ...[
            _buildExitSummary(colors),
          ],

          const SizedBox(height: 32),

          // Main Action Button
          _buildMainActionButton(colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildComplianceBanner(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OSHA 1910.146', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.accentWarning)),
                const SizedBox(height: 4),
                Text(
                  'Permit-Required Confined Space Entry. All entries must be documented with atmospheric monitoring.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ZaftoColors colors) {
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    switch (_state) {
      case _EntryState.preEntry:
        statusColor = colors.accentInfo;
        statusIcon = LucideIcons.clipboard;
        statusTitle = 'Pre-Entry Setup';
        statusSubtitle = 'Complete checklist before entry';
        break;
      case _EntryState.active:
        statusColor = colors.accentWarning;
        statusIcon = LucideIcons.alertCircle;
        statusTitle = 'ENTRY ACTIVE';
        statusSubtitle = '${_entrants.where((e) => e.isInside).length} personnel inside';
        break;
      case _EntryState.exited:
        statusColor = colors.accentSuccess;
        statusIcon = LucideIcons.checkCircle;
        statusTitle = 'Entry Complete';
        statusSubtitle = 'All personnel exited safely';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 48, color: statusColor),
          const SizedBox(height: 12),
          Text(statusTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: statusColor)),
          const SizedBox(height: 4),
          Text(statusSubtitle, style: TextStyle(fontSize: 14, color: colors.textSecondary)),

          if (_state == _EntryState.active) ...[
            const SizedBox(height: 20),
            // Elapsed time
            Text(
              _formatDuration(_elapsedTime),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w200,
                color: statusColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text('Time in space', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
          ],

          if (_currentAddress != null) ...[
            const SizedBox(height: 16),
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
    );
  }

  Widget _buildPreEntryChecklist(ZaftoColors colors) {
    final completedCount = _checklist.values.where((v) => v).length;
    final totalCount = _checklist.length;

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
              Icon(LucideIcons.clipboardCheck, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'PRE-ENTRY CHECKLIST',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: completedCount == totalCount ? colors.accentSuccess.withOpacity(0.2) : colors.fillDefault,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: completedCount == totalCount ? colors.accentSuccess : colors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._ChecklistItem.values.map((item) => _buildChecklistItem(colors, item)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ZaftoColors colors, _ChecklistItem item) {
    final isChecked = _checklist[item] ?? false;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _checklist[item] = !isChecked);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isChecked ? colors.accentSuccess.withOpacity(0.1) : colors.fillDefault,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isChecked ? colors.accentSuccess : colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? colors.accentSuccess : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isChecked ? colors.accentSuccess : colors.borderDefault, width: 2),
              ),
              child: isChecked ? Icon(LucideIcons.check, size: 16, color: colors.isDark ? Colors.black : Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Icon(item.icon, size: 18, color: isChecked ? colors.accentSuccess : colors.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  color: isChecked ? colors.textPrimary : colors.textSecondary,
                  fontWeight: isChecked ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermitInfo(ZaftoColors colors) {
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
              Icon(LucideIcons.fileText, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'PERMIT INFORMATION',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(colors, 'Permit Number', _permitController, LucideIcons.hash),
          const SizedBox(height: 12),
          _buildTextField(colors, 'Space Description', _spaceDescriptionController, LucideIcons.box, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildPersonnelSetup(ZaftoColors colors) {
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
              Icon(LucideIcons.users, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'PERSONNEL',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Attendant
          _buildRoleField(colors, 'Attendant (required)', _attendantName, LucideIcons.eye, (name) => setState(() => _attendantName = name)),
          const SizedBox(height: 12),
          // Supervisor
          _buildRoleField(colors, 'Entry Supervisor', _supervisorName, LucideIcons.userCog, (name) => setState(() => _supervisorName = name)),
          const SizedBox(height: 16),
          // Entrants
          Text('Authorized Entrants', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
          const SizedBox(height: 8),
          ..._entrants.asMap().entries.map((entry) => _buildEntrantChip(colors, entry.key, entry.value)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _entrantNameController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add entrant name...',
                    hintStyle: TextStyle(color: colors.textTertiary),
                    filled: true,
                    fillColor: colors.fillDefault,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onFieldSubmitted: (_) => _addEntrant(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(LucideIcons.plus, color: colors.accentPrimary),
                onPressed: _addEntrant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleField(ZaftoColors colors, String label, String? value, IconData icon, Function(String) onSet) {
    return GestureDetector(
      onTap: () => _showNameDialog(colors, label, value, onSet),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.fillDefault,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value != null ? colors.accentSuccess : colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: value != null ? colors.accentSuccess : colors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Tap to assign',
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null ? colors.textPrimary : colors.textTertiary,
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null) Icon(LucideIcons.checkCircle, size: 18, color: colors.accentSuccess),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrantChip(ZaftoColors colors, int index, _Entrant entrant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.user, size: 14, color: colors.textTertiary),
          const SizedBox(width: 8),
          Text(entrant.name, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _entrants.removeAt(index));
            },
            child: Icon(LucideIcons.x, size: 14, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEntry(ZaftoColors colors) {
    final insideCount = _entrants.where((e) => e.isInside).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accentWarning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.users, size: 20, color: colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personnel Inside', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    Text('$insideCount of ${_entrants.length} entrants', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Entry/Exit tracking
          ..._entrants.asMap().entries.map((entry) => _buildEntrantStatus(colors, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildEntrantStatus(ZaftoColors colors, int index, _Entrant entrant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entrant.isInside ? colors.accentWarning.withOpacity(0.1) : colors.accentSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: entrant.isInside ? colors.accentWarning : colors.accentSuccess),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entrant.isInside ? colors.accentWarning : colors.accentSuccess,
              shape: BoxShape.circle,
            ),
            child: Icon(
              entrant.isInside ? LucideIcons.moveDown : LucideIcons.moveUp,
              size: 18,
              color: colors.isDark ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entrant.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                Text(
                  entrant.isInside
                      ? 'Entered ${_formatTime(entrant.entryTime!)}'
                      : 'Exited ${_formatTime(entrant.exitTime!)}',
                  style: TextStyle(fontSize: 11, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: entrant.isInside ? colors.accentSuccess : colors.accentWarning,
              foregroundColor: colors.isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            onPressed: () => _toggleEntrantStatus(index),
            child: Text(entrant.isInside ? 'Exit' : 'Re-enter', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAirMonitoring(ZaftoColors colors) {
    final minutesSinceMonitor = _timeSinceLastMonitor.inMinutes;
    final isOverdue = _timeSinceLastMonitor > _airMonitorInterval;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOverdue ? colors.accentError : colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isOverdue ? colors.accentError : colors.accentInfo).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.wind, size: 20, color: isOverdue ? colors.accentError : colors.accentInfo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Air Monitoring', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    Text(
                      isOverdue
                          ? 'OVERDUE - Last check ${minutesSinceMonitor}m ago'
                          : 'Next check in ${(_airMonitorInterval - _timeSinceLastMonitor).inMinutes}m',
                      style: TextStyle(fontSize: 12, color: isOverdue ? colors.accentError : colors.textTertiary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Log Reading'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _logAirReading(colors),
              ),
            ],
          ),
          if (_airReadings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Recent Readings', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
            const SizedBox(height: 8),
            ..._airReadings.reversed.take(3).map((reading) => _buildAirReadingItem(colors, reading)),
          ],
        ],
      ),
    );
  }

  Widget _buildAirReadingItem(ZaftoColors colors, _AirReading reading) {
    final isAcceptable = reading.o2 >= 19.5 && reading.o2 <= 23.5 && reading.lel < 10 && reading.co < 35 && reading.h2s < 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAcceptable ? colors.accentSuccess.withOpacity(0.1) : colors.accentError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isAcceptable ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
            size: 14,
            color: isAcceptable ? colors.accentSuccess : colors.accentError,
          ),
          const SizedBox(width: 8),
          Text(_formatTime(reading.timestamp), style: TextStyle(fontSize: 11, color: colors.textTertiary)),
          const Spacer(),
          _buildReadingChip(colors, 'O2', '${reading.o2.toStringAsFixed(1)}%', reading.o2 >= 19.5 && reading.o2 <= 23.5),
          _buildReadingChip(colors, 'LEL', '${reading.lel}%', reading.lel < 10),
          _buildReadingChip(colors, 'CO', '${reading.co}ppm', reading.co < 35),
          _buildReadingChip(colors, 'H2S', '${reading.h2s}ppm', reading.h2s < 10),
        ],
      ),
    );
  }

  Widget _buildReadingChip(ZaftoColors colors, String label, String value, bool isOk) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOk ? colors.accentSuccess.withOpacity(0.2) : colors.accentError.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:$value',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isOk ? colors.accentSuccess : colors.accentError),
      ),
    );
  }

  Widget _buildEntrantsList(ZaftoColors colors) {
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
              Icon(LucideIcons.clipboardList, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'ENTRY ROLES',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRoleItem(colors, 'Attendant', _attendantName ?? 'Not assigned', LucideIcons.eye),
          _buildRoleItem(colors, 'Supervisor', _supervisorName ?? 'Not assigned', LucideIcons.userCog),
          if (_permitController.text.isNotEmpty)
            _buildRoleItem(colors, 'Permit #', _permitController.text, LucideIcons.fileText),
        ],
      ),
    );
  }

  Widget _buildRoleItem(ZaftoColors colors, String role, String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textTertiary),
          const SizedBox(width: 10),
          Text('$role: ', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
          Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildExitSummary(ZaftoColors colors) {
    final duration = _entryTime != null ? DateTime.now().difference(_entryTime!) : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.checkCircle, size: 48, color: colors.accentSuccess),
          const SizedBox(height: 16),
          Text('Entry Complete', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.accentSuccess)),
          const SizedBox(height: 8),
          Text('Total duration: ${_formatDuration(duration)}', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          Text('${_airReadings.length} air readings recorded', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          Text('${_entrants.length} entrants logged', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(ZaftoColors colors) {
    switch (_state) {
      case _EntryState.preEntry:
        final isReady = _checklist.values.every((v) => v) && _attendantName != null && _entrants.isNotEmpty;
        return ElevatedButton.icon(
          icon: const Icon(LucideIcons.logIn, size: 24),
          label: const Text('Begin Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isReady ? colors.accentWarning : colors.textTertiary,
            foregroundColor: colors.isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: isReady ? _startEntry : null,
        );

      case _EntryState.active:
        final allExited = _entrants.every((e) => !e.isInside);
        return ElevatedButton.icon(
          icon: const Icon(LucideIcons.logOut, size: 24),
          label: Text(
            allExited ? 'Complete Entry' : 'Emergency Exit All',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: allExited ? colors.accentSuccess : colors.accentError,
            foregroundColor: colors.isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: allExited ? _completeEntry : _emergencyExitAll,
        );

      case _EntryState.exited:
        return ElevatedButton.icon(
          icon: const Icon(LucideIcons.fileText, size: 24),
          label: const Text('Generate Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accentPrimary,
            foregroundColor: colors.isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _generateReport(colors),
        );
    }
  }

  Widget _buildTextField(ZaftoColors colors, String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: colors.textTertiary),
        filled: true,
        fillColor: colors.fillDefault,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _addEntrant() {
    final name = _entrantNameController.text.trim();
    if (name.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _entrants.add(_Entrant(name: name));
        _entrantNameController.clear();
      });
    }
  }

  void _showNameDialog(ZaftoColors colors, String role, String? currentValue, Function(String) onSet) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Assign $role', style: TextStyle(color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter name',
            hintStyle: TextStyle(color: colors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Assign', style: TextStyle(color: colors.accentPrimary)),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSet(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _startEntry() {
    HapticFeedback.heavyImpact();
    setState(() {
      _state = _EntryState.active;
      _entryTime = DateTime.now();
      _elapsedTime = Duration.zero;
      _timeSinceLastMonitor = Duration.zero;
      for (int i = 0; i < _entrants.length; i++) {
        _entrants[i] = _entrants[i].copyWith(entryTime: DateTime.now(), isInside: true);
      }
    });

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime += const Duration(seconds: 1);
        _timeSinceLastMonitor += const Duration(seconds: 1);
      });
    });
  }

  void _toggleEntrantStatus(int index) {
    HapticFeedback.mediumImpact();
    final entrant = _entrants[index];
    setState(() {
      if (entrant.isInside) {
        _entrants[index] = entrant.copyWith(exitTime: DateTime.now(), isInside: false);
      } else {
        _entrants[index] = entrant.copyWith(entryTime: DateTime.now(), isInside: true, exitTime: null);
      }
    });
  }

  void _logAirReading(ZaftoColors colors) {
    final o2Controller = TextEditingController(text: '20.9');
    final lelController = TextEditingController(text: '0');
    final coController = TextEditingController(text: '0');
    final h2sController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Log Air Reading', style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _buildReadingField(colors, 'O2 %', o2Controller)),
                const SizedBox(width: 8),
                Expanded(child: _buildReadingField(colors, 'LEL %', lelController)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildReadingField(colors, 'CO ppm', coController)),
                const SizedBox(width: 8),
                Expanded(child: _buildReadingField(colors, 'H2S ppm', h2sController)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary),
            onPressed: () {
              setState(() {
                _airReadings.add(_AirReading(
                  timestamp: DateTime.now(),
                  o2: double.tryParse(o2Controller.text) ?? 0,
                  lel: int.tryParse(lelController.text) ?? 0,
                  co: int.tryParse(coController.text) ?? 0,
                  h2s: int.tryParse(h2sController.text) ?? 0,
                ));
                _timeSinceLastMonitor = Duration.zero;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingField(ZaftoColors colors, String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textTertiary, fontSize: 11),
        filled: true,
        fillColor: colors.fillDefault,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  void _emergencyExitAll() {
    HapticFeedback.heavyImpact();
    setState(() {
      for (int i = 0; i < _entrants.length; i++) {
        if (_entrants[i].isInside) {
          _entrants[i] = _entrants[i].copyWith(exitTime: DateTime.now(), isInside: false);
        }
      }
    });
  }

  void _completeEntry() async {
    HapticFeedback.heavyImpact();
    _elapsedTimer?.cancel();
    setState(() => _state = _EntryState.exited);

    // Persist confined space entry to Supabase
    try {
      final service = ref.read(complianceServiceProvider);
      await service.createRecord(
        type: ComplianceRecordType.confinedSpace,
        jobId: widget.jobId,
        data: {
          'permit_number': _permitController.text.trim(),
          'space_description': _spaceDescriptionController.text.trim(),
          'attendant': _attendantName,
          'supervisor': _supervisorName,
          'location': _currentAddress,
          'checklist': {
            for (var entry in _checklist.entries)
              entry.key.label: entry.value,
          },
          'entrants': _entrants.map((e) => {
            'name': e.name,
            'entry_time': e.entryTime?.toUtc().toIso8601String(),
            'exit_time': e.exitTime?.toUtc().toIso8601String(),
          }).toList(),
          'air_readings': _airReadings.map((r) => {
            'timestamp': r.timestamp.toUtc().toIso8601String(),
            'o2': r.o2,
            'lel': r.lel,
            'co': r.co,
            'h2s': r.h2s,
          }).toList(),
          'total_duration_seconds': _elapsedTime.inSeconds,
        },
        startedAt: _entryTime,
        endedAt: DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save entry log: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _generateReport(ZaftoColors colors) {
    // TODO: BACKEND - Generate PDF report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Report generation coming soon'),
        backgroundColor: colors.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmExit(ZaftoColors colors) {
    if (_state == _EntryState.preEntry || _state == _EntryState.exited) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Exit Without Completing?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'Entry is still active. Exiting will not save the current session.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Exit Anyway', style: TextStyle(color: colors.accentError)),
            onPressed: () {
              _elapsedTimer?.cancel();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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

enum _EntryState { preEntry, active, exited }

enum _ChecklistItem {
  permit(label: 'Entry permit obtained and signed', icon: LucideIcons.fileCheck),
  hazards(label: 'Hazards identified and controlled', icon: LucideIcons.alertTriangle),
  atmosphere(label: 'Atmosphere tested - acceptable', icon: LucideIcons.wind),
  ventilation(label: 'Ventilation in place', icon: LucideIcons.fan),
  communication(label: 'Communication system tested', icon: LucideIcons.radio),
  rescue(label: 'Rescue equipment ready', icon: LucideIcons.lifeBuoy),
  ppe(label: 'Required PPE available', icon: LucideIcons.hardHat),
  lockout(label: 'Lockout/tagout complete', icon: LucideIcons.lock);

  final String label;
  final IconData icon;

  const _ChecklistItem({required this.label, required this.icon});
}

class _Entrant {
  final String name;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final bool isInside;

  const _Entrant({
    required this.name,
    this.entryTime,
    this.exitTime,
    this.isInside = false,
  });

  _Entrant copyWith({String? name, DateTime? entryTime, DateTime? exitTime, bool? isInside}) {
    return _Entrant(
      name: name ?? this.name,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime,
      isInside: isInside ?? this.isInside,
    );
  }
}

class _AirReading {
  final DateTime timestamp;
  final double o2;
  final int lel;
  final int co;
  final int h2s;

  const _AirReading({
    required this.timestamp,
    required this.o2,
    required this.lel,
    required this.co,
    required this.h2s,
  });
}
