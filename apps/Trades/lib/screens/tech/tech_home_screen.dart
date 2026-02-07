import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class TechHomeScreen extends ConsumerWidget {
  const TechHomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final dayFormat = DateFormat('EEEE, MMMM d');

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(context, colors, textTheme, dayFormat.format(now)),
              const SizedBox(height: 16),
              _buildClockSlider(context, colors, textTheme),
              const SizedBox(height: 20),
              _buildTodaysJobs(context, colors, textTheme),
              const SizedBox(height: 20),
              _buildQuickActions(context, colors, textTheme),
              const SizedBox(height: 20),
              _buildThisWeekStats(context, colors, textTheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
    String dateString,
  ) {
    return Row(
      children: [
        const ZAvatar(name: 'Tech User', size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, Tech',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateString,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.notifications_outlined,
            color: colors.textSecondary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildClockSlider(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
  ) {
    return ZCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.access_time_outlined,
            size: 36,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'NOT CLOCKED IN',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '00:00:00',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: colors.textQuaternary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusFull),
              border: Border.all(
                color: colors.accentSuccess.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 4,
                  top: 4,
                  bottom: 4,
                  child: Container(
                    width: 44,
                    decoration: BoxDecoration(
                      color: colors.accentSuccess,
                      borderRadius: BorderRadius.circular(
                        ZaftoThemeBuilder.radiusFull,
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'SLIDE TO CLOCK IN',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: colors.accentSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ZaftoColors colors,
    TextTheme textTheme, {
    required String title,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.textTertiary,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildTodaysJobs(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          colors,
          textTheme,
          title: "TODAY'S JOBS",
          trailing: ZBadge(label: '0', color: colors.accentPrimary),
        ),
        ZCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 32,
                  color: colors.textQuaternary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No jobs scheduled today',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, textTheme, title: 'QUICK ACTIONS'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickAction(
              colors,
              icon: Icons.camera_alt_outlined,
              label: 'Photo',
              onTap: () {},
            ),
            _buildQuickAction(
              colors,
              icon: Icons.mic_outlined,
              label: 'Voice Note',
              onTap: () {},
            ),
            _buildQuickAction(
              colors,
              icon: Icons.access_time_outlined,
              label: 'Time',
              onTap: () {},
            ),
            _buildQuickAction(
              colors,
              icon: Icons.videocam_outlined,
              label: 'Walkthrough',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.accentPrimary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThisWeekStats(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, textTheme, title: 'THIS WEEK'),
        ZCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatRow(
                colors,
                label: 'Hours',
                value: '0 / 40',
                progress: 0.0,
                progressColor: colors.accentPrimary,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      colors,
                      label: 'Jobs Completed',
                      value: '0',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: colors.borderSubtle,
                  ),
                  Expanded(
                    child: _buildMiniStat(
                      colors,
                      label: 'Miles',
                      value: '0',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    ZaftoColors colors, {
    required String label,
    required String value,
    required double progress,
    required Color progressColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colors.bgInset,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    ZaftoColors colors, {
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
