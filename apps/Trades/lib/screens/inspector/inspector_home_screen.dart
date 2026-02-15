import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/widgets/shared/ai_brain_card.dart';
import 'package:zafto/widgets/shared/clean_brand_header.dart';
import 'package:zafto/widgets/shared/matrix_rain_painter.dart';
import 'package:zafto/screens/ai/z_chat_sheet.dart';
import 'package:zafto/screens/tools/tools_hub_screen.dart';
import 'package:zafto/screens/field_tools/job_site_photos_screen.dart';
import 'package:zafto/screens/field_tools/voice_notes_screen.dart';
import 'package:zafto/screens/field_tools/before_after_screen.dart';
import 'package:zafto/screens/field_tools/defect_markup_screen.dart';
import 'package:zafto/screens/field_tools/safety_briefing_screen.dart';
import 'package:zafto/screens/field_tools/receipt_scanner_screen.dart';
import 'package:zafto/screens/field_tools/daily_log_screen.dart';
import 'package:zafto/screens/field_tools/punch_list_screen.dart';
import 'package:zafto/screens/certifications/certifications_screen.dart';
import 'package:zafto/screens/tech/tech_timesheet_screen.dart';
import 'package:zafto/screens/time_clock/time_clock_screen.dart';
import 'package:zafto/services/inspection_service.dart';
import 'package:zafto/services/time_clock_service.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/models/time_entry.dart';
import 'package:zafto/screens/inspector/inspection_templates_screen.dart';

// ============================================================
// Inspector Home Screen — Premium Dashboard (Owner-Parity)
//
// Same visual quality as TechHomeScreen / HomeScreenV2.
// AI brain card, clock in, quick tools carousel, stats tiles,
// today's inspections list, reference library.
// ============================================================

class InspectorHomeScreen extends ConsumerStatefulWidget {
  const InspectorHomeScreen({super.key});

  @override
  ConsumerState<InspectorHomeScreen> createState() => _InspectorHomeScreenState();
}

class _InspectorHomeScreenState extends ConsumerState<InspectorHomeScreen> {
  void _openAIChat() {
    HapticFeedback.lightImpact();
    showZChatSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final now = DateTime.now();
    final dayFormat = DateFormat('EEEE, MMMM d');
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(colors, dayFormat.format(now)),
              const SizedBox(height: 20),
              _buildAIBar(colors),
              const SizedBox(height: 24),
              _buildRightNow(colors),
              const SizedBox(height: 24),
              _buildQuickToolsCarousel(colors),
              const SizedBox(height: 24),
              _buildStatsTiles(colors, inspectionsAsync),
              const SizedBox(height: 24),
              _buildTodayInspections(colors, inspectionsAsync),
              const SizedBox(height: 24),
              _buildReferenceLibrary(colors),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(ZaftoColors colors, String dateString) {
    return Row(
      children: [
        const CleanBrandHeader(subtitle: 'INSPECTOR'),
        const Spacer(),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notifications coming soon'),
                backgroundColor: colors.bgElevated,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: Icon(LucideIcons.bell, color: colors.textSecondary, size: 20),
        ),
        const SizedBox(width: 4),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: crmEmerald.withValues(alpha: 0.15),
          ),
          child: Icon(LucideIcons.user, color: crmEmerald, size: 16),
        ),
      ],
    );
  }

  // ── AI Brain Card ───────────────────────────────────────────
  Widget _buildAIBar(ZaftoColors colors) {
    return AIBrainCard(
      colors: colors,
      onTap: _openAIChat,
      onLongPress: () {
        HapticFeedback.lightImpact();
        _openAIChat();
      },
      subtitle: 'Look up a code, find a violation, or check compliance',
    );
  }

  // ── Right Now Section ───────────────────────────────────────
  Widget _buildRightNow(ZaftoColors colors) {
    final activeClock = ref.watch(activeClockEntryProvider);
    final isClockedIn = activeClock != null;
    final clockColor = isClockedIn ? colors.accentSuccess : colors.textTertiary;
    final clockLabel = isClockedIn ? 'Clocked In' : 'Not Clocked In';
    final clockSub = isClockedIn
        ? 'Since ${DateFormat.jm().format(activeClock.clockIn)}'
        : 'Tap to start your shift';
    final btnLabel = isClockedIn ? 'VIEW' : 'CLOCK IN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, 'RIGHT NOW'),
        // Clock in card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: clockColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.clock, color: clockColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clockLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clockSub,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _push(const TimeClockScreen());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    btnLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Next inspection card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.clipboardCheck, color: colors.accentPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Inspections Scheduled',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Check the Inspections tab for upcoming work',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Quick Tools Carousel ────────────────────────────────────
  Widget _buildQuickToolsCarousel(ZaftoColors colors) {
    final tools = <_QuickTool>[
      _QuickTool('Checklist', LucideIcons.listChecks, () => _push(const InspectionTemplatesScreen(quickChecklistMode: true))),
      _QuickTool('Photos', LucideIcons.camera, () => _push(const JobSitePhotosScreen())),
      _QuickTool('Markup', LucideIcons.penTool, () => _push(const DefectMarkupScreen())),
      _QuickTool('Voice Notes', LucideIcons.mic, () => _push(const VoiceNotesScreen())),
      _QuickTool('Before/After', LucideIcons.columns, () => _push(const BeforeAfterScreen())),
      _QuickTool('Safety', LucideIcons.shieldCheck, () => _push(const SafetyBriefingScreen())),
      _QuickTool('Punch List', LucideIcons.checkSquare, () => _push(const PunchListScreen())),
      _QuickTool('Daily Log', LucideIcons.clipboardList, () => _push(const DailyLogScreen())),
      _QuickTool('Receipts', LucideIcons.receipt, () => _push(const ReceiptScannerScreen())),
      _QuickTool('Calculators', LucideIcons.calculator, () => _push(const ToolsHubScreen())),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, 'QUICK TOOLS'),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tool = tools[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  tool.onTap();
                },
                child: SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: crmEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(tool.icon, color: crmEmerald, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tool.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Stats Tiles (2x2 Grid) ────────────────────────────────
  Widget _buildStatsTiles(ZaftoColors colors, AsyncValue<List<PmInspection>> inspectionsAsync) {
    final service = ref.read(inspectionServiceProvider);
    final clockStats = ref.watch(timeClockStatsProvider);
    final hoursStr = '${clockStats.totalHoursThisWeek.toStringAsFixed(1)} / 40';
    final weekCount = inspectionsAsync.maybeWhen(
      data: (list) => service.thisWeek(list).where((i) => i.status == InspectionStatus.completed).length,
      orElse: () => 0,
    );
    final rate = inspectionsAsync.maybeWhen(
      data: (list) => service.passRate(list),
      orElse: () => 0.0,
    );
    final deficiencies = inspectionsAsync.maybeWhen(
      data: (list) => service.failCount(list),
      orElse: () => 0,
    );
    final todayCount = inspectionsAsync.maybeWhen(
      data: (list) => service.scheduledToday(list).length,
      orElse: () => 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, 'AT A GLANCE'),
        Row(
          children: [
            Expanded(
              child: _buildTile(
                colors,
                icon: LucideIcons.clipboardCheck,
                label: 'Completed',
                value: '$weekCount',
                subtitle: 'this week',
                iconColor: colors.accentPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTile(
                colors,
                icon: LucideIcons.percent,
                label: 'Pass Rate',
                value: '${rate.toStringAsFixed(0)}%',
                iconColor: colors.accentSuccess,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTile(
                colors,
                icon: LucideIcons.alertTriangle,
                label: 'Deficiencies',
                value: '$deficiencies',
                subtitle: 'found',
                iconColor: colors.accentError,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _push(const TechTimesheetScreen()),
                child: _buildTile(
                  colors,
                  icon: LucideIcons.clock,
                  label: 'My Hours',
                  value: hoursStr,
                  iconColor: colors.accentWarning,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTile(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    String? subtitle,
  }) {
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: colors.textQuaternary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Today's Inspections ───────────────────────────────────
  Widget _buildTodayInspections(ZaftoColors colors, AsyncValue<List<PmInspection>> inspectionsAsync) {
    final service = ref.read(inspectionServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, "TODAY'S INSPECTIONS"),
        inspectionsAsync.when(
          loading: () => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Center(
              child: CircularProgressIndicator(color: colors.accentPrimary),
            ),
          ),
          error: (e, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.alertCircle, size: 32, color: colors.error),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load inspections',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => ref.read(inspectionsProvider.notifier).refresh(),
                    child: Text('Tap to retry', style: TextStyle(fontSize: 13, color: colors.accentPrimary)),
                  ),
                ],
              ),
            ),
          ),
          data: (inspections) {
            final today = service.scheduledToday(inspections);
            if (today.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.calendarOff, size: 32, color: colors.textQuaternary),
                      const SizedBox(height: 8),
                      Text(
                        'No inspections scheduled today',
                        style: TextStyle(fontSize: 14, color: colors.textTertiary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check the Inspections tab for upcoming work',
                        style: TextStyle(fontSize: 12, color: colors.textQuaternary),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: today.map((inspection) => _buildInspectionCard(colors, inspection)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInspectionCard(ZaftoColors colors, PmInspection inspection) {
    final statusColor = _inspectionStatusColor(inspection.status, colors);
    final time = inspection.scheduledDate != null
        ? '${inspection.scheduledDate!.hour.toString().padLeft(2, '0')}:${inspection.scheduledDate!.minute.toString().padLeft(2, '0')}'
        : 'TBD';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.accentPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _inspectionTypeLabel(inspection.inspectionType),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (inspection.notes ?? '').isNotEmpty ? inspection.notes! : 'No notes',
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _inspectionStatusLabel(inspection.status),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reference Library Card ──────────────────────────────────
  Widget _buildReferenceLibrary(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _push(const ToolsHubScreen());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: crmEmerald.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: crmEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.calculator, color: crmEmerald, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reference Library',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1,194 trade calculators across 11 trades',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: colors.textQuaternary, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────
  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: colors.textTertiary,
        ),
      ),
    );
  }

  String _inspectionTypeLabel(InspectionType type) {
    return _typeLabels[type] ?? type.name;
  }

  static const _typeLabels = <InspectionType, String>{
    InspectionType.moveIn: 'Move-In',
    InspectionType.moveOut: 'Move-Out',
    InspectionType.routine: 'Routine',
    InspectionType.annual: 'Annual',
    InspectionType.maintenance: 'Maintenance',
    InspectionType.safety: 'Safety',
    InspectionType.roughIn: 'Rough-In',
    InspectionType.framing: 'Framing',
    InspectionType.foundation: 'Foundation',
    InspectionType.finalInspection: 'Final',
    InspectionType.permit: 'Permit',
    InspectionType.codeCompliance: 'Code Compliance',
    InspectionType.qcHoldPoint: 'QC Hold Point',
    InspectionType.reInspection: 'Re-Inspection',
    InspectionType.swppp: 'SWPPP',
    InspectionType.environmental: 'Environmental',
    InspectionType.ada: 'ADA',
    InspectionType.insuranceDamage: 'Insurance Damage',
    InspectionType.tpi: 'TPI',
    InspectionType.preConstruction: 'Pre-Construction',
    InspectionType.roofing: 'Roofing',
    InspectionType.fireLifeSafety: 'Fire/Life Safety',
    InspectionType.electrical: 'Electrical',
    InspectionType.plumbing: 'Plumbing',
    InspectionType.hvac: 'HVAC',
  };

  String _inspectionStatusLabel(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.scheduled: return 'Scheduled';
      case InspectionStatus.inProgress: return 'In Progress';
      case InspectionStatus.completed: return 'Completed';
      case InspectionStatus.cancelled: return 'Cancelled';
    }
  }

  Color _inspectionStatusColor(InspectionStatus status, ZaftoColors colors) {
    switch (status) {
      case InspectionStatus.scheduled:
        return colors.accentPrimary;
      case InspectionStatus.inProgress:
        return Colors.amber;
      case InspectionStatus.completed:
        return colors.accentSuccess;
      case InspectionStatus.cancelled:
        return colors.textTertiary;
    }
  }

  void _push(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _QuickTool {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickTool(this.label, this.icon, this.onTap);
}
