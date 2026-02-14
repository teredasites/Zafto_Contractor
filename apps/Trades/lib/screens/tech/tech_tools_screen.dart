import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

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

class TechToolsScreen extends ConsumerWidget {
  const TechToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('Field Tools'),
        backgroundColor: colors.bgBase,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.search,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            _buildCategory(context, colors, 'JOB SITE', [
              _ToolItem(
                icon: Icons.camera_alt_outlined,
                title: 'Photos',
                subtitle: 'Capture and organize job site photos',
                onTap: () => _navigate(
                  context,
                  const JobSitePhotosScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.mic_outlined,
                title: 'Voice Notes',
                subtitle: 'Record audio notes on site',
                onTap: () => _navigate(
                  context,
                  const VoiceNotesScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.compare_outlined,
                title: 'Before / After',
                subtitle: 'Side-by-side comparison photos',
                onTap: () => _navigate(
                  context,
                  const BeforeAfterScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.edit_outlined,
                title: 'Defect Markup',
                subtitle: 'Annotate photos with defect markers',
                onTap: () => _navigate(
                  context,
                  const DefectMarkupScreen(),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildCategory(context, colors, 'SAFETY', [
              _ToolItem(
                icon: Icons.health_and_safety_outlined,
                title: 'Safety Briefing',
                subtitle: 'Daily safety meeting documentation',
                onTap: () => _navigate(
                  context,
                  const SafetyBriefingScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.warning_amber_outlined,
                title: 'Incident Report',
                subtitle: 'Report workplace incidents',
                onTap: () => _navigate(
                  context,
                  const IncidentReportScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.lock_outlined,
                title: 'LOTO',
                subtitle: 'Lockout/Tagout logging',
                onTap: () => _navigate(
                  context,
                  const LOTOLoggerScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.sensors_outlined,
                title: 'Confined Space',
                subtitle: 'Confined space entry timer and checklist',
                onTap: () => _navigate(
                  context,
                  const ConfinedSpaceTimerScreen(),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildCategory(context, colors, 'FINANCIAL', [
              _ToolItem(
                icon: Icons.receipt_long_outlined,
                title: 'Receipt Scanner',
                subtitle: 'Scan and categorize receipts',
                onTap: () => _navigate(
                  context,
                  const ReceiptScannerScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.directions_car_outlined,
                title: 'Mileage Tracker',
                subtitle: 'Track driving miles for jobs',
                onTap: () => _navigate(
                  context,
                  const MileageTrackerScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.draw_outlined,
                title: 'Client Signature',
                subtitle: 'Capture client approval signatures',
                onTap: () => _navigate(
                  context,
                  const ClientSignatureScreen(),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildCategory(context, colors, 'MEASUREMENT', [
              _ToolItem(
                icon: Icons.wb_sunny_outlined,
                title: 'Sun Position',
                subtitle: 'Solar position and shadow tracking',
                onTap: () => _navigate(
                  context,
                  const SunPositionScreen(),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildCategory(context, colors, 'JOB TRACKING', [
              _ToolItem(
                icon: Icons.inventory_2_outlined,
                title: 'Materials',
                subtitle: 'Track materials used on site',
                onTap: () => _navigate(
                  context,
                  const MaterialsTrackerScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.description_outlined,
                title: 'Daily Log',
                subtitle: 'Record daily work progress',
                onTap: () => _navigate(
                  context,
                  const DailyLogScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.checklist_outlined,
                title: 'Punch List',
                subtitle: 'Track remaining items to complete',
                onTap: () => _navigate(
                  context,
                  const PunchListScreen(),
                ),
              ),
              _ToolItem(
                icon: Icons.swap_horiz_outlined,
                title: 'Change Orders',
                subtitle: 'Document scope changes',
                onTap: () => _navigate(
                  context,
                  const ChangeOrderScreen(),
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    ZaftoColors colors,
    String title,
    List<_ToolItem> tools,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.textTertiary,
            ),
          ),
        ),
        ZCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < tools.length; i++) ...[
                _buildToolTile(context, colors, tools[i]),
                if (i < tools.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: colors.borderSubtle,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolTile(
    BuildContext context,
    ZaftoColors colors,
    _ToolItem tool,
  ) {
    return InkWell(
      onTap: tool.onTap,
      borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusLG),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  ZaftoThemeBuilder.radiusSM,
                ),
              ),
              child: Icon(
                tool.icon,
                size: 20,
                color: colors.accentPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool.subtitle,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.textQuaternary,
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
