import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class TenantUnitScreen extends ConsumerWidget {
  const TenantUnitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('My Unit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildUnitInfoCard(colors),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, title: 'LEASE INFO'),
            _buildLeaseCard(colors),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, title: 'UPCOMING INSPECTIONS'),
            _buildEmptyState(
              colors,
              icon: Icons.search_outlined,
              message: 'No upcoming inspections',
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, title: 'UNIT HISTORY'),
            _buildEmptyState(
              colors,
              icon: Icons.history,
              message: 'No unit history',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitInfoCard(ZaftoColors colors) {
    return ZCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
            ),
            child: Icon(
              Icons.apartment,
              color: colors.accentPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unit ---',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No property address on file',
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
        ],
      ),
    );
  }

  Widget _buildLeaseCard(ZaftoColors colors) {
    return ZCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLeaseRow(colors, label: 'Start Date', value: '---'),
          Divider(height: 24, color: colors.borderSubtle),
          _buildLeaseRow(colors, label: 'End Date', value: '---'),
          Divider(height: 24, color: colors.borderSubtle),
          _buildLeaseRow(colors, label: 'Monthly Rent', value: '---'),
        ],
      ),
    );
  }

  Widget _buildLeaseRow(
    ZaftoColors colors, {
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, {required String title}) {
    return Padding(
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
    );
  }

  Widget _buildEmptyState(
    ZaftoColors colors, {
    required IconData icon,
    required String message,
  }) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: colors.textQuaternary),
            const SizedBox(height: 8),
            Text(
              message,
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
    );
  }
}
