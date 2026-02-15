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
import 'package:zafto/screens/field_tools/field_tools_hub_screen.dart';
import 'package:zafto/screens/field_tools/job_site_photos_screen.dart';
import 'package:zafto/screens/field_tools/voice_notes_screen.dart';
import 'package:zafto/screens/field_tools/before_after_screen.dart';
import 'package:zafto/screens/field_tools/defect_markup_screen.dart';
import 'package:zafto/screens/field_tools/safety_briefing_screen.dart';
import 'package:zafto/screens/field_tools/receipt_scanner_screen.dart';
import 'package:zafto/screens/field_tools/mileage_tracker_screen.dart';
import 'package:zafto/screens/field_tools/daily_log_screen.dart';
import 'package:zafto/screens/field_tools/materials_tracker_screen.dart';
import 'package:zafto/screens/field_tools/punch_list_screen.dart';
import 'package:zafto/screens/certifications/certifications_screen.dart';

// ============================================================
// Tech Home Screen V2 — Premium Dashboard (Owner-Parity)
//
// Same visual quality as HomeScreenV2 (owner), with tech-relevant
// content: AI brain card, quick tools carousel, job tiles,
// schedule strip, calculators access. No financials.
// ============================================================

class TechHomeScreen extends ConsumerStatefulWidget {
  const TechHomeScreen({super.key});

  @override
  ConsumerState<TechHomeScreen> createState() => _TechHomeScreenState();
}

class _TechHomeScreenState extends ConsumerState<TechHomeScreen> {
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openAIChat() {
    HapticFeedback.lightImpact();
    showZChatSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final now = DateTime.now();
    final dayFormat = DateFormat('EEEE, MMMM d');

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
              _buildQuickAccessTiles(colors),
              const SizedBox(height: 24),
              _buildTodaySchedule(colors),
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
        const CleanBrandHeader(subtitle: 'FIELD TECH'),
        const Spacer(),
        IconButton(
          onPressed: () {},
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
      subtitle: 'Diagnose an issue, find a part, or get a repair guide',
    );
  }

  // ── Right Now Section ───────────────────────────────────────
  Widget _buildRightNow(ZaftoColors colors) {
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
                  color: colors.accentSuccess.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.clock, color: colors.accentSuccess, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not Clocked In',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Slide to start your shift',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.accentSuccess,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CLOCK IN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Next job card
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
                child: Icon(LucideIcons.briefcase, color: colors.accentPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Jobs Scheduled',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Check your schedule for upcoming work',
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
      _QuickTool('Photos', LucideIcons.camera, () => _push(const JobSitePhotosScreen())),
      _QuickTool('Voice Notes', LucideIcons.mic, () => _push(const VoiceNotesScreen())),
      _QuickTool('Before/After', LucideIcons.columns, () => _push(const BeforeAfterScreen())),
      _QuickTool('Safety', LucideIcons.shieldCheck, () => _push(const SafetyBriefingScreen())),
      _QuickTool('Receipts', LucideIcons.receipt, () => _push(const ReceiptScannerScreen())),
      _QuickTool('Mileage', LucideIcons.car, () => _push(const MileageTrackerScreen())),
      _QuickTool('Markup', LucideIcons.penTool, () => _push(const DefectMarkupScreen())),
      _QuickTool('Daily Log', LucideIcons.clipboardList, () => _push(const DailyLogScreen())),
      _QuickTool('Materials', LucideIcons.box, () => _push(const MaterialsTrackerScreen())),
      _QuickTool('Punch List', LucideIcons.checkSquare, () => _push(const PunchListScreen())),
      _QuickTool('Calculators', LucideIcons.calculator, () => _push(const ToolsHubScreen())),
      _QuickTool('All Tools', LucideIcons.wrench, () => _push(const FieldToolsHubScreen())),
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

  // ── Quick Access Tiles (2x2 Grid) ──────────────────────────
  Widget _buildQuickAccessTiles(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, 'AT A GLANCE'),
        Row(
          children: [
            Expanded(
              child: _buildTile(
                colors,
                icon: LucideIcons.briefcase,
                label: 'My Jobs',
                value: '0',
                iconColor: colors.accentPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTile(
                colors,
                icon: LucideIcons.clock,
                label: 'My Hours',
                value: '0 / 40',
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
                icon: LucideIcons.calendarDays,
                label: 'Schedule',
                value: '0 today',
                iconColor: colors.accentInfo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _push(const CertificationsScreen()),
                child: _buildTile(
                  colors,
                  icon: LucideIcons.award,
                  label: 'Certifications',
                  value: '0 active',
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
        ],
      ),
    );
  }

  // ── Today's Schedule ────────────────────────────────────────
  Widget _buildTodaySchedule(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, "TODAY'S SCHEDULE"),
        Container(
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
                  'No jobs scheduled today',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check the Schedule tab for upcoming work',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textQuaternary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
