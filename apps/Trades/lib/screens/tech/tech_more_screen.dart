import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/widgets/shared/matrix_rain_painter.dart';
import 'package:zafto/screens/tech/tech_walkthrough_screen.dart';
import 'package:zafto/screens/field_tools/daily_log_screen.dart';
import 'package:zafto/screens/field_tools/materials_tracker_screen.dart';
import 'package:zafto/screens/field_tools/punch_list_screen.dart';
import 'package:zafto/screens/field_tools/change_order_screen.dart';
import 'package:zafto/screens/certifications/certifications_screen.dart';
import 'package:zafto/screens/properties/properties_hub_screen.dart';
import 'package:zafto/screens/settings/settings_screen.dart';
import 'package:zafto/screens/tech/tech_timesheet_screen.dart';
import 'package:zafto/screens/time_clock/time_clock_screen.dart';

// ============================================================
// Tech More Screen — Expanded Feature Access
//
// Structured sections: FIELD, PERSONAL, ACCOUNT.
// All onTap handlers wired to real screens. No dead buttons.
// ============================================================

class TechMoreScreen extends ConsumerWidget {
  const TechMoreScreen({super.key});

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
                'More',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(context, colors, 'FIELD', [
                _MenuItem(LucideIcons.video, 'Walkthrough', 'Record video walkthroughs', () => _push(context, const TechWalkthroughScreen())),
                _MenuItem(LucideIcons.clipboardList, 'Daily Log', 'Record daily work progress', () => _push(context, const DailyLogScreen())),
                _MenuItem(LucideIcons.box, 'Materials Tracker', 'Track materials used on site', () => _push(context, const MaterialsTrackerScreen())),
                _MenuItem(LucideIcons.checkSquare, 'Punch List', 'Track remaining items', () => _push(context, const PunchListScreen())),
                _MenuItem(LucideIcons.fileDiff, 'Change Orders', 'Document scope changes', () => _push(context, const ChangeOrderScreen())),
              ]),
              const SizedBox(height: 20),
              _buildSection(context, colors, 'TIME & PAY', [
                _MenuItem(LucideIcons.clock, 'Time Clock', 'Clock in/out, track breaks', () => _push(context, const TimeClockScreen())),
                _MenuItem(LucideIcons.calendarClock, 'My Timesheet', 'Weekly hours and daily breakdown', () => _push(context, const TechTimesheetScreen())),
              ]),
              const SizedBox(height: 20),
              _buildSection(context, colors, 'PERSONAL', [
                _MenuItem(LucideIcons.award, 'Certifications', 'View your active certifications', () => _push(context, const CertificationsScreen())),
                _MenuItem(LucideIcons.building, 'Properties', 'View assigned properties', () => _push(context, const PropertiesHubScreen())),
              ]),
              const SizedBox(height: 20),
              _buildSection(context, colors, 'ACCOUNT', [
                _MenuItem(LucideIcons.settings, 'Profile & Settings', 'Account, notifications, preferences', () => _push(context, const SettingsScreen())),
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
    List<_MenuItem> items,
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
                _buildMenuItem(context, colors, items[i]),
                if (i < items.length - 1)
                  Divider(height: 0.5, indent: 56, color: colors.borderSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, ZaftoColors colors, _MenuItem item) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: crmEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 18, color: crmEmerald),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    item.subtitle,
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

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.title, this.subtitle, this.onTap);
}
