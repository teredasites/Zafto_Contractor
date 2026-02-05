// Expandable Reference Card Widget - Design System v2.6
// Reusable expandable card for reference screens
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/zafto_colors.dart';

/// Data model for expandable card content
class ExpandableCardData {
  final String title;
  final String subtitle;
  final String necRef;
  final String? fullNecText;
  final List<String>? exceptions;
  final List<String>? tips;
  final String? relatedDiagramRoute;
  final String? relatedDiagramTitle;

  const ExpandableCardData({
    required this.title,
    required this.subtitle,
    required this.necRef,
    this.fullNecText,
    this.exceptions,
    this.tips,
    this.relatedDiagramRoute,
    this.relatedDiagramTitle,
  });
}

/// Expandable reference card with Apple-style animation
class ExpandableReferenceCard extends StatefulWidget {
  final ExpandableCardData data;
  final ZaftoColors colors;
  final IconData? leadingIcon;
  final Color? leadingIconColor;

  const ExpandableReferenceCard({
    super.key,
    required this.data,
    required this.colors,
    this.leadingIcon,
    this.leadingIconColor,
  });

  @override
  State<ExpandableReferenceCard> createState() => _ExpandableReferenceCardState();
}

class _ExpandableReferenceCardState extends State<ExpandableReferenceCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  bool get _hasExpandedContent =>
      widget.data.fullNecText != null ||
      (widget.data.exceptions?.isNotEmpty ?? false) ||
      (widget.data.tips?.isNotEmpty ?? false) ||
      widget.data.relatedDiagramRoute != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_hasExpandedContent) return;
    
    HapticFeedback.selectionClick();
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
    final colors = widget.colors;
    final data = widget.data;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded ? colors.accentPrimary.withValues(alpha: 0.5) : colors.borderDefault,
        ),
      ),
      child: Column(
        children: [
          // Header (always visible)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _hasExpandedContent ? _toggle : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading icon
                    Icon(
                      widget.leadingIcon ?? LucideIcons.checkCircle,
                      color: widget.leadingIconColor ?? colors.accentSuccess,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    // Title & subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.subtitle,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // NEC ref badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data.necRef,
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Expand chevron (only if has content)
                    if (_hasExpandedContent) ...[
                      const SizedBox(width: 8),
                      RotationTransition(
                        turns: _rotateAnimation,
                        child: Icon(
                          LucideIcons.chevronDown,
                          color: colors.textTertiary,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Expanded content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildExpandedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    final colors = widget.colors;
    final data = widget.data;

    return Container(
      decoration: BoxDecoration(
        color: colors.fillDefault.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            color: colors.borderDefault,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full NEC text
                if (data.fullNecText != null) ...[
                  _ExpandedSection(
                    colors: colors,
                    icon: LucideIcons.fileText,
                    title: 'NEC Code Text',
                    child: Text(
                      data.fullNecText!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                // Exceptions
                if (data.exceptions?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  _ExpandedSection(
                    colors: colors,
                    icon: LucideIcons.alertCircle,
                    iconColor: Colors.orange,
                    title: 'Exceptions',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.exceptions!
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ', style: TextStyle(color: colors.textTertiary)),
                                    Expanded(
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                // Installation tips
                if (data.tips?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  _ExpandedSection(
                    colors: colors,
                    icon: LucideIcons.lightbulb,
                    iconColor: colors.accentWarning,
                    title: 'Installation Tips',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.tips!
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      LucideIcons.check,
                                      size: 14,
                                      color: colors.accentSuccess,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        t,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                // Related diagram link
                if (data.relatedDiagramRoute != null) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, data.relatedDiagramRoute!);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.accentPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.accentPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.gitBranch,
                              size: 16,
                              color: colors.accentPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'View ${data.relatedDiagramTitle ?? "Diagram"}',
                                style: TextStyle(
                                  color: colors.accentPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 16,
                              color: colors.accentPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section within expanded content
class _ExpandedSection extends StatelessWidget {
  final ZaftoColors colors;
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget child;

  const _ExpandedSection({
    required this.colors,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor ?? colors.textTertiary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// NEC Edition badge for top of reference screens
class NecEditionBadge extends StatelessWidget {
  final String edition;
  final ZaftoColors colors;

  const NecEditionBadge({
    super.key,
    required this.edition,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
          const SizedBox(width: 6),
          Text(
            'Based on $edition',
            style: TextStyle(
              color: colors.accentInfo,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
