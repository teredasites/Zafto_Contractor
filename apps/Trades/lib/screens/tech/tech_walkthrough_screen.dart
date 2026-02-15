import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/services/walkthrough_service.dart';
import 'package:zafto/models/walkthrough.dart';
import 'package:zafto/screens/walkthrough/walkthrough_start_screen.dart';
import 'package:zafto/screens/walkthrough/walkthrough_capture_screen.dart';
import 'package:zafto/screens/walkthrough/walkthrough_summary_screen.dart';

// ============================================================
// Tech Walkthrough Screen — Start & view walkthroughs
//
// CTA to start a new walkthrough + list of recent walkthroughs.
// Taps navigate to real walkthrough screens.
// ============================================================

class TechWalkthroughScreen extends ConsumerWidget {
  const TechWalkthroughScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final walkthroughsAsync = ref.watch(walkthroughsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('Walkthroughs'),
        backgroundColor: colors.bgBase,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildStartCTA(context, colors),
              const SizedBox(height: 24),
              _buildRecentSection(context, colors, ref, walkthroughsAsync),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartCTA(BuildContext context, ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalkthroughStartScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 0.5),
        ),
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
                LucideIcons.video,
                size: 32,
                color: colors.accentPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start New Walkthrough',
              style: TextStyle(
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
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.accentPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.circle, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Start Recording',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(
    BuildContext context,
    ZaftoColors colors,
    WidgetRef ref,
    AsyncValue<List<Walkthrough>> walkthroughsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'RECENT WALKTHROUGHS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.textTertiary,
            ),
          ),
        ),
        walkthroughsAsync.when(
          loading: () => Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: colors.accentPrimary),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.alertCircle, size: 32, color: colors.error),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load walkthroughs',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => ref.invalidate(walkthroughsProvider),
                    child: Text(
                      'Tap to retry',
                      style: TextStyle(fontSize: 13, color: colors.accentPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (walkthroughs) {
            if (walkthroughs.isEmpty) return _buildEmptyRecent(colors);

            // Show up to 10 most recent
            final recent = walkthroughs.take(10).toList();
            return Column(
              children: recent.map((w) => _buildWalkthroughCard(context, colors, w)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWalkthroughCard(
    BuildContext context,
    ZaftoColors colors,
    Walkthrough walkthrough,
  ) {
    final statusColor = _walkthroughStatusColor(walkthrough.status, colors);
    final timeAgo = _formatTimeAgo(walkthrough.createdAt);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (walkthrough.status == 'recording' || walkthrough.status == 'paused') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WalkthroughCaptureScreen(walkthroughId: walkthrough.id),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WalkthroughSummaryScreen(walkthroughId: walkthrough.id),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                walkthrough.status == 'completed'
                    ? LucideIcons.checkCircle
                    : walkthrough.status == 'recording'
                        ? LucideIcons.circle
                        : LucideIcons.clock,
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    walkthrough.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${walkthrough.walkthroughType} · $timeAgo',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                walkthrough.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecent(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.videoOff, size: 32, color: colors.textQuaternary),
            const SizedBox(height: 8),
            Text(
              'No walkthroughs yet',
              style: TextStyle(fontSize: 14, color: colors.textTertiary),
            ),
            const SizedBox(height: 4),
            Text(
              'Start your first walkthrough above',
              style: TextStyle(fontSize: 13, color: colors.textQuaternary),
            ),
          ],
        ),
      ),
    );
  }

  Color _walkthroughStatusColor(String status, ZaftoColors colors) {
    switch (status) {
      case 'completed':
        return colors.success;
      case 'recording':
        return Colors.red;
      case 'paused':
        return colors.warning;
      case 'draft':
        return colors.accentPrimary;
      default:
        return colors.textTertiary;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
