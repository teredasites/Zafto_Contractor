import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/widgets/shared/matrix_rain_painter.dart';
import 'package:zafto/screens/tools/tools_hub_screen.dart';
import 'package:zafto/screens/field_tools/field_tools_hub_screen.dart';
import 'package:zafto/screens/field_tools/job_site_photos_screen.dart';
import 'package:zafto/screens/field_tools/defect_markup_screen.dart';
import 'package:zafto/screens/field_tools/before_after_screen.dart';
import 'package:zafto/screens/field_tools/voice_notes_screen.dart';
import 'package:zafto/screens/field_tools/safety_briefing_screen.dart';
import 'package:zafto/screens/field_tools/daily_log_screen.dart';
import 'package:zafto/screens/field_tools/punch_list_screen.dart';
import 'package:zafto/screens/field_tools/receipt_scanner_screen.dart';
import 'package:zafto/screens/field_tools/mileage_tracker_screen.dart';
import 'package:zafto/screens/inspector/inspection_templates_screen.dart';

// ============================================================
// Inspector Tools Screen — Inspector-Specific & Shared Tools
//
// Organized by section: INSPECTION, DOCUMENTATION, FIELD,
// REFERENCE. All tools wired to real screens. Calculators
// accessible. Photo-to-sketch placeholder for Phase SK.
// ============================================================

class InspectorToolsScreen extends ConsumerWidget {
  const InspectorToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Tools',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(context, colors, 'INSPECTION', [
                _ToolItem(
                  LucideIcons.fileCheck,
                  'Templates',
                  'Inspection checklists by type & trade',
                  () => _push(context, const InspectionTemplatesScreen()),
                ),
                _ToolItem(
                  LucideIcons.camera,
                  'Site Photos',
                  'Capture and tag job site photos',
                  () => _push(context, const JobSitePhotosScreen()),
                ),
                _ToolItem(
                  LucideIcons.penTool,
                  'Defect Markup',
                  'Annotate photos with deficiencies',
                  () => _push(context, const DefectMarkupScreen()),
                ),
                _ToolItem(
                  LucideIcons.columns,
                  'Before / After',
                  'Side-by-side comparison photos',
                  () => _push(context, const BeforeAfterScreen()),
                ),
                _ToolItem(
                  LucideIcons.scanLine,
                  'Photo to Sketch',
                  'Snap photos → auto-generate floor plan (Phase SK)',
                  null, // Wires to Sketch Engine when built
                  comingSoon: true,
                ),
              ]),
              const SizedBox(height: 20),
              _buildSection(context, colors, 'DOCUMENTATION', [
                _ToolItem(
                  LucideIcons.mic,
                  'Voice Notes',
                  'Record voice memos on site',
                  () => _push(context, const VoiceNotesScreen()),
                ),
                _ToolItem(
                  LucideIcons.clipboardList,
                  'Daily Log',
                  'Record daily inspection activity',
                  () => _push(context, const DailyLogScreen()),
                ),
                _ToolItem(
                  LucideIcons.checkSquare,
                  'Punch List',
                  'Track deficiencies and corrections',
                  () => _push(context, const PunchListScreen()),
                ),
                _ToolItem(
                  LucideIcons.receipt,
                  'Receipts',
                  'Scan and store receipts',
                  () => _push(context, const ReceiptScannerScreen()),
                ),
              ]),
              const SizedBox(height: 20),
              _buildSection(context, colors, 'FIELD', [
                _ToolItem(
                  LucideIcons.shieldCheck,
                  'Safety Briefing',
                  'OSHA compliance checklists',
                  () => _push(context, const SafetyBriefingScreen()),
                ),
                _ToolItem(
                  LucideIcons.car,
                  'Mileage Tracker',
                  'Track driving between sites',
                  () => _push(context, const MileageTrackerScreen()),
                ),
                _ToolItem(
                  LucideIcons.wrench,
                  'All Field Tools',
                  'Full field tools hub',
                  () => _push(context, const FieldToolsHubScreen()),
                ),
              ]),
              const SizedBox(height: 20),
              _buildSection(context, colors, 'REFERENCE', [
                _ToolItem(
                  LucideIcons.calculator,
                  'Trade Calculators',
                  '1,194 calculators across 11 trades',
                  () => _push(context, const ToolsHubScreen()),
                ),
                _ToolItem(
                  LucideIcons.bookOpen,
                  'Code Reference',
                  'NEC, IBC, IRC code lookup (Phase SK)',
                  null,
                  comingSoon: true,
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ZaftoColors colors,
    String title,
    List<_ToolItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildToolRow(context, colors, items[i]),
                if (i < items.length - 1)
                  Divider(height: 0.5, indent: 56, color: colors.borderSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolRow(BuildContext context, ZaftoColors colors, _ToolItem item) {
    return InkWell(
      onTap: item.onTap != null
          ? () {
              HapticFeedback.lightImpact();
              item.onTap!();
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (item.comingSoon
                        ? colors.textQuaternary
                        : crmEmerald)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: item.comingSoon ? colors.textQuaternary : crmEmerald,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: item.comingSoon ? colors.textTertiary : colors.textPrimary,
                        ),
                      ),
                      if (item.comingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.accentWarning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SOON',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: colors.accentWarning,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: item.comingSoon ? colors.textQuaternary : colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: item.comingSoon ? colors.textQuaternary : colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool comingSoon;
  const _ToolItem(this.icon, this.title, this.subtitle, this.onTap, {this.comingSoon = false});
}
