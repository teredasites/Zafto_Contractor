import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class InspectorHomeScreen extends ConsumerWidget {
  const InspectorHomeScreen({super.key});

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
              _buildStatsRow(colors),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    "TODAY'S INSPECTIONS",
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ZBadge(label: '0', color: colors.accentPrimary),
                ],
              ),
              const SizedBox(height: 12),
              ZCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Text(
                    'No inspections scheduled today',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ),
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
        const ZAvatar(name: 'Inspector', size: 44),
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
              Text('Inspector', style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(colors, 'Completed', '0', 'this week')),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(colors, 'Pass Rate', '0%', null)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(colors, 'Deficiencies', '0', 'found')),
      ],
    );
  }

  Widget _buildStatCard(ZaftoColors colors, String label, String value, String? subtitle) {
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: colors.textQuaternary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
