import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/draft_recovery_provider.dart';
import '../services/draft_recovery_service.dart';

// ============================================================
// DraftRecoveryBanner — DEPTH27
//
// Floating pill at bottom of screen showing recoverable drafts.
// Place once in AppShell — works globally.
// Shows: "2 unsaved drafts" → tappable → expand to list.
// Each draft: feature icon, title, time ago, resume/discard.
// ============================================================

class DraftRecoveryBanner extends ConsumerStatefulWidget {
  final void Function(DraftRecord draft)? onResume;

  const DraftRecoveryBanner({super.key, this.onResume});

  @override
  ConsumerState<DraftRecoveryBanner> createState() =>
      _DraftRecoveryBannerState();
}

class _DraftRecoveryBannerState extends ConsumerState<DraftRecoveryBanner> {
  bool _expanded = false;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(activeDraftsProvider);

    return draftsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (drafts) {
        if (drafts.isEmpty || _dismissed) return const SizedBox.shrink();

        return Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header pill
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restore,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${drafts.length} unsaved draft${drafts.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _dismissed = true),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded draft list
                if (_expanded) ...[
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: drafts.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 52,
                      ),
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        return _DraftTile(
                          draft: draft,
                          onResume: () {
                            widget.onResume?.call(draft);
                          },
                          onDiscard: () async {
                            final svc = ref
                                .read(draftRecoveryServiceProvider);
                            await svc.deleteDraft(
                                draft.feature, draft.key);
                            ref.invalidate(activeDraftsProvider);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DraftTile extends StatelessWidget {
  final DraftRecord draft;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _DraftTile({
    required this.draft,
    required this.onResume,
    required this.onDiscard,
  });

  IconData _featureIcon(String feature) {
    switch (feature) {
      case 'sketch':
        return Icons.draw;
      case 'bid':
        return Icons.request_quote;
      case 'invoice':
        return Icons.receipt_long;
      case 'estimate':
        return Icons.calculate;
      case 'walkthrough':
        return Icons.directions_walk;
      case 'inspection':
        return Icons.fact_check;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.description;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _featureIcon(draft.feature),
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${draft.feature[0].toUpperCase()}${draft.feature.substring(1)} draft',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _timeAgo(draft.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (draft.isPinned)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.push_pin,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          // Resume
          IconButton(
            onPressed: onResume,
            icon: const Icon(Icons.open_in_new, size: 18),
            tooltip: 'Resume',
            visualDensity: VisualDensity.compact,
          ),
          // Discard
          IconButton(
            onPressed: onDiscard,
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Discard',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
