import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// Field Tool Screens
import 'job_site_photos_screen.dart';
import 'before_after_screen.dart';
import 'defect_markup_screen.dart';
import 'voice_notes_screen.dart';
import 'mileage_tracker_screen.dart';
import 'loto_logger_screen.dart';
import 'incident_report_screen.dart';
import 'safety_briefing_screen.dart';
import 'sun_position_screen.dart';
import 'dead_man_switch_screen.dart';
import 'confined_space_timer_screen.dart';
import 'client_signature_screen.dart';
import 'receipt_scanner_screen.dart';
import 'level_plumb_screen.dart';

/// Field Tools Hub - All 14 iPhone hardware tools in one place
class FieldToolsHubScreen extends ConsumerWidget {
  final String? jobId;

  const FieldToolsHubScreen({super.key, this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: Text('Field Tools', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          _buildInfoBanner(colors),
          const SizedBox(height: 24),

          // Photo & Documentation
          _buildSectionHeader(colors, 'PHOTO & DOCUMENTATION'),
          const SizedBox(height: 12),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.camera,
            title: 'Job Site Photos',
            subtitle: 'Capture with date/location stamps',
            color: Colors.blue,
            onTap: () => _openTool(context, JobSitePhotosScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.columns,
            title: 'Before / After',
            subtitle: 'Side-by-side comparison with slider',
            color: Colors.green,
            onTap: () => _openTool(context, BeforeAfterScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.edit3,
            title: 'Defect Markup',
            subtitle: 'Annotate photos with arrows & notes',
            color: Colors.orange,
            onTap: () => _openTool(context, DefectMarkupScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.mic,
            title: 'Voice Notes',
            subtitle: 'Audio recording with transcription',
            color: Colors.purple,
            onTap: () => _openTool(context, VoiceNotesScreen(jobId: jobId)),
          ),
          const SizedBox(height: 24),

          // Business & Tracking
          _buildSectionHeader(colors, 'BUSINESS & TRACKING'),
          const SizedBox(height: 12),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.car,
            title: 'Mileage Tracker',
            subtitle: 'GPS trip tracking for tax deductions',
            color: Colors.teal,
            onTap: () => _openTool(context, MileageTrackerScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.receipt,
            title: 'Receipt Scanner',
            subtitle: 'Expense tracking with categorization',
            color: Colors.indigo,
            onTap: () => _openTool(context, ReceiptScannerScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.penTool,
            title: 'Client Signature',
            subtitle: 'Digital signatures for approvals',
            color: Colors.cyan,
            onTap: () => _openTool(context, ClientSignatureScreen(jobId: jobId)),
          ),
          const SizedBox(height: 24),

          // Safety & Compliance
          _buildSectionHeader(colors, 'SAFETY & COMPLIANCE'),
          const SizedBox(height: 12),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.lock,
            title: 'LOTO Logger',
            subtitle: 'Lock Out / Tag Out documentation',
            color: Colors.red,
            onTap: () => _openTool(context, LOTOLoggerScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.alertTriangle,
            title: 'Incident Report',
            subtitle: 'OSHA-compliant incident documentation',
            color: Colors.deepOrange,
            onTap: () => _openTool(context, IncidentReportScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.shield,
            title: 'Safety Briefing',
            subtitle: 'Toolbox talks with crew sign-off',
            color: Colors.amber,
            onTap: () => _openTool(context, SafetyBriefingScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.box,
            title: 'Confined Space',
            subtitle: 'Entry tracking with air monitoring',
            color: Colors.brown,
            onTap: () => _openTool(context, ConfinedSpaceTimerScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.userCheck,
            title: 'Dead Man Switch',
            subtitle: 'Lone worker safety timer',
            color: Colors.pink,
            onTap: () => _openTool(context, DeadManSwitchScreen(jobId: jobId)),
          ),
          const SizedBox(height: 24),

          // Utilities
          _buildSectionHeader(colors, 'UTILITIES'),
          const SizedBox(height: 12),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.sun,
            title: 'Sun Position',
            subtitle: 'Solar angles for panel placement',
            color: Colors.orange,
            onTap: () => _openTool(context, SunPositionScreen(jobId: jobId)),
          ),
          _buildToolCard(
            context, colors,
            icon: LucideIcons.ruler,
            title: 'Level & Plumb',
            subtitle: 'Digital bubble level with calibration',
            color: Colors.lime,
            onTap: () => _openTool(context, LevelPlumbScreen(jobId: jobId)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.smartphone, color: colors.accentPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'iPhone Hardware Tools',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.accentPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Camera, GPS, microphone, and sensors built for the field. All photos include date and location stamps.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: colors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    ZaftoColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  void _openTool(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
