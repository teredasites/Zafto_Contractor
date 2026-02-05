import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO NEC Badge - Design System v2.6 / Phase 0.5
///
/// Blue-tinted badge for displaying NEC article references.
///
/// Structure:
/// ┌─────────────────────────────────────────────────┐
/// │  [Book Icon]  NEC 210.19(A) · Recommends ≤3%    │
/// └─────────────────────────────────────────────────┘
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoNecBadge(
///   article: 'NEC 210.19(A)',
///   description: 'Recommends ≤3%',
/// )
/// ```

class ZaftoNecBadge extends ConsumerWidget {
  /// The NEC article reference (e.g., "NEC 210.19(A)")
  final String article;

  /// Optional description text
  final String? description;

  /// Whether to add horizontal margin
  final bool addMargin;

  /// Callback when tapped (for expanding info)
  final VoidCallback? onTap;

  const ZaftoNecBadge({
    super.key,
    required this.article,
    this.description,
    this.addMargin = true,
    this.onTap,
  });

  // Spec: Blue accent color
  static const Color _blueAccent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        // Spec: margin 20px horizontal
        margin: addMargin ? const EdgeInsets.symmetric(horizontal: 20) : null,
        // Spec: 16px horizontal, 12px vertical padding
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Spec: Blue 8%
          color: const Color(0x143B82F6),
          // Spec: Blue 15% border
          border: Border.all(color: const Color(0x263B82F6)),
          // Spec: 12px border radius
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spec: bookOpen icon, 16px, Blue
            const Icon(
              LucideIcons.bookOpen,
              size: 16,
              color: _blueAccent,
            ),
            // Spec: 10px gap
            const SizedBox(width: 10),
            // Text
            Flexible(
              child: Text(
                _buildText(),
                // Spec: 13px, Blue
                style: const TextStyle(
                  fontSize: 13,
                  color: _blueAccent,
                ),
              ),
            ),
            // Chevron if tappable
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: _blueAccent.withOpacity(0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildText() {
    if (description != null) {
      return '$article · $description';
    }
    return article;
  }
}

/// Compact NEC badge for inline use
///
/// Usage:
/// ```dart
/// ZaftoNecBadgeCompact(article: 'NEC 310.16')
/// ```
class ZaftoNecBadgeCompact extends ConsumerWidget {
  final String article;
  final VoidCallback? onTap;

  const ZaftoNecBadgeCompact({
    super.key,
    required this.article,
    this.onTap,
  });

  static const Color _blueAccent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x143B82F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.bookOpen,
              size: 12,
              color: _blueAccent,
            ),
            const SizedBox(width: 6),
            Text(
              article,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// NEC badge with expandable info section
///
/// Usage:
/// ```dart
/// ZaftoNecBadgeExpandable(
///   article: 'NEC 210.19(A)',
///   title: 'Conductor Sizing',
///   content: 'Branch-circuit conductors shall have...',
/// )
/// ```
class ZaftoNecBadgeExpandable extends ConsumerStatefulWidget {
  final String article;
  final String title;
  final String content;
  final bool initiallyExpanded;

  const ZaftoNecBadgeExpandable({
    super.key,
    required this.article,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<ZaftoNecBadgeExpandable> createState() =>
      _ZaftoNecBadgeExpandableState();
}

class _ZaftoNecBadgeExpandableState
    extends ConsumerState<ZaftoNecBadgeExpandable>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late Animation<double> _expandAnimation;

  static const Color _blueAccent = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x143B82F6),
        border: Border.all(color: const Color(0x263B82F6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.bookOpen,
                    size: 16,
                    color: _blueAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.article} · ${widget.title}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _blueAccent,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: _blueAccent.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
