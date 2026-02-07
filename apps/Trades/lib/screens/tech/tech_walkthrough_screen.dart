import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class TechWalkthroughScreen extends ConsumerWidget {
  const TechWalkthroughScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('Walkthrough'),
        backgroundColor: colors.bgBase,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildStartCTA(context, colors, textTheme),
              const SizedBox(height: 24),
              _buildRecentSection(context, colors, textTheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartCTA(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
  ) {
    return ZCard(
      padding: const EdgeInsets.all(24),
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam_outlined,
              size: 32,
              color: colors.accentPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start New Walkthrough',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record a video walkthrough of the job site with voice notes and annotations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ZButton(
            label: 'Start Recording',
            icon: Icons.fiber_manual_record,
            onPressed: () {},
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(
    BuildContext context,
    ZaftoColors colors,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'RECENT WALKTHROUGHS',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.textTertiary,
            ),
          ),
        ),
        ZCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  size: 32,
                  color: colors.textQuaternary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No walkthroughs yet',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start your first walkthrough above',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: colors.textQuaternary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
