import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';

// =============================================================================
// ZAFTO Design System v3 - Core Component Library
//
// 8 components: ZCard, ZButton, ZTextField, ZBottomSheet, ZChip, ZBadge,
//               ZAvatar, ZSkeleton
//
// All components use ZaftoColors via Theme.of(context).extension<ZaftoColors>()
// and ZaftoThemeBuilder for spacing/radius/animation constants.
// =============================================================================

// -----------------------------------------------------------------------------
// 1. ZCard
// -----------------------------------------------------------------------------

class ZCard extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Widget? header;
  final String? title;
  final Widget? trailing;

  const ZCard({
    super.key,
    this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.header,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) header!,
        if (title != null || trailing != null)
          Padding(
            padding: header != null
                ? const EdgeInsets.only(top: 12)
                : EdgeInsets.zero,
            child: Row(
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        if (child != null)
          Padding(
            padding: (title != null || header != null)
                ? const EdgeInsets.only(top: 12)
                : EdgeInsets.zero,
            child: child!,
          ),
      ],
    );

    final decoration = BoxDecoration(
      color: colors.bgElevated,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: colors.borderSubtle),
    );

    final Widget card = Container(
      margin: margin,
      decoration: decoration,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                splashColor: colors.fillDefault,
                highlightColor: colors.fillDefault.withValues(alpha: 0.5),
                child: Padding(
                  padding: padding,
                  child: content,
                ),
              ),
            )
          : Padding(
              padding: padding,
              child: content,
            ),
    );

    return card;
  }
}

// -----------------------------------------------------------------------------
// 2. ZButton
// -----------------------------------------------------------------------------

enum ZButtonVariant { primary, secondary, ghost, destructive }

enum ZButtonSize { small, medium, large }

class ZButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ZButtonVariant variant;
  final ZButtonSize size;
  final bool isExpanded;

  const ZButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = ZButtonVariant.primary,
    this.size = ZButtonSize.medium,
    this.isExpanded = false,
  });

  double get _minHeight {
    switch (size) {
      case ZButtonSize.small:
        return 36;
      case ZButtonSize.medium:
        return 44;
      case ZButtonSize.large:
        return 52;
    }
  }

  double get _fontSize {
    switch (size) {
      case ZButtonSize.small:
        return 13;
      case ZButtonSize.medium:
        return 15;
      case ZButtonSize.large:
        return 16;
    }
  }

  double get _iconSize {
    switch (size) {
      case ZButtonSize.small:
        return 16;
      case ZButtonSize.medium:
        return 18;
      case ZButtonSize.large:
        return 20;
    }
  }

  double get _horizontalPadding {
    switch (size) {
      case ZButtonSize.small:
        return 14;
      case ZButtonSize.medium:
        return 20;
      case ZButtonSize.large:
        return 24;
    }
  }

  double get _indicatorSize {
    switch (size) {
      case ZButtonSize.small:
        return 14;
      case ZButtonSize.medium:
        return 18;
      case ZButtonSize.large:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    Color bgColor;
    Color fgColor;
    Color? borderColor;

    switch (variant) {
      case ZButtonVariant.primary:
        bgColor = colors.accentPrimary;
        fgColor = Colors.white;
        borderColor = null;
      case ZButtonVariant.secondary:
        bgColor = colors.bgInset;
        fgColor = colors.textPrimary;
        borderColor = colors.borderDefault;
      case ZButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = colors.textSecondary;
        borderColor = null;
      case ZButtonVariant.destructive:
        bgColor = colors.accentError;
        fgColor = Colors.white;
        borderColor = null;
    }

    final bool enabled = onPressed != null && !isLoading;

    void handleTap() {
      if (!enabled) return;
      switch (variant) {
        case ZButtonVariant.ghost:
          ZaftoThemeBuilder.hapticLight();
        case ZButtonVariant.primary:
        case ZButtonVariant.destructive:
          ZaftoThemeBuilder.hapticMedium();
        case ZButtonVariant.secondary:
          ZaftoThemeBuilder.hapticLight();
      }
      onPressed?.call();
    }

    final buttonContent = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox.square(
            dimension: _indicatorSize,
            child: CupertinoActivityIndicator(
              color: fgColor,
              radius: _indicatorSize / 2,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: _iconSize, color: fgColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ],
    );

    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: ZaftoThemeBuilder.durationFast,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? handleTap : null,
          borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusFull),
          splashColor: fgColor.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: ZaftoThemeBuilder.durationFast,
            constraints: BoxConstraints(
              minHeight: _minHeight,
              minWidth: isExpanded ? double.infinity : 0,
            ),
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  BorderRadius.circular(ZaftoThemeBuilder.radiusFull),
              border: borderColor != null
                  ? Border.all(color: borderColor)
                  : null,
            ),
            alignment: Alignment.center,
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. ZTextField
// -----------------------------------------------------------------------------

class ZTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscure;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final TextInputType? keyboardType;

  const ZTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscure = false,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textQuaternary),
            prefixIcon: prefix,
            suffixIcon: suffix,
            filled: true,
            fillColor: colors.bgInset,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
              borderSide: BorderSide(
                color: hasError ? colors.accentError : colors.borderDefault,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
              borderSide: BorderSide(
                color: hasError ? colors.accentError : colors.borderSubtle,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
              borderSide: BorderSide(
                color:
                    hasError ? colors.accentError : colors.accentPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
              borderSide: BorderSide(color: colors.accentError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
              borderSide: BorderSide(color: colors.accentError, width: 2),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colors.accentError,
            ),
          ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 4. ZBottomSheet
// -----------------------------------------------------------------------------

class ZBottomSheet {
  ZBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
    List<Widget>? actions,
  }) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textQuaternary,
                      borderRadius: BorderRadius.circular(
                        ZaftoThemeBuilder.radiusFull,
                      ),
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: child,
                    ),
                  ),
                  // Actions
                  if (actions != null && actions.isNotEmpty) ...[
                    Divider(height: 1, color: colors.borderSubtle),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions
                              .expand((a) => [
                                    a,
                                    const SizedBox(width: 8),
                                  ])
                              .toList()
                            ..removeLast(),
                        ),
                      ),
                    ),
                  ] else
                    const SafeArea(
                      top: false,
                      child: SizedBox(height: 16),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 5. ZChip
// -----------------------------------------------------------------------------

class ZChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const ZChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final chipColor = color ?? colors.accentPrimary;

    final bgColor = isSelected
        ? chipColor.withValues(alpha: 0.1)
        : colors.bgInset;
    final fgColor = isSelected ? chipColor : colors.textSecondary;
    final bdColor = isSelected ? chipColor : colors.borderSubtle;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ZaftoThemeBuilder.durationFast,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              BorderRadius.circular(ZaftoThemeBuilder.radiusFull),
          border: Border.all(color: bdColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. ZBadge
// -----------------------------------------------------------------------------

enum ZBadgeSize { small, medium }

class ZBadge extends StatelessWidget {
  final String? label;
  final Color? color;
  final ZBadgeSize size;

  const ZBadge({
    super.key,
    this.label,
    this.color,
    this.size = ZBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final badgeColor = color ?? colors.accentPrimary;

    if (size == ZBadgeSize.small) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius:
            BorderRadius.circular(ZaftoThemeBuilder.radiusFull),
      ),
      child: Text(
        label ?? '',
        style: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. ZAvatar
// -----------------------------------------------------------------------------

class ZAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ZAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.onTap,
    this.onLongPress,
  });

  static const List<Color> _presetColors = [
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
  ];

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color get _bgColor {
    final index = name.hashCode.abs() % _presetColors.length;
    return _presetColors[index];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: colors.bgInset,
      );
    } else {
      avatar = CircleAvatar(
        radius: size / 2,
        backgroundColor: _bgColor,
        child: Text(
          _initials,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    // Outer ring (2px bgElevated border for outline effect)
    final Widget bordered = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.bgElevated, width: 2),
      ),
      child: avatar,
    );

    if (onTap != null || onLongPress != null) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: bordered,
      );
    }

    return bordered;
  }
}

// -----------------------------------------------------------------------------
// 8. ZSkeleton
// -----------------------------------------------------------------------------

class ZSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ZSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  State<ZSkeleton> createState() => _ZSkeletonState();
}

class _ZSkeletonState extends State<ZSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = Color.lerp(
          colors.bgInset,
          colors.borderSubtle,
          _animation.value,
        )!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
