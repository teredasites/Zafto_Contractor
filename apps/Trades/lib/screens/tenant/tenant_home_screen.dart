import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

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
              const SizedBox(height: 20),
              _buildRentBalanceCard(colors),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, title: 'ALERTS'),
              _buildEmptyState(colors, 'No alerts'),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, title: 'QUICK ACTIONS'),
              _buildQuickActions(colors),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, title: 'RECENT ACTIVITY'),
              _buildEmptyState(colors, 'No recent activity'),
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
        const ZAvatar(name: 'Tenant', size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No unit assigned',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRentBalanceCard(ZaftoColors colors) {
    return ZCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'RENT BALANCE',
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
            '\$0 due',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: colors.accentSuccess,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Next due: ---',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          ZButton(
            label: 'Pay Now',
            icon: Icons.payment,
            onPressed: () {},
            isExpanded: true,
          ),
        ],
      ),
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

  Widget _buildQuickActions(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            colors,
            icon: Icons.payment,
            label: 'Pay Rent',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickAction(
            colors,
            icon: Icons.build_outlined,
            label: 'Submit Request',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickAction(
            colors,
            icon: Icons.description_outlined,
            label: 'View Lease',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickAction(
            colors,
            icon: Icons.chat_outlined,
            label: 'Contact',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.accentPrimary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
