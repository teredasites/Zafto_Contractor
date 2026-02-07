import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class ClientMoreScreen extends ConsumerWidget {
  const ClientMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildMenuItem(
            colors,
            icon: Icons.description_outlined,
            label: 'Documents',
            subtitle: 'Contracts, permits, and files',
            onTap: () {},
          ),
          _buildMenuItem(
            colors,
            icon: Icons.payment_outlined,
            label: 'Payments',
            subtitle: 'Payment methods and history',
            onTap: () {},
          ),
          _buildMenuItem(
            colors,
            icon: Icons.chat_outlined,
            label: 'Contact Contractor',
            subtitle: 'Message or call your contractor',
            onTap: () {},
          ),
          _buildMenuItem(
            colors,
            icon: Icons.settings_outlined,
            label: 'Settings',
            subtitle: 'Account, notifications, preferences',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ZCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(ZaftoThemeBuilder.radiusSM),
              ),
              child: Icon(icon, color: colors.accentPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13,
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
      ),
    );
  }
}
