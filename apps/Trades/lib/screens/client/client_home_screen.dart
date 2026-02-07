import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

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
              _buildSectionHeader(colors, title: 'ACTIVE PROJECTS'),
              _buildEmptyState(colors, 'No active projects'),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, title: 'NEEDS YOUR ATTENTION'),
              _buildEmptyState(colors, 'No invoices due or bids to review'),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, title: 'HOME HEALTH'),
              _buildEmptyState(colors, 'No maintenance reminders'),
              const SizedBox(height: 20),
              _buildScanCta(colors),
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
        const ZAvatar(name: 'Homeowner', size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome home',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No address on file',
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

  Widget _buildScanCta(ZaftoColors colors) {
    return ZCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 40,
            color: colors.accentPrimary,
          ),
          const SizedBox(height: 12),
          Text(
            'See something wrong?',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Point your camera at it.',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          ZButton(
            label: 'Open Scanner',
            icon: Icons.camera_alt,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
