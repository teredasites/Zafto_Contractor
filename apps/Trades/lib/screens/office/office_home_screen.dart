import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class OfficeHomeScreen extends ConsumerWidget {
  const OfficeHomeScreen({super.key});

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
              _buildHeader(colors, textTheme),
              const SizedBox(height: 16),
              _buildQuickStats(colors),
              const SizedBox(height: 16),
              _buildSection(colors, textTheme, "TODAY'S TASKS"),
              const SizedBox(height: 12),
              _buildEmptyState(colors, 'No tasks for today'),
              const SizedBox(height: 16),
              _buildSection(colors, textTheme, 'OVERDUE ITEMS'),
              const SizedBox(height: 12),
              _buildEmptyState(colors, 'Nothing overdue'),
              const SizedBox(height: 16),
              _buildSection(colors, textTheme, 'LEAD ACTIVITY'),
              const SizedBox(height: 12),
              _buildEmptyState(colors, 'No recent lead activity'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors, TextTheme textTheme) {
    return Row(
      children: [
        const ZAvatar(name: 'Office Manager', size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text('Office Manager', style: textTheme.bodySmall),
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

  Widget _buildQuickStats(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(child: _buildStatItem(colors, 'Scheduled', '0')),
        const SizedBox(width: 8),
        Expanded(child: _buildStatItem(colors, 'Open Leads', '0')),
        const SizedBox(width: 8),
        Expanded(child: _buildStatItem(colors, 'Pending Inv.', '0')),
        const SizedBox(width: 8),
        Expanded(child: _buildStatItem(colors, 'Messages', '0')),
      ],
    );
  }

  Widget _buildStatItem(ZaftoColors colors, String label, String value) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
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
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ZaftoColors colors, TextTheme textTheme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colors.textTertiary,
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
}
