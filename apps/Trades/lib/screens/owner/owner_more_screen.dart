import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/screens/scheduling/schedule_list_screen.dart';

class OwnerMoreScreen extends ConsumerWidget {
  const OwnerMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionLabel(colors, 'BUSINESS'),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.people_outline,
            title: 'Customers',
          ),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.group_outlined,
            title: 'Team',
          ),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.shield_outlined,
            title: 'Insurance Claims',
          ),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.apartment_outlined,
            title: 'Properties',
          ),
          _buildMenuItem(
            context,
            colors,
            icon: LucideIcons.ganttChart,
            title: 'Scheduling',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleListScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.trending_up,
            title: 'Leads',
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 8),
          _buildSectionLabel(colors, 'FINANCE'),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.bar_chart,
            title: 'Reports',
          ),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.verified_outlined,
            title: 'Certifications',
          ),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.book_outlined,
            title: 'ZBooks',
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 8),
          _buildSectionLabel(colors, 'SYSTEM'),
          _buildMenuItem(
            context,
            colors,
            icon: Icons.settings_outlined,
            title: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ZaftoColors colors, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: colors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    ZaftoColors colors, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          // Navigation placeholder
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius:
                      BorderRadius.circular(ZaftoThemeBuilder.radiusSM),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
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
      ),
    );
  }
}
