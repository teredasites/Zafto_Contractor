import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

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

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(context, colors, textTheme),
              const SizedBox(height: 12),
              _buildRevenueCards(context, colors, textTheme),
              const SizedBox(height: 12),
              _buildPipelineStats(context, colors, textTheme),
              const SizedBox(height: 12),
              _buildNeedsAttention(context, colors, textTheme),
              const SizedBox(height: 12),
              _buildTodaySchedule(context, colors, textTheme),
              const SizedBox(height: 12),
              _buildRecentActivity(context, colors, textTheme),
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
  ) {
    return Row(
      children: [
        ZAvatar(
          name: 'Damian Tereda',
          size: 44,
          onLongPress: () {
            // Role switch placeholder
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, Damian',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Business Command Center',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // Notifications placeholder
          },
          icon: Icon(
            Icons.notifications_outlined,
            color: colors.textSecondary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCards(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: ZCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Today',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$0',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'vs avg',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ZCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue MTD',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$0',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'of target',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineStats(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colors,
                textTheme,
                label: 'Active Jobs',
                value: '0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colors,
                textTheme,
                label: 'Crew Out',
                value: '0/0',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colors,
                textTheme,
                label: 'Bids Pending',
                value: '0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colors,
                textTheme,
                label: 'Overdue',
                value: '0',
                valueColor: colors.accentError,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ZaftoColors colors,
    TextTheme textTheme, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.textPrimary,
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
    String? actionLabel,
    VoidCallback? onAction,
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
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.accentPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors, String message) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildNeedsAttention(
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
          title: 'NEEDS ATTENTION',
          actionLabel: 'See All',
          onAction: () {},
        ),
        _buildEmptyState(colors, 'Nothing needs your attention'),
      ],
    );
  }

  Widget _buildTodaySchedule(
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
          title: "TODAY'S SCHEDULE",
          actionLabel: 'See All',
          onAction: () {},
        ),
        _buildEmptyState(colors, 'No appointments today'),
      ],
    );
  }

  Widget _buildRecentActivity(
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
          title: 'RECENT ACTIVITY',
        ),
        _buildEmptyState(colors, 'No recent activity'),
      ],
    );
  }
}
