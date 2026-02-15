import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/widgets/shared/matrix_rain_painter.dart';
import 'package:zafto/screens/tools/tools_hub_screen.dart';
import 'package:zafto/screens/field_tools/job_site_photos_screen.dart';
import 'package:zafto/screens/field_tools/voice_notes_screen.dart';
import 'package:zafto/screens/field_tools/before_after_screen.dart';
import 'package:zafto/screens/field_tools/defect_markup_screen.dart';
import 'package:zafto/screens/field_tools/safety_briefing_screen.dart';
import 'package:zafto/screens/field_tools/incident_report_screen.dart';
import 'package:zafto/screens/field_tools/loto_logger_screen.dart';
import 'package:zafto/screens/field_tools/confined_space_timer_screen.dart';
import 'package:zafto/screens/field_tools/receipt_scanner_screen.dart';
import 'package:zafto/screens/field_tools/mileage_tracker_screen.dart';
import 'package:zafto/screens/field_tools/client_signature_screen.dart';
import 'package:zafto/screens/field_tools/sun_position_screen.dart';
import 'package:zafto/screens/field_tools/materials_tracker_screen.dart';
import 'package:zafto/screens/field_tools/daily_log_screen.dart';
import 'package:zafto/screens/field_tools/punch_list_screen.dart';
import 'package:zafto/screens/field_tools/change_order_screen.dart';

// ============================================================
// Tech Tools & Calculators Screen
//
// Two-segment view: Field Tools (18 tools) | Calculators (1,194)
// Field Tools is default (used hourly in the field).
// Calculators navigates to ToolsHubScreen (full trade-grouped list).
// ============================================================

class TechToolsCalcsScreen extends ConsumerStatefulWidget {
  const TechToolsCalcsScreen({super.key});

  @override
  ConsumerState<TechToolsCalcsScreen> createState() => _TechToolsCalcsScreenState();
}

class _TechToolsCalcsScreenState extends ConsumerState<TechToolsCalcsScreen> {
  int _selectedTab = 0; // 0 = Field Tools, 1 = Calculators

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            _buildSegmentControl(colors),
            Expanded(
              child: _selectedTab == 0
                  ? _buildFieldTools(colors)
                  : _buildCalculatorsEntry(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        'Tools',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSegmentControl(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: colors.bgInset,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildSegment(colors, 'Field Tools', 0, LucideIcons.wrench),
            _buildSegment(colors, 'Calculators', 1, LucideIcons.calculator),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(ZaftoColors colors, String label, int index, IconData icon) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? colors.bgElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? crmEmerald : colors.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? colors.textPrimary : colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field Tools Tab ─────────────────────────────────────────
  Widget _buildFieldTools(ZaftoColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategory(colors, 'JOB SITE', [
            _ToolItem('Photos', 'Capture & organize job site photos', LucideIcons.camera, () => _push(const JobSitePhotosScreen())),
            _ToolItem('Voice Notes', 'Record audio notes on site', LucideIcons.mic, () => _push(const VoiceNotesScreen())),
            _ToolItem('Before / After', 'Side-by-side comparison photos', LucideIcons.columns, () => _push(const BeforeAfterScreen())),
            _ToolItem('Defect Markup', 'Annotate photos with defect markers', LucideIcons.penTool, () => _push(const DefectMarkupScreen())),
          ]),
          _buildCategory(colors, 'SAFETY', [
            _ToolItem('Safety Briefing', 'Daily safety meeting documentation', LucideIcons.shieldCheck, () => _push(const SafetyBriefingScreen())),
            _ToolItem('Incident Report', 'Report workplace incidents', LucideIcons.alertTriangle, () => _push(const IncidentReportScreen())),
            _ToolItem('LOTO', 'Lockout/Tagout logging', LucideIcons.lock, () => _push(const LOTOLoggerScreen())),
            _ToolItem('Confined Space', 'Entry timer and checklist', LucideIcons.clock, () => _push(const ConfinedSpaceTimerScreen())),
          ]),
          _buildCategory(colors, 'FINANCIAL', [
            _ToolItem('Receipt Scanner', 'Scan and categorize receipts', LucideIcons.receipt, () => _push(const ReceiptScannerScreen())),
            _ToolItem('Mileage Tracker', 'Track driving miles for jobs', LucideIcons.car, () => _push(const MileageTrackerScreen())),
            _ToolItem('Client Signature', 'Capture client approval signatures', LucideIcons.pencil, () => _push(const ClientSignatureScreen())),
          ]),
          _buildCategory(colors, 'MEASUREMENT', [
            _ToolItem('Sun Position', 'Solar position and shadow tracking', LucideIcons.sun, () => _push(const SunPositionScreen())),
          ]),
          _buildCategory(colors, 'JOB TRACKING', [
            _ToolItem('Materials', 'Track materials used on site', LucideIcons.box, () => _push(const MaterialsTrackerScreen())),
            _ToolItem('Daily Log', 'Record daily work progress', LucideIcons.clipboardList, () => _push(const DailyLogScreen())),
            _ToolItem('Punch List', 'Track remaining items to complete', LucideIcons.checkSquare, () => _push(const PunchListScreen())),
            _ToolItem('Change Orders', 'Document scope changes', LucideIcons.fileDiff, () => _push(const ChangeOrderScreen())),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategory(ZaftoColors colors, String title, List<_ToolItem> tools) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: colors.textTertiary,
            ),
          ),
        ),
        ...tools.map((tool) => _buildToolRow(colors, tool)),
      ],
    );
  }

  Widget _buildToolRow(ZaftoColors colors, _ToolItem tool) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        tool.onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: crmEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(tool.icon, color: crmEmerald, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    tool.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  // ── Calculators Tab ─────────────────────────────────────────
  Widget _buildCalculatorsEntry(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: crmEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(LucideIcons.calculator, color: crmEmerald, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              '1,194 Trade Calculators',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Electrical, Plumbing, HVAC, Solar, Roofing,\nGeneral Contractor, and more',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _push(const ToolsHubScreen());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: crmEmerald,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Open Calculator Library',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _ToolItem {
  final String name;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ToolItem(this.name, this.subtitle, this.icon, this.onTap);
}
