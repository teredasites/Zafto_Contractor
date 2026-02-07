import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class ClientMyHomeScreen extends ConsumerWidget {
  const ClientMyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('My Home')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildPropertyCard(colors),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, title: 'SYSTEMS'),
            _buildEmptyState(
              colors,
              icon: Icons.settings_outlined,
              message: 'No systems registered',
              detail: 'HVAC, Water Heater, Electrical Panel',
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, title: 'MAINTENANCE LOG'),
            _buildEmptyState(
              colors,
              icon: Icons.build_outlined,
              message: 'No maintenance records',
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, title: 'FLOOR PLAN'),
            _buildFloorPlanPlaceholder(colors),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(ZaftoColors colors) {
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
              Icons.home_outlined,
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
                  'Property Address',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No address on file',
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
          Icon(
            Icons.chevron_right,
            color: colors.textQuaternary,
            size: 20,
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

  Widget _buildEmptyState(
    ZaftoColors colors, {
    required IconData icon,
    required String message,
    String? detail,
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
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colors.textQuaternary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloorPlanPlaceholder(ZaftoColors colors) {
    return ZCard(
      onTap: () {},
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.map_outlined,
              size: 40,
              color: colors.textQuaternary,
            ),
            const SizedBox(height: 12),
            Text(
              'Upload floor plan',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
